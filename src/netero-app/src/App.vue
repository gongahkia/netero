<template>
  <div id="app">
<<<<<<< HEAD
    <RoleSelectionModal
      :show="!userRole"
      @role-selected="handleRoleSelection"
    />

    <header class="site-header" v-if="userRole">
      <div class="container header-inner">
        <div class="brand">Netero</div>
        <div class="role-indicator">
          <span class="role-label">// {{ userRole === 'organization' ? 'ORGANIZER_MODE' : 'MEMBER_MODE' }}</span>
        </div>
        <nav class="nav">
          <router-link v-if="userRole === 'member'" to="/member" class="nav-link">Dashboard</router-link>
          <router-link v-if="userRole === 'organization'" to="/org" class="nav-link">Dashboard</router-link>
        </nav>
      </div>
    </header>

    <main class="container" v-if="userRole">
      <router-view></router-view>
    </main>

    <footer class="site-footer" v-if="userRole">
      <div class="container footer-inner">
        <span class="foot-note">Local-only demo • Chain: 1337 • RPC: http://localhost:8545</span>
      </div>
    </footer>
=======
    <h1 class="app-title">Netero</h1>
    <h2 class="app-subtitle">A blockchain-powered voting system</h2>
    <h4 class="app-description">Made with ❤️ by <a href="https://github.com/gongahkia">Gabriel Ong</a></h4>
    <img src="@/assets/netero.gif" alt="Netero GIF" class="app-gif" />
    <nav class="app-nav">
      <router-link to="/register" class="nav-link">Register</router-link>
      <router-link to="/create-ballot" class="nav-link">Create Ballot</router-link>
      <router-link to="/vote" class="nav-link">Vote</router-link>
      <router-link to="/results" class="nav-link">Results</router-link>
      <router-link to="/analytics" class="nav-link">Analytics</router-link>
    </nav>
    <router-view></router-view>
>>>>>>> 4101ed0d25cc66c54228e09b78b052e0c78bf190
  </div>
</template>

<script>
import RoleSelectionModal from './components/RoleSelectionModal.vue';

export default {
  name: 'App',
  components: {
    RoleSelectionModal
  },
  data() {
    return {
      userRole: null // 'member' | 'organization' | null
    }
  },
  provide() {
    return {
      userRole: () => this.userRole
    }
  },
  methods: {
    handleRoleSelection(role) {
      this.userRole = role;
      // Navigate to appropriate dashboard
      if (role === 'member') {
        this.$router.push('/member');
      } else if (role === 'organization') {
        this.$router.push('/org');
      }
    }
  }
}
</script>

<style>
.site-header {
  position: sticky; top: 0; z-index: 40;
  background: var(--bg-surface);
  border-bottom: 1px solid var(--border);
}
.header-inner { display:flex; align-items:center; justify-content:space-between; padding: 16px 24px; }
.brand { font-weight: 700; font-size: 18px; letter-spacing: .08em; }
.role-indicator { flex: 1; display: flex; justify-content: center; }
.role-label { font-size: 12px; color: var(--text-muted); font-weight: 600; letter-spacing: 1px; }
.nav { display:flex; align-items:center; gap: 12px; }
.nav-link { text-decoration:none; color: var(--text-secondary); padding: 8px 12px; border-radius: var(--radius-sm); }
.nav-link.router-link-active { color: var(--text-primary); background: var(--bg-muted); }
.nav-sep { width:1px; height:20px; background: var(--border); margin: 0 8px; }

.site-footer { margin-top: 40px; border-top: 1px solid var(--border); background: var(--bg-surface); }
.footer-inner { padding: 16px 24px; display:flex; align-items:center; justify-content:center; }
.foot-note { color: var(--text-muted); font-size: 12px; }
</style>