<template>
  <div id="app">
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