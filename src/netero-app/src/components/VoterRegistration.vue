<template>
  <div class="registration">
    <div class="field-row">
      <label>
        <span>Organizer address</span>
        <input v-model="orgAddressInternal" class="input" placeholder="0x..." />
      </label>
      <button class="btn btn-ghost" type="button" @click="loadOrgPolls" :disabled="loading">
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
    <p v-else class="helper">Deploy a poll or refresh once your ballot is live.</p>

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

      <div class="upload-row">
        <input type="file" accept=".csv,.txt" @change="onFile" />
        <span class="hint">Upload CSV or TXT — one address per line or comma-separated.</span>
      </div>

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
  props: {
    orgAddress: {
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
      addressesText: '',
      allowed: true,
      factory: null,
      loading: false,
      feedback: '',
      feedbackType: 'success',
    }
  },
  computed: {
    parsedAddresses() {
      return this.addressesText
        .split(/[\s,]+/)
        .map((value) => value.trim())
        .filter(Boolean)
    },
    addressCount() {
      return this.parsedAddresses.length
    },
  },
  watch: {
    orgAddress: {
      immediate: true,
      async handler(newOrg) {
        if (!newOrg) return
        this.orgAddressInternal = newOrg
        if (this.factory) {
          await this.loadOrgPolls()
        }
      },
    },
  },
  async mounted() {
    try {
      await initWeb3()
      const accounts = await getAccounts()
      this.orgAddressInternal = this.orgAddress || accounts[0]
      const addr = await getDeployedAddress(PollFactoryArtifact)
      this.factory = await getContract(PollFactoryArtifact, addr)
      await this.loadOrgPolls()
    } catch (error) {
      console.error('Voter registration bootstrap failed', error)
    }
  },
  methods: {
    async loadOrgPolls() {
      try {
        if (!this.factory || !this.orgAddressInternal) return
        const list = await this.factory.methods.getOrgPolls(this.orgAddressInternal).call()
        this.polls = list
        if (!this.selectedPollAddress && list.length) {
          this.selectedPollAddress = list[list.length - 1]
        } else if (this.selectedPollAddress && !list.includes(this.selectedPollAddress)) {
          this.selectedPollAddress = list[0] || ''
        }
        this.emitPolls()
      } catch (error) {
        console.error('Failed to load organizer polls', error)
      }
    },
    emitPolls() {
      this.$emit('polls-updated', this.polls)
    },
    onFile(e) {
      const file = e.target.files && e.target.files[0]
      if (!file) return
      const reader = new FileReader()
      reader.onload = () => {
        try {
          const content = String(reader.result || '')
          const items = content
            .split(/[\s,\n\r]+/)
            .map((s) => s.trim())
            .filter(Boolean)
          const merged = new Set([...
            this.parsedAddresses,
            ...items,
          ])
          this.addressesText = Array.from(merged).join('\n')
        } catch (err) {
          console.error('Failed to parse file', err)
        }
      }
      reader.readAsText(file)
      // reset value to allow re-uploading the same file
      e.target.value = ''
    },
    validateAddresses(addresses) {
      const invalid = addresses.find((address) => !/^0x[a-fA-F0-9]{40}$/.test(address))
      if (invalid) {
        throw new Error(`Invalid address: ${invalid}`)
      }
    },
    async setAllowlist() {
      if (!this.selectedPollAddress) return
      try {
        this.loading = true
        this.feedback = ''
        const addresses = this.parsedAddresses
        if (!addresses.length) {
          throw new Error('Provide at least one wallet address')
        }
        this.validateAddresses(addresses)
        const poll = await getContract(PollArtifact, this.selectedPollAddress)
        const accounts = await getAccounts()
        await poll.methods.setAllowlisted(addresses, this.allowed).send({ from: accounts[0] })
        this.feedbackType = 'success'
        this.feedback = `${addresses.length} wallet${addresses.length === 1 ? '' : 's'} ${
          this.allowed ? 'granted' : 'revoked'
        } access`
        this.addressesText = ''
      } catch (error) {
        console.error('Failed to update allowlist', error)
        this.feedbackType = 'error'
        this.feedback = error?.message || 'Unable to update allowlist'
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

.upload-row {
  display: flex;
  gap: 12px;
  align-items: center;
}

.upload-row .hint { font-size: 12px; color: var(--text-secondary); }

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
