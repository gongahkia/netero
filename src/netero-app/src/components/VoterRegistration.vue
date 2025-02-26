<template>
  <div class="voter-registration">
    <h2>Voter Registration</h2>
    <form @submit.prevent="registerVoter">
      <input v-model="voterAddress" placeholder="Enter Ethereum address" required>
      <button type="submit">Register</button>
    </form>
  </div>
</template>

<script>
import Web3 from 'web3'

export default {
  name: 'VoterRegistration',
  data() {
    return {
      voterAddress: '',
      web3: null,
      contract: null
    }
  },
  mounted() {
    // Initialize Web3 and contract
  },
  methods: {
    async registerVoter() {
      try {
        await this.contract.methods.registerVoter(this.voterAddress).send({ from: this.web3.eth.defaultAccount })
        alert('Voter registered successfully!')
      } catch (error) {
        console.error('Error registering voter:', error)
        alert('Failed to register voter')
      }
    }
  }
}
</script>