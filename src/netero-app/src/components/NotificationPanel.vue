<template>
  <aside class="notification-sidebar" aria-live="polite">
    <header class="panel-header">
      <div>
        <h2>Live Notifications</h2>
        <p class="panel-subtitle">
          Track the wallets that matter and get an alert the second a vote lands.
        </p>
      </div>
      <button
        class="btn btn-ghost"
        type="button"
        @click="handleClear"
        :disabled="!notifications.length"
      >
        Clear
      </button>
    </header>

    <div class="activity">
      <div class="section-heading">
        <span class="section-title">Activity Feed</span>
        <span class="section-helper">Most recent votes from your watchlist.</span>
      </div>
      <ul class="activity-feed" v-if="notifications.length">
        <li v-for="note in notifications" :key="note.id" class="activity-row">
          <div class="activity-main">
            <div class="activity-title">
              {{ note.label || formatAddress(note.voter) }} voted
            </div>
            <div class="activity-meta">
              {{ formatTime(note.timestamp) }} • Poll {{ shortAddress(note.poll) }}
            </div>
          </div>
          <span class="activity-pill">Option {{ Number(note.optionIndex) + 1 }}</span>
        </li>
      </ul>
      <p v-else class="empty-hint">No live updates yet. Votes will appear here instantly.</p>
    </div>
  </aside>
</template>

<script setup>
import { computed, onBeforeUnmount, reactive, ref, watch, defineProps } from 'vue'
import PollArtifact from '../../../core/build/contracts/Poll.json'
import { getContract, subscribeToEventOptional } from '../eth'
import { useNotificationStore } from '../store/notifications'

const props = defineProps({
  pollAddresses: {
    type: Array,
    default: () => []
  },
  role: {
    type: String,
    default: ''
  }
})

const store = useNotificationStore()
const form = reactive({ address: '', label: '' })
const error = ref('')
const statusByAddress = ref({})
const pollContracts = ref([])
let refreshTimer = null
let subscriptions = []
const voteCache = reactive({})

const watchlist = computed(() => store.state.watchlist)
const notifications = computed(() => store.state.notifications.slice(0, 12))

const pollSignature = computed(() =>
  props.pollAddresses
    .filter(Boolean)
    .map((addr) => addr.toLowerCase())
    .sort()
    .join(',')
)

watch(
  [pollSignature, watchlist],
  () => {
    initialiseTracking()
  },
  { immediate: true }
)

onBeforeUnmount(() => {
  clearTracking()
})

function shortAddress(addr) {
  if (!addr) return ''
  return `${addr.slice(0, 6)}…${addr.slice(-4)}`
}

function formatAddress(addr) {
  if (!addr) return ''
  return `${addr.slice(0, 6)}…${addr.slice(-4)}`
}

function formatTime(timestamp) {
  if (!timestamp) return ''
  const date = new Date(Number(timestamp))
  return date.toLocaleString()
}

function statusVariant(summary) {
  if (!summary) return ''
  if (summary.total === 0) return 'status-idle'
  if (summary.voted === 0) return 'status-pending'
  if (summary.voted === summary.total) return 'status-complete'
  return 'status-inprogress'
}

function statusLabel(summary) {
  if (!summary || summary.total === 0) return 'No open polls'
  if (summary.voted === 0) return 'Waiting'
  if (summary.voted === summary.total) return 'All votes in'
  return `${summary.voted} of ${summary.total} voted`
}

function keyFor(poll, address) {
  return `${poll.toLowerCase()}-${address.toLowerCase()}`
}

function handleClear() {
  store.clearNotifications()
}

async function handleAddWatcher() {
  error.value = ''
  if (!form.address) {
    error.value = 'Enter a wallet address'
    return
  }
  try {
    store.addWatcher({ address: form.address, label: form.label })
    form.address = ''
    form.label = ''
    await refreshStatuses(true)
  } catch (err) {
    error.value = err?.message || 'Could not add address'
  }
}

function removeWatcher(address) {
  store.removeWatcher(address)
  refreshStatuses(true)
}

function handleVote(pollAddress, voter, optionIndex) {
  if (!voter) return
  const normalised = voter.toLowerCase()
  const key = keyFor(pollAddress, normalised)
  voteCache[key] = true
  const match = watchlist.value.find((item) => item.address.toLowerCase() === normalised)
  if (match) {
    store.recordNotification({
      poll: pollAddress,
      voter: normalised,
      optionIndex,
      timestamp: Date.now(),
      label: match.label,
      role: props.role
    })
  }
  refreshStatuses(false)
}

