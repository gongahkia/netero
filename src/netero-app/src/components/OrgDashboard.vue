<template>
  <div class="container stack-lg">
    <header class="stack">
      <h1>// ORGANIZER_DASHBOARD</h1>
      <p class="subtitle">Create ballots, register voters, and manage elections</p>

      <WalletConnection />

      <div class="instructions-card card stack">
        <span class="section-title">// WORKFLOW</span>
        <div class="instruction-steps">
          <div class="step">
            <span class="step-number">01.</span>
            <div class="step-content">
              <strong>Connect MetaMask to local network</strong>
              <p>Ensure MetaMask is connected to http://localhost:8545 (Chain ID: 1337)</p>
            </div>
          </div>
          <div class="step">
            <span class="step-number">02.</span>
            <div class="step-content">
              <strong>Deploy a new voting contract</strong>
              <p>Use the "Contract Deployment" section below to create proposals and deploy</p>
              <p>Save the contract address that appears after deployment</p>
            </div>
          </div>
          <div class="step">
            <span class="step-number">03.</span>
            <div class="step-content">
              <strong>Register member wallet addresses</strong>
              <p>Use "Member Registration" to grant voting rights to participants</p>
              <p>Members must provide their MetaMask addresses</p>
            </div>
          </div>
          <div class="step">
            <span class="step-number">04.</span>
            <div class="step-content">
              <strong>Share contract address with members</strong>
              <p>Members need this address to connect and cast votes</p>
            </div>
          </div>
          <div class="step">
            <span class="step-number">05.</span>
            <div class="step-content">
              <strong>Monitor results in real-time</strong>
              <p>View live voting results in the "Live Results" section below</p>
            </div>
          </div>
        </div>
      </div>

      <div class="network-info card">
        <span class="section-title">// NETWORK_STATUS</span>
        <div class="info-grid">
          <div class="info-item">
            <span class="info-label">RPC URL:</span>
            <span class="info-value">http://localhost:8545</span>
          </div>
          <div class="info-item">
            <span class="info-label">Chain ID:</span>
            <span class="info-value">1337 (Local)</span>
          </div>
          <div class="info-item">
            <span class="info-label">Frontend:</span>
            <span class="info-value">http://localhost:8080</span>
          </div>
        </div>
      </div>
    </header>

    <section class="stack-lg">
      <div class="stack">
        <span class="section-title">// CONTRACT_DEPLOYMENT</span>
        <div class="card deployment-section">
          <BallotCreation />
        </div>
      </div>

      <div class="stack">
        <span class="section-title">// MEMBER_REGISTRATION</span>
        <div class="card registration-section">
          <VoterRegistration />
        </div>
      </div>

      <div class="stack">
        <span class="section-title">// LIVE_RESULTS</span>
        <div class="card results-section">
          <ResultsDisplay />
        </div>
      </div>
    </section>
  </div>
</template>

<script>
import BallotCreation from './BallotCreation.vue'
import VoterRegistration from './VoterRegistration.vue'
import ResultsDisplay from './ResultsDisplay.vue'
import WalletConnection from './WalletConnection.vue'

export default {
  name: 'OrgDashboard',
  components: { BallotCreation, VoterRegistration, ResultsDisplay, WalletConnection }
}
</script>

<style scoped>
h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 700;
  letter-spacing: 1px;
}

.subtitle {
  color: var(--text-secondary);
  margin: 8px 0 0 0;
  font-size: 14px;
}

.instructions-card {
  padding: 24px;
  margin-top: 24px;
}

.instruction-steps {
  display: grid;
  gap: 20px;
  margin-top: 16px;
}

.step {
  display: flex;
  gap: 16px;
  align-items: flex-start;
}

.step-number {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-primary);
  min-width: 40px;
}

.step-content {
  flex: 1;
}

.step-content strong {
  display: block;
  color: var(--text-primary);
  margin-bottom: 6px;
  font-size: 14px;
}

.step-content p {
  margin: 4px 0;
  color: var(--text-secondary);
  font-size: 13px;
  line-height: 1.5;
}

.network-info {
  padding: 20px;
  margin-top: 16px;
}

.info-grid {
  display: grid;
  gap: 12px;
  margin-top: 12px;
}

.info-item {
  display: flex;
  gap: 12px;
  font-size: 13px;
}

.info-label {
  color: var(--text-muted);
  min-width: 100px;
}

.info-value {
  color: var(--text-primary);
  font-weight: 600;
}

.deployment-section,
.registration-section,
.results-section {
  padding: 20px;
}

.section-title {
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 1px;
  margin-bottom: 12px;
  display: block;
}
</style>
