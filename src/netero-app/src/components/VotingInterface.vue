<template>
  <div class="voting">
    <section class="poll-picker">
      <div class="picker-grid">
        <label>
          <span>Organizer</span>
          <input v-model="orgAddressInternal" class="input" placeholder="0x..." />
        </label>
        <button class="btn btn-ghost" type="button" @click="loadOrgPolls" :disabled="loading">
          Refresh
        </button>
      </div>

      <div v-if="!address" class="picker-grid poll-select">
        <label>
          <span>Poll</span>
          <select class="input" v-model="selectedPollAddress" @change="handlePollChange">
            <option disabled value="">Select a poll</option>
            <option v-for="poll in polls" :key="poll" :value="poll">{{ poll }}</option>
          </select>
        </label>
      </div>

      <div v-else class="preselected">
        <span>Using preselected poll</span>
        <code>{{ address }}</code>
      </div>
    </section>

    <div v-if="selectedPollAddress" class="poll-state">
      <span class="state-chip" :class="stateClass">{{ stateLabel }}</span>
      <span v-if="startTime" class="meta">Opens {{ formatTime(startTime * 1000) }}</span>
      <span v-if="endTime" class="meta">Closes {{ formatTime(endTime * 1000) }}</span>
      <span v-if="timerCopy" class="countdown">{{ timerCopy }}</span>
      <PollShare v-if="selectedPollAddress" :address="selectedPollAddress" />
    </div>

    <p v-if="status" class="status-message" :class="status.type">{{ status.message }}</p>

    <div v-if="restricted && !isAllowlisted" class="notice">
      <p>
        This poll is restricted. Your wallet isn’t allowlisted yet.
        Please contact the organizer to be added before voting.
      </p>
    </div>

    <form v-if="options.length" class="ballot" @submit.prevent="castVote">
      <div class="options">
        <label v-for="(option, index) in options" :key="`${option}-${index}`" class="option">
          <input type="radio" :value="index" v-model.number="selectedOption" />
          <span>{{ option }}</span>
        </label>
      </div>
      <template v-if="!privateMode">
        <button class="btn btn-primary" type="submit" :disabled="!canVote || submitting">
          {{ submitting ? 'Submitting…' : 'Cast vote' }}
        </button>
      </template>
      <template v-else>
        <div class="stack">
          <label v-if="needsProof" class="proof">
            <span>Merkle proof</span>
            <input class="input" v-model.trim="proofText" placeholder="0x...,0x...,0x..." />
          </label>
          <div class="row">
            <button class="btn btn-primary" type="button" @click="commit" :disabled="!canCommit || submitting">
              {{ submitting ? 'Submitting…' : 'Commit vote' }}
            </button>
            <button class="btn" type="button" @click="reveal" :disabled="!canReveal || submitting">
              {{ submitting ? 'Submitting…' : 'Reveal vote' }}
            </button>
          </div>
          <p class="hint">Your commitment is saved locally to help with reveal. Do not clear your browser storage until you reveal.</p>
        </div>
      </template>
    </form>

    <div v-else-if="selectedPollAddress" class="empty">No options found for this poll.</div>

    <div v-if="showAutoClose" class="autoclose">
      <p>The voting window elapsed. Sync the contract state to prevent further votes.</p>
      <button class="btn" type="button" @click="triggerAutoClose" :disabled="autoClosing">
        {{ autoClosing ? 'Syncing…' : 'Close voting window' }}
      </button>
    </div>
  </div>
</template>

<script>
import {
  initWeb3,
  getAccounts,
  getDeployedAddress,
  getContract,
  subscribeToEventOptional,
} from '../eth'
import PollShare from './PollShare.vue'
import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
import PollArtifact from '../../../core/build/contracts/Poll.json'

const STATE_LABELS = ['Draft', 'Active', 'Ended', 'Finalized']

