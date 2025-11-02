<template>
  <div class="voter-registration">
    <h2>Allowlist Voters</h2>

    <div class="selector">
      <label>Org (defaults to your address):</label>
      <input v-model="orgAddress" placeholder="0x..." />
      <button @click="loadOrgPolls">Load Polls</button>
    </div>

    <div class="selector" v-if="polls.length">
      <label>Select Poll:</label>
      <select v-model="selectedPollAddress">
        <option disabled value="">-- choose a poll --</option>
        <option v-for="addr in polls" :key="addr" :value="addr">{{ addr }}</option>
      </select>
    </div>

    <form @submit.prevent="setAllowlist" v-if="selectedPollAddress">
      <textarea v-model="addressesText" placeholder="Comma or newline separated addresses" rows="4"></textarea>
      <div>
        <label><input type="checkbox" v-model="allowed" /> Allowed</label>
      </div>
      <button type="submit">Update Allowlist</button>
    </form>
  </div>
</template>

<script>
import { initWeb3, getAccounts, getDeployedAddress, getContract } from '../eth'
import PollFactoryArtifact from '../../../core/build/contracts/PollFactory.json'
import PollArtifact from '../../../core/build/contracts/Poll.json'

export default {
  name: 'VoterRegistration',
  data() {
    return {
      orgAddress: '',
      polls: [],
      selectedPollAddress: '',
      addressesText: '',
      allowed: true,
      factory: null
    }
  },
  async mounted() {
    await initWeb3()
    const accounts = await getAccounts()
    this.orgAddress = accounts[0]
    const addr = await getDeployedAddress(PollFactoryArtifact)
    this.factory = await getContract(PollFactoryArtifact, addr)
    await this.loadOrgPolls()
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
    async setAllowlist() {
      try {
        const addresses = this.addressesText
          .split(/[\s,]+/)
          .map(a => a.trim())
          .filter(Boolean)
        if (!addresses.length) {
          alert('Provide at least one address.')
          return
        }
        const poll = await getContract(PollArtifact, this.selectedPollAddress)
        const accounts = await getAccounts()
        await poll.methods.setAllowlisted(addresses, this.allowed).send({ from: accounts[0] })
        alert('Allowlist updated')
      } catch (e) {
        console.error('Failed to update allowlist', e)
        alert('Failed to update allowlist: ' + (e?.message || e))
      }
    }
  }
}
</script>

<style scoped>
.selector { display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.75rem; }
input, select, textarea { padding: 0.4rem; width: 100%; max-width: 640px; }
form { display: flex; flex-direction: column; gap: 0.5rem; }
</style>