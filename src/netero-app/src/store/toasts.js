import { reactive, readonly } from 'vue'

const state = reactive({ toasts: [] })
let counter = 0

export function useToasts() {
  const push = (message, type = 'info', timeoutMs = 3000) => {
    const id = ++counter
    state.toasts.push({ id, message, type })
    if (timeoutMs > 0) {
      setTimeout(() => dismiss(id), timeoutMs)
    }
  }
  const dismiss = (id) => {
    const idx = state.toasts.findIndex((t) => t.id === id)
    if (idx >= 0) state.toasts.splice(idx, 1)
  }
  return { state: readonly(state), push, dismiss }
}
