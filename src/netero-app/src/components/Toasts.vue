<template>
  <div class="toasts">
    <div v-for="t in state.toasts" :key="t.id" :class="['toast', `toast-${t.type}`]">
      <span>{{ t.message }}</span>
      <button class="btn btn-ghost" @click="dismiss(t.id)">×</button>
    </div>
  </div>
</template>

<script setup>
import { useToasts } from '../store/toasts'
const { state, dismiss } = useToasts()
</script>

<style scoped>
.toasts {
  position: fixed;
  right: 16px;
  bottom: 16px;
  display: grid;
  gap: 10px;
  z-index: 50;
}
.toast {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-radius: 8px;
  border: 1px solid var(--border);
  background: var(--bg-surface);
  box-shadow: var(--shadow-sm);
  min-width: 220px;
}
.toast-success { border-color: #bbf7d0; background: #f0fdf4; }
.toast-error   { border-color: #fecaca; background: #fef2f2; }
.toast-info    { border-color: #d1d5db; background: #f9fafb; }

.btn-ghost { border: none; background: transparent; cursor: pointer; }
</style>
