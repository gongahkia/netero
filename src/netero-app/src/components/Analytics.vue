<template>
  <div class="analytics">
    <h2>Subgraph Analytics</h2>

    <div class="selector">
      <label>Endpoint:</label>
      <input v-model="endpoint" />
      <button @click="probe">Probe</button>
      <span v-if="endpointOk" class="ok">OK</span>
      <span v-else-if="endpointChecked" class="fail">Unavailable</span>
    </div>

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

    <div v-if="selectedPollAddress">
      <div class="stats">
        <div class="stat"><span class="label">Total Votes</span><span class="value">{{ totalVotes }}</span></div>
        <div class="stat"><span class="label">Unique Voters</span><span class="value">{{ uniqueVoters }}</span></div>
      </div>

      <div class="chart-section" v-if="options.length">
        <h3>Votes Over Time</h3>
        <canvas ref="chart" height="200"></canvas>
      </div>

      <div class="table-section">
        <h3>Recent Votes</h3>
        <table>
          <thead>
            <tr>
              <th>Time</th>
              <th>Voter</th>
              <th>Option</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="v in recentVotes" :key="v.id">
              <td>{{ formatTs(v.timestamp) }}</td>
              <td>{{ v.voter }}</td>
              <td>{{ optionLabel(v.optionIndex) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
import { initWeb3, getAccounts, getDeployedAddress, getContract } from '../eth'
import { graphqlRequest } from '../graphql'
import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
import PollArtifact from '../../../core/build/contracts/Poll.json'
import { Chart, LineElement, PointElement, LinearScale, TimeScale, Legend, Tooltip, CategoryScale } from 'chart.js'
Chart.register(LineElement, PointElement, LinearScale, TimeScale, Legend, Tooltip, CategoryScale)

export default {
  name: 'AnalyticsPanel',
  data() {
    return {
      endpoint: 'http://127.0.0.1:8000/subgraphs/name/netero/subgraph',
      endpointOk: false,
      endpointChecked: false,
      orgAddress: '',
      polls: [],
      selectedPollAddress: '',
      options: [],
      factory: null,
      poll: null,
      totalVotes: 0,
      uniqueVoters: 0,
      series: [],
      labels: [],
      chartInstance: null,
      recentVotes: []
    }
  },
  async mounted() {
    await initWeb3()
    const accounts = await getAccounts()
    this.orgAddress = accounts[0]
    const addr = await getDeployedAddress(PollFactoryArtifact)
    this.factory = await getContract(PollFactoryArtifact, addr)
  },
  methods: {
    async probe() {
      this.endpointChecked = true
      try {
        await graphqlRequest(this.endpoint, '{ __typename }')
        this.endpointOk = true
      } catch (e) {
        console.warn('Graph endpoint probe failed', e)
        this.endpointOk = false
      }
    },
    async loadOrgPolls() {
      if (!this.factory) return
      const list = await this.factory.methods.getOrgPolls(this.orgAddress).call()
      this.polls = list
    },
    async onPollChange() {
      await this.loadOnChainPoll()
      await this.loadFromSubgraph()
    },
    async loadOnChainPoll() {
      if (!this.selectedPollAddress) return
      this.poll = await getContract(PollArtifact, this.selectedPollAddress)
      this.options = await this.poll.methods.getOptions().call()
    },
    async loadFromSubgraph() {
      if (!this.endpoint || !this.selectedPollAddress) return
      const pollId = this.selectedPollAddress.toLowerCase()
      const query = `
        query VotesByPoll($poll: String!) {
          votes(first: 1000, orderBy: timestamp, orderDirection: asc, where: { poll: $poll }) {
            id
            voter
            optionIndex
            timestamp
          }
        }
      `
      const data = await graphqlRequest(this.endpoint, query, { poll: pollId })
      const votes = data.votes || []
      this.totalVotes = votes.length
      const uniq = new Set(votes.map(v => v.voter.toLowerCase()))
      this.uniqueVoters = uniq.size
      this.recentVotes = votes.slice(-10).reverse()

      // Build time series per option (cumulative)
      const byOption = this.options.map(() => [])
      const times = []
      const counts = this.options.map(() => 0)
      for (const v of votes) {
        const idx = Number(v.optionIndex)
        if (idx >= 0 && idx < counts.length) {
          counts[idx] += 1
        }
        times.push(Number(v.timestamp) * 1000)
        for (let i = 0; i < counts.length; i++) {
          byOption[i].push(counts[i])
        }
      }
      this.labels = times
      this.series = byOption
      this.renderChart()
    },
    optionLabel(idx) {
      return this.options[idx] ?? `#${idx}`
    },
    formatTs(ts) {
      const d = new Date(Number(ts) * 1000)
      return d.toLocaleString()
    },
    renderChart() {
      if (!this.$refs.chart) return
      const ctx = this.$refs.chart.getContext('2d')
      const colors = ['#3498db','#2ecc71','#e67e22','#9b59b6','#e74c3c','#1abc9c','#f1c40f']
      const datasets = this.series.map((arr, i) => ({
        label: this.options[i] || `Option ${i}`,
        data: arr,
        borderColor: colors[i % colors.length],
        fill: false,
        tension: 0.1
      }))
      const data = { labels: this.labels.map(t => new Date(t).toLocaleTimeString()), datasets }
      if (this.chartInstance) {
        this.chartInstance.data = data
        this.chartInstance.update()
        return
      }
      this.chartInstance = new Chart(ctx, {
        type: 'line',
        data,
        options: {
          responsive: true,
          interaction: { mode: 'index', intersect: false },
          scales: {
            y: { beginAtZero: true }
          }
        }
      })
    }
  }
}
</script>

<style scoped>
.selector { display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.75rem; }
input, select { padding: 0.4rem; }
.ok { color: #2ecc71; margin-left: 0.5rem; }
.fail { color: #e74c3c; margin-left: 0.5rem; }
.stats { display: flex; gap: 1rem; margin: 1rem 0; }
.stat { background: #f7f7f7; padding: 0.5rem 0.75rem; border-radius: 6px; min-width: 140px; display: flex; justify-content: space-between; }
.table-section table { width: 100%; border-collapse: collapse; }
.table-section th, .table-section td { text-align: left; padding: 6px 8px; border-bottom: 1px solid #eee; font-size: 0.9rem; }
</style>
