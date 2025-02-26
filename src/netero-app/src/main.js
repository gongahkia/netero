import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'

import Register from './components/Register.vue'
import CreateBallot from './components/CreateBallot.vue'
import Vote from './components/Vote.vue'
import Results from './components/Results.vue'

const routes = [
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