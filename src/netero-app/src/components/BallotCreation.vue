<template>
  <div class="ballot-creation">
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
      restricted: false,
      factory: null,
      createdPoll: ''
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

        // Get created poll address from event
        const ev = tx.events?.PollCreated || (tx.logs || []).find(l => l.event === 'PollCreated')
        const pollAddress = ev ? (ev.returnValues?.poll || ev.args?.poll) : null
        this.createdPoll = pollAddress || ''

        // Auto-activate
        if (pollAddress) {
          const poll = await getContract(PollArtifact, pollAddress)
          await poll.methods.activate().send({ from: accounts[0] })
        }

        this.$nextTick(() => {
          this.title = ''
          this.description = ''
          this.options = ['', '']
          this.restricted = false
        })

        alert('Poll created successfully' + (this.createdPoll ? ` at ${this.createdPoll}` : ''))
      } catch (error) {
        console.error('Error creating poll:', error)
        alert('Failed to create poll: ' + (error?.message || error))
      }
    }
  }
}
</script>

<style scoped>
.row { margin-bottom: 0.75rem; }
.options { margin: 1rem 0; }
.option { display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.5rem; }
.created { margin-top: 1rem; }
code { font-family: monospace; }
</style>