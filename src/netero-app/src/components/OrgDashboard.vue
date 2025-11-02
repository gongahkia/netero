<template>
  <div class="container stack-lg">
    <header class="stack">
      <h1>Organizer Dashboard</h1>
      <p class="section-title">Tools for creating and managing ballots, registering members, and viewing outcomes.</p>
      <div class="card stack" style="padding:16px;">
        <div class="grid-2">
          <div class="stack">
            <span class="section-title">Quick Actions</span>
            <div class="stack">
              <router-link class="btn btn-primary" to="/create-ballot">Create New Ballot</router-link>
              <router-link class="btn" to="/register">Register Member Address</router-link>
              <router-link class="btn" to="/results">View Current Results</router-link>
            </div>
          </div>
          <div class="stack">
            <span class="section-title">Network Status</span>
            <div class="card stack" style="padding:16px;">
              <div>RPC: http://localhost:8545</div>
              <div>Chain Id: 1337 (Local)</div>
              <div>Frontend: http://localhost:8080</div>
            </div>
          </div>
        </div>
      </div>
    </header>

    <section class="stack-lg">
      <div class="stack">
        <span class="section-title">Contract Deployment</span>
        <div class="card" style="padding:16px;">
          <BallotCreation />
        </div>
      </div>

      <div class="stack">
        <span class="section-title">Member Registration</span>
        <div class="card" style="padding:16px;">
          <VoterRegistration />
        </div>
      </div>

      <div class="stack">
        <span class="section-title">Live Results</span>
        <div class="card" style="padding:16px;">
          <ResultsDisplay />
        </div>
      </div>
    </section>
  </div>
</template>

<script>
import BallotCreation from './BallotCreation.vue'
import VoterRegistration from './VoterRegistration.vue'
import ResultsDisplay from './ResultsDisplay.vue'

export default {
  name: 'OrgDashboard',
  components: { BallotCreation, VoterRegistration, ResultsDisplay }
}
</script>

<style scoped>
h1 { margin: 0; font-size: 28px; }
</style>
