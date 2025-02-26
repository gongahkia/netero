<template>
  <div class="results-display">
    <h2>Voting Results</h2>
    <div v-if="proposals.length > 0">
      <h3>Results</h3>
      <ul>
        <li v-for="(proposal, index) in proposals" :key="index">
          {{ web3 ? web3.utils.hexToUtf8(proposal.name) : '' }}: {{ proposal.voteCount }} votes
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
    try {
      await this.initWeb3()
      await this.loadResults()
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
    async loadResults() {
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