<template>
  <div id="app">
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
  display: flex;
  flex-direction: column;
  align-items: center;
}

.app-title {
  font-size: 3rem;
  color: var(--primary-color);
  margin-bottom: 0.5rem;
  text-align: center;
}

.app-subtitle {
  font-size: 1.2rem;
  color: var(--secondary-color);
  margin-bottom: 0.5rem; /* Adjusted for spacing */
  text-align: center;
}

.app-description {
  font-size: 0.8rem;
  color: gray;
  margin-bottom: 1rem; /* Adjusted for spacing */
  text-align: center;
}

.app-gif {
  width: auto; /* Adjust width as needed */
  height: auto; /* Adjust height as needed */
  max-width: 100%; /* Responsive */
  margin-bottom: 2rem; /* Space below the GIF */
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
    align-items: center;
  }

  .nav-link {
    margin: 5px 0;
  }
}
</style>