<template>
  <div class="voting-interface">
<<<<<<< HEAD
    <div class="section-header">
      <h2>// CAST_VOTE</h2>
      <div class="status-indicator">[ {{ proposals.length }} PROPOSALS ]</div>
    </div>
    
    <form @submit.prevent="castVote" class="vote-form">
      <div class="proposals-list">
        <label class="section-label">&gt; SELECT_PROPOSAL:</label>
        <div v-if="proposals.length > 0">
          <div 
            v-for="(proposal, index) in proposals" 
            :key="index"
            class="proposal-option"
          >
            <input 
              type="radio" 
              :id="'proposal-' + index" 
              :value="index" 
              v-model="selectedProposal"
              class="radio-input"
            >
            <label :for="'proposal-' + index" class="proposal-label">
              <span class="proposal-index">[{{ String(index + 1).padStart(2, '0') }}]</span>
              <span class="proposal-name">{{ web3 ? web3.utils.hexToUtf8(proposal.name) : '' }}</span>
            </label>
          </div>
        </div>
        <div v-else class="no-proposals">
          &gt; NO_PROPOSALS_AVAILABLE
        </div>
      </div>
      
      <template>
        <div class="voting">
          <section class="poll-picker">
            <div class="picker-grid">
              <label>
                <span>Organizer</span>
                <input v-model="orgAddress" class="input" placeholder="0x..." />
              </label>
              <button class="btn btn-ghost" type="button" @click="loadOrgPolls">
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
          </div>

          <p v-if="status" class="status-message" :class="status.type">{{ status.message }}</p>

          <form v-if="options.length" class="ballot" @submit.prevent="castVote">
            <div class="options">
              <label v-for="(option, index) in options" :key="index" class="option">
                <input type="radio" :value="index" v-model.number="selectedOption" />
                <span>{{ option }}</span>
              </label>
            </div>
            <button class="btn btn-primary" type="submit" :disabled="!canVote || submitting">
              {{ submitting ? 'Submitting…' : 'Cast vote' }}
            </button>
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
      import { initWeb3, getAccounts, getDeployedAddress, getContract, subscribeToEventOptional } from '../eth'
      import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
      import PollArtifact from '../../../core/build/contracts/Poll.json'

      const STATE_LABELS = ['Draft', 'Active', 'Ended', 'Finalized']

      export default {
        name: 'VotingInterface',
        props: {
          address: {
            type: String,
            default: '',
          },
        },
        emits: ['polls-updated'],
        data() {
          return {
            orgAddress: '',
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
            factory: null,
            stateSubscription: null,
            voteSubscription: null,
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
            if (this.startTime && Date.now() < this.startTime * 1000) return false
            if (this.endTime && Date.now() > this.endTime * 1000) return false
            return this.selectedOption !== null && this.selectedPollAddress
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
            handler(newAddress) {
              if (newAddress) {
                this.selectedPollAddress = newAddress
                this.loadPoll()
                this.$emit('polls-updated', [newAddress])
              }
            },
          },
        },
        async mounted() {
          try {
            await initWeb3()
            const accounts = await getAccounts()
            this.orgAddress = accounts[0]
            const factoryAddress = await getDeployedAddress(PollFactoryArtifact)
            this.factory = await getContract(PollFactoryArtifact, factoryAddress)
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
        },
        methods: {
          async loadOrgPolls() {
            try {
              if (!this.factory || !this.orgAddress) return
              const list = await this.factory.methods.getOrgPolls(this.orgAddress).call()
              this.polls = list
              this.$emit('polls-updated', list)
            } catch (error) {
              console.error('Unable to load polls', error)
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
              const [options, state, startTime, endTime] = await Promise.all([
                this.poll.methods.getOptions().call(),
                this.poll.methods.state().call(),
                this.poll.methods.startTime().call(),
                this.poll.methods.endTime().call(),
              ])
              this.options = options
              this.state = Number(state)
              this.startTime = Number(startTime)
              this.endTime = Number(endTime)
              this.selectedOption = null
              this.status = null
              this.startCountdown()
              this.setupSubscriptions()
            } catch (error) {
              console.error('Failed to load poll', error)
              this.status = { type: 'error', message: 'Unable to load poll details' }
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
            try {
              this.submitting = true
              const accounts = await getAccounts()
              await this.poll.methods.vote(this.selectedOption).send({ from: accounts[0] })
              this.status = { type: 'success', message: 'Vote submitted successfully' }
              this.selectedOption = null
            } catch (error) {
              console.error('Failed to cast vote', error)
              const message = error?.message || 'Unable to cast vote'
              this.status = { type: 'error', message }
            } finally {
              this.submitting = false
            }
          },
          async triggerAutoClose() {
            if (!this.poll) return
            try {
              this.autoClosing = true
              const accounts = await getAccounts()
              await this.poll.methods.autoCloseIfExpired().send({ from: accounts[0] })
              await this.loadPoll()
              this.status = { type: 'success', message: 'Voting window closed' }
            } catch (error) {
              console.error('Auto-close failed', error)
              this.status = { type: 'error', message: error?.message || 'Unable to close poll' }
            } finally {
              this.autoClosing = false
            }
          },
          setupSubscriptions() {
            if (!this.poll || !this.selectedPollAddress) return
            try {
              this.stateSubscription = subscribeToEventOptional(
                PollArtifact.abi,
                this.selectedPollAddress,
                'StateChanged',
                async () => {
                  try {
                    const state = await this.poll.methods.state().call()
                    this.state = Number(state)
                  } catch (error) {
                    console.error('Failed to refresh state', error)
                  }
                }
              )
              this.voteSubscription = subscribeToEventOptional(
                PollArtifact.abi,
                this.selectedPollAddress,
                'Voted',
                () => {
                  if (!this.status || this.status.type !== 'success') return
                  this.status = { type: 'success', message: 'Vote submitted successfully' }
                }
              )
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
            const subs = [this.stateSubscription, this.voteSubscription]
            subs.forEach((sub) => {
              if (sub && typeof sub.unsubscribe === 'function') {
                try {
                  sub.unsubscribe()
                } catch (error) {
                  // ignore
                }
              }
            })
            this.stateSubscription = null
            this.voteSubscription = null
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

      .countdown {
        font-weight: 600;
        color: var(--text-primary);
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

      .preselected {
        display: flex;
        flex-direction: column;
        gap: 6px;
        padding: 12px 16px;
        border: 1px solid var(--border);
        border-radius: var(--radius-sm);
        background: var(--bg-muted);
        font-size: 13px;
      }

      .meta {
        color: var(--text-muted);
      }
      </style>
