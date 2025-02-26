<template>
  <div class="ballot-creation">
    <h1>Netero</h1>
    <h2>Create New Voting Contract</h2>
    <form @submit.prevent="createVotingContract">
      <div v-for="(option, index) in options" :key="index">
        <input v-model="options[index]" :placeholder="`Proposal ${index + 1}`" required>
      </div>
      <button type="button" @click="addOption">Add Proposal</button>
      <button type="submit">Create Voting Contract</button>
    </form>
  </div>
</template>

<script>

import Web3 from 'web3'
import VoteContract from '../../build/contracts/Vote.json'

export default {
  name: 'BallotCreation',
  data() {
    return {
      options: ['', ''],
      web3: null,
      contract: null
    }
  },
  async mounted() {
    // Initialize Web3
    if (window.ethereum) {
      this.web3 = new Web3(window.ethereum)
      try {
        // Request account access
        await window.ethereum.enable()
      } catch (error) {
        console.error("User denied account access")
      }
    } else if (window.web3) {
      this.web3 = new Web3(window.web3.currentProvider)
    } else {
      console.log('Non-Ethereum browser detected. Consider using MetaMask!')
    }
  },
  methods: {
    addOption() {
      this.options.push('')
    },
    async createVotingContract() {
      try {
        const accounts = await this.web3.eth.getAccounts()
        const networkId = await this.web3.eth.net.getId()
        const deployedNetwork = VoteContract.networks[networkId]

        this.contract = new this.web3.eth.Contract(
          VoteContract.abi,
          deployedNetwork && deployedNetwork.address,
        )

        const proposalNames = this.options.map(option => this.web3.utils.asciiToHex(option))
        
        // Use the first three accounts as initial authorities (adjust as needed)
        const initialAuthorities = accounts.slice(0, 3)

        await this.contract.deploy({
          data: VoteContract.bytecode,
          arguments: [proposalNames, initialAuthorities]
        }).send({
          from: accounts[0],
          gas: 3000000
        })

        alert('Voting contract created successfully!')
      } catch (error) {
        console.error('Error creating voting contract:', error)
        alert('Failed to create voting contract')
      }
    }
  }
}
</script>