<template>
  <div class="results-display">
    <h2>Voting Results</h2>

    <div class="selector">
      <label>Org (defaults to your address):</label>
      <input v-model="orgAddress" placeholder="0x..." />
      <button @click="loadOrgPolls">Load Polls</button>
    </div>

    <div class="selector" v-if="polls.length">
      <label>Select Poll:</label>
      <select v-model="selectedPollAddress" @change="onPollChange">
        <option disabled value="">-- choose a poll --</option>
        <option v-for="addr in polls" :key="addr" :value="addr">{{ addr }}</option>
      </select>
    </div>

    <div v-if="options.length">
      <div class="header-row">
        <h3>{{ title }}</h3>
        <span class="badge" :class="stateClass">{{ stateLabel }}</span>
      </div>
      <ul>
        <li v-for="(opt, idx) in options" :key="idx">{{ opt }}: {{ tallies[idx] || 0 }} votes</li>
      </ul>
      <p>Winning Option: <strong>{{ winningOption }}</strong></p>
      <canvas ref="chart" height="200"></canvas>

      <div v-if="isAdmin" class="admin-actions">
        <button v-if="state === 0" @click="activate">Activate</button>
        <button v-if="state === 1" @click="end">End</button>
        <button v-if="state === 2" @click="finalize">Finalize</button>
      </div>
    </div>
    <div v-else>
      <p>No results available</p>
    </div>
  </div>
</template>

<script>
import { initWeb3, getAccounts, getDeployedAddress, getContract } from '../eth'
import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
import PollArtifact from '../../../core/build/contracts/Poll.json'
import { Chart, ArcElement, Tooltip, Legend } from 'chart.js'
Chart.register(ArcElement, Tooltip, Legend)

export default {
  name: 'ResultsDisplay',
  computed: {
    stateLabel() {
      switch (this.state) {
        case 0: return 'Draft'
        case 1: return 'Active'
        case 2: return 'Ended'
        case 3: return 'Finalized'
        default: return 'Unknown'
      }
    },
    stateClass() {
      return {
        draft: this.state === 0,
        active: this.state === 1,
        ended: this.state === 2,
        finalized: this.state === 3
      }
    }
  },
  data() {
    return {
      orgAddress: '',
      polls: [],
      selectedPollAddress: '',
      title: '',
      options: [],
      tallies: [],
      winningOption: '',
      factory: null,
      poll: null,
      chartInstance: null,
      state: 0,
      isAdmin: false,
      refreshId: null
    }
  },
  async mounted() {
    try {
      await initWeb3()
      const accounts = await getAccounts()
      this.orgAddress = accounts[0]
      const addr = await getDeployedAddress(PollFactoryArtifact)
      this.factory = await getContract(PollFactoryArtifact, addr)
      await this.loadOrgPolls()
    } catch (error) {
      console.error('Error in mounted hook:', error)
    }
  },
  beforeUnmount() {
    if (this.refreshId) clearInterval(this.refreshId)
  },
  methods: {
    async loadOrgPolls() {
      try {
        if (!this.factory) return
        const list = await this.factory.methods.getOrgPolls(this.orgAddress).call()
        this.polls = list
      } catch (e) {
        console.error('Failed to load org polls', e)
      }
    },
    async onPollChange() {
      if (this.refreshId) {
        clearInterval(this.refreshId)
        this.refreshId = null
      }
      await this.loadResults()
      this.refreshId = setInterval(() => {
        this.loadResults(true)
      }, 3000)
    },
    async loadResults(isRefresh = false) {
      try {
        if (!this.selectedPollAddress) return
        this.poll = await getContract(PollArtifact, this.selectedPollAddress)
        const [opts, tallies, t, st, admin] = await Promise.all([
          this.poll.methods.getOptions().call(),
          this.poll.methods.getTallies().call(),
          this.poll.methods.title().call(),
          this.poll.methods.state().call(),
          this.poll.methods.admin().call()
        ])
        this.options = opts
        this.tallies = tallies.map(v => Number(v))
        this.title = t
        this.state = Number(st)
        const accounts = await getAccounts()
        this.isAdmin = accounts[0]?.toLowerCase() === admin.toLowerCase()
        const maxIdx = this.tallies.reduce((best, v, i, arr) => v > arr[best] ? i : best, 0)
        this.winningOption = this.options[maxIdx] || ''
        this.renderChart()
      } catch (e) {
        console.error('Failed to load results', e)
      }
    },
    renderChart() {
      if (!this.$refs.chart) return
      const ctx = this.$refs.chart.getContext('2d')
      const data = {
        labels: this.options,
        datasets: [{
          label: 'Votes',
          data: this.tallies,
          backgroundColor: ['#3498db','#2ecc71','#e67e22','#9b59b6','#e74c3c','#1abc9c','#f1c40f']
        }]
      }
      if (this.chartInstance) {
        this.chartInstance.data = data
        this.chartInstance.update()
        return
      }
      this.chartInstance = new Chart(ctx, { type: 'doughnut', data })
    },
    async activate() {
      try {
        const accounts = await getAccounts()
        await this.poll.methods.activate().send({ from: accounts[0] })
        await this.loadResults(true)
      } catch (e) { console.error(e) }
    },
    async end() {
      try {
        const accounts = await getAccounts()
        await this.poll.methods.end().send({ from: accounts[0] })
        await this.loadResults(true)
      } catch (e) { console.error(e) }
    },
    async finalize() {
      try {
        const accounts = await getAccounts()
        await this.poll.methods.finalize().send({ from: accounts[0] })
        await this.loadResults(true)
      } catch (e) { console.error(e) }
    }
  }
}
</script>

<style scoped>
.selector { display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.75rem; }
input, select { padding: 0.4rem; }
.header-row { display: flex; align-items: center; gap: 0.5rem; }
.badge { padding: 0.2rem 0.5rem; border-radius: 8px; font-size: 0.8rem; color: white; }
.badge.draft { background: #7f8c8d; }
.badge.active { background: #2ecc71; }
.badge.ended { background: #e67e22; }
.badge.finalized { background: #9b59b6; }
.admin-actions { margin-top: 0.75rem; display: flex; gap: 0.5rem; }
</style>