<template>
  <div class="share">
    <button class="btn" type="button" @click="copy" :disabled="!address">Copy link</button>
    <button class="btn" type="button" @click="toggleQr" :disabled="!address">QR</button>
    <div v-if="showQr" class="qr-pop">
      <canvas ref="canvas" width="144" height="144"></canvas>
    </div>
  </div>
</template>

<script>
import QRCode from 'qrcode'
import { useToasts } from '../store/toasts'

export default {
  name: 'PollShare',
  props: { address: { type: String, default: '' } },
  data() {
    return { showQr: false }
  },
  mounted() {
    if (this.address) this.renderQr()
  },
  watch: {
    address() { this.renderQr() }
  },
  methods: {
    link() {
      const url = new URL(window.location.href)
      url.pathname = '/vote'
      url.search = ''
      // for this app, voting route reads selection from state, so include address in path via query hash
      url.hash = `#poll=${this.address}`
      return url.toString()
    },
    async copy() {
      const { push } = useToasts()
      try {
        await navigator.clipboard.writeText(this.link())
        push('Link copied', 'success')
      } catch {
        push('Copy failed', 'error')
      }
    },
    toggleQr() {
      this.showQr = !this.showQr
      if (this.showQr) this.renderQr()
    },
    async renderQr() {
      if (!this.$refs.canvas || !this.address) return
      try {
        await QRCode.toCanvas(this.$refs.canvas, this.link(), { margin: 1, width: 144 })
      } catch (e) {
        // ignore QR errors silently
      }
    },
  },
}
</script>

<style scoped>
.share { display: inline-flex; gap: 8px; align-items: center; }
.qr-pop { position: absolute; background: var(--bg-surface); border: 1px solid var(--border); padding: 8px; border-radius: 8px; box-shadow: var(--shadow-sm); }
</style>
