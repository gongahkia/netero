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
    <canvas v-else ref="chart" height="180"></canvas>
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
    bucketMinutes: { type: Number, default: 1 }
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
        // Fetch votes across all polls of this org ordered by timestamp asc
        const q = `query($org: String!) {
          polls(where: { org: $org }) { id }
          votes(where: { poll_in: (polls: $org) }) { id }
        }`
        // Simpler approach: two queries
        const r1 = await graphqlRequest(this.endpoint, `query($org: String!) { polls(where: { org: $org }) { id } }`, { org: this.orgAddress.toLowerCase() })
        const pollIds = (r1.polls || []).map(p => p.id)
        if (!pollIds.length) { this.render([], []); return }
        const r2 = await graphqlRequest(this.endpoint, `query($ids: [String!]) { votes(where: { poll_in: $ids }, orderBy: timestamp, orderDirection: asc) { timestamp } }`, { ids: pollIds })
        const votes = r2.votes || []
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
        const labels = Array.from(bucketed.keys()).sort((a,b)=>a-b).map(t => new Date(t).toLocaleTimeString())
        const data = labels.map((_, i) => {
          const t = Array.from(bucketed.keys()).sort((a,b)=>a-b)[i]
          return Array.from(bucketed.entries()).filter(([k]) => k <= t).reduce((s, [,v]) => s+v, 0)
        })
        this.render(labels, data)
      } catch (e) {
        this.render([], [])
      } finally { this.loading = false }
    },
    render(labels, data) {
      const ctx = this.$refs.chart?.getContext('2d')
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
