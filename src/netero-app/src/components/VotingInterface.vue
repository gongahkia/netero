<template>
  <div class="voting-interface">
    <h2>Vote on Ballot</h2>
    <select v-model="selectedBallot" @change="loadBallotOptions">
      <option v-for="ballot in ballots" :key="ballot.id" :value="ballot.id">
        {{ ballot.name }}
      </option>
    </select>
    <form v-if="selectedBallot" @submit.prevent="castVote">
      <div v-for="option in ballotOptions" :key="option.id">
        <input type="radio" :id="option.id" :value="option.id" v-model="selectedOption">
        <label :for="option.id">{{ option.name }}</label>
      </div>
      <button type="submit">Cast Vote</button>
    </form>
  </div>
</template>

<script>
export default {
  name: 'VotingInterface',
  data() {
    return {
      ballots: [],
      selectedBallot: null,
      ballotOptions: [],
      selectedOption: null,
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
    async loadBallotOptions() {
      // Load options for selected ballot
    },
    async castVote() {
      try {
        await this.contract.methods.vote(this.selectedBallot, this.selectedOption).send({ from: this.web3.eth.defaultAccount })
        alert('Vote cast successfully!')
      } catch (error) {
        console.error('Error casting vote:', error)
        alert('Failed to cast vote')
      }
    }
  }
}
</script>