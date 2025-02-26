<template>
  <div class="results-display">
    <h1>Netero</h1>
    <h2>Voting Results</h2>
    <div v-if="proposals.length > 0">
      <h3>Results</h3>
      <ul>
        <li v-for="(proposal, index) in proposals" :key="index">
          {{ web3.utils.hexToUtf8(proposal.name) }}: {{ proposal.voteCount }} votes
        </li>
      </ul>
      <p>Winning Proposal: {{ winningProposalName }}</p>
    </div>
    <div v-else>
      <p>No results available</p>
    </div>
  </div>
</template>

<script>
import Web3 from 'web3'
import VoteContract from '../../../core/build/contracts/Vote.json'

export default {
  name: 'ResultsDisplay',
  data() {
    return {
      proposals: [],
      winningProposalName: '',
      web3: null,
      contract: null
    }
  },
  async mounted() {
    await this.initWeb3()
    await this.loadResults()
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
    async loadResults() {
      try {
        const proposalCount = await this.contract.methods.proposals.length().call()
        this.proposals = []
        for (let i = 0; i < proposalCount; i++) {
          const proposal = await this.contract.methods.proposals(i).call()
          this.proposals.push(proposal)
        }

        // const winningProposalIndex = await this.contract.methods.winningProposal().call()

        const winnerName = await this.contract.methods.winnerName().call()
        this.winningProposalName = this.web3.utils.hexToUtf8(winnerName)
      } catch (error) {
        console.error('Error loading results:', error)
        alert('Failed to load results')
      }
    }
  }
}
</script>