async function initialiseTracking() {
  clearTracking()
  statusByAddress.value = {}
  const polls = props.pollAddresses.filter(Boolean)
  if (!polls.length || !watchlist.value.length) {
    return
  }
  const contracts = []
  for (const address of polls) {
    try {
      const contract = await getContract(PollArtifact, address)
      contracts.push({ address, contract })
    } catch (e) {
      console.error('Live notifications: unable to initialise poll', address, e)
    }
  }
  pollContracts.value = contracts
  if (!contracts.length) return
  await refreshStatuses(true)
  subscriptions = contracts
    .map(({ address }) =>
      subscribeToEventOptional(PollArtifact.abi, address, 'Voted', (event) => {
        const voter = (event?.returnValues?.voter || '').toLowerCase()
        const optionIndex = Number(event?.returnValues?.optionIndex ?? 0)
        handleVote(address, voter, optionIndex)
      })
    )
    .filter(Boolean)
  refreshTimer = setInterval(() => {
    refreshStatuses(false)
  }, 15000)
}

async function refreshStatuses(force = false) {
  if (!pollContracts.value.length || !watchlist.value.length) {
    statusByAddress.value = {}
    return
  }
  const totals = pollContracts.value.length
  const summary = {}
  for (const watcher of watchlist.value) {
    summary[watcher.address.toLowerCase()] = { voted: 0, total: totals }
  }
  for (const { address: pollAddress, contract } of pollContracts.value) {
    const tasks = watchlist.value.map(async (watcher) => {
      const normalised = watcher.address.toLowerCase()
      const key = keyFor(pollAddress, normalised)
      let has = voteCache[key]
      if (force || has === undefined) {
        try {
          has = await contract.methods.hasVoted(watcher.address).call()
        } catch (e) {
          has = false
        }
        if (has) voteCache[key] = true
      }
      if (has) {
        summary[normalised].voted += 1
      }
    })
    await Promise.all(tasks)
  }
  const display = {}
  for (const watcher of watchlist.value) {
    const normalised = watcher.address.toLowerCase()
    display[watcher.address] = summary[normalised]
  }
  statusByAddress.value = display
}

function clearTracking() {
  if (refreshTimer) {
    clearInterval(refreshTimer)
    refreshTimer = null
  }
  subscriptions.forEach((sub) => {
    if (sub && typeof sub.unsubscribe === 'function') {
      try {
        sub.unsubscribe()
      } catch (e) {
        // ignore unsubscribe errors
      }
    }
  })
  subscriptions = []
  pollContracts.value = []
}
</script>

<style scoped>
/* Right-hand sidebar that floats over content on wide screens */
.notification-sidebar {
  position: fixed;
  right: 0;
  top: 64px; /* below header */
  bottom: 0;
  width: 340px;
  padding: 16px 16px 24px;
  background: var(--bg-surface);
  border-left: 1px solid var(--border);
  box-shadow: var(--shadow-sm);
  overflow-y: auto;
  z-index: 15;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 24px;
}

.panel-header h2 {
  margin: 0;
  font-size: 20px;
}

.panel-subtitle {
  margin: 6px 0 0 0;
  color: var(--text-secondary);
  font-size: 14px;
}

/* Remove original grid since sidebar is single-column */

.section-heading {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 16px;
}

.section-helper {
  color: var(--text-muted);
  font-size: 13px;
}

/* Optional: hide watchlist UI in sidebar for a lean feed-only look */
.watchlist, .watchlist-form, .watchers { display: none; }

.form-error {
  color: #d14343;
  font-size: 13px;
  margin: -4px 0 12px 0;
}

.watchers {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 12px;
}

.watcher-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  padding: 14px 18px;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: var(--bg-muted);
}

.watcher-label {
  font-weight: 600;
  font-size: 14px;
}

.watcher-address {
  font-size: 12px;
  color: var(--text-muted);
}

.watcher-meta {
  display: flex;
  align-items: center;
  gap: 12px;
}

.status-chip {
  padding: 4px 8px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 600;
}

.status-idle {
  background: var(--bg-surface);
  color: var(--text-muted);
  border: 1px solid var(--border);
}

.status-pending {
  background: #fef3c7;
  color: #92400e;
}

.status-inprogress {
  background: #e0ecff;
  color: #1d4ed8;
}

.status-complete {
  background: #dcfce7;
  color: #166534;
}

.btn-ghost {
  border: none;
  background: transparent;
  color: var(--text-secondary);
  padding: 4px 8px;
}

.btn-ghost:hover {
  color: var(--text-primary);
  border: none;
  box-shadow: none;
}

.activity-feed {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 12px;
}

.activity-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 16px 18px;
}

.activity-title {
  font-weight: 600;
  font-size: 14px;
  margin-bottom: 4px;
}

.activity-meta {
  font-size: 12px;
  color: var(--text-muted);
}

.activity-pill {
  padding: 6px 12px;
  border-radius: 999px;
  border: 1px solid var(--border);
  font-size: 12px;
  color: var(--text-secondary);
}

.empty-hint {
  margin: 12px 0 0;
  color: var(--text-muted);
  font-size: 13px;
}

@media (max-width: 960px) {
  .notification-sidebar {
    display: none; /* hide on small screens to keep space */
  }
}
</style>
