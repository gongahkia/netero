<template>
  <div class="ballot-creation">
    <h2>Create New Ballot</h2>
    <form @submit.prevent="createBallot">
      <input v-model="ballotName" placeholder="Ballot Name" required>
      <div v-for="(option, index) in options" :key="index">
        <input v-model="options[index]" :placeholder="`Option ${index + 1}`" required>
      </div>
      <button type="button" @click="addOption">Add Option</button>
      <button type="submit">Create Ballot</button>
    </form>
  </div>
</template>

<script>
export default {
  name: 'BallotCreation',
  data() {
    return {
      ballotName: '',
      options: ['', ''],
      web3: null,
      contract: null
    }
  },
  mounted() {
    // Initialize Web3 and contract
  },
  methods: {
    addOption() {
      this.options.push('')
    },
    async createBallot() {
      try {
        await this.contract.methods.createBallot(this.ballotName, this.options).send({ from: this.web3.eth.defaultAccount })
        alert('Ballot created successfully!')
      } catch (error) {
        console.error('Error creating ballot:', error)
        alert('Failed to create ballot')
      }
    }
  }
}
</script>