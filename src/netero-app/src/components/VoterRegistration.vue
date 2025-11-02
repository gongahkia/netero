<template>
  <div class="voter-registration">
    <div class="section-header">
      <h2>// VOTER_REGISTRATION</h2>
      <div class="status-indicator">[ ACTIVE ]</div>
    </div>
    
    <form @submit.prevent="giveRightToVote" class="registration-form">
      <div class="form-section">
        <label class="section-label">&gt; ETHEREUM_ADDRESS:</label>
        <div class="input-wrapper">
          <span class="input-icon">0x</span>
          <input 
            v-model="voterAddress" 
            placeholder="ENTER_WALLET_ADDRESS" 
            required
            class="terminal-input"
          >
        </div>
      </div>
      
      <button type="submit" class="btn-primary">
        [ GRANT_VOTING_RIGHTS ]
      </button>
      
      <div v-if="lastRegistered" class="registration-result">
        <div class="result-label">&gt; LAST_REGISTERED:</div>
        <div class="registered-address">{{ lastRegistered }}</div>
      </div>
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
      contract: null,
      lastRegistered: null
    }
  },
  async mounted() {
    await this.initWeb3()
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
    async giveRightToVote() {
      if (!this.web3 || !this.contract) {
        alert('[ ERROR ] Web3 not initialized. Check MetaMask connection.')
        return
      }
      try {
        const accounts = await this.web3.eth.getAccounts()
        await this.contract.methods.giveRightToVote(this.voterAddress).send({ from: accounts[0] })
        this.lastRegistered = this.voterAddress
        alert('[ SUCCESS ] Voting rights granted to: ' + this.voterAddress)
        this.voterAddress = '' 
      } catch (error) {
        console.error('Error giving right to vote:', error)
        alert('[ ERROR ] Failed to grant voting rights. Ensure you have authority.')
      }
    }
  }
}
</script>

<style scoped>
.voter-registration {
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

.registration-form {
  background-color: var(--bg-secondary);
  border: 1px solid var(--border-color);
  padding: 2rem;
}

.form-section {
  margin-bottom: 2rem;
}

.section-label {
  display: block;
  color: var(--text-secondary);
  margin-bottom: 1rem;
  font-size: 0.9rem;
  letter-spacing: 0.1rem;
}

.input-wrapper {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.input-icon {
  color: var(--text-muted);
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

.btn-primary:hover {
  background-color: var(--accent-hover);
  border-color: var(--accent-hover);
  color: var(--accent-contrast);
  box-shadow: 0 8px 24px rgba(17, 24, 39, 0.25);
}

.registration-result {
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid var(--border-color);
}

.result-label {
  color: var(--text-secondary);
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
}

.registered-address {
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
  
  .registration-form {
    padding: 1rem;
  }
}
</style>