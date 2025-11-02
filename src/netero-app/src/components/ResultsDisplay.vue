<template>
  <div class="results-display">
<<<<<<< HEAD
    <div class="section-header">
      <h2>// VOTING_RESULTS</h2>
      <div class="status-indicator">[ {{ proposals.length }} PROPOSALS ]</div>
=======
    <h2>Voting Results</h2>

    <div class="selector">
      <label>Org (defaults to your address):</label>
      <input v-model="orgAddress" placeholder="0x..." />
      <button @click="loadOrgPolls">Load Polls</button>
    </div>

    <div class="selector" v-if="polls.length">
      <label>Select Poll:</label>
      <select v-model="selectedPollAddress" @change="onPollChange">
        <option disabled value="">-- choose a poll --</option>
        <option v-for="addr in polls" :key="addr" :value="addr">{{ addr }}</option>
      </select>
    </div>

    <div v-if="options.length">
      <div class="header-row">
        <h3>{{ title }}</h3>
        <span class="badge" :class="stateClass">{{ stateLabel }}</span>
      </div>
      <ul>
        <li v-for="(opt, idx) in options" :key="idx">{{ opt }}: {{ tallies[idx] || 0 }} votes</li>
      </ul>
      <p>Winning Option: <strong>{{ winningOption }}</strong></p>
      <canvas ref="chart" height="200"></canvas>

      <div v-if="isAdmin" class="admin-actions">
        <button v-if="state === 0" @click="activate">Activate</button>
        <button v-if="state === 1" @click="end">End</button>
        <button v-if="state === 2" @click="finalize">Finalize</button>
      </div>
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
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
import { initWeb3, getAccounts, getDeployedAddress, getContract, subscribeToEventOptional } from '../eth'
import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
import PollArtifact from '../../../core/build/contracts/Poll.json'
import { Chart, ArcElement, Tooltip, Legend } from 'chart.js'
Chart.register(ArcElement, Tooltip, Legend)

export default {
  name: 'ResultsDisplay',
<<<<<<< HEAD
  props: { address: { type: String, default: '' } },
=======
  computed: {
    stateLabel() {
      switch (this.state) {
        case 0: return 'Draft'
        case 1: return 'Active'
        case 2: return 'Ended'
        case 3: return 'Finalized'
        default: return 'Unknown'
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
  },
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
  data() {
    return {
      orgAddress: '',
      polls: [],
      selectedPollAddress: '',
      title: '',
      options: [],
      tallies: [],
      winningOption: '',
      factory: null,
      poll: null,
      chartInstance: null,
      state: 0,
      isAdmin: false,
      refreshId: null,
      eventSubs: []
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
    if (this.refreshId) clearInterval(this.refreshId)
    this.teardownSubs()
  },
  methods: {
    teardownSubs() {
      if (!this.eventSubs) return
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
        this.eventSubs.forEach(s => { if (s && s.unsubscribe) s.unsubscribe() })
      } catch (e) {}
      this.eventSubs = []
    },
    async loadOrgPolls() {
      try {
        if (!this.factory) return
        const list = await this.factory.methods.getOrgPolls(this.orgAddress).call()
        this.polls = list
      } catch (e) {
        console.error('Failed to load org polls', e)
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
      }
    },
    async onPollChange() {
      if (this.refreshId) {
        clearInterval(this.refreshId)
        this.refreshId = null
      }
      this.teardownSubs()
      await this.loadResults()
      this.refreshId = setInterval(() => {
        this.loadResults(true)
      }, 3000)

      // Try event-driven updates if WS available
      try {
        const sub1 = subscribeToEventOptional(PollArtifact.abi, this.selectedPollAddress, 'Voted', () => this.loadResults(true))
        const sub2 = subscribeToEventOptional(PollArtifact.abi, this.selectedPollAddress, 'StateChanged', () => this.loadResults(true))
        this.eventSubs = [sub1, sub2].filter(Boolean)
      } catch (e) {
        // no-op; will keep polling
      }
    },
    async loadResults(isRefresh = false) {
      try {
        if (!this.selectedPollAddress) return
        this.poll = await getContract(PollArtifact, this.selectedPollAddress)
        const [opts, tallies, t, st, admin] = await Promise.all([
          this.poll.methods.getOptions().call(),
          this.poll.methods.getTallies().call(),
          this.poll.methods.title().call(),
          this.poll.methods.state().call(),
          this.poll.methods.admin().call()
        ])
        this.options = opts
        this.tallies = tallies.map(v => Number(v))
        this.title = t
        this.state = Number(st)
        const accounts = await getAccounts()
        this.isAdmin = accounts[0]?.toLowerCase() === admin.toLowerCase()
        const maxIdx = this.tallies.reduce((best, v, i, arr) => v > arr[best] ? i : best, 0)
        this.winningOption = this.options[maxIdx] || ''
        this.renderChart()
      } catch (e) {
        console.error('Failed to load results', e)
      }
    },
    renderChart() {
      if (!this.$refs.chart) return
      const ctx = this.$refs.chart.getContext('2d')
      const data = {
        labels: this.options,
        datasets: [{
          label: 'Votes',
          data: this.tallies,
          backgroundColor: ['#3498db','#2ecc71','#e67e22','#9b59b6','#e74c3c','#1abc9c','#f1c40f']
        }]
      }
      if (this.chartInstance) {
        this.chartInstance.data = data
        this.chartInstance.update()
        return
      }
      this.chartInstance = new Chart(ctx, { type: 'doughnut', data })
    },
    async activate() {
      try {
<<<<<<< HEAD
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
=======
        const accounts = await getAccounts()
        await this.poll.methods.activate().send({ from: accounts[0] })
        await this.loadResults(true)
      } catch (e) { console.error(e) }
    },
    async end() {
      try {
        const accounts = await getAccounts()
        await this.poll.methods.end().send({ from: accounts[0] })
        await this.loadResults(true)
      } catch (e) { console.error(e) }
    },
    async finalize() {
      try {
        const accounts = await getAccounts()
        await this.poll.methods.finalize().send({ from: accounts[0] })
        await this.loadResults(true)
      } catch (e) { console.error(e) }
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
    }
  }
}
</script>

<style scoped>
<<<<<<< HEAD
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
=======
.selector { display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.75rem; }
input, select { padding: 0.4rem; }
.header-row { display: flex; align-items: center; gap: 0.5rem; }
.badge { padding: 0.2rem 0.5rem; border-radius: 8px; font-size: 0.8rem; color: white; }
.badge.draft { background: #7f8c8d; }
.badge.active { background: #2ecc71; }
.badge.ended { background: #e67e22; }
.badge.finalized { background: #9b59b6; }
.admin-actions { margin-top: 0.75rem; display: flex; gap: 0.5rem; }
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
</style>