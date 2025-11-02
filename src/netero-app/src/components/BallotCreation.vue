<template>
  <div class="ballot-creation">
<<<<<<< HEAD
    <div class="section-header">
      <h2>// CREATE_VOTING_CONTRACT</h2>
      <div class="status-indicator">[ READY ]</div>
    </div>
    
    <form @submit.prevent="createVotingContract" class="contract-form">
      <div class="proposals-section">
        <label class="section-label">&gt; PROPOSALS:</label>
        <div v-for="(option, index) in options" :key="index" class="input-group">
          <span class="input-prefix">{{ String(index + 1).padStart(2, '0') }}:</span>
          <input 
            v-model="options[index]" 
            :placeholder="`PROPOSAL_${index + 1}`" 
            required
            class="terminal-input"
          >
        </div>
      </div>
      
      <div class="button-group">
        <button type="button" @click="addOption" class="btn-secondary">
          [ + ADD_PROPOSAL ]
        </button>
        <button type="submit" class="btn-primary">
          [ DEPLOY_CONTRACT ]
        </button>
      </div>
      
      <div v-if="contractAddress" class="contract-result">
        <div class="result-label">&gt; CONTRACT_DEPLOYED:</div>
        <div class="contract-address">{{ contractAddress }}</div>
      </div>
=======
    <h2>Create Poll</h2>
    <form @submit.prevent="createPoll">
      <div class="row">
        <input v-model="title" placeholder="Title" required />
      </div>
      <div class="row">
        <textarea v-model="description" placeholder="Description" rows="3" />
      </div>
      <div class="row">
        <label><input type="checkbox" v-model="restricted" /> Restricted (allowlist required)</label>
      </div>
      <div class="options">
        <h3>Options</h3>
        <div v-for="(option, index) in options" :key="index" class="option">
          <input v-model="options[index]" :placeholder="`Option ${index + 1}`" required />
          <button type="button" @click="removeOption(index)" v-if="options.length > 2">Remove</button>
        </div>
        <button type="button" @click="addOption">Add Option</button>
      </div>
      <button type="submit">Create & Activate</button>
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
    </form>

    <div v-if="createdPoll" class="created">
      <p>Created poll at: <code>{{ createdPoll }}</code></p>
    </div>
  </div>
  
</template>

<script>
import { initWeb3, getAccounts, getDeployedAddress, getContract } from '../eth'
import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
import PollArtifact from '../../../core/build/contracts/Poll.json'

export default {
  name: 'BallotCreation',
  data() {
    return {
      title: '',
      description: '',
      options: ['', ''],
<<<<<<< HEAD
      web3: null,
      contract: null,
      contractAddress: null
=======
      restricted: false,
      factory: null,
      createdPoll: ''
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
    }
  },
  async mounted() {
    await this.init()
  },
  methods: {
    async init() {
      await initWeb3()
      const address = await getDeployedAddress(PollFactoryArtifact)
      this.factory = await getContract(PollFactoryArtifact, address)
    },
    addOption() {
      this.options.push('')
    },
    removeOption(index) {
      this.options.splice(index, 1)
    },
    async createPoll() {
      try {
        if (!this.factory) await this.init()
        const accounts = await getAccounts()
        const org = accounts[0] // MVP: org = admin/creator address
        const startTime = 0
        const endTime = 0
        const tx = await this.factory.methods.createPoll(
          org,
          this.title,
          this.description,
          this.options,
          startTime,
          endTime,
          this.restricted
        ).send({ from: accounts[0] })

<<<<<<< HEAD
        const proposalNames = this.options.map(option => this.web3.utils.asciiToHex(option))
        const initialAuthorities = accounts.slice(0, 3)
=======
        // Get created poll address from event
        const ev = tx.events?.PollCreated || (tx.logs || []).find(l => l.event === 'PollCreated')
        const pollAddress = ev ? (ev.returnValues?.poll || ev.args?.poll) : null
        this.createdPoll = pollAddress || ''

        // Auto-activate
        if (pollAddress) {
          const poll = await getContract(PollArtifact, pollAddress)
          await poll.methods.activate().send({ from: accounts[0] })
        }
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190

        this.$nextTick(() => {
          this.title = ''
          this.description = ''
          this.options = ['', '']
          this.restricted = false
        })

<<<<<<< HEAD
        this.contractAddress = deployedContract.options.address
        console.log('Contract deployed at:', this.contractAddress)
        alert('[ SUCCESS ] Contract deployed at: ' + this.contractAddress)
      } catch (error) {
        console.error('Error creating voting contract:', error)
        alert('[ ERROR ] Failed to deploy contract: ' + error.message)
=======
        alert('Poll created successfully' + (this.createdPoll ? ` at ${this.createdPoll}` : ''))
      } catch (error) {
        console.error('Error creating poll:', error)
        alert('Failed to create poll: ' + (error?.message || error))
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
      }
    }
  }
}
</script>

<style scoped>
<<<<<<< HEAD
.ballot-creation {
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

.contract-form {
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  padding: 2rem;
}

.proposals-section {
  margin-bottom: 2rem;
}

.section-label {
  display: block;
  color: var(--text-secondary);
  margin-bottom: 1rem;
  font-size: 0.9rem;
  letter-spacing: 0.1rem;
}

.input-group {
  display: flex;
  align-items: center;
  margin-bottom: 1rem;
  gap: 1rem;
}

.input-prefix {
  color: var(--text-muted);
  min-width: 40px;
  font-size: 0.9rem;
}

.terminal-input {
  flex: 1;
  background-color: var(--bg-primary);
  border: 1px solid var(--border-color);
  color: var(--text-primary);
  padding: 0.8rem 1rem;
  font-family: 'Courier New', 'Consolas', 'Monaco', monospace;
  font-size: 0.9rem;
  transition: all 0.3s ease;
}

.terminal-input:focus {
  outline: none;
  border-color: var(--text-primary);
  box-shadow: 0 0 0 4px rgba(17, 24, 39, 0.08);
}

.terminal-input::placeholder {
  color: var(--text-muted);
  opacity: 0.5;
}

.button-group {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.btn-primary,
.btn-secondary {
  background-color: var(--bg-primary);
  border: 1px solid var(--border-color);
  color: var(--text-primary);
  padding: 0.8rem 1.5rem;
  font-family: 'Courier New', 'Consolas', 'Monaco', monospace;
  font-size: 0.9rem;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
  letter-spacing: 0.05rem;
}

.btn-primary:hover,
.btn-secondary:hover {
  background-color: var(--accent);
  border-color: var(--accent);
  color: var(--accent-contrast);
  box-shadow: 0 8px 24px rgba(17, 24, 39, 0.25);
}

.btn-primary {
  border-width: 2px;
}

.contract-result {
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid var(--border-color);
}

.result-label {
  color: var(--text-secondary);
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
}

.contract-address {
  color: var(--text-primary);
  font-size: 0.85rem;
  word-break: break-all;
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
  
  .contract-form {
    padding: 1rem;
  }
  
  .button-group {
    flex-direction: column;
  }
  
  .btn-primary,
  .btn-secondary {
    width: 100%;
  }
}
=======
.row { margin-bottom: 0.75rem; }
.options { margin: 1rem 0; }
.option { display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.5rem; }
.created { margin-top: 1rem; }
code { font-family: monospace; }
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
</style>