// Phone Store Module
export default {
  namespaced: true,
  
  state: {
    isVisible: false,
    phoneNumber: '',
    currentApp: null,
    notifications: [],
    notificationQueue: [],
    maxNotifications: 3,
    notificationTimers: {}
  },
  
  mutations: {
    setVisible(state, visible) {
      state.isVisible = visible
    },
    
    setPhoneNumber(state, phoneNumber) {
      state.phoneNumber = phoneNumber
    },
    
    setCurrentApp(state, app) {
      state.currentApp = app
    },
    
    addNotification(state, notification) {
      // Add to queue if max notifications reached
      if (state.notifications.length >= state.maxNotifications) {
        state.notificationQueue.push(notification)
      } else {
        state.notifications.push(notification)
      }
    },
    
    removeNotification(state, id) {
      state.notifications = state.notifications.filter(n => n.id !== id)
      
      // Clear timer if exists
      if (state.notificationTimers[id]) {
        clearTimeout(state.notificationTimers[id])
        delete state.notificationTimers[id]
      }
      
      // Process queue if there are pending notifications
      if (state.notificationQueue.length > 0) {
        const nextNotification = state.notificationQueue.shift()
        state.notifications.push(nextNotification)
      }
    },
    
    setNotificationTimer(state, { id, timer }) {
      state.notificationTimers[id] = timer
    },
    
    clearAllNotifications(state) {
      // Clear all timers
      Object.values(state.notificationTimers).forEach(timer => clearTimeout(timer))
      state.notificationTimers = {}
      state.notifications = []
      state.notificationQueue = []
    }
  },
  
  actions: {
    showNotification({ commit, state }, notification) {
      // Generate unique ID
      const notificationWithId = {
        id: Date.now() + Math.random(),
        type: notification.type || 'default',
        title: notification.title || 'Notification',
        message: notification.message || '',
        duration: notification.duration || 5000,
        sound: notification.sound !== false, // Default to true unless explicitly false
        ...notification
      }
      
      commit('addNotification', notificationWithId)
      
      // Play notification sound if enabled
      if (notificationWithId.sound) {
        playNotificationSound(notificationWithId.type)
      }
      
      // Auto-dismiss after duration
      const timer = setTimeout(() => {
        commit('removeNotification', notificationWithId.id)
      }, notificationWithId.duration)
      
      commit('setNotificationTimer', { id: notificationWithId.id, timer })
      
      return notificationWithId.id
    },
    
    dismissNotification({ commit }, id) {
      commit('removeNotification', id)
    },
    
    clearAll({ commit }) {
      commit('clearAllNotifications')
    }
  }
}

// Notification sound helper
function playNotificationSound(type) {
  try {
    // Create audio context if not exists
    if (!window.audioContext) {
      window.audioContext = new (window.AudioContext || window.webkitAudioContext)()
    }
    
    const ctx = window.audioContext
    const oscillator = ctx.createOscillator()
    const gainNode = ctx.createGain()
    
    oscillator.connect(gainNode)
    gainNode.connect(ctx.destination)
    
    // Different sounds for different notification types
    switch (type) {
      case 'message':
        oscillator.frequency.value = 800
        gainNode.gain.value = 0.1
        oscillator.start()
        oscillator.stop(ctx.currentTime + 0.1)
        break
      case 'call':
        oscillator.frequency.value = 600
        gainNode.gain.value = 0.15
        oscillator.start()
        oscillator.stop(ctx.currentTime + 0.2)
        setTimeout(() => {
          const osc2 = ctx.createOscillator()
          const gain2 = ctx.createGain()
          osc2.connect(gain2)
          gain2.connect(ctx.destination)
          osc2.frequency.value = 600
          gain2.gain.value = 0.15
          osc2.start()
          osc2.stop(ctx.currentTime + 0.2)
        }, 300)
        break
      case 'error':
        oscillator.frequency.value = 400
        gainNode.gain.value = 0.12
        oscillator.start()
        oscillator.stop(ctx.currentTime + 0.15)
        break
      case 'success':
        oscillator.frequency.value = 1000
        gainNode.gain.value = 0.1
        oscillator.start()
        oscillator.stop(ctx.currentTime + 0.08)
        setTimeout(() => {
          const osc2 = ctx.createOscillator()
          const gain2 = ctx.createGain()
          osc2.connect(gain2)
          gain2.connect(ctx.destination)
          osc2.frequency.value = 1200
          gain2.gain.value = 0.1
          osc2.start()
          osc2.stop(ctx.currentTime + 0.08)
        }, 100)
        break
      default:
        oscillator.frequency.value = 700
        gainNode.gain.value = 0.1
        oscillator.start()
        oscillator.stop(ctx.currentTime + 0.1)
    }
  } catch (error) {
    console.warn('Could not play notification sound:', error)
  }
}
