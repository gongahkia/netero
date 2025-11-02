import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import './styles/theme.css'

import Register from './components/VoterRegistration.vue'
import CreateBallot from './components/BallotCreation.vue'
import Vote from './components/VotingInterface.vue'
import Results from './components/ResultsDisplay.vue'
import OrgDashboard from './components/OrgDashboard.vue'
import MemberDashboard from './components/MemberDashboard.vue'

const routes = [
  { path: '/', redirect: '/member' },
  { path: '/member', component: MemberDashboard },
  { path: '/org', component: OrgDashboard },
  // legacy/direct routes
  { path: '/register', component: Register },
  { path: '/create-ballot', component: CreateBallot },
  { path: '/vote', component: Vote },
  { path: '/results', component: Results }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

const app = createApp(App)
app.use(router)
app.mount('#app')