<template>
  <div id="app">
    <h1>Netero</h1>
    <h2>A blockchain-powered voting system</h2>
    <nav>
      <router-link to="/register">Register</router-link> |
      <router-link to="/create-ballot">Create Ballot</router-link> |
      <router-link to="/vote">Vote</router-link> |
      <router-link to="/results">Results</router-link>
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
#app {
  font-family: Arial, sans-serif;
  text-align: center;
  margin-top: 60px;
}
</style>