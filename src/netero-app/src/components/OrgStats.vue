<template>
  <section class="card org-stats">
    <header class="section-head">
      <div>
        <h3>Org stats</h3>
        <p>Snapshot across your ballots (via subgraph).</p>
      </div>
      <button class="btn btn-ghost" @click="load" :disabled="loading">{{ loading ? 'Refreshing…' : 'Refresh' }}</button>
    </header>

    <div v-if="!endpointOk" class="muted">Graph endpoint not available. Start indexer to enable stats.</div>

    <div v-else class="stats-grid">
      <div class="stat"><span class="label">Total votes</span><span class="value">{{ totalVotes }}</span></div>
      <div class="stat"><span class="label">Unique voters</span><span class="value">{{ uniqueVoters }}</span></div>
      <div class="stat"><span class="label">Most active poll</span><span class="value mono">{{ shortAddress(mostActivePoll) || '—' }}</span></div>
    </div>
  </section>
</template>

<script>
import { graphqlRequest } from '../graphql'

export default {
  name: 'OrgStats',
  props: { orgAddress: { type: String, required: true }, endpoint: { type: String, default: 'http://127.0.0.1:8000/subgraphs/name/netero/subgraph' } },
  data() {
    return { loading: false, endpointOk: false, polls: [], totalVotes: 0, uniqueVoters: 0, mostActivePoll: '' }
  },
  mounted() { this.init() },
  methods: {
    async init() {
      try { await graphqlRequest(this.endpoint, '{ __typename }'); this.endpointOk = true } catch { this.endpointOk = false }
      if (this.endpointOk) await this.load()
    },
    async load() {
      if (!this.endpointOk || !this.orgAddress) return
      this.loading = true
      try {
        // Fetch polls for org
        const qPolls = `query($org: String!) { polls(where: { org: $org }) { id } }`
        const r1 = await graphqlRequest(this.endpoint, qPolls, { org: this.orgAddress.toLowerCase() })
        const ids = (r1.polls || []).map(p => p.id)
        this.polls = ids
        if (!ids.length) { this.totalVotes = 0; this.uniqueVoters = 0; this.mostActivePoll = ''; return }
        // Aggregate votes across polls
        const qVotes = `query($ids: [String!]) { votes(where: { poll_in: $ids }) { id voter poll } }`
        const r2 = await graphqlRequest(this.endpoint, qVotes, { ids })
        const votes = r2.votes || []
        this.totalVotes = votes.length
        const uniq = new Set(votes.map(v => v.voter.toLowerCase()))
        this.uniqueVoters = uniq.size
        // Count per poll to find most active
        const counts = new Map()
        for (const v of votes) { counts.set(v.poll, (counts.get(v.poll) || 0) + 1) }
        let best = ''; let max = -1
        counts.forEach((c, id) => { if (c > max) { max = c; best = id } })
        this.mostActivePoll = best
      } catch (e) {
        // leave endpointOk true; just show zeros
        this.totalVotes = 0; this.uniqueVoters = 0; this.mostActivePoll = ''
      } finally { this.loading = false }
    },
    shortAddress(a) { return a ? `${a.slice(0,6)}…${a.slice(-4)}` : '' },
  }
}
</script>

<style scoped>
.stats-grid { display: grid; gap: 12px; grid-template-columns: repeat(3, minmax(0, 1fr)); }
.stat { background: var(--bg-muted); border: 1px solid var(--border); border-radius: var(--radius-sm); padding: 12px 14px; display: flex; justify-content: space-between; align-items: center; }
.label { font-size: 12px; color: var(--text-muted); text-transform: uppercase; letter-spacing: .05em; }
.value { font-weight: 700; }
.mono { font-family: var(--font-mono); font-size: 12px; }
.muted { color: var(--text-muted); font-size: 13px; }
</style>
