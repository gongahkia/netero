<template>
  <div class="container stack-lg">
    <header class="stack">
      <h1>Member Dashboard</h1>
      <p class="section-title">Participate in active ballots with your wallet. Connect to the local network and cast your vote.</p>

      <div class="card stack" style="padding:16px;">
        <div class="grid-2">
          <div class="stack">
            <span class="section-title">How to Join</span>
            <ol class="stack">
              <li>Install MetaMask and connect to RPC http://localhost:8545 (Chain Id 1337).</li>
              <li>Ask an organizer to grant your wallet the right to vote.</li>
              <li>Return here and cast your vote.</li>
            </ol>
          </div>
          <div class="stack">
            <span class="section-title">Selected Contract</span>
            <div class="stack">
              <input v-model="contractAddress" @change="persistAddress" class="input" placeholder="Contract address (optional)" />
              <button class="btn" @click="clearAddress">Clear</button>
              <small class="section-title" v-if="stored">Saved in this browser</small>
            </div>
          </div>
        </div>
      </div>
    </header>

    <section class="stack-lg">
      <div class="stack">
        <span class="section-title">Vote</span>
        <div class="card" style="padding:16px;">
          <VotingInterface :address="contractAddress || undefined" />
        </div>
      </div>

      <div class="stack">
        <span class="section-title">Results Snapshot</span>
        <div class="card" style="padding:16px;">
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
h1 { margin: 0; font-size: 28px; }
ol { margin: 0; padding-left: 18px; }
</style>
