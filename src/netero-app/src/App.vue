<template>
  <div id="app">
    <RoleSelectionModal :show="!userRole" @role-selected="handleRoleSelection" />

    <header v-if="userRole" class="app-header">
      <div class="container header-bar">
        <div class="brand-group">
          <span class="brand">Netero</span>
          <span class="tagline">Trusted decisions, transparently tallied.</span>
        </div>
        <nav class="nav-links">
          <router-link to="/member" class="nav-link">Member</router-link>
          <router-link to="/org" class="nav-link">Organizer</router-link>
          <router-link to="/analytics" class="nav-link">Analytics</router-link>
        </nav>
        <div class="role-controls">
          <span class="role-chip">{{ roleLabel }}</span>
          <button class="btn btn-ghost" type="button" @click="switchRole">Switch role</button>
        </div>
      </div>
    </header>

    <main v-if="userRole" class="app-main">
      <router-view :key="$route.fullPath"></router-view>
    </main>

    <footer v-if="userRole" class="app-footer">
      <div class="container footer-row">
        <span>Local demo · Chain 1337 · RPC http://localhost:8545</span>
        <a
          class="footer-link"
          href="https://github.com/gongahkia/netero"
          target="_blank"
          rel="noreferrer"
        >
          View project
        </a>
      </div>
    </footer>
  </div>
</template>

<script>
import RoleSelectionModal from './components/RoleSelectionModal.vue'

const ROLE_KEY = 'netero.role'

export default {
  name: 'App',
  components: { RoleSelectionModal },
  data() {
    return {
      userRole: null,
    }
  },
  computed: {
    roleLabel() {
      if (this.userRole === 'organization') return 'Organizer workspace'
      if (this.userRole === 'member') return 'Member workspace'
      return 'Select role'
    },
  },
  provide() {
    return {
      userRole: () => this.userRole,
    }
  },
  created() {
    try {
      const stored = localStorage.getItem(ROLE_KEY)
      if (stored === 'member' || stored === 'organization') {
        this.userRole = stored
        this.navigateForRole(stored)
      }
    } catch (e) {
      this.userRole = null
    }
  },
  methods: {
    handleRoleSelection(role) {
      this.userRole = role
      try {
        localStorage.setItem(ROLE_KEY, role)
      } catch (e) {
        // ignore persistence errors
      }
      this.navigateForRole(role)
    },
    switchRole() {
      this.userRole = null
      try {
        localStorage.removeItem(ROLE_KEY)
      } catch (e) {
        // ignore persistence errors
      }
    },
    navigateForRole(role) {
      if (role === 'organization') {
        if (this.$route.path !== '/org') this.$router.push('/org')
      } else if (role === 'member') {
        if (this.$route.path !== '/member') this.$router.push('/member')
      }
    },
  },
}
</script>

<style>
.app-header {
  position: sticky;
  top: 0;
  z-index: 20;
  background: var(--bg-surface);
  border-bottom: 1px solid var(--border);
  box-shadow: var(--shadow-sm);
}

.header-bar {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 24px;
  padding: 18px 24px;
}

.brand-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.brand {
  font-weight: 700;
  font-size: 20px;
  letter-spacing: 0.08em;
}

.tagline {
  font-size: 12px;
  color: var(--text-muted);
}

.nav-links {
  display: flex;
  justify-content: center;
  gap: 16px;
}

.nav-link {
  color: var(--text-secondary);
  text-decoration: none;
  font-size: 14px;
  padding: 6px 10px;
  border-radius: var(--radius-sm);
}

.nav-link.router-link-active {
  background: var(--bg-muted);
  color: var(--text-primary);
  font-weight: 600;
}

.role-controls {
  display: flex;
  align-items: center;
  gap: 12px;
}

.role-chip {
  padding: 6px 12px;
  border-radius: 999px;
  background: var(--bg-muted);
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.03em;
}

.btn-ghost {
  border: none;
  background: transparent;
  color: var(--text-secondary);
  font-family: var(--font-mono);
  padding: 6px 10px;
}

.btn-ghost:hover {
  color: var(--text-primary);
  box-shadow: none;
}

.app-main {
  padding: 32px 0 48px;
}

.app-footer {
  border-top: 1px solid var(--border);
  background: var(--bg-surface);
}

.footer-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  padding: 18px 24px;
  color: var(--text-muted);
  font-size: 13px;
}

.footer-link {
  color: var(--text-secondary);
  text-decoration: none;
}

.footer-link:hover {
  color: var(--text-primary);
}

@media (max-width: 900px) {
  .header-bar {
    grid-template-columns: 1fr;
    gap: 16px;
  }
  .nav-links {
    justify-content: flex-start;
  }
  .role-controls {
    justify-content: flex-start;
  }
  .footer-row {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>