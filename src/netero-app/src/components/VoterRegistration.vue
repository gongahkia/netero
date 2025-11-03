<template>
  <div class="voter-registration">
<<<<<<< HEAD
    <div class="section-header">
      <h2>// VOTER_REGISTRATION</h2>
      <div class="status-indicator">[ ACTIVE ]</div>
    </div>
    
    <form @submit.prevent="giveRightToVote" class="registration-form">
      <div class="form-section">
        <label class="section-label">&gt; ETHEREUM_ADDRESS:</label>
        <div class="input-wrapper">
          <span class="input-icon">0x</span>
          <input 
            v-model="voterAddress" 
            placeholder="ENTER_WALLET_ADDRESS" 
            required
            class="terminal-input"
          >
        </div>
      </div>
      
      <button type="submit" class="btn-primary">
        [ GRANT_VOTING_RIGHTS ]
      </button>
      
      <div v-if="lastRegistered" class="registration-result">
        <div class="result-label">&gt; LAST_REGISTERED:</div>
        <div class="registered-address">{{ lastRegistered }}</div>
      </div>
=======
    <h2>Allowlist Voters</h2>

    <div class="selector">
      <label>Org (defaults to your address):</label>
      <input v-model="orgAddress" placeholder="0x..." />
      <button @click="loadOrgPolls">Load Polls</button>
    </div>

    <template>
      <div class="registration">
        <div class="field-row">
          <label>
            <span>Organizer address</span>
            <input v-model="orgAddress" class="input" placeholder="0x..." />
          </label>
          <button class="btn btn-ghost" type="button" @click="loadOrgPolls">
            Refresh polls
          </button>
        </div>

        <label v-if="polls.length" class="select-label">
          <span>Target poll</span>
          <select class="input" v-model="selectedPollAddress" @change="emitPolls">
            <option disabled value="">Select a poll</option>
            <option v-for="poll in polls" :key="poll" :value="poll">{{ poll }}</option>
          </select>
        </label>
        <p v-else class="helper">Deploy a poll to populate this list.</p>

        <form v-if="selectedPollAddress" class="allowlist" @submit.prevent="setAllowlist">
          <label>
            <span>Wallets</span>
            <textarea
              v-model="addressesText"
              rows="4"
              class="input"
              placeholder="Paste addresses separated by commas or new lines"
              required
            ></textarea>
          </label>

          <div class="allow-controls">
            <label class="toggle">
              <input type="checkbox" v-model="allowed" />
              <span>{{ allowed ? 'Grant voting rights' : 'Revoke voting rights' }}</span>
            </label>
            <span class="count">{{ addressCount }} address{{ addressCount === 1 ? '' : 'es' }}</span>
          </div>

          <button class="btn btn-primary" type="submit" :disabled="loading">
            {{ loading ? 'Submitting…' : 'Update allowlist' }}
          </button>
        </form>

        <p v-if="feedback" :class="['feedback', feedbackType]">{{ feedback }}</p>
      </div>
    </template>

    <script>
    import { initWeb3, getAccounts, getDeployedAddress, getContract } from '../eth'
    import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
    import PollArtifact from '../../../core/build/contracts/Poll.json'

    export default {
      name: 'VoterRegistration',
      emits: ['polls-updated'],
      data() {
        return {
          orgAddress: '',
          polls: [],
          selectedPollAddress: '',
          addressesText: '',
          allowed: true,
          factory: null,
          loading: false,
          feedback: '',
          feedbackType: 'success',
        }
      },
      computed: {
        addressCount() {
          return this.addressesText
            .split(/[\s,]+/)
            .map((a) => a.trim())
            .filter(Boolean).length
        },
      },
      async mounted() {
        await initWeb3()
        const accounts = await getAccounts()
        this.orgAddress = accounts[0]
        const addr = await getDeployedAddress(PollFactoryArtifact)
        this.factory = await getContract(PollFactoryArtifact, addr)
        await this.loadOrgPolls()
      },
      methods: {
        async loadOrgPolls() {
          try {
            if (!this.factory || !this.orgAddress) return
            const list = await this.factory.methods.getOrgPolls(this.orgAddress).call()
            this.polls = list
            if (!this.selectedPollAddress && list.length) {
              this.selectedPollAddress = list[list.length - 1]
            }
            this.emitPolls()
          } catch (e) {
            console.error('Failed to load org polls', e)
          }
        },
        emitPolls() {
          this.$emit('polls-updated', this.polls)
        },
        normalise(address) {
          return address.trim().toLowerCase()
        },
        async setAllowlist() {
          try {
            this.loading = true
            this.feedback = ''
            const addresses = this.addressesText
              .split(/[\s,]+/)
              .map((a) => a.trim())
              .filter(Boolean)
            if (!addresses.length) {
              throw new Error('Provide at least one wallet address')
            }
            const invalid = addresses.find((addr) => !addr.startsWith('0x') || addr.length !== 42)
            if (invalid) {
              throw new Error(`Invalid address: ${invalid}`)
            }
            const poll = await getContract(PollArtifact, this.selectedPollAddress)
            const accounts = await getAccounts()
            await poll.methods.setAllowlisted(addresses, this.allowed).send({ from: accounts[0] })
            this.feedbackType = 'success'
            this.feedback = `${addresses.length} wallet${addresses.length === 1 ? '' : 's'} ${this.allowed ? 'granted' : 'revoked'} access`
            this.addressesText = ''
          } catch (e) {
            console.error('Failed to update allowlist', e)
            this.feedbackType = 'error'
            this.feedback = e?.message || 'Unable to update allowlist'
          } finally {
            this.loading = false
          }
        },
      },
    }
    </script>

    <style scoped>
    .registration {
      display: grid;
      gap: 24px;
    }

    .field-row {
      display: grid;
      gap: 12px;
    }

    @media (min-width: 680px) {
      .field-row {
        grid-template-columns: 1fr auto;
        align-items: end;
      }
    }

    label > span {
      display: block;
      margin-bottom: 6px;
      font-size: 13px;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      font-weight: 600;
    }

    .select-label {
      display: grid;
      gap: 8px;
    }

    .helper {
      color: var(--text-muted);
      font-size: 13px;
      margin: 0;
    }

    .allowlist {
      display: grid;
      gap: 16px;
    }

    .allow-controls {
      display: flex;
      flex-wrap: wrap;
      gap: 16px;
      align-items: center;
      justify-content: space-between;
    }

    .toggle {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
    }

    .count {
      font-size: 12px;
      color: var(--text-secondary);
    }

    .feedback {
      font-size: 13px;
      margin: 0;
    }

    .feedback.success {
      color: #166534;
    }

    .feedback.error {
      color: #b91c1c;
    }
    </style>
