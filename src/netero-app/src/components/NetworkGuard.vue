<template>
  <div v-if="show" class="network-guard">
    <div class="container guard-row">
      <div class="guard-text">
        <strong>Wrong network detected.</strong>
        <span>Please switch to the local chain (1337) to continue.</span>
      </div>
      <div class="guard-actions">
        <button class="btn btn-primary" @click="switchNetwork" :disabled="busy">
          {{ busy ? 'Switching…' : 'Switch to 1337' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { isCorrectNetwork, switchToLocalNetwork } from '../eth'

export default {
  name: 'NetworkGuard',
  data() {
    return {
      show: false,
      busy: false,
    }
  },
  async mounted() {
    await this.evaluate()
    if (window?.ethereum?.on) {
      window.ethereum.on('chainChanged', this.evaluate)
    }
  },
  beforeUnmount() {
    if (window?.ethereum?.removeListener) {
      window.ethereum.removeListener('chainChanged', this.evaluate)
    }
  },
  methods: {
    async evaluate() {
      try {
        this.show = !(await isCorrectNetwork())
      } catch (e) {
        this.show = false
      }
    },
    async switchNetwork() {
      this.busy = true
      try {
        const ok = await switchToLocalNetwork()
        if (!ok) {
          // no-op, user may cancel
        }
        await this.evaluate()
      } finally {
        this.busy = false
      }
    },
  },
}
</script>

<style scoped>
.network-guard {
  position: sticky;
  top: 0;
  z-index: 30;
  background: #fff1f2;
  border-bottom: 1px solid #fecdd3;
}
.guard-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 12px 24px;
}
.guard-text {
  display: flex;
  flex-direction: column;
  gap: 4px;
  color: #9f1239;
  font-size: 13px;
}
</style>
