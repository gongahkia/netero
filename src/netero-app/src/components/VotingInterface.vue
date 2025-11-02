<template>
  <div class="voting-interface">
    <div class="section-header">
      <h2>// CAST_VOTE</h2>
      <div class="status-indicator">[ {{ proposals.length }} PROPOSALS ]</div>
    </div>
    
    <form @submit.prevent="castVote" class="vote-form">
      <div class="proposals-list">
        <label class="section-label">&gt; SELECT_PROPOSAL:</label>
        <div v-if="proposals.length > 0">
          <div 
            v-for="(proposal, index) in proposals" 
            :key="index"
            class="proposal-option"
          >
            <input 
              type="radio" 
              :id="'proposal-' + index" 
              :value="index" 
              v-model="selectedProposal"
              class="radio-input"
            >
            <label :for="'proposal-' + index" class="proposal-label">
              <span class="proposal-index">[{{ String(index + 1).padStart(2, '0') }}]</span>
              <span class="proposal-name">{{ web3 ? web3.utils.hexToUtf8(proposal.name) : '' }}</span>
            </label>
          </div>
        </div>
        <div v-else class="no-proposals">
          &gt; NO_PROPOSALS_AVAILABLE
        </div>
      </div>
      
      <button 
        type="submit" 
        :disabled="selectedProposal === null"
        class="btn-primary"
        :class="{ 'btn-disabled': selectedProposal === null }"
      >
        [ SUBMIT_VOTE ]
      </button>
      
      <div v-if="voteConfirmation" class="vote-confirmation">
        <div class="confirmation-label">&gt; VOTE_CONFIRMED:</div>
        <div class="confirmation-text">{{ voteConfirmation }}</div>
      </div>
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
      contract: null,
      voteConfirmation: null
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
        alert('[ ERROR ] Failed to initialize Web3. Check network connection.')
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
        alert('[ ERROR ] Failed to load proposals')
      }
    },
    async castVote() {
      if (!this.web3 || !this.contract) {
        alert('[ ERROR ] Web3 not initialized. Check MetaMask connection.')
        return
      }
      try {
        const accounts = await this.web3.eth.getAccounts()
        await this.contract.methods.vote(this.selectedProposal).send({ from: accounts[0] })
        const proposalName = this.web3.utils.hexToUtf8(this.proposals[this.selectedProposal].name)
        this.voteConfirmation = `Voted for: ${proposalName}`
        alert('[ SUCCESS ] Vote cast successfully!')
        this.selectedProposal = null 
      } catch (error) {
        console.error('Error casting vote:', error)
        alert('[ ERROR ] Failed to cast vote: ' + error.message)
      }
    }
  }
}
</script>

<style scoped>
.voting-interface {
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

.vote-form {
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  padding: 2rem;
}

.proposals-list {
  margin-bottom: 2rem;
}

.section-label {
  display: block;
  color: var(--text-secondary);
  margin-bottom: 1.5rem;
  font-size: 0.9rem;
  letter-spacing: 0.1rem;
}

.proposal-option {
  display: flex;
  align-items: center;
  padding: 1rem;
  margin-bottom: 0.5rem;
  background-color: var(--bg-primary);
  border: 1px solid var(--border-color);
  transition: all 0.3s ease;
  cursor: pointer;
}

.proposal-option:hover {
  background-color: rgba(0, 255, 0, 0.05);
  border-color: var(--accent);
}

.radio-input {
  margin-right: 1rem;
  appearance: none;
  width: 18px;
  height: 18px;
  border: 2px solid var(--border-color);
  background-color: var(--bg-primary);
  cursor: pointer;
  position: relative;
}

.radio-input:checked::before {
  content: '■';
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  color: var(--text-primary);
  font-size: 12px;
}

.proposal-label {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 1rem;
  cursor: pointer;
  color: var(--text-primary);
}

.proposal-index {
  color: var(--text-muted);
  font-size: 0.9rem;
  min-width: 50px;
}

.proposal-name {
  color: var(--text-primary);
  font-size: 0.95rem;
}

.no-proposals {
  color: var(--text-muted);
  padding: 2rem;
  text-align: center;
  font-size: 0.9rem;
}

.btn-primary {
  width: 100%;
  background-color: var(--bg-primary);
  border: 2px solid var(--border-color);
  color: var(--text-primary);
  padding: 1rem 1.5rem;
  font-family: 'Courier New', 'Consolas', 'Monaco', monospace;
  font-size: 0.9rem;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
  letter-spacing: 0.05rem;
}

.btn-primary:hover:not(.btn-disabled) {
  background-color: rgba(0, 255, 0, 0.1);
  box-shadow: 0 0 15px rgba(0, 255, 0, 0.3);
  text-shadow: 0 0 5px var(--accent);
}

.btn-disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.vote-confirmation {
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid var(--border-color);
}

.confirmation-label {
  color: var(--text-secondary);
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
}

.confirmation-text {
  color: var(--text-primary);
  padding: 1rem;
  background-color: var(--bg-primary);
  border: 1px solid var(--border-color);
}

@media (max-width: 768px) {
  .section-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  
  .vote-form {
    padding: 1rem;
  }
  
  .proposal-label {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
}
</style>
        console.error('Error casting vote:', error)
        alert('Failed to cast vote. Make sure you have the right to vote and haven\'t voted before.')
      }
    }
  }
}
</script>