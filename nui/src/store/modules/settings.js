// Settings Store Module
export default {
  namespaced: true,
  
  state: {
    theme: 'dark',
    notificationEnabled: true,
    soundEnabled: true,
    volume: 50,
    customSettings: {},
    isLoaded: false,
    availableThemes: ['light', 'dark', 'oled']
  },
  
  mutations: {
    setTheme(state, theme) {
      state.theme = theme
      // Apply theme to document root
      document.documentElement.setAttribute('data-theme', theme)
    },
    
    setNotificationEnabled(state, enabled) {
      state.notificationEnabled = enabled
    },
    
    setSoundEnabled(state, enabled) {
      state.soundEnabled = enabled
    },
    
    setVolume(state, volume) {
      state.volume = Math.max(0, Math.min(100, volume))
    },
    
    setCustomSetting(state, { key, value }) {
      state.customSettings[key] = value
    },
    
    setAllSettings(state, settings) {
      if (settings.theme) state.theme = settings.theme
      if (settings.notificationEnabled !== undefined) state.notificationEnabled = settings.notificationEnabled
      if (settings.soundEnabled !== undefined) state.soundEnabled = settings.soundEnabled
      if (settings.volume !== undefined) state.volume = settings.volume
      if (settings.customSettings) state.customSettings = { ...settings.customSettings }
      state.isLoaded = true
      
      // Apply theme
      document.documentElement.setAttribute('data-theme', state.theme)
    },
    
    setLoaded(state, loaded) {
      state.isLoaded = loaded
    },
    
    resetSettings(state) {
      state.theme = 'dark'
      state.notificationEnabled = true
      state.soundEnabled = true
      state.volume = 50
      state.customSettings = {}
    }
  },
  
  actions: {
    async loadSettings({ commit }) {
      try {
        const response = await fetch('https://phone/getSettings', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({})
        })
        
        const data = await response.json()
        
        if (data.success && data.settings) {
          commit('setAllSettings', data.settings)
          return { success: true }
        } else {
          console.error('Failed to load settings:', data.error)
          return { success: false, error: data.error }
        }
      } catch (error) {
        console.error('Error loading settings:', error)
        return { success: false, error: error.message }
      }
    },
    
    async updateSettings({ commit, state }, updates) {
      try {
        const response = await fetch('https://phone/updateSettings', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ settings: updates })
        })
        
        const data = await response.json()
        
        if (data.success) {
          // Apply updates locally
          Object.keys(updates).forEach(key => {
            if (key === 'theme') commit('setTheme', updates[key])
            else if (key === 'notificationEnabled') commit('setNotificationEnabled', updates[key])
            else if (key === 'soundEnabled') commit('setSoundEnabled', updates[key])
            else if (key === 'volume') commit('setVolume', updates[key])
            else if (key === 'customSettings') {
              Object.keys(updates[key]).forEach(customKey => {
                commit('setCustomSetting', { key: customKey, value: updates[key][customKey] })
              })
            }
          })
          return { success: true }
        } else {
          console.error('Failed to update settings:', data.error)
          return { success: false, error: data.error }
        }
      } catch (error) {
        console.error('Error updating settings:', error)
        return { success: false, error: error.message }
      }
    },
    
    async updateSetting({ commit }, { key, value }) {
      try {
        const response = await fetch('https://phone/updateSetting', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ key, value })
        })
        
        const data = await response.json()
        
        if (data.success) {
          // Apply update locally
          if (key === 'theme') commit('setTheme', value)
          else if (key === 'notificationEnabled') commit('setNotificationEnabled', value)
          else if (key === 'soundEnabled') commit('setSoundEnabled', value)
          else if (key === 'volume') commit('setVolume', value)
          
          return { success: true }
        } else {
          console.error('Failed to update setting:', data.error)
          return { success: false, error: data.error }
        }
      } catch (error) {
        console.error('Error updating setting:', error)
        return { success: false, error: error.message }
      }
    },
    
    changeTheme({ dispatch }, theme) {
      return dispatch('updateSetting', { key: 'theme', value: theme })
    },
    
    toggleNotifications({ state, dispatch }) {
      return dispatch('updateSetting', { key: 'notificationEnabled', value: !state.notificationEnabled })
    },
    
    toggleSound({ state, dispatch }) {
      return dispatch('updateSetting', { key: 'soundEnabled', value: !state.soundEnabled })
    },
    
    setVolumeLevel({ dispatch }, volume) {
      return dispatch('updateSetting', { key: 'volume', value: volume })
    }
  },
  
  getters: {
    currentTheme: state => state.theme,
    isNotificationEnabled: state => state.notificationEnabled,
    isSoundEnabled: state => state.soundEnabled,
    currentVolume: state => state.volume,
    isSettingsLoaded: state => state.isLoaded,
    getCustomSetting: state => key => state.customSettings[key],
    allSettings: state => ({
      theme: state.theme,
      notificationEnabled: state.notificationEnabled,
      soundEnabled: state.soundEnabled,
      volume: state.volume,
      customSettings: state.customSettings
    })
  }
}
