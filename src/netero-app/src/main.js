import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'

import Register from './components/VoterRegistration.vue'
import CreateBallot from './components/BallotCreation.vue'
import Vote from './components/VotingInterface.vue'
import Results from './components/ResultsDisplay.vue'
import Analytics from './components/Analytics.vue'

const routes = [
  { path: '/register', component: Register },
  { path: '/create-ballot', component: CreateBallot },
  { path: '/vote', component: Vote },
  { path: '/results', component: Results },
  { path: '/analytics', component: Analytics }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

const app = createApp(App)
app.use(router)
app.mount('#app')