<template>
  <div class="voting-interface">
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
    </form>
  </div>
  
</template>

<script>
import { initWeb3, getAccounts, getDeployedAddress, getContract, subscribeToEventOptional } from '../eth'
import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
import PollArtifact from '../../../core/build/contracts/Poll.json'

export default {
  name: 'VotingInterface',
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
  },
  data() {
    return {
      orgAddress: '',
      polls: [],
      selectedPollAddress: '',
      options: [],
      selectedProposal: null,
      factory: null,
      poll: null,
      state: null,
      stateSub: null
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
        if (!this.factory) return
        const list = await this.factory.methods.getOrgPolls(this.orgAddress).call()
        this.polls = list
      } catch (e) {
        console.error('Failed to load org polls', e)
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
      }
    }
  }
}
</script>

<style scoped>
.selector { display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.75rem; }
input, select { padding: 0.4rem; }
.state-row { margin-bottom: 0.5rem; }
.badge { padding: 0.2rem 0.5rem; border-radius: 8px; font-size: 0.8rem; color: white; }
.badge.draft { background: #7f8c8d; }
.badge.active { background: #2ecc71; }
.badge.ended { background: #e67e22; }
.badge.finalized { background: #9b59b6; }
</style>