export default {
  name: 'VotingInterface',
  components: { PollShare },
  props: {
    address: {
      type: String,
      default: '',
    },
  },
  emits: ['polls-updated'],
  data() {
    return {
      orgAddressInternal: '',
      polls: [],
      selectedPollAddress: '',
      poll: null,
      options: [],
      selectedOption: null,
      state: null,
      startTime: 0,
      endTime: 0,
      remainingSeconds: -1,
      countdownTimer: null,
      submitting: false,
      status: null,
      autoClosing: false,
      loading: false,
      factory: null,
      subscriptions: [],
      restricted: false,
      isAllowlisted: true,
      privateMode: false,
      proofText: '',
    }
  },
  computed: {
    stateLabel() {
      return STATE_LABELS[this.state] || 'Unknown'
    },
    stateClass() {
      switch (this.state) {
        case 1:
          return 'state-active'
        case 2:
          return 'state-ended'
        case 3:
          return 'state-finalized'
        default:
          return 'state-draft'
      }
    },
    canVote() {
      if (this.state !== 1) return false
      const now = Date.now() / 1000
      if (this.startTime && now < this.startTime) return false
      if (this.endTime && now > this.endTime) return false
      return this.selectedOption !== null && Boolean(this.selectedPollAddress)
    },
    timerCopy() {
      if (!this.endTime) return ''
      const seconds = this.remainingSeconds
      if (seconds <= 0) return 'Voting window elapsed'
      const h = Math.floor(seconds / 3600)
      const m = Math.floor((seconds % 3600) / 60)
      const s = seconds % 60
      return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s
        .toString()
        .padStart(2, '0')}`
    },
    showAutoClose() {
      return this.state === 1 && this.endTime && this.remainingSeconds <= 0
    },
  },
  watch: {
    address: {
      immediate: true,
      async handler(newAddress) {
        if (newAddress) {
          this.selectedPollAddress = newAddress
          await this.loadPoll()
          this.$emit('polls-updated', [newAddress])
        } else {
          this.selectedPollAddress = ''
          this.options = []
          this.status = null
          this.teardown()
        }
      },
    },
  },
  async mounted() {
    try {
      await initWeb3()
      const accounts = await getAccounts()
      this.orgAddressInternal = accounts[0]
      const factoryAddress = await getDeployedAddress(PollFactoryArtifact)
      this.factory = await getContract(PollFactoryArtifact, factoryAddress)
      // Support deep link via hash #poll=0x...
      this.applyHash()
      window.addEventListener('hashchange', this.applyHash)
      await this.loadOrgPolls()
      if (!this.address && this.polls.length && !this.selectedPollAddress) {
        this.selectedPollAddress = this.polls[this.polls.length - 1]
        await this.loadPoll()
      }
    } catch (error) {
      console.error('Voting interface bootstrap failed', error)
    }
  },
  beforeUnmount() {
    this.teardown()
    window.removeEventListener('hashchange', this.applyHash)
  },
  methods: {
    applyHash() {
      try {
        const hash = window.location.hash || ''
        const m = hash.match(/poll=(0x[a-fA-F0-9]{40})/)
        if (m && m[1] && !this.address) {
          this.selectedPollAddress = m[1]
        }
      } catch (e) { /* ignore */ }
    },
    async loadOrgPolls() {
      try {
        if (!this.factory || !this.orgAddressInternal) return
        this.loading = true
        const list = await this.factory.methods.getOrgPolls(this.orgAddressInternal).call()
        this.polls = list
        this.$emit('polls-updated', list)
        if (!this.address) {
          if (!this.selectedPollAddress && list.length) {
            this.selectedPollAddress = list[list.length - 1]
            await this.loadPoll()
          } else if (this.selectedPollAddress && !list.includes(this.selectedPollAddress)) {
            this.selectedPollAddress = list[0] || ''
            if (this.selectedPollAddress) {
              await this.loadPoll()
            } else {
              this.options = []
            }
          }
        }
      } catch (error) {
        console.error('Unable to load organizer polls', error)
      } finally {
        this.loading = false
      }
    },
    async handlePollChange() {
      await this.loadPoll()
    },
    async loadPoll() {
      if (!this.selectedPollAddress) return
      try {
        this.teardownSubscriptions()
        this.poll = await getContract(PollArtifact, this.selectedPollAddress)
        const [options, state, startTime, endTime, remaining, restricted, privateMode] = await Promise.all([
          this.poll.methods.getOptions().call(),
          this.poll.methods.state().call(),
          this.poll.methods.startTime().call(),
          this.poll.methods.endTime().call(),
          this.poll.methods.remainingSeconds().call().catch(() => '-1'),
          this.poll.methods.restricted().call().catch(() => false),
          this.poll.methods.privateMode().call().catch(() => false),
        ])
        this.options = options
        this.state = Number(state)
        this.startTime = Number(startTime)
        this.endTime = Number(endTime)
  this.restricted = Boolean(restricted)
  this.privateMode = Boolean(privateMode)
        const onChainRemaining = Number(remaining)
        const clockRemaining = this.endTime ? Math.floor(this.endTime - Date.now() / 1000) : onChainRemaining
        const candidates = [onChainRemaining, clockRemaining].filter((v) => Number.isFinite(v))
        this.remainingSeconds = candidates.length ? Math.min(...candidates) : -1
        this.selectedOption = null
        this.status = null
        await this.evaluateAllowlist()
        this.startCountdown()
        this.setupSubscriptions()
      } catch (error) {
        console.error('Failed to load poll details', error)
        this.status = { type: 'error', message: 'Unable to load poll details' }
      }
    },
    async evaluateAllowlist() {
      try {
        if (!this.poll) return
        if (!this.restricted) {
          this.isAllowlisted = true
          return
        }
        const accounts = await getAccounts()
        const me = accounts[0]
        if (!me) {
          this.isAllowlisted = false
          return
        }
        const allowed = await this.poll.methods.allowlist(me).call().catch(() => false)
        this.isAllowlisted = Boolean(allowed)
      } catch (e) {
        this.isAllowlisted = true
      }
    },
    startCountdown() {
      if (this.countdownTimer) {
        clearInterval(this.countdownTimer)
        this.countdownTimer = null
      }
      if (!this.endTime) {
        this.remainingSeconds = -1
        return
      }
      const update = () => {
        this.remainingSeconds = Math.floor(this.endTime - Date.now() / 1000)
      }
      update()
      this.countdownTimer = setInterval(update, 1000)
    },
    async castVote() {
      if (!this.poll || this.selectedOption === null) return
      if (this.restricted && !this.isAllowlisted) {
        this.setStatus('error', 'Your wallet is not allowlisted for this poll')
        return
      }
      if (this.privateMode) return // handled by commit/reveal
      try {
        this.submitting = true
        const accounts = await getAccounts()
        await this.poll.methods.vote(this.selectedOption).send({ from: accounts[0] })
        this.setStatus('success', 'Vote submitted successfully')
        this.selectedOption = null
      } catch (error) {
        console.error('Failed to cast vote', error)
        this.setStatus('error', error?.message || 'Unable to cast vote')
      } finally {
        this.submitting = false
      }
    },
    storageKey() {
      return `netero.commit.${(this.selectedPollAddress || '').toLowerCase()}`
    },
    saveCommit(salt, option) {
      try {
        const accounts = JSON.parse(localStorage.getItem(this.storageKey()) || '{}')
        const me = (this.cachedAccount || '').toLowerCase()
        accounts[me] = { salt, option }
        localStorage.setItem(this.storageKey(), JSON.stringify(accounts))
      } catch (e) { /* ignore */ }
    },
    loadCommit() {
      try {
        const accounts = JSON.parse(localStorage.getItem(this.storageKey()) || '{}')
        const me = (this.cachedAccount || '').toLowerCase()
        return accounts[me]
      } catch (e) { return null }
    },
    get cachedAccount() { return (this._acct || '') },
    async commit() {
      if (!this.poll || this.selectedOption === null) return
      try {
        this.submitting = true
        const accounts = await getAccounts()
        this._acct = accounts[0]
        const salt = '0x' + [...crypto.getRandomValues(new Uint8Array(32))].map(x => x.toString(16).padStart(2, '0')).join('')
        const commitment = window.web3 ? window.web3.utils.soliditySha3({t:'address', v: accounts[0]}, {t:'uint256', v: this.selectedOption}, {t:'bytes32', v: salt}) : null
        if (!commitment) throw new Error('Commit hash failed')
        const proof = (this.proofText || '').split(',').map(s => s.trim()).filter(Boolean)
        await this.poll.methods.commit(commitment, proof).send({ from: accounts[0] })
        this.saveCommit(salt, this.selectedOption)
        this.setStatus('success', 'Commit submitted. Reveal after the voting window ends.')
      } catch (e) {
        console.error('Commit failed', e)
        this.setStatus('error', e?.message || 'Commit failed')
      } finally { this.submitting = false }
    },
    async reveal() {
      try {
        this.submitting = true
        const accounts = await getAccounts()
        this._acct = accounts[0]
        const rec = this.loadCommit()
        if (!rec) throw new Error('No saved commitment for this wallet')
        await this.poll.methods.reveal(rec.option, rec.salt).send({ from: accounts[0] })
        this.setStatus('success', 'Reveal submitted')
      } catch (e) {
        console.error('Reveal failed', e)
        this.setStatus('error', e?.message || 'Reveal failed')
      } finally { this.submitting = false }
    },
    async triggerAutoClose() {
      if (!this.poll) return
      try {
        this.autoClosing = true
        const accounts = await getAccounts()
        await this.poll.methods.autoCloseIfExpired().send({ from: accounts[0] })
        await this.loadPoll()
        this.setStatus('success', 'Voting window closed')
      } catch (error) {
        console.error('Auto-close failed', error)
        this.setStatus('error', error?.message || 'Unable to close poll')
      } finally {
        this.autoClosing = false
      }
    },
    setupSubscriptions() {
      if (!this.poll || !this.selectedPollAddress) return
      try {
        const stateSub = subscribeToEventOptional(
          PollArtifact.abi,
          this.selectedPollAddress,
          'StateChanged',
          async () => {
            try {
              await this.loadPoll()
            } catch (error) {
              console.error('Failed to refresh poll state', error)
            }
          }
        )
        const voteSub = subscribeToEventOptional(
          PollArtifact.abi,
          this.selectedPollAddress,
          'Voted',
          () => {
            if (!this.status || this.status.type !== 'success') {
              this.setStatus('success', 'New vote recorded')
            }
          }
        )
        this.subscriptions = [stateSub, voteSub].filter(Boolean)
      } catch (error) {
        console.warn('Event subscriptions unavailable', error)
      }
    },
    teardown() {
      if (this.countdownTimer) {
        clearInterval(this.countdownTimer)
        this.countdownTimer = null
      }
      this.teardownSubscriptions()
    },
    teardownSubscriptions() {
      this.subscriptions.forEach((subscription) => {
        if (subscription && typeof subscription.unsubscribe === 'function') {
          try {
            subscription.unsubscribe()
          } catch (error) {
            // ignore
          }
        }
      })
      this.subscriptions = []
    },
    setStatus(type, message) {
      this.status = { type, message }
    },
    formatTime(timestamp) {
      const date = new Date(Number(timestamp))
      return date.toLocaleString()
    },
  },
}
</script>

<style scoped>
.voting {
  display: grid;
  gap: 24px;
}

.poll-picker {
  display: grid;
  gap: 16px;
}

.picker-grid {
  display: grid;
  gap: 12px;
}

@media (min-width: 720px) {
  .picker-grid {
    grid-template-columns: 1fr auto;
    align-items: end;
  }
}

label > span {
  display: block;
  margin-bottom: 6px;
  font-size: 13px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.preselected {
  display: flex;
  gap: 12px;
  align-items: center;
  font-size: 13px;
  color: var(--text-secondary);
  padding: 12px 16px;
  border: 1px dashed var(--border);
  border-radius: var(--radius-sm);
  background: var(--bg-muted);
}

.preselected code {
  font-size: 12px;
}

.poll-state {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  align-items: center;
  font-size: 13px;
  color: var(--text-secondary);
}

.state-chip {
  padding: 4px 10px;
  border-radius: 12px;
  font-weight: 600;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

.state-draft {
  background: #f3f4f6;
  color: #1f2937;
}

.state-active {
  background: #dcfce7;
  color: #166534;
}

.state-ended {
  background: #fee2e2;
  color: #b91c1c;
}

.state-finalized {
  background: #e0e7ff;
  color: #3730a3;
}

.meta {
  color: var(--text-muted);
}

.ballot {
  display: grid;
  gap: 20px;
}

.options {
  display: grid;
  gap: 12px;
}

.option {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: var(--bg-muted);
}

.option:hover {
  border-color: var(--border-strong);
}

.empty {
  font-size: 13px;
  color: var(--text-muted);
}

.status-message {
  font-size: 13px;
  margin: 0;
}

.status-message.success {
  color: #166534;
}

.status-message.error {
  color: #b91c1c;
}

.notice {
  padding: 12px 14px;
  border: 1px dashed var(--border);
  border-radius: var(--radius-sm);
  background: var(--bg-muted);
  font-size: 13px;
  color: var(--text-secondary);
}

.autoclose {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: center;
  padding: 16px;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: var(--bg-muted);
  font-size: 13px;
}

.countdown {
  font-weight: 600;
  color: var(--text-primary);
}

.row { display: flex; gap: 12px; align-items: center; }
.hint { color: var(--text-muted); font-size: 12px; }
.proof span { display: block; margin-bottom: 6px; font-size: 13px; color: var(--text-muted); text-transform: uppercase; letter-spacing: .05em; }
</style>
