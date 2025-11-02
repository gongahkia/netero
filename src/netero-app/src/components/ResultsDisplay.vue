<template>
  <div class="results-display">
    <div class="section-header">
      <h2>// VOTING_RESULTS</h2>
      <div class="status-indicator">[ {{ proposals.length }} PROPOSALS ]</div>
    </div>
    
    <div v-if="proposals.length > 0" class="results-container">
      <div class="results-section">
        <label class="section-label">&gt; VOTE_COUNT:</label>
        <div class="proposals-results">
          <div 
            v-for="(proposal, index) in proposals" 
            :key="index"
            class="result-item"
          >
            <div class="result-header">
              <span class="result-index">[{{ String(index + 1).padStart(2, '0') }}]</span>
              <span class="result-name">{{ web3 ? web3.utils.hexToUtf8(proposal.name) : '' }}</span>
            </div>
            <div class="result-votes">
              <div class="vote-bar-container">
                <div 
                  class="vote-bar" 
                  :style="{ width: getVotePercentage(proposal.voteCount) + '%' }"
                ></div>
              </div>
              <span class="vote-count">{{ proposal.voteCount }} VOTES</span>
            </div>
          </div>
        </div>
      </div>
      
      <div class="winner-section">
        <div class="winner-label">&gt; WINNING_PROPOSAL:</div>
        <div class="winner-name">{{ winningProposalName }}</div>
      </div>
    </div>
    
    <div v-else class="no-results">
      <span>&gt; NO_RESULTS_AVAILABLE</span>
      <p>Deploy a contract and cast votes first.</p>
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
        alert('[ ERROR ] Failed to initialize Web3. Check network connection.')
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
        alert('[ ERROR ] Failed to load results')
      }
    },
    getVotePercentage(voteCount) {
      const total = this.proposals.reduce((sum, p) => sum + parseInt(p.voteCount), 0)
      return total > 0 ? (parseInt(voteCount) / total) * 100 : 0
    }
  }
}
</script>

<style scoped>
.results-display {
  max-width: 800px;
  margin: 0 auto;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--border-color);
}

.section-header h2 {
  color: var(--text-primary);
  font-size: 1.5rem;
  font-weight: bold;
  letter-spacing: 0.1rem;
}

.status-indicator {
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.results-container {
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  padding: 2rem;
}

.results-section {
  margin-bottom: 2rem;
}

.section-label {
  display: block;
  color: var(--text-secondary);
  margin-bottom: 1.5rem;
  font-size: 0.9rem;
  letter-spacing: 0.1rem;
}

.proposals-results {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.result-item {
  padding: 1.5rem;
  background-color: var(--bg-primary);
  border: 1px solid var(--border-color);
}

.result-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.result-index {
  color: var(--text-muted);
  font-size: 0.9rem;
  min-width: 50px;
}

.result-name {
  color: var(--text-primary);
  font-size: 1rem;
  flex: 1;
}

.result-votes {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.vote-bar-container {
  width: 100%;
  height: 20px;
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  position: relative;
  overflow: hidden;
}

.vote-bar {
  height: 100%;
  background-color: var(--accent);
  transition: width 0.5s ease;
  opacity: 0.3;
}

.vote-count {
  color: var(--text-secondary);
  font-size: 0.85rem;
  text-align: right;
}

.winner-section {
  padding-top: 2rem;
  border-top: 2px solid var(--border-color);
}

.winner-label {
  color: var(--text-secondary);
  margin-bottom: 1rem;
  font-size: 0.9rem;
  letter-spacing: 0.1rem;
}

.winner-name {
  color: var(--text-primary);
  font-size: 1.5rem;
  padding: 1.5rem;
  background-color: var(--bg-primary);
  border: 2px solid var(--border-color);
  text-align: center;
  text-shadow: 0 0 10px var(--accent);
  letter-spacing: 0.2rem;
}

.no-results {
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  padding: 3rem 2rem;
  text-align: center;
}

.no-results span {
  display: block;
  color: var(--text-secondary);
  font-size: 1.2rem;
  margin-bottom: 1rem;
}

.no-results p {
  color: var(--text-muted);
  font-size: 0.9rem;
}

@media (max-width: 768px) {
  .section-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  
  .results-container {
    padding: 1rem;
  }
  
  .result-item {
    padding: 1rem;
  }
  
  .winner-name {
    font-size: 1.2rem;
    padding: 1rem;
  }
}
</style>