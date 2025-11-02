<template>
  <div id="app">
    <header class="app-header">
      <div class="header-content">
        <div class="logo-section">
          <span class="logo-bracket">[</span>
          <span class="logo-text">NETERO</span>
          <span class="logo-bracket">]</span>
        </div>
        <div class="subtitle">BLOCKCHAIN VOTING SYSTEM</div>
      </div>
    </header>
    
    <nav class="app-nav">
      <router-link to="/register" class="nav-link">[ REGISTER ]</router-link>
      <router-link to="/create-ballot" class="nav-link">[ CREATE ]</router-link>
      <router-link to="/vote" class="nav-link">[ VOTE ]</router-link>
      <router-link to="/results" class="nav-link">[ RESULTS ]</router-link>
    </nav>
    
    <main class="app-main">
      <router-view></router-view>
    </main>
    
    <footer class="app-footer">
      <span>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>
      <div class="footer-text">POWERED BY ETHEREUM • TRUFFLE • VUE.JS</div>
    </footer>
  </div>
</template>

<script>
export default {
  name: 'App'
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

:root {
  --bg-primary: #0a0a0a;
  --bg-secondary: #1a1a1a;
  --text-primary: #00ff00;
  --text-secondary: #00cc00;
  --text-muted: #008800;
  --border-color: #00ff00;
  --accent: #00ff00;
}

body {
  margin: 0;
  padding: 0;
  font-family: 'Courier New', 'Consolas', 'Monaco', monospace;
  background-color: var(--bg-primary);
  color: var(--text-primary);
  line-height: 1.6;
  overflow-x: hidden;
}

#app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* Header */
.app-header {
  background-color: var(--bg-secondary);
  border-bottom: 2px solid var(--border-color);
  padding: 2rem 1rem;
  text-align: center;
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
}

.logo-section {
  font-size: 3rem;
  font-weight: bold;
  letter-spacing: 0.5rem;
  margin-bottom: 0.5rem;
  text-shadow: 0 0 10px var(--accent);
}

.logo-bracket {
  color: var(--text-muted);
}

.logo-text {
  color: var(--text-primary);
}

.subtitle {
  font-size: 0.9rem;
  letter-spacing: 0.3rem;
  color: var(--text-secondary);
  opacity: 0.8;
}

/* Navigation */
.app-nav {
  background-color: var(--bg-secondary);
  border-bottom: 1px solid var(--border-color);
  padding: 1rem;
  display: flex;
  justify-content: center;
  gap: 2rem;
  flex-wrap: wrap;
}

.nav-link {
  color: var(--text-secondary);
  text-decoration: none;
  padding: 0.5rem 1rem;
  font-size: 0.9rem;
  font-weight: bold;
  letter-spacing: 0.1rem;
  transition: all 0.3s ease;
  border: 1px solid transparent;
}

.nav-link:hover {
  color: var(--text-primary);
  border: 1px solid var(--border-color);
  background-color: rgba(0, 255, 0, 0.05);
  text-shadow: 0 0 5px var(--accent);
}

.nav-link.router-link-active {
  color: var(--text-primary);
  border: 1px solid var(--border-color);
  background-color: rgba(0, 255, 0, 0.1);
  text-shadow: 0 0 8px var(--accent);
}

/* Main Content */
.app-main {
  flex: 1;
  max-width: 1200px;
  width: 100%;
  margin: 0 auto;
  padding: 2rem 1rem;
}

/* Footer */
.app-footer {
  background-color: var(--bg-secondary);
  border-top: 2px solid var(--border-color);
  padding: 1.5rem 1rem;
  text-align: center;
  font-size: 0.75rem;
  color: var(--text-muted);
  letter-spacing: 0.1rem;
}

.app-footer span {
  display: block;
  margin-bottom: 0.5rem;
  overflow: hidden;
  text-overflow: ellipsis;
}

.footer-text {
  opacity: 0.7;
}

/* Responsive */
@media (max-width: 768px) {
  .logo-section {
    font-size: 2rem;
    letter-spacing: 0.3rem;
  }
  
  .subtitle {
    font-size: 0.7rem;
    letter-spacing: 0.2rem;
  }
  
  .app-nav {
    gap: 1rem;
  }
  
  .nav-link {
    font-size: 0.8rem;
    padding: 0.4rem 0.8rem;
  }
  }

  .nav-link {
    margin: 5px 0;
  }
}
</style>