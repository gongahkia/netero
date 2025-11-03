import { reactive, readonly, watch } from 'vue'

const WATCHLIST_KEY = 'netero.watchlist'
const NOTIFICATIONS_KEY = 'netero.notifications'
const MAX_NOTIFICATIONS = 50

function safeParse(json, fallback) {
  try {
    const value = JSON.parse(json)
    return Array.isArray(fallback) && !Array.isArray(value) ? fallback : value ?? fallback
  } catch (e) {
    return fallback
  }
}

const storage = typeof window !== 'undefined' ? window.localStorage : null

const state = reactive({
  watchlist: storage ? safeParse(storage.getItem(WATCHLIST_KEY), []) : [],
  notifications: storage ? safeParse(storage.getItem(NOTIFICATIONS_KEY), []) : [],
})

watch(
  () => state.watchlist,
  (next) => {
    if (storage) storage.setItem(WATCHLIST_KEY, JSON.stringify(next))
  },
  { deep: true }
)

watch(
  () => state.notifications,
  (next) => {
    if (storage) storage.setItem(NOTIFICATIONS_KEY, JSON.stringify(next.slice(0, MAX_NOTIFICATIONS)))
  },
  { deep: true }
)

function normaliseAddress(address) {
  return typeof address === 'string' ? address.trim().toLowerCase() : ''
}

export function useNotificationStore() {
  const addWatcher = (input) => {
    const address = normaliseAddress(input?.address || input)
    if (!address || !address.startsWith('0x') || address.length !== 42) {
      throw new Error('Invalid address')
    }
    if (state.watchlist.some((item) => normaliseAddress(item.address) === address)) {
      return
    }
    const label = input?.label?.trim() || ''
    state.watchlist.unshift({ address, label })
    if (state.watchlist.length > 25) {
      state.watchlist = state.watchlist.slice(0, 25)
    }
  }

  const removeWatcher = (address) => {
    const target = normaliseAddress(address)
    state.watchlist = state.watchlist.filter((item) => normaliseAddress(item.address) !== target)
  }

  const renameWatcher = (address, label) => {
    const target = normaliseAddress(address)
    state.watchlist = state.watchlist.map((item) =>
      normaliseAddress(item.address) === target ? { ...item, label: label.trim() } : item
    )
  }

  const recordNotification = (payload) => {
    state.notifications.unshift({ ...payload, id: `${payload.poll}-${payload.voter}-${payload.timestamp}` })
    if (state.notifications.length > MAX_NOTIFICATIONS) {
      state.notifications = state.notifications.slice(0, MAX_NOTIFICATIONS)
    }
  }

  const clearNotifications = () => {
    state.notifications = []
  }

  return {
    state: readonly(state),
    addWatcher,
    removeWatcher,
    renameWatcher,
    recordNotification,
    clearNotifications,
  }
}
