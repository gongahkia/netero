<template>
  <div class="results">
    <section class="picker">
      <div class="picker-row">
        <label>
          <span>Organizer</span>
          <input v-model="orgAddress" class="input" placeholder="0x..." />
        </label>
        <button class="btn btn-ghost" type="button" @click="loadOrgPolls">Refresh</button>
      </div>

      <div v-if="!address" class="picker-row">
        <label>
          <span>Poll</span>
          <select class="input" v-model="selectedPollAddress" @change="handlePollChange">
            <option disabled value="">Select a poll</option>
            <option v-for="poll in polls" :key="poll" :value="poll">{{ poll }}</option>
          </select>
        </label>
      </div>
    </section>

    <section v-if="selectedPollAddress" class="summary">
      <div class="summary-text">
        <h3>{{ title || shortAddress(selectedPollAddress) }}</h3>
        <p v-if="description">{{ description }}</p>
        <p v-if="!description" class="muted">No description provided.</p>
      </div>
      <div class="state">
        <span class="state-chip" :class="stateClass">{{ stateLabel }}</span>
        <span v-if="totalVotes >= 0" class="meta">{{ totalVotes }} vote{{ totalVotes === 1 ? '' : 's' }}</span>
      </div>
    </section>

    <div v-if="selectedPollAddress" class="grid">
      <section class="card tally-card">
        <header>
          <h4>Breakdown</h4>
          <span v-if="winningOption" class="meta">In the lead: {{ winningOption }}</span>
        </header>
        <p v-if="!options.length" class="placeholder">No options configured for this poll yet.</p>
        <ul v-else class="tally-list">
          <li v-for="(option, index) in options" :key="option" class="tally-item">
            <div>
              <span class="option-name">{{ option }}</span>
              <span class="option-count">{{ tallies[index] || 0 }} votes</span>
            </div>
            <div class="progress">
              <div class="progress-bar" :style="{ width: optionPercentage(index) + '%' }"></div>
            </div>
          </li>
        </ul>
      </section>

      <section class="card chart-card">
        <header>
          <h4>Distribution</h4>
        </header>
        <canvas ref="chart" height="200"></canvas>
        <div v-if="isAdmin" class="admin-actions">
          <button v-if="state === 0" class="btn" type="button" @click="activate">Activate</button>
          <button v-if="state === 1" class="btn" type="button" @click="end">End voting</button>
          <button v-if="state === 2" class="btn" type="button" @click="finalize">Finalize</button>
        </div>
      </section>
    </div>

    <div v-else class="empty">Select a poll to view results.</div>
  </div>
</template>

<script>
import { initWeb3, getAccounts, getDeployedAddress, getContract, subscribeToEventOptional } from '../eth'
import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
import PollArtifact from '../../../core/build/contracts/Poll.json'
import { Chart, ArcElement, Tooltip, Legend } from 'chart.js'

Chart.register(ArcElement, Tooltip, Legend)

const STATE_LABELS = ['Draft', 'Active', 'Ended', 'Finalized']

