<template>
  <div class="voting-interface">
<<<<<<< HEAD
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
=======
    <h2>Cast Your Vote</h2>

    <div class="selector">
      <label>Org (defaults to your address):</label>
      <input v-model="orgAddress" placeholder="0x..." />
      <button @click="loadOrgPolls">Load Polls</button>
    </div>

    <div class="selector" v-if="polls.length">
      <label>Select Poll:</label>
      <select v-model="selectedPollAddress" @change="loadPoll">
        <option disabled value="">-- choose a poll --</option>
        <option v-for="addr in polls" :key="addr" :value="addr">{{ addr }}</option>
      </select>
    </div>

    <div v-if="stateLabel" class="state-row">
      <span class="badge" :class="stateClass">{{ stateLabel }}</span>
    </div>

    <form v-if="options.length" @submit.prevent="castVote">
      <div v-for="(opt, index) in options" :key="index">
        <input type="radio" :id="'proposal-' + index" :value="index" v-model.number="selectedProposal" />
        <label :for="'proposal-' + index">{{ opt }}</label>
      </div>
      <button type="submit" :disabled="selectedProposal === null || !selectedPollAddress">Cast Vote</button>
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
    </form>
  </div>
  
</template>

<script>
import { initWeb3, getAccounts, getDeployedAddress, getContract, subscribeToEventOptional } from '../eth'
import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
import PollArtifact from '../../../core/build/contracts/Poll.json'

export default {
  name: 'VotingInterface',
<<<<<<< HEAD
  props: {
    address: { type: String, default: '' }
=======
  computed: {
    stateLabel() {
      switch (this.state) {
        case 0: return 'Draft'
        case 1: return 'Active'
        case 2: return 'Ended'
        case 3: return 'Finalized'
        default: return ''
      }
    },
    stateClass() {
      return {
        draft: this.state === 0,
        active: this.state === 1,
        ended: this.state === 2,
        finalized: this.state === 3
      }
    }
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
  },
  data() {
    return {
      orgAddress: '',
      polls: [],
      selectedPollAddress: '',
      options: [],
      selectedProposal: null,
<<<<<<< HEAD
      web3: null,
      contract: null,
      voteConfirmation: null
=======
      factory: null,
      poll: null,
      state: null,
      stateSub: null
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
    }
  },
  async mounted() {
    try {
      await initWeb3()
      const accounts = await getAccounts()
      this.orgAddress = accounts[0]
      const addr = await getDeployedAddress(PollFactoryArtifact)
      this.factory = await getContract(PollFactoryArtifact, addr)
      await this.loadOrgPolls()
    } catch (error) {
      console.error('Error in mounted hook:', error)
    }
  },
  beforeUnmount() {
    if (this.stateSub && this.stateSub.unsubscribe) {
      try { this.stateSub.unsubscribe() } catch (e) {}
    }
  },
  methods: {
    async loadOrgPolls() {
      try {
<<<<<<< HEAD
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
        if (!deployedNetwork && !this.address) {
          throw new Error('Contract not deployed on the current network')
        }
        const targetAddress = this.address && this.address.length > 0 ? this.address : deployedNetwork.address
        this.contract = new this.web3.eth.Contract(
          VoteContract.abi,
          targetAddress
        )
      } catch (error) {
        console.error('Failed to initialize Web3:', error)
        alert('[ ERROR ] Failed to initialize Web3. Check network connection.')
=======
        if (!this.factory) return
        const list = await this.factory.methods.getOrgPolls(this.orgAddress).call()
        this.polls = list
      } catch (e) {
        console.error('Failed to load org polls', e)
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
      }
    },
    async loadPoll() {
      try {
        if (!this.selectedPollAddress) return
        this.poll = await getContract(PollArtifact, this.selectedPollAddress)
        if (this.stateSub && this.stateSub.unsubscribe) {
          try { this.stateSub.unsubscribe() } catch (e) {}
          this.stateSub = null
        }
<<<<<<< HEAD
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
=======
        const [opts, st] = await Promise.all([
          this.poll.methods.getOptions().call(),
          this.poll.methods.state().call()
        ])
        this.options = opts
        this.selectedProposal = null
        this.state = Number(st)

        // Subscribe to state changes if WS is available
        try {
          this.stateSub = subscribeToEventOptional(PollArtifact.abi, this.selectedPollAddress, 'StateChanged', async () => {
            try {
              const s = await this.poll.methods.state().call()
              this.state = Number(s)
            } catch (e) {}
          })
        } catch (e) {}
      } catch (e) {
        console.error('Failed to load poll', e)
      }
    },
    async castVote() {
      if (!this.poll) {
        alert('Select a poll first.')
        return
      }
      try {
        const accounts = await getAccounts()
        await this.poll.methods.vote(this.selectedProposal).send({ from: accounts[0] })
        alert('Vote cast successfully!')
        this.selectedProposal = null
      } catch (error) {
        console.error('Error casting vote:', error)
        alert('Failed to cast vote. You may not be allowlisted or have already voted.')
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
      }
    }
  }
}
</script>

<style scoped>
<<<<<<< HEAD
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
  background-color: var(--bg-muted);
  border-color: var(--text-primary);
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
  background-color: var(--accent-hover);
  border-color: var(--accent-hover);
  box-shadow: 0 8px 24px rgba(17, 24, 39, 0.25);
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
=======
.selector { display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.75rem; }
input, select { padding: 0.4rem; }
.state-row { margin-bottom: 0.5rem; }
.badge { padding: 0.2rem 0.5rem; border-radius: 8px; font-size: 0.8rem; color: white; }
.badge.draft { background: #7f8c8d; }
.badge.active { background: #2ecc71; }
.badge.ended { background: #e67e22; }
.badge.finalized { background: #9b59b6; }
</style>
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
