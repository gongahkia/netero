<template>
  <div class="modal-overlay" v-if="show">
    <div class="modal-card">
      <div class="modal-header">
        <h1>// NETERO_VOTING_SYSTEM</h1>
        <p class="subtitle">Select your role to continue</p>
      </div>

      <div class="role-selection">
        <button class="role-btn" @click="selectRole('organization')">
          <div class="role-icon">[ ORG ]</div>
          <h2>Organization</h2>
          <p class="role-description">
            Create ballots, deploy voting contracts,
            register members, and manage elections
          </p>
          <div class="role-action">[ SELECT_ORGANIZER ]</div>
        </button>

        <button class="role-btn" @click="selectRole('member')">
          <div class="role-icon">[ MEM ]</div>
          <h2>Member</h2>
          <p class="role-description">
            Connect to voting contracts, cast votes
            on proposals, and view election results
          </p>
          <div class="role-action">[ SELECT_MEMBER ]</div>
        </button>
      </div>

      <div class="modal-footer">
        <p class="info-text">
          // This selection will reset when you refresh the page
        </p>
      </div>
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
  background: rgba(0, 0, 0, 0.95);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 24px;
}

.modal-card {
  background: var(--bg-surface);
  border: 2px solid var(--text-primary);
  max-width: 900px;
  width: 100%;
  padding: 48px 32px;
  font-family: 'JetBrains Mono', monospace;
}

.modal-header {
  text-align: center;
  margin-bottom: 48px;
}

.modal-header h1 {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  margin: 0 0 12px 0;
  letter-spacing: 1px;
}

.subtitle {
  font-size: 14px;
  color: var(--text-secondary);
  margin: 0;
}

.role-selection {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  margin-bottom: 32px;
}

.role-btn {
  background: var(--bg-surface);
  border: 2px solid var(--border);
  padding: 32px 24px;
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: center;
  font-family: 'JetBrains Mono', monospace;
}

.role-btn:hover {
  border-color: var(--text-primary);
  background: var(--text-primary);
  color: var(--bg-surface);
  transform: translateY(-2px);
}

.role-btn:hover .role-icon,
.role-btn:hover h2,
.role-btn:hover .role-description,
.role-btn:hover .role-action {
  color: var(--bg-surface);
}

.role-btn:active {
  transform: translateY(0);
}

.role-icon {
  font-size: 24px;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 16px;
  letter-spacing: 2px;
}

.role-btn h2 {
  font-size: 20px;
  font-weight: 600;
  color: var(--text-primary);
  margin: 0 0 12px 0;
}

.role-description {
  font-size: 13px;
  line-height: 1.6;
  color: var(--text-secondary);
  margin: 0 0 24px 0;
  min-height: 60px;
}

.role-action {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  letter-spacing: 1px;
}

.modal-footer {
  text-align: center;
  padding-top: 24px;
  border-top: 1px solid var(--border);
}

.info-text {
  font-size: 12px;
  color: var(--text-muted);
  margin: 0;
  font-style: italic;
}

@media (max-width: 768px) {
  .role-selection {
    grid-template-columns: 1fr;
  }

  .modal-card {
    padding: 32px 24px;
  }

  .modal-header h1 {
    font-size: 22px;
  }
}
</style>
