<template>
  <form class="ballot-form" @submit.prevent="createPoll">
    <div class="form-grid">
      <label>
        <span>Title</span>
        <input v-model.trim="title" class="input" placeholder="e.g. Q4 budget approval" required />
      </label>
      <label>
        <span>Voting mode</span>
        <div class="toggle-row">
          <input id="restrictedToggle" type="checkbox" v-model="restricted" />
          <label for="restrictedToggle">Restrict to allowlisted wallets</label>
        </div>
      </label>
    </div>

    <label>
      <span>Description</span>
      <textarea
        v-model.trim="description"
        rows="3"
        class="input"
        placeholder="Add context so voters understand what they're approving"
      ></textarea>
    </label>

    <section class="options">
      <div class="options-header">
        <span>Options</span>
        <button class="btn btn-ghost" type="button" @click="addOption">Add option</button>
      </div>
      <div v-for="(option, index) in options" :key="index" class="option-row">
        <input
          v-model.trim="options[index]"
          class="input"
          :placeholder="`Option ${index + 1}`"
          required
        />
        <button
          v-if="options.length > 2"
          class="btn btn-ghost"
          type="button"
          @click="removeOption(index)"
        >
          Remove
        </button>
      </div>
    </section>

    <section class="schedule">
      <div class="schedule-header">
        <span>Scheduling</span>
        <div class="radio-group">
          <label><input type="radio" value="immediate" v-model="startMode" /> Open immediately</label>
          <label><input type="radio" value="scheduled" v-model="startMode" /> Start later</label>
        </div>
      </div>

      <div v-if="startMode === 'scheduled'" class="schedule-grid">
        <label>
          <span>Start date & time</span>
          <input type="datetime-local" class="input" v-model="scheduledAt" required />
        </label>
      </div>

      <div class="duration-grid">
        <label>
          <span>Duration</span>
          <div class="duration-row">
            <input type="number" min="0" class="input" v-model.number="durationHours" />
            <span class="suffix">hours</span>
            <input type="number" min="0" max="59" class="input" v-model.number="durationMinutes" />
            <span class="suffix">minutes</span>
          </div>
        </label>
        <label class="auto-activate">
          <input type="checkbox" v-model="autoActivate" />
          <span>Activate automatically after deployment</span>
        </label>
      </div>
    </section>

    <section class="modes">
      <div class="mode-row">
        <label class="toggle">
          <input type="checkbox" v-model="privateMode" />
          <span>Private voting (commit → reveal)</span>
        </label>
        <label class="toggle">
          <input type="checkbox" v-model="restricted" />
          <span>Restrict to allowlist</span>
        </label>
      </div>
      <div class="grid-adv">
        <label>
          <span>Merkle root (optional)</span>
          <input class="input" v-model.trim="merkleRoot" placeholder="0x… (32-byte hex)" />
        </label>
        <label>
          <span>Trusted forwarder (optional)</span>
          <input class="input" v-model.trim="trustedForwarder" placeholder="0x… forwarder address" />
        </label>
      </div>
    </section>

    <p v-if="error" class="form-error">{{ error }}</p>

    <button class="btn btn-primary" type="submit" :disabled="submitting">
      {{ submitting ? 'Deploying…' : 'Deploy poll' }}
    </button>

    <div v-if="createdPoll.address" class="result-card">
      <div>
        <span class="label">Poll address</span>
        <code>{{ createdPoll.address }}</code>
      </div>
      <div class="result-meta" v-if="createdPoll.endTime">
        <span class="label">Closes</span>
        <span>{{ formatDate(createdPoll.endTime * 1000) }}</span>
      </div>
    </div>
  </form>
</template>

<script>
import { initWeb3, getAccounts, getDeployedAddress, getContract } from '../eth'
import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
import PollArtifact from '../../../core/build/contracts/Poll.json'