export default {
  name: 'ResultsDisplay',
  props: {
    address: {
      type: String,
      default: '',
    },
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
      poll: null,
      options: [],
      tallies: [],
      title: '',
      description: '',
      state: 0,
      totalVotes: 0,
      winningOption: '',
      isAdmin: false,
      chartInstance: null,
      refreshInterval: null,
      subscriptions: [],
      factory: null,
    }
  },
  computed: {
    orgAddress: {
      get() {
        return this.orgAddressInternal
      },
      set(value) {
        this.orgAddressInternal = value
      },
    },
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
  },
  watch: {
    address: {
      immediate: true,
      async handler(newAddress) {
        if (newAddress) {
          this.selectedPollAddress = newAddress
          await this.loadResults()
          this.$emit('polls-updated', [newAddress])
        }
      },
    },
  },
  async mounted() {
    try {
      await initWeb3()
      const accounts = await getAccounts()
      this.orgAddressInternal = this.orgAddress || accounts[0]
      const factoryAddress = await getDeployedAddress(PollFactoryArtifact)
      this.factory = await getContract(PollFactoryArtifact, factoryAddress)
      await this.loadOrgPolls()
      if (!this.address && this.polls.length && !this.selectedPollAddress) {
        this.selectedPollAddress = this.polls[this.polls.length - 1]
        await this.loadResults()
      }
    } catch (error) {
      console.error('Results display bootstrap failed', error)
    }
  },
  beforeUnmount() {
    this.teardown()
  },
  methods: {
    async loadOrgPolls() {
      try {
        if (!this.factory || !this.orgAddressInternal) return
        const list = await this.factory.methods.getOrgPolls(this.orgAddressInternal).call()
        this.polls = list
        this.$emit('polls-updated', list)
      } catch (error) {
        console.error('Failed to load organizer polls', error)
      }
    },
    async handlePollChange() {
      await this.loadResults()
    },
    optionPercentage(index) {
      if (!this.totalVotes) return 0
      return Math.round(((this.tallies[index] || 0) / this.totalVotes) * 100)
    },
    async loadResults() {
      if (!this.selectedPollAddress) return
      try {
        this.teardownSubscriptions()
        this.poll = await getContract(PollArtifact, this.selectedPollAddress)
        const [options, tallies, title, description, state, admin] = await Promise.all([
          this.poll.methods.getOptions().call(),
          this.poll.methods.getTallies().call(),
          this.poll.methods.title().call(),
          this.poll.methods.description().call(),
          this.poll.methods.state().call(),
          this.poll.methods.admin().call(),
        ])
        const accounts = await getAccounts()
        this.isAdmin = accounts[0]?.toLowerCase() === admin.toLowerCase()
        this.options = options
        this.tallies = tallies.map((value) => Number(value))
        this.title = title
        this.description = description
        this.state = Number(state)
        this.totalVotes = this.tallies.reduce((sum, value) => sum + value, 0)
        const leaderIndex = this.tallies.reduce(
          (bestIndex, value, currentIndex, array) => (value > array[bestIndex] ? currentIndex : bestIndex),
          0
        )
        this.winningOption = options[leaderIndex] || ''
        this.renderChart()
        this.setupRefresh()
        this.setupSubscriptions()
      } catch (error) {
        console.error('Failed to load poll results', error)
      }
    },
    renderChart() {
      if (!this.$refs.chart) return
      const ctx = this.$refs.chart.getContext('2d')
      const data = {
        labels: this.options,
        datasets: [
          {
            label: 'Votes',
            data: this.tallies,
            backgroundColor: ['#111827', '#4b5563', '#6b7280', '#9ca3af', '#d1d5db', '#e5e7eb'],
          },
        ],
      }
      if (this.chartInstance) {
        this.chartInstance.data = data
        this.chartInstance.update()
        return
      }
      this.chartInstance = new Chart(ctx, {
        type: 'doughnut',
        data,
        options: {
          plugins: {
            legend: {
              position: 'bottom',
            },
          },
        },
      })
    },
    setupRefresh() {
      if (this.refreshInterval) {
        clearInterval(this.refreshInterval)
      }
      this.refreshInterval = setInterval(async () => {
        try {
          await this.loadResults()
        } catch (error) {
          console.warn('Refresh failed', error)
        }
      }, 4000)
    },
    setupSubscriptions() {
      if (!this.poll || !this.selectedPollAddress) return
      try {
        const votedSub = subscribeToEventOptional(
          PollArtifact.abi,
          this.selectedPollAddress,
          'Voted',
          () => this.loadResults()
        )
        const stateSub = subscribeToEventOptional(
          PollArtifact.abi,
          this.selectedPollAddress,
          'StateChanged',
          () => this.loadResults()
        )
        this.subscriptions = [votedSub, stateSub].filter(Boolean)
      } catch (error) {
        console.warn('Realtime subscriptions unavailable', error)
      }
    },
    async activate() {
      try {
        const accounts = await getAccounts()
        await this.poll.methods.activate().send({ from: accounts[0] })
        await this.loadResults()
      } catch (error) {
        console.error('Activate failed', error)
      }
    },
    async end() {
      try {
        const accounts = await getAccounts()
        await this.poll.methods.end().send({ from: accounts[0] })
        await this.loadResults()
      } catch (error) {
        console.error('End failed', error)
      }
    },
    async finalize() {
      try {
        const accounts = await getAccounts()
        await this.poll.methods.finalize().send({ from: accounts[0] })
        await this.loadResults()
      } catch (error) {
        console.error('Finalize failed', error)
      }
    },
    teardown() {
      if (this.refreshInterval) {
        clearInterval(this.refreshInterval)
        this.refreshInterval = null
      }
      this.teardownSubscriptions()
      if (this.chartInstance) {
        this.chartInstance.destroy()
        this.chartInstance = null
      }
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
    shortAddress(address) {
      return `${address.slice(0, 6)}…${address.slice(-4)}`
    },
  },
}
</script>

<style scoped>
.results {
  display: grid;
  gap: 24px;
}

.picker {
  display: grid;
  gap: 16px;
}

.picker-row {
  display: grid;
  gap: 12px;
}

@media (min-width: 760px) {
  .picker-row {
    grid-template-columns: 1fr auto;
    align-items: end;
  }
}

label > span {
  display: block;
  margin-bottom: 6px;
  font-size: 13px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-muted);
}

.summary {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 16px;
  align-items: flex-start;
}

.summary-text h3 {
  margin: 0 0 8px 0;
  font-size: 20px;
}

.summary-text p {
  margin: 0;
  color: var(--text-secondary);
  font-size: 14px;
}

.summary-text .muted {
  color: var(--text-muted);
}

.state {
  display: flex;
  flex-direction: column;
  gap: 8px;
  align-items: flex-end;
}

.state-chip {
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
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
  font-size: 13px;
  color: var(--text-muted);
}

.grid {
  display: grid;
  gap: 24px;
}

@media (min-width: 960px) {
  .grid {
    grid-template-columns: 1fr 1fr;
  }
}

.card {
  padding: 24px;
  border: 1px solid var(--border);
  border-radius: var(--radius);
  background: var(--bg-surface);
  display: grid;
  gap: 16px;
}

.tally-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 16px;
}

.tally-item {
  display: grid;
  gap: 8px;
}

.option-name {
  font-weight: 600;
}

.option-count {
  font-size: 13px;
  color: var(--text-muted);
}

.progress {
  position: relative;
  height: 6px;
  border-radius: 999px;
  background: var(--bg-muted);
  overflow: hidden;
}

}

.placeholder {
  margin: 8px 0 0;
  font-size: 13px;
  color: var(--text-muted);
.progress-bar {
  position: absolute;
  top: 0;
  left: 0;
  bottom: 0;
  border-radius: inherit;
  background: #111827;
  transition: width 0.3s ease;
}

.admin-actions {
  display: flex;
  gap: 12px;
}

.admin-actions .btn {
  padding: 8px 14px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
}

.empty {
  font-size: 13px;
  color: var(--text-muted);
}
</style>