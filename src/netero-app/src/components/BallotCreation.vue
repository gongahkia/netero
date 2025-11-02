<template>
  <div class="ballot-creation">
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
    </form>
  </div>
</template>

<script>
import Web3 from 'web3'
import VoteContract from '../../../core/build/contracts/Vote.json'

export default {
  name: 'BallotCreation',
  data() {
    return {
      options: ['', ''],
      web3: null,
      contract: null,
      contractAddress: null
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
          await window.ethereum.request({ method: 'eth_requestAccounts' })
        } catch (error) {
          console.error("User denied account access")
        }
      } else if (window.web3) {
        this.web3 = new Web3(window.web3.currentProvider)
      } else {
        console.log('Non-Ethereum browser detected. Consider using MetaMask!')
      }
    },
    addOption() {
      this.options.push('')
    },
    async createVotingContract() {
      try {
        const accounts = await this.web3.eth.getAccounts()
        const networkId = await this.web3.eth.net.getId()

        const proposalNames = this.options.map(option => this.web3.utils.asciiToHex(option))
        const initialAuthorities = accounts.slice(0, 3)

        const deployContract = new this.web3.eth.Contract(VoteContract.abi)

        const deployedContract = await deployContract.deploy({
          data: VoteContract.bytecode,
          arguments: [proposalNames, initialAuthorities]
        }).send({
          from: accounts[0],
          gas: 3000000
        })

        this.contractAddress = deployedContract.options.address
        console.log('Contract deployed at:', this.contractAddress)
        alert('[ SUCCESS ] Contract deployed at: ' + this.contractAddress)
      } catch (error) {
        console.error('Error creating voting contract:', error)
        alert('[ ERROR ] Failed to deploy contract: ' + error.message)
      }
    }
  }
}
</script>

<style scoped>
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
  border-color: var(--accent);
  box-shadow: 0 0 10px rgba(0, 255, 0, 0.2);
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
  background-color: rgba(0, 255, 0, 0.1);
  box-shadow: 0 0 15px rgba(0, 255, 0, 0.3);
  text-shadow: 0 0 5px var(--accent);
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
</style>