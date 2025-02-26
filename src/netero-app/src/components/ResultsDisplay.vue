<template>
  <div class="results-display">
    <h2>Voting Results</h2>
    <select v-model="selectedBallot" @change="loadResults">
      <option v-for="ballot in ballots" :key="ballot.id" :value="ballot.id">
        {{ ballot.name }}
      </option>
    </select>
    <div v-if="results.length > 0">
      <h3>Results for {{ selectedBallotName }}</h3>
      <ul>
        <li v-for="result in results" :key="result.option">
          {{ result.option }}: {{ result.votes }} votes
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ResultsDisplay',
  data() {
    return {
      ballots: [],
      selectedBallot: null,
      selectedBallotName: '',
      results: [],
      web3: null,
      contract: null
    }
  },
  mounted() {
    // Initialize Web3 and contract
    this.loadBallots()
  },
  methods: {
    async loadBallots() {
      // Load ballots from smart contract
    },
    async loadResults() {
      try {
        const ballotResults = await this.contract.methods.getBallotResults(this.selectedBallot).call()
        this.results = ballotResults
        this.selectedBallotName = this.ballots.find(b => b.id === this.selectedBallot).name
      } catch (error) {
        console.error('Error loading results:', error)
        alert('Failed to load results')
      }
    }
  }
}
</script>