export default {
  name: 'BallotCreation',
  emits: ['poll-created'],
  data() {
    return {
      title: '',
      description: '',
      options: ['', ''],
      restricted: false,
      privateMode: false,
      merkleRoot: '',
      trustedForwarder: '',
      startMode: 'immediate',
      scheduledAt: '',
      durationHours: 0,
      durationMinutes: 30,
      autoActivate: true,
      submitting: false,
      createdPoll: {
        address: '',
        endTime: 0,
      },
      error: '',
      factory: null,
    }
  },
  async mounted() {
    await this.init()
  },
  methods: {
    async init() {
      if (this.factory) return
      await initWeb3()
      const address = await getDeployedAddress(PollFactoryArtifact)
      this.factory = await getContract(PollFactoryArtifact, address)
    },
    addOption() {
      this.options.push('')
    },
    removeOption(index) {
      this.options.splice(index, 1)
    },
    validateOptions() {
      const filled = this.options.filter((option) => option && option.trim().length)
      if (filled.length < 2) {
        throw new Error('Provide at least two options')
      }
    },
    computeSchedule() {
      const now = Math.floor(Date.now() / 1000)
      let startTime = 0
      if (this.startMode === 'scheduled') {
        if (!this.scheduledAt) throw new Error('Select a start date')
        const parsed = Math.floor(new Date(this.scheduledAt).getTime() / 1000)
        if (!parsed || Number.isNaN(parsed)) throw new Error('Invalid start time')
        startTime = parsed
      } else {
        startTime = now
      }
      const durationSeconds = (Number(this.durationHours) || 0) * 3600 + (Number(this.durationMinutes) || 0) * 60
      const endTime = durationSeconds > 0 ? startTime + durationSeconds : 0
      return { startTime, endTime }
    },
    async createPoll() {
      this.error = ''
      try {
        this.validateOptions()
        const { startTime, endTime } = this.computeSchedule()
        await this.init()
        this.submitting = true
        const accounts = await getAccounts()
        const org = accounts[0]
        const tx = await this.factory.methods
          .createPoll(
            org,
            this.title,
            this.description,
            this.options,
            startTime,
            endTime,
            this.restricted,
            this.privateMode,
            this.trustedForwarder || '0x0000000000000000000000000000000000000000',
            this.merkleRoot || '0x0000000000000000000000000000000000000000000000000000000000000000'
          )
          .send({ from: accounts[0] })

        const event = tx.events?.PollCreated || (tx.logs || []).find((log) => log.event === 'PollCreated')
        const pollAddress = event ? event.returnValues?.poll || event.args?.poll : null
        this.createdPoll = {
          address: pollAddress || '',
          endTime,
        }
        if (pollAddress) {
          this.$emit('poll-created', pollAddress)
          if (this.autoActivate) {
            try {
              const poll = await getContract(PollArtifact, pollAddress)
              await poll.methods.activate().send({ from: accounts[0] })
            } catch (activationError) {
              console.warn('Auto-activation failed', activationError)
            }
          }
        }

        this.resetForm()
      } catch (error) {
        console.error('Error creating poll', error)
        this.error = error?.message || 'Failed to deploy poll'
      } finally {
        this.submitting = false
      }
    },
    resetForm() {
      this.title = ''
      this.description = ''
      this.options = ['', '']
      this.restricted = false
      this.privateMode = false
      this.merkleRoot = ''
      this.trustedForwarder = ''
      this.startMode = 'immediate'
      this.scheduledAt = ''
      this.durationHours = 0
      this.durationMinutes = 30
      this.autoActivate = true
    },
    formatDate(timestamp) {
      const date = new Date(Number(timestamp))
      return date.toLocaleString()
    },
  },
}
</script>

<style scoped>
.ballot-form {
  display: grid;
  gap: 24px;
}

.ballot-form label > span {
  display: block;
  margin-bottom: 8px;
  font-size: 13px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--text-muted);
}

.form-grid {
  display: grid;
  gap: 18px;
}

@media (min-width: 880px) {
  .form-grid {
    grid-template-columns: 2fr 1fr;
  }
}

.toggle-row {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 14px;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: var(--bg-muted);
}

.options {
  display: grid;
  gap: 16px;
}

.options-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.option-row {
  display: grid;
  gap: 12px;
}

@media (min-width: 720px) {
  .option-row {
    grid-template-columns: 1fr auto;
    align-items: center;
  }
}

.schedule {
  display: grid;
  gap: 16px;
  padding: 20px;
  border: 1px solid var(--border);
  border-radius: var(--radius);
  background: var(--bg-muted);
}

.schedule-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.schedule-header span {
  font-size: 13px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--text-muted);
}

.radio-group {
  display: flex;
  gap: 16px;
  font-size: 13px;
}

.schedule-grid {
  display: grid;
  gap: 12px;
}

.duration-grid {
  display: grid;
  gap: 16px;
}

@media (min-width: 720px) {
  .duration-grid {
    grid-template-columns: 1fr auto;
    align-items: center;
  }
}

.duration-row {
  display: grid;
  gap: 8px;
  grid-template-columns: repeat(4, auto);
  align-items: center;
}

.duration-row .input {
  width: 100px;
}

.suffix {
  font-size: 13px;
  color: var(--text-secondary);
}

.auto-activate {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  color: var(--text-secondary);
}

.form-error {
  color: #d14343;
  font-size: 13px;
}

.result-card {
  margin-top: 8px;
  padding: 16px 18px;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: var(--bg-muted);
  display: grid;
  gap: 12px;
}

.result-card .label {
  font-size: 12px;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.result-card code {
  font-size: 14px;
}

.result-meta {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
</style>
