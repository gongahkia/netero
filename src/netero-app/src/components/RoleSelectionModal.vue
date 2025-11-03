<template>
  <div v-if="show" class="modal-overlay">
    <div class="modal-card">
      <div class="modal-header">
        <h1>Welcome to Netero</h1>
        <p>Choose how you'd like to participate. You can switch any time.</p>
      </div>

      <div class="role-grid">
        <button type="button" class="role-card" @click="selectRole('organization')">
          <div class="role-heading">
            <span class="role-title">Organizer</span>
            <span class="role-chip">Manage ballots</span>
          </div>
          <p>
            Publish proposals, configure timelines, coordinate voter access, and follow results in real time.
          </p>
        </button>

        <button type="button" class="role-card" @click="selectRole('member')">
          <div class="role-heading">
            <span class="role-title">Member</span>
            <span class="role-chip">Cast votes</span>
          </div>
          <p>
            Connect your wallet, review proposals assigned to you, and vote with confidence on each decision.
          </p>
        </button>
      </div>

      <footer class="modal-footer">
        <small>Switch roles later from the navigation bar.</small>
      </footer>
    </div>
  </div>
</template>

<script>
export default {
  name: 'RoleSelectionModal',
  props: {
    show: {
      type: Boolean,
      default: true
    }
  },
  methods: {
    selectRole(role) {
      this.$emit('role-selected', role);
    }
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(17, 24, 39, 0.84);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 24px;
}

.modal-card {
  background: var(--bg-surface);
  border-radius: 16px;
  max-width: 720px;
  width: 100%;
  padding: 48px 40px;
  box-shadow: 0 24px 64px rgba(17, 24, 39, 0.25);
}

.modal-header {
  text-align: center;
  margin-bottom: 48px;
}

.modal-header h1 {
  font-size: 32px;
  margin: 0 0 12px 0;
  font-weight: 700;
  letter-spacing: 0.03em;
}

.modal-header p {
  margin: 0;
  color: var(--text-secondary);
  font-size: 14px;
}

.role-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  margin-bottom: 32px;
}


.role-card {
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 28px;
  text-align: left;
  background: var(--bg-muted);
  transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
  cursor: pointer;
}

.role-card p {
  margin: 12px 0 0 0;
  color: var(--text-secondary);
  line-height: 1.6;
  font-size: 14px;
}

.role-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-md);
  border-color: var(--border-strong);
  background: var(--bg-surface);
}

.role-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.role-title {
  font-size: 18px;
  font-weight: 600;
}

.role-chip {
  font-size: 12px;
  padding: 4px 10px;
  border-radius: 999px;
  background: var(--bg-surface);
  border: 1px solid var(--border);
}

.modal-footer {
  text-align: center;
  color: var(--text-muted);
  font-size: 13px;
}

@media (max-width: 768px) {
  .role-grid {
    grid-template-columns: 1fr;
  }

  .modal-card {
    padding: 32px 28px;
  }
}
</style>
