<template>
  <div class="voting-interface">
    <h2>Cast Your Vote</h2>
    <form @submit.prevent="castVote">
      <div v-for="(proposal, index) in proposals" :key="index">
        <input 
          type="radio" 
          :id="'proposal-' + index" 
          :value="index" 
          v-model="selectedProposal"
        >
        <label :for="'proposal-' + index">{{ web3 ? web3.utils.hexToUtf8(proposal.name) : '' }}</label>
      </div>
      <button type="submit" :disabled="selectedProposal === null">Cast Vote</button>
    </form>
  </div>
</template>

<script>
import Web3 from 'web3'
import VoteContract from '../../../core/build/contracts/Vote.json'

export default {
  name: 'VotingInterface',
  data() {
    return {
      proposals: [],
      selectedProposal: null,
      web3: null,
      contract: null
    }
  },
  async mounted() {
    try {
      await this.initWeb3()
      await this.loadProposals()
    } catch (error) {
      console.error('Error in mounted hook:', error)
    }
  },
  methods: {
    async initWeb3() {
      try {
        if (window.ethereum) {
          this.web3 = new Web3(window.ethereum)
          try {
            await window.ethereum.request({ method: 'eth_requestAccounts' })
          } catch (error) {
            console.error("User denied account access")
            return
          }
        } else if (window.web3) {
          this.web3 = new Web3(window.web3.currentProvider)
        } else {
          console.log('Non-Ethereum browser detected. Consider using MetaMask!')
          return
        }

        const networkId = await this.web3.eth.net.getId()
        const deployedNetwork = VoteContract.networks[networkId]
        if (!deployedNetwork) {
          throw new Error('Contract not deployed on the current network')
        }
        this.contract = new this.web3.eth.Contract(
          VoteContract.abi,
          deployedNetwork.address
        )
      } catch (error) {
        console.error('Failed to initialize Web3:', error)
        alert('Failed to initialize Web3. Please make sure you are connected to the correct network and have MetaMask installed.')
      }
    },
    async loadProposals() {
      if (!this.web3 || !this.contract) {
        console.error('Web3 or contract not initialized')
        return
      }
      try {
        const proposalCount = await this.contract.methods.proposals.length().call()
        this.proposals = []
        for (let i = 0; i < proposalCount; i++) {
          const proposal = await this.contract.methods.proposals(i).call()
          this.proposals.push(proposal)
        }
      } catch (error) {
        console.error('Error loading proposals:', error)
        alert('Failed to load proposals')
      }
    },
    async castVote() {
      if (!this.web3 || !this.contract) {
        alert('Web3 is not initialized. Please make sure you are connected to the correct network and have MetaMask installed.')
        return
      }
      try {
        const accounts = await this.web3.eth.getAccounts()
        await this.contract.methods.vote(this.selectedProposal).send({ from: accounts[0] })
        alert('Vote cast successfully!')
        this.selectedProposal = null 
      } catch (error) {
        console.error('Error casting vote:', error)
        alert('Failed to cast vote. Make sure you have the right to vote and haven\'t voted before.')
      }
    }
  }
}
</script>