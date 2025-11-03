import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import './styles/theme.css'

import OrgDashboard from './components/OrgDashboard.vue'
import MemberDashboard from './components/MemberDashboard.vue'
import Analytics from './components/Analytics.vue'
import VoterRegistration from './components/VoterRegistration.vue'
import BallotCreation from './components/BallotCreation.vue'
import VotingInterface from './components/VotingInterface.vue'
import ResultsDisplay from './components/ResultsDisplay.vue'

const routes = [
  { path: '/', redirect: '/member' },
  { path: '/member', component: MemberDashboard },
  { path: '/org', component: OrgDashboard },
  // direct access routes for deep links
  { path: '/register', component: VoterRegistration },
  { path: '/create-ballot', component: BallotCreation },
  { path: '/vote', component: VotingInterface },
  { path: '/results', component: ResultsDisplay }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

const app = createApp(App)
app.use(router)
app.mount('#app')