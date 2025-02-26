<template>
  <div id="app">
    <h1 class="app-title">Netero</h1>
    <h2 class="app-subtitle">A blockchain-powered voting system</h2>
    <nav class="app-nav">
      <router-link to="/register" class="nav-link">Register</router-link>
      <router-link to="/create-ballot" class="nav-link">Create Ballot</router-link>
      <router-link to="/vote" class="nav-link">Vote</router-link>
      <router-link to="/results" class="nav-link">Results</router-link>
    </nav>
    <router-view></router-view>
  </div>
</template>

<script>
export default {
  name: 'App'
}
</script>

<style>
:root {
  --primary-color: #3498db;
  --secondary-color: #2c3e50;
  --background-color: #f4f4f4;
  --text-color: #333;
}

body {
  margin: 0;
  padding: 0;
  font-family: 'Arial', sans-serif;
  background-color: var(--background-color);
  color: var(--text-color);
}

#app {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  align-content: center;
}

.app-title {
  font-size: 3rem;
  color: var(--primary-color);
  margin-bottom: 0.5rem;
  align-content: center;
}

.app-subtitle {
  font-size: 1.2rem;
  color: var(--secondary-color);
  margin-bottom: 2rem;
}

.app-nav {
  display: flex;
  justify-content: center;
  margin-bottom: 2rem;
}

.nav-link {
  color: var(--secondary-color);
  text-decoration: none;
  padding: 10px 20px;
  margin: 0 5px;
  border-radius: 5px;
  transition: background-color 0.3s, color 0.3s;
}

.nav-link:hover,
.nav-link.router-link-active {
  background-color: var(--primary-color);
  color: white;
}

@media (max-width: 768px) {
  .app-nav {
    flex-direction: column;
  }

  .nav-link {
    margin: 5px 0;
  }
}
</style>