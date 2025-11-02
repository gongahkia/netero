<template>
  <div class="container stack-lg">
    <header class="stack">
      <h1>// MEMBER_DASHBOARD</h1>
      <p class="subtitle">Cast your vote on active proposals</p>

      <div class="instructions-card card stack">
        <span class="section-title">// SETUP_INSTRUCTIONS</span>
        <div class="instruction-steps">
          <div class="step">
            <span class="step-number">01.</span>
            <div class="step-content">
              <strong>Install MetaMask browser extension</strong>
              <p>Download from metamask.io and add to your browser</p>
            </div>
          </div>
          <div class="step">
            <span class="step-number">02.</span>
            <div class="step-content">
              <strong>Configure local network in MetaMask</strong>
              <p>Network Name: Localhost 8545</p>
              <p>RPC URL: http://localhost:8545</p>
              <p>Chain ID: 1337</p>
              <p>Currency: ETH</p>
            </div>
          </div>
          <div class="step">
            <span class="step-number">03.</span>
            <div class="step-content">
              <strong>Share your wallet address with organizer</strong>
              <p>Copy your address from MetaMask and request voting rights</p>
            </div>
          </div>
          <div class="step">
            <span class="step-number">04.</span>
            <div class="step-content">
              <strong>Enter contract address below (if provided)</strong>
              <p>Optional: For targeting specific ballots</p>
            </div>
          </div>
        </div>
      </div>

      <div class="card contract-section stack">
        <span class="section-title">// CONTRACT_ADDRESS</span>
        <input
          v-model="contractAddress"
          @change="persistAddress"
          class="input"
          placeholder="0x... (optional - leave empty for default contract)"
        />
        <div class="button-group">
          <button class="btn btn-primary" @click="persistAddress" :disabled="!contractAddress">
            [ SAVE_ADDRESS ]
          </button>
          <button class="btn" @click="clearAddress" :disabled="!stored">
            [ CLEAR ]
          </button>
        </div>
        <small class="status-text" v-if="stored">✓ Address saved in browser</small>
      </div>
    </header>

    <section class="stack-lg">
      <div class="stack">
        <span class="section-title">// CAST_VOTE</span>
        <div class="card voting-section">
          <VotingInterface :address="contractAddress || undefined" />
        </div>
      </div>

      <div class="stack">
        <span class="section-title">// LIVE_RESULTS</span>
        <div class="card results-section">
          <ResultsDisplay :address="contractAddress || undefined" />
        </div>
      </div>
    </section>
  </div>
</template>

<script>
import VotingInterface from './VotingInterface.vue'
import ResultsDisplay from './ResultsDisplay.vue'

export default {
  name: 'MemberDashboard',
  components: { VotingInterface, ResultsDisplay },
  data(){
    return { contractAddress: localStorage.getItem('netero.contract') || '', stored: !!localStorage.getItem('netero.contract') }
  },
  methods:{
    persistAddress(){
      if(this.contractAddress){
        localStorage.setItem('netero.contract', this.contractAddress)
        this.stored = true
      }
    },
    clearAddress(){
      localStorage.removeItem('netero.contract')
      this.contractAddress = ''
      this.stored = false
    }
  }
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

.contract-section {
  padding: 20px;
  margin-top: 16px;
}

.button-group {
  display: flex;
  gap: 12px;
}

.status-text {
  color: var(--text-muted);
  font-size: 12px;
  margin-top: 8px;
  display: block;
}

.voting-section,
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
