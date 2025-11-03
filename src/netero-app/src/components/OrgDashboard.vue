<template>
  <div class="dashboard container">
    <header class="page-header">
      <div>
        <h1>Organizer workspace</h1>
        <p>Launch ballots, manage participation, and monitor outcomes with real-time insight.</p>
      </div>
      <WalletConnection />
    </header>

    <section class="card summary">
      <div class="summary-text">
        <h2>Operating context</h2>
        <p>You're connected on localhost for rapid iteration. Use these details when onboarding voters.</p>
      </div>
      <div class="summary-grid">
        <div class="summary-item">
          <span class="label">RPC endpoint</span>
          <span class="value">http://localhost:8545</span>
        </div>
        <div class="summary-item">
          <span class="label">Chain ID</span>
          <span class="value">1337</span>
        </div>
        <div class="summary-item">
          <span class="label">Frontend</span>
          <span class="value">http://localhost:8080</span>
        </div>
        <div class="summary-item">
          <span class="label">Active polls</span>
          <span class="value">{{ polls.length }}</span>
        </div>
      </div>
      <button class="btn btn-ghost" type="button" @click="refreshPolls">
        Refresh list
      </button>
    </section>

    <section class="grid layout-management">
      <div class="card">
        <header class="section-head">
          <div>
            <h3>Create a ballot</h3>
            <p>Define your proposal, schedule, and voting mode. The contract auto-closes when the window ends.</p>
          </div>
        </header>
        <BallotCreation @poll-created="handlePollCreated" />
      </div>

      <div class="card">
        <header class="section-head">
          <div>
            <h3>Voter management</h3>
            <p>Bulk-allowlist wallets or revoke access in a single transaction.</p>
          </div>
        </header>
        <VoterRegistration @polls-updated="handlePollsUpdated" />
      </div>
    </section>

    <NotificationPanel :poll-addresses="polls" role="organization" />

    <section class="grid layout-results">
      <div class="card">
        <header class="section-head">
          <div>
            <h3>Live results</h3>
            <p>Select a poll to see live tallies and transition the state when ready.</p>
          </div>
        </header>
        <ResultsDisplay :org-address="orgAddress" @polls-updated="handlePollsUpdated" />
      </div>

      <div class="card analytics-card">
        <header class="section-head">
          <div>
            <h3>Analytics</h3>
            <p>Pull subgraph insights to measure engagement across your ballots.</p>
          </div>
        </header>
        <Analytics :org-address="orgAddress" :focus-poll="primaryPoll" />
      </div>
    </section>
  </div>
</template>

<script>
import BallotCreation from './BallotCreation.vue'
import VoterRegistration from './VoterRegistration.vue'
import ResultsDisplay from './ResultsDisplay.vue'
import WalletConnection from './WalletConnection.vue'
import NotificationPanel from './NotificationPanel.vue'
import Analytics from './Analytics.vue'
import { initWeb3, getAccounts, getDeployedAddress, getContract } from '../eth'
import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'

export default {
  name: 'OrgDashboard',
  components: {
    BallotCreation,
    VoterRegistration,
    ResultsDisplay,
    WalletConnection,
    NotificationPanel,
    Analytics,
  },
  data() {
    return {
      polls: [],
      orgAddress: '',
      factory: null,
    }
  },
  computed: {
    primaryPoll() {
      return this.polls[0] || ''
    },
  },
  async created() {
    await this.bootstrap()
  },
  methods: {
    async bootstrap() {
      try {
        await initWeb3()
        const accounts = await getAccounts()
        this.orgAddress = accounts[0]
        const address = await getDeployedAddress(PollFactoryArtifact)
        this.factory = await getContract(PollFactoryArtifact, address)
        await this.refreshPolls()
      } catch (e) {
        console.error('Organizer dashboard bootstrap failed', e)
      }
    },
    async refreshPolls() {
      if (!this.factory || !this.orgAddress) return
      try {
        const list = await this.factory.methods.getOrgPolls(this.orgAddress).call()
        this.polls = Array.from(new Set(list))
      } catch (e) {
        console.error('Unable to refresh poll list', e)
      }
    },
    handlePollCreated(address) {
      if (!address) return
      if (!this.polls.includes(address)) {
        this.polls = [address, ...this.polls]
      }
    },
    handlePollsUpdated(list = []) {
      if (!list.length) return
      const merged = new Set([...this.polls, ...list])
      this.polls = Array.from(merged)
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
  gap: 24px;
  align-items: flex-start;
}

.page-header h1 {
  margin: 0 0 12px 0;
  font-size: 28px;
}

.page-header p {
  margin: 0;
  color: var(--text-secondary);
  font-size: 14px;
  max-width: 460px;
}

.summary {
  display: grid;
  gap: 24px;
  padding: 28px;
}

.summary-text h2 {
  margin: 0 0 8px 0;
  font-size: 20px;
}

.summary-text p {
  margin: 0;
  color: var(--text-secondary);
  font-size: 14px;
}

.summary-grid {
  display: grid;
  gap: 16px;
}

@media (min-width: 720px) {
  .summary-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}

.summary-item {
  padding: 16px;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: var(--bg-muted);
  display: grid;
  gap: 6px;
}

.summary-item .label {
  font-size: 12px;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.summary-item .value {
  font-size: 15px;
  font-weight: 600;
}

.layout-management,
.layout-results {
  display: grid;
  gap: 32px;
}

@media (min-width: 1080px) {
  .layout-management,
  .layout-results {
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

.analytics-card {
  padding-bottom: 8px;
}

@media (max-width: 880px) {
  .page-header {
    flex-direction: column;
  }
}
</style>
