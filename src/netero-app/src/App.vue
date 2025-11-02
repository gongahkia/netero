<template>
  <div id="app">
    <header class="site-header">
      <div class="container header-inner">
        <div class="brand">Netero</div>
        <nav class="nav">
          <router-link to="/member" class="nav-link">Member</router-link>
          <router-link to="/org" class="nav-link">Organizer</router-link>
          <div class="nav-sep"></div>
          <router-link to="/vote" class="nav-link">Vote (direct)</router-link>
          <router-link to="/results" class="nav-link">Results (direct)</router-link>
        </nav>
      </div>
    </header>

    <main class="container">
      <router-view></router-view>
    </main>

    <footer class="site-footer">
      <div class="container footer-inner">
        <span class="foot-note">Local-only demo • Chain: 1337 • RPC: http://localhost:8545</span>
      </div>
    </footer>
  </div>
</template>

<script>
export default {
  name: 'App'
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
.nav { display:flex; align-items:center; gap: 12px; }
.nav-link { text-decoration:none; color: var(--text-secondary); padding: 8px 12px; border-radius: var(--radius-sm); }
.nav-link.router-link-active { color: var(--text-primary); background: var(--bg-muted); }
.nav-sep { width:1px; height:20px; background: var(--border); margin: 0 8px; }

.site-footer { margin-top: 40px; border-top: 1px solid var(--border); background: var(--bg-surface); }
.footer-inner { padding: 16px 24px; display:flex; align-items:center; justify-content:center; }
.foot-note { color: var(--text-muted); font-size: 12px; }
</style>