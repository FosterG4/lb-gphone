// NUI Main Entry Point
import { createApp } from 'vue'
import App from './App.vue'
import store from './store'
import i18n, { initI18n } from './i18n'
import { showShareDeclinedNotification, showShareErrorNotification, showBroadcastContactAddedNotification } from './utils/notifications'
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

// Listen for NUI messages from Lua
window.addEventListener('message', (event) => {
    if (!event.data) return

    const { action, data } = event.data

    try {
        if (action === 'setVisible') {
            store.commit('phone/setVisible', data.visible)
        } else if (action === 'showNotification') {
            store.dispatch('phone/showNotification', data)
        } else if (action === 'setPhoneNumber') {
            store.commit('phone/setPhoneNumber', data.phoneNumber)
        } else if (action === 'loadPhoneData') {
            // Load all phone data on player login
            if (data.contacts) store.commit('contacts/setList', data.contacts)
            if (data.messages) store.commit('messages/setConversations', data.messages)
            if (data.callHistory) store.commit('calls/setHistory', data.callHistory)
        } else if (action === 'receiveMessage') {
            // Handle incoming message
            store.dispatch('messages/receiveMessage', data)
        } else if (action === 'incomingCall') {
            // Handle incoming call
            store.dispatch('calls/receiveIncomingCall', data)
            store.commit('phone/setCurrentApp', 'call-screen')
        } else if (action === 'callAccepted') {
            // Handle call accepted
            store.dispatch('calls/callAccepted')
        } else if (action === 'callEnded') {
            // Handle call ended
            store.dispatch('calls/callEnded')
            store.commit('phone/setCurrentApp', null)
        } else if (action === 'callBusy') {
            // Handle call busy
            store.dispatch('calls/callEnded')
            store.commit('phone/setCurrentApp', null)
            store.dispatch('phone/showNotification', {
                type: 'error',
                title: 'Call Failed',
                message: 'The person you are calling is busy'
            })
        } else if (action === 'callTimeout') {
            // Handle call timeout
            store.dispatch('calls/callEnded')
            store.commit('phone/setCurrentApp', null)
            store.dispatch('phone/showNotification', {
                type: 'error',
                title: 'Call Failed',
                message: 'Call timed out'
            })
        } else if (action === 'updateCallState') {
            // Update call state
            store.commit('calls/setState', data.state)
        } else if (action === 'switchToCallScreen') {
            // Switch to call screen
            store.commit('phone/setCurrentApp', 'call-screen')
        } else if (action === 'newTweet') {
            // Handle new tweet broadcast
            store.commit('apps/addTweetToFeed', data)
        } else if (action === 'tweetLikeUpdate') {
            // Handle tweet like update broadcast
            store.commit('apps/updateTweetLikes', {
                tweetId: data.tweetId,
                likes: data.likes,
                isLiked: false // We don't know if current user liked it from broadcast
            })
        } else if (action === 'notification') {
            // Generic notification handler
            store.dispatch('phone/showNotification', data)
        } else if (action === 'setTheme') {
            // Handle theme change from client
            store.commit('settings/setTheme', data.theme || data)
        } else if (action === 'setVolume') {
            // Handle volume change from client
            store.commit('settings/setVolume', data.volume || data)
        } else if (action === 'setNotificationEnabled') {
            // Handle notification toggle from client
            store.commit('settings/setNotificationEnabled', data.enabled !== undefined ? data.enabled : data)
        } else if (action === 'setSoundEnabled') {
            // Handle sound toggle from client
            store.commit('settings/setSoundEnabled', data.enabled !== undefined ? data.enabled : data)
        } else if (action === 'setCustomSettings') {
            // Handle custom settings from client
            if (data.settings) {
                Object.keys(data.settings).forEach(key => {
                    store.commit('settings/setCustomSetting', { key, value: data.settings[key] })
                })
            }
        } else if (action === 'settingsLoaded') {
            // Handle settings loaded from server
            if (data.settings) {
                store.commit('settings/setAllSettings', data.settings)
                // Load locale from settings
                if (data.settings.locale) {
                    import('./i18n').then(({ loadLocaleFromSettings }) => {
                        loadLocaleFromSettings(data.settings)
                    })
                }
            }
        } else if (action === 'settingsUpdated') {
            // Handle settings updated from server
            if (data.settings) {
                store.commit('settings/setAllSettings', data.settings)
                // Update locale if changed
                if (data.settings.locale) {
                    import('./i18n').then(({ loadLocaleFromSettings }) => {
                        loadLocaleFromSettings(data.settings)
                    })
                }
            }
        } else if (action === 'settingsError') {
            // Handle settings error
            store.dispatch('phone/showNotification', {
                type: 'error',
                title: 'Settings Error',
                message: data.error || 'Failed to update settings'
            })
        } else if (action === 'showShareDeclinedNotification') {
            // Handle share declined notification
            showShareDeclinedNotification(data.contactName, i18n.global)
        } else if (action === 'showShareErrorNotification') {
            // Handle share error notification
            showShareErrorNotification(data.errorMessage, null, i18n.global)
        } else if (action === 'showBroadcastContactAddedNotification') {
            // Handle broadcast contact added notification
            showBroadcastContactAddedNotification(data.addedBy, i18n.global)
        }
    } catch (error) {
        console.error('Error handling NUI message:', error)
    }
})

// Prevent right-click context menu
document.addEventListener('contextmenu', (e) => e.preventDefault())
