<template>
  <section class="card org-overview">
    <header class="section-head">
      <div>
        <h3>Org overview</h3>
        <p>Votes over time across all your polls (subgraph).</p>
      </div>
      <button class="btn btn-ghost" type="button" @click="load" :disabled="loading">
        {{ loading ? 'Refreshing…' : 'Refresh' }}
      </button>
    </header>

    <div v-if="!endpointOk" class="muted">Graph endpoint not available. Start indexer to enable charts.</div>
    <div v-else>
      <div v-if="loading" class="muted">Loading…</div>
      <div v-else-if="!labels.length" class="muted">No votes yet.</div>
      <canvas v-else ref="chart" height="180"></canvas>
    </div>
  </section>
</template>

<script>
import { Chart, LineElement, PointElement, LinearScale, TimeScale, Legend, Tooltip, CategoryScale } from 'chart.js'
Chart.register(LineElement, PointElement, LinearScale, TimeScale, Legend, Tooltip, CategoryScale)
import { graphqlRequest } from '../graphql'

export default {
  name: 'OrgOverviewChart',
  props: {
    orgAddress: { type: String, required: true },
    endpoint: { type: String, default: 'http://127.0.0.1:8000/subgraphs/name/netero/subgraph' },
    bucketMinutes: { type: Number, default: 1 },
    maxPoints: { type: Number, default: 60 }
  },
  data() {
    return { loading: false, endpointOk: false, chart: null, labels: [], series: [] }
  },
  mounted() { this.init() },
  methods: {
    async init() {
      try { await graphqlRequest(this.endpoint, '{ __typename }'); this.endpointOk = true } catch { this.endpointOk = false }
      if (this.endpointOk) await this.load()
    },
    async load() {
      if (!this.orgAddress || !this.endpointOk) return
      this.loading = true
      try {
        // Fetch all polls for this org
        const r1 = await graphqlRequest(this.endpoint, `query($org: String!) { 
          polls(where: { org: $org }, orderBy: createdAt, orderDirection: asc) { 
            id 
          } 
        }`, { org: this.orgAddress.toLowerCase() })
        
        const pollIds = (r1.polls || []).map(p => p.id)
        if (!pollIds.length) { 
          this.render([], [])
          return 
        }
        
        // Fetch all votes across these polls ordered by timestamp
        const r2 = await graphqlRequest(this.endpoint, `query($ids: [String!]!) { 
          votes(where: { poll_in: $ids }, orderBy: timestamp, orderDirection: asc, first: 1000) { 
            timestamp 
          } 
        }`, { ids: pollIds })
        
        const votes = r2.votes || []
        if (!votes.length) {
          this.render([], [])
          return
        }
        
        const times = votes.map(v => Number(v.timestamp) * 1000)
        
        // Bucket by configurable minute interval
        const bucketed = new Map()
        times.forEach(ts => {
          const d = new Date(ts)
          const m = d.getMinutes()
          const snapped = m - (m % Math.max(1, this.bucketMinutes))
          d.setMinutes(snapped, 0, 0)
          const key = d.getTime()
          bucketed.set(key, (bucketed.get(key) || 0) + 1)
        })
        
        const keys = Array.from(bucketed.keys()).sort((a,b)=>a-b)
        const limitedKeys = this.maxPoints > 0 ? keys.slice(-this.maxPoints) : keys
        const labels = limitedKeys.map(t => new Date(t).toLocaleTimeString())
        
        // Calculate cumulative counts
        let running = 0
        const data = limitedKeys.map(t => { 
          running += (bucketed.get(t) || 0)
          return running 
        })
        
        this.render(labels, data)
      } catch (e) {
        console.error('Failed to load org overview chart:', e)
        this.render([], [])
      } finally { 
        this.loading = false 
      }
    },
    render(labels, data) {
      const ctx = this.$refs.chart?.getContext('2d')
      if (!labels.length) { this.labels = []; this.series = []; if (this.chart) { this.chart.destroy(); this.chart = null }; return }
      if (!ctx) return
      const payload = { labels, datasets: [{ label: 'Cumulative votes', data, borderColor: '#1d4ed8', tension: 0.2, fill: false }] }
      if (this.chart) { this.chart.data = payload; this.chart.update(); return }
      this.chart = new Chart(ctx, { type: 'line', data: payload, options: { responsive: true, scales: { y: { beginAtZero: true } }, plugins: { legend: { display: true, position: 'bottom' } } } })
    }
  }
}
</script>

<style scoped>
.muted { color: var(--text-muted); font-size: 13px; }
</style>
