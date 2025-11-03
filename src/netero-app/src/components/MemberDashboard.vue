<template>
  <div class="dashboard container">
    <header class="page-header">
      <div>
        <h1>Member workspace</h1>
        <p>Review proposals, cast your vote, and stay informed as results update live.</p>
      </div>
      <WalletConnection />
    </header>

    <section class="card current-ballot">
      <div class="card-header">
        <div>
          <h2>Active ballot</h2>
          <p>Paste the poll address shared by your organizer. We'll remember it for you.</p>
        </div>
        <div class="status-pill" :class="stored ? 'status-pill--saved' : 'status-pill--blank'">
          {{ stored ? 'Saved locally' : 'Not saved' }}
        </div>
      </div>
      <div class="address-row">
        <input
          v-model.trim="contractAddress"
          class="input"
          placeholder="0x... poll address"
        />
        <button class="btn btn-primary" type="button" @click="persistAddress" :disabled="!contractAddress">
          Save
        </button>
        <button class="btn btn-ghost" type="button" @click="clearAddress" :disabled="!stored">
          Clear
        </button>
      </div>
      <ul class="helper-list">
        <li>Make sure you're allowlisted before voting.</li>
        <li>We'll prompt you automatically if the poll closes while you're on this page.</li>
      </ul>
    </section>

    <section class="grid-two">
      <div class="card">
        <header class="section-head">
          <div>
            <h3>Cast your vote</h3>
            <p>Select a ballot and submit your choice with a single transaction.</p>
          </div>
        </header>
        <VotingInterface
          :address="contractAddress || undefined"
          @polls-updated="handlePollsUpdated"
        />
      </div>

      <div class="card">
        <header class="section-head">
          <div>
            <h3>Live results</h3>
            <p>Follow turnout and see which option is in the lead in real time.</p>
          </div>
        </header>
        <ResultsDisplay :address="contractAddress || undefined" />
      </div>
    </section>

    <NotificationPanel :poll-addresses="activePolls" role="member" />

    <section class="card analytics-section">
      <header class="section-head">
        <div>
          <h3>Analytics</h3>
          <p>Understand voter engagement and turnout trends for the selected ballot.</p>
        </div>
      </header>
      <Analytics :focus-poll="primaryPoll" compact />
    </section>
  </div>
</template>

<script>
import VotingInterface from './VotingInterface.vue'
import ResultsDisplay from './ResultsDisplay.vue'
import WalletConnection from './WalletConnection.vue'
import NotificationPanel from './NotificationPanel.vue'
import Analytics from './Analytics.vue'

const STORAGE_KEY = 'netero.contract'

export default {
  name: 'MemberDashboard',
  components: {
    VotingInterface,
    ResultsDisplay,
    WalletConnection,
    NotificationPanel,
    Analytics,
  },
  data() {
    const saved = typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY) : ''
    return {
      contractAddress: saved || '',
      stored: Boolean(saved),
      discoveredPolls: [],
    }
  },
  computed: {
    activePolls() {
      const fromAddress = this.contractAddress ? [this.contractAddress] : []
      const combined = new Set([...fromAddress, ...this.discoveredPolls])
      return Array.from(combined).filter(Boolean)
    },
    primaryPoll() {
      return this.activePolls[0] || ''
    },
  },
  methods: {
    persistAddress() {
      if (!this.contractAddress) return
      try {
        localStorage.setItem(STORAGE_KEY, this.contractAddress)
        this.stored = true
      } catch (e) {
        // no-op if storage unavailable
      }
      this.handlePollsUpdated([this.contractAddress])
    },
    clearAddress() {
      try {
        localStorage.removeItem(STORAGE_KEY)
      } catch (e) {
        // ignore
      }
      this.contractAddress = ''
      this.stored = false
      this.discoveredPolls = []
    },
    handlePollsUpdated(addresses = []) {
      const cleaned = (addresses || []).filter(Boolean)
      if (!cleaned.length) return
      this.discoveredPolls = Array.from(new Set([...this.discoveredPolls, ...cleaned]))
    },
  },
}
</script>

<style scoped>
.dashboard {
  display: grid;
  gap: 32px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 24px;
}

.page-header h1 {
  margin: 0 0 12px 0;
  font-size: 28px;
}

.page-header p {
  margin: 0;
  color: var(--text-secondary);
  font-size: 14px;
  max-width: 420px;
}

.current-ballot {
  padding: 28px;
  display: grid;
  gap: 24px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 18px;
}

.card-header h2 {
  margin: 0 0 8px 0;
  font-size: 20px;
}

.card-header p {
  margin: 0;
  color: var(--text-secondary);
  font-size: 14px;
}

.status-pill {
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 600;
}

.status-pill--saved {
  background: #dcfce7;
  color: #166534;
}

.status-pill--blank {
  background: var(--bg-muted);
  color: var(--text-muted);
}

.address-row {
  display: grid;
  gap: 12px;
}

.address-row .btn {
  width: 100%;
}

@media (min-width: 780px) {
  .address-row {
    grid-template-columns: 1fr auto auto;
  }
  .address-row .btn {
    width: auto;
  }
}

.helper-list {
  margin: 0;
  padding-left: 18px;
  color: var(--text-muted);
  font-size: 13px;
  line-height: 1.6;
}

.grid-two {
  display: grid;
  gap: 32px;
}

@media (min-width: 1000px) {
  .grid-two {
    grid-template-columns: 1fr 1fr;
  }
}

.section-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.section-head h3 {
  margin: 0 0 6px 0;
  font-size: 18px;
}

.section-head p {
  margin: 0;
  color: var(--text-secondary);
  font-size: 13px;
}

.analytics-section {
  padding: 28px;
}

@media (max-width: 820px) {
  .page-header {
    flex-direction: column;
  }
}
</style>
