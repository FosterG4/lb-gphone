// NUI Main Entry Point
import { createApp } from 'vue'
import App from './App.vue'
import store from './store'
import i18n, { initI18n } from './i18n'
import * as notificationUtils from './utils/notifications'
import { createActionHandlers } from './constants/actionTypes'
import './assets/styles.css'
import './assets/themes.css'
import './assets/ios-styles.css'

// Initialize i18n and mount app
initI18n().then(() => {
  const app = createApp(App)
  
  app.use(store)
  app.use(i18n)
  
  app.mount('#app')
}).catch(error => {
  console.error('Failed to initialize i18n:', error)
})

// Create action handlers with dependencies
const actionHandlers = createActionHandlers(store, i18n, notificationUtils)

// Listen for NUI messages from Lua
window.addEventListener('message', (event) => {
    if (!event.data) return

    const { action, data } = event.data

    try {
        const handler = actionHandlers[action]
        if (handler) {
            handler(data)
        } else {
            console.warn(`Unknown NUI action: ${action}`)
        }
    } catch (error) {
        console.error(`Error handling NUI action '${action}':`, error)
        // Show user-friendly error notification
        store.dispatch('phone/showNotification', {
            type: 'error',
            title: 'System Error',
            message: 'An unexpected error occurred'
        })
    }
})

// Prevent right-click context menu
document.addEventListener('contextmenu', (e) => e.preventDefault())
