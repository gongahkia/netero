<template>
  <div class="voter-registration">
    <h1>Netero</h1>
    <h2>Give Right to Vote</h2>
    <form @submit.prevent="giveRightToVote">
      <input v-model="voterAddress" placeholder="Enter Ethereum address" required>
      <button type="submit">Give Right to Vote</button>
    </form>
  </div>
</template>

<script>
import Web3 from 'web3'
import VoteContract from '../../../core/build/contracts/Vote.json'

export default {
  name: 'VoterRegistration',
  data() {
    return {
      voterAddress: '',
      web3: null,
      contract: null
    }
  },
  async mounted() {
    await this.initWeb3()
  },
  methods: {
    async initWeb3() {
      if (window.ethereum) {
        this.web3 = new Web3(window.ethereum)
        try {
          await window.ethereum.enable()
        } catch (error) {
          console.error("User denied account access")
        }
      } else if (window.web3) {
        this.web3 = new Web3(window.web3.currentProvider)
      } else {
        console.log('Non-Ethereum browser detected. Consider using MetaMask!')
      }

      const networkId = await this.web3.eth.net.getId()
      const deployedNetwork = VoteContract.networks[networkId]
      this.contract = new this.web3.eth.Contract(
        VoteContract.abi,
        deployedNetwork && deployedNetwork.address,
      )
    },
    async giveRightToVote() {
      try {
        const accounts = await this.web3.eth.getAccounts()
        await this.contract.methods.giveRightToVote(this.voterAddress).send({ from: accounts[0] })
        alert('Right to vote given successfully!')
        this.voterAddress = '' // Clear the input field
      } catch (error) {
        console.error('Error giving right to vote:', error)
        alert('Failed to give right to vote. Make sure you are an authority.')
      }
    }
  }
}
</script>