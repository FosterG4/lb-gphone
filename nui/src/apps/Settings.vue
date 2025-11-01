<template>
  <div class="settings-app">
    <div class="settings-content">
      <!-- Notifications Section -->
      <div class="settings-section">
        <div class="section-header">
          <h3>{{ $t('settings.notifications.title') }}</h3>
        </div>
        
        <div class="settings-list">
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                  <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                </svg>
              </div>
              <div class="setting-text">
                <div class="setting-label">{{ $t('settings.notifications.enable') }}</div>
                <div class="setting-description">{{ $t('settings.notifications.enableDescription') }}</div>
              </div>
            </div>
            <label class="toggle-switch">
              <input 
                type="checkbox" 
                :checked="notificationEnabled"
                @change="toggleNotifications"
              >
              <span class="toggle-slider"></span>
            </label>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M9 18V5l12-2v13"/>
                  <circle cx="6" cy="18" r="3"/>
                  <circle cx="18" cy="16" r="3"/>
                </svg>
              </div>
              <div class="setting-text">
                <div class="setting-label">{{ $t('settings.notifications.sounds') }}</div>
                <div class="setting-description">{{ $t('settings.notifications.soundsDescription') }}</div>
              </div>
            </div>
            <label class="toggle-switch">
              <input 
                type="checkbox" 
                :checked="soundEnabled"
                @change="toggleSound"
              >
              <span class="toggle-slider"></span>
            </label>
          </div>
        </div>
      </div>
      
      <!-- Sound Section -->
      <div class="settings-section">
        <div class="section-header">
          <h3>{{ $t('settings.sound.title') }}</h3>
        </div>
        
        <div class="settings-list">
          <div class="setting-item volume-setting">
            <div class="setting-info">
              <div class="setting-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"/>
                  <path d="M15.54 8.46a5 5 0 0 1 0 7.07"/>
                  <path d="M19.07 4.93a10 10 0 0 1 0 14.14"/>
                </svg>
              </div>
              <div class="setting-text">
                <div class="setting-label">{{ $t('settings.sound.volume') }}</div>
                <div class="setting-description">{{ volume }}%</div>
              </div>
            </div>
            <div class="volume-control">
              <input 
                type="range" 
                min="0" 
                max="100" 
                :value="volume"
                @input="updateVolume"
                class="volume-slider"
              >
            </div>
          </div>
        </div>
      </div>
      
      <!-- Theme Section -->
      <div class="settings-section">
        <div class="section-header">
          <h3>{{ $t('settings.appearance.title') }}</h3>
        </div>
        
        <div class="settings-list">
          <div class="setting-item theme-setting">
            <div class="setting-info full-width">
              <div class="setting-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="5"/>
                  <line x1="12" y1="1" x2="12" y2="3"/>
                  <line x1="12" y1="21" x2="12" y2="23"/>
                  <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
                  <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
                  <line x1="1" y1="12" x2="3" y2="12"/>
                  <line x1="21" y1="12" x2="23" y2="12"/>
                  <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
                  <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
                </svg>
              </div>
              <div class="setting-text">
                <div class="setting-label">{{ $t('settings.appearance.theme') }}</div>
                <div class="setting-description">{{ $t('settings.appearance.themeDescription') }}</div>
              </div>
            </div>
            
            <div class="theme-selector">
              <div 
                v-for="themeOption in availableThemes" 
                :key="themeOption"
                class="theme-option"
                :class="{ active: theme === themeOption }"
                @click="changeTheme(themeOption)"
              >
                <div class="theme-preview" :data-theme="themeOption">
                  <div class="preview-bar"></div>
                  <div class="preview-content">
                    <div class="preview-circle"></div>
                    <div class="preview-lines">
                      <div class="preview-line"></div>
                      <div class="preview-line short"></div>
                    </div>
                  </div>
                </div>
                <div class="theme-name">{{ formatThemeName(themeOption) }}</div>
                <div v-if="theme === themeOption" class="theme-check">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                    <polyline points="20 6 9 17 4 12"/>
                  </svg>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Language Section -->
      <div class="settings-section">
        <div class="section-header">
          <h3>{{ $t('settings.language.title') }}</h3>
        </div>
        
        <div class="settings-list">
          <div class="setting-item language-setting">
            <div class="setting-info full-width">
              <div class="setting-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="10"/>
                  <path d="M2 12h20"/>
                  <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
                </svg>
              </div>
              <div class="setting-text">
                <div class="setting-label">{{ $t('settings.language.label') }}</div>
                <div class="setting-description">{{ $t('settings.language.description') }}</div>
              </div>
            </div>
            
            <div class="language-selector">
              <div 
                v-for="lang in availableLanguages" 
                :key="lang.code"
                class="language-option"
                :class="{ active: currentLocale === lang.code }"
                @click="changeLanguage(lang.code)"
              >
                <div class="language-flag">{{ lang.flag }}</div>
                <div class="language-info">
                  <div class="language-name">{{ lang.name }}</div>
                  <div class="language-native">{{ lang.native }}</div>
                </div>
                <div v-if="currentLocale === lang.code" class="language-check">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                    <polyline points="20 6 9 17 4 12"/>
                  </svg>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Display Section -->
      <div class="settings-section">
        <div class="section-header">
          <h3>{{ $t('settings.display.title') }}</h3>
        </div>
        
        <div class="settings-list">
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <rect x="2" y="3" width="20" height="14" rx="2" ry="2"/>
                  <line x1="8" y1="21" x2="16" y2="21"/>
                  <line x1="12" y1="17" x2="12" y2="21"/>
                </svg>
              </div>
              <div class="setting-text">
                <div class="setting-label">{{ $t('settings.display.autoLock') }}</div>
                <div class="setting-description">{{ $t('settings.display.autoLockDescription') }}</div>
              </div>
            </div>
            <label class="toggle-switch">
              <input 
                type="checkbox" 
                :checked="getCustomSetting('autoLock', false)"
                @change="toggleAutoLock"
              >
              <span class="toggle-slider"></span>
            </label>
          </div>
        </div>
      </div>
      
      <!-- About Section -->
      <div class="settings-section">
        <div class="section-header">
          <h3>{{ $t('settings.about.title') }}</h3>
        </div>
        
        <div class="settings-list">
          <div class="setting-item info-item">
            <div class="setting-info">
              <div class="setting-text">
                <div class="setting-label">{{ $t('settings.about.phoneNumber') }}</div>
                <div class="setting-value">{{ phoneNumber || $t('settings.about.notAssigned') }}</div>
              </div>
            </div>
          </div>
          
          <div class="setting-item info-item">
            <div class="setting-info">
              <div class="setting-text">
                <div class="setting-label">{{ $t('settings.about.version') }}</div>
                <div class="setting-value">1.0.0</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { computed, onMounted } from 'vue'
import { useStore } from 'vuex'
import { useI18n } from 'vue-i18n'

export default {
  name: 'Settings',
  setup() {
    const store = useStore()
    const { locale } = useI18n()
    
    // Computed properties
    const theme = computed(() => store.state.settings.theme)
    const notificationEnabled = computed(() => store.state.settings.notificationEnabled)
    const soundEnabled = computed(() => store.state.settings.soundEnabled)
    const volume = computed(() => store.state.settings.volume)
    const availableThemes = computed(() => store.state.settings.availableThemes)
    const phoneNumber = computed(() => store.state.phone.phoneNumber)
    const currentLocale = computed(() => locale.value)
    
    const availableLanguages = computed(() => [
      { code: 'en', name: 'English', native: 'English', flag: '🇺🇸' },
      { code: 'ja', name: 'Japanese', native: '日本語', flag: '🇯🇵' },
      { code: 'es', name: 'Spanish', native: 'Español', flag: '🇪🇸' },
      { code: 'fr', name: 'French', native: 'Français', flag: '🇫🇷' },
      { code: 'de', name: 'German', native: 'Deutsch', flag: '🇩🇪' },
      { code: 'pt', name: 'Portuguese', native: 'Português', flag: '🇵🇹' }
    ])
    
    // Load settings on mount
    onMounted(async () => {
      if (!store.state.settings.isLoaded) {
        await store.dispatch('settings/loadSettings')
      }
    })
    
    // Methods
    const changeTheme = async (newTheme) => {
      const result = await store.dispatch('settings/changeTheme', newTheme)
      if (result.success) {
        store.dispatch('phone/showNotification', {
          type: 'success',
          title: 'Theme Changed',
          message: `Switched to ${formatThemeName(newTheme)} theme`,
          duration: 2000
        })
      }
    }
    
    const toggleNotifications = async () => {
      const result = await store.dispatch('settings/toggleNotifications')
      if (result.success) {
        const enabled = !notificationEnabled.value
        store.dispatch('phone/showNotification', {
          type: 'info',
          title: 'Notifications',
          message: enabled ? 'Notifications enabled' : 'Notifications disabled',
          duration: 2000
        })
      }
    }
    
    const toggleSound = async () => {
      const result = await store.dispatch('settings/toggleSound')
      if (result.success) {
        const enabled = !soundEnabled.value
        store.dispatch('phone/showNotification', {
          type: 'info',
          title: 'Sound',
          message: enabled ? 'Sounds enabled' : 'Sounds disabled',
          duration: 2000,
          sound: enabled
        })
      }
    }
    
    const updateVolume = async (event) => {
      const newVolume = parseInt(event.target.value)
      await store.dispatch('settings/setVolumeLevel', newVolume)
    }
    
    const toggleAutoLock = async (event) => {
      const enabled = event.target.checked
      await store.dispatch('settings/updateSettings', {
        customSettings: { autoLock: enabled }
      })
    }
    
    const getCustomSetting = (key, defaultValue) => {
      return store.getters['settings/getCustomSetting'](key) ?? defaultValue
    }
    
    const formatThemeName = (themeName) => {
      return themeName.charAt(0).toUpperCase() + themeName.slice(1)
    }
    
    const changeLanguage = async (newLocale) => {
      try {
        // Update i18n locale immediately for instant UI feedback
        locale.value = newLocale
        
        // Save to localStorage for persistence
        localStorage.setItem('phone-locale', newLocale)
        
        // Send to server via NUI callback to save in database
        const response = await fetch(`https://${GetParentResourceName()}/setPlayerLocale`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            locale: newLocale
          })
        })
        
        const result = await response.json()
        
        if (result.success) {
          // Show success notification
          store.dispatch('phone/showNotification', {
            type: 'success',
            title: 'Language Changed',
            message: `Language switched to ${availableLanguages.value.find(l => l.code === newLocale)?.name}`,
            duration: 2000
          })
        } else {
          throw new Error(result.message || 'Failed to save language preference')
        }
      } catch (error) {
        console.error('Failed to change language:', error)
        store.dispatch('phone/showNotification', {
          type: 'error',
          title: 'Error',
          message: 'Failed to change language',
          duration: 3000
        })
      }
    }
    
    // Helper function to get resource name
    const GetParentResourceName = () => {
      return window.GetParentResourceName ? window.GetParentResourceName() : 'phone'
    }
    
    return {
      theme,
      notificationEnabled,
      soundEnabled,
      volume,
      availableThemes,
      phoneNumber,
      currentLocale,
      availableLanguages,
      changeTheme,
      toggleNotifications,
      toggleSound,
      updateVolume,
      toggleAutoLock,
      getCustomSetting,
      formatThemeName,
      changeLanguage
    }
  }
}
</script>

<style scoped>
.settings-app {
  flex: 1;
  overflow-y: auto;
  background: var(--background-primary);
}

.settings-content {
  padding-bottom: 20px;
}

.settings-section {
  margin-bottom: 24px;
}

.section-header {
  padding: 16px 20px 8px;
}

.section-header h3 {
  font-size: 13px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--text-tertiary);
  margin: 0;
}

.settings-list {
  background: var(--background-secondary);
  border-top: 1px solid var(--border-primary);
  border-bottom: 1px solid var(--border-primary);
}

.setting-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 20px;
  border-bottom: 1px solid var(--border-primary);
  min-height: 60px;
}

.setting-item:last-child {
  border-bottom: none;
}

.setting-item.volume-setting,
.setting-item.theme-setting {
  flex-direction: column;
  align-items: stretch;
}

.setting-info {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}

.setting-info.full-width {
  width: 100%;
}

.setting-icon {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--primary-color);
  flex-shrink: 0;
}

.setting-text {
  flex: 1;
}

.setting-label {
  font-size: 16px;
  font-weight: 500;
  color: var(--text-primary);
  margin-bottom: 2px;
}

.setting-description {
  font-size: 13px;
  color: var(--text-tertiary);
}

.setting-value {
  font-size: 14px;
  color: var(--text-secondary);
}

/* Toggle Switch */
.toggle-switch {
  position: relative;
  display: inline-block;
  width: 51px;
  height: 31px;
  flex-shrink: 0;
}

.toggle-switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.toggle-slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: var(--background-elevated);
  transition: 0.3s;
  border-radius: 31px;
  border: 2px solid var(--border-primary);
}

.toggle-slider:before {
  position: absolute;
  content: "";
  height: 27px;
  width: 27px;
  left: 0;
  bottom: 0;
  background-color: white;
  transition: 0.3s;
  border-radius: 50%;
}

input:checked + .toggle-slider {
  background-color: var(--primary-color);
  border-color: var(--primary-color);
}

input:checked + .toggle-slider:before {
  transform: translateX(20px);
}

/* Volume Control */
.volume-control {
  width: 100%;
  margin-top: 12px;
  padding: 0 12px;
}

.volume-slider {
  width: 100%;
  height: 4px;
  border-radius: 2px;
  background: var(--background-elevated);
  outline: none;
  -webkit-appearance: none;
}

.volume-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--primary-color);
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.volume-slider::-moz-range-thumb {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--primary-color);
  cursor: pointer;
  border: none;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

/* Theme Selector */
.theme-selector {
  display: flex;
  gap: 12px;
  margin-top: 16px;
  padding: 0 8px;
}

.theme-option {
  flex: 1;
  cursor: pointer;
  text-align: center;
  position: relative;
}

.theme-preview {
  width: 100%;
  aspect-ratio: 9/16;
  border-radius: 12px;
  overflow: hidden;
  border: 2px solid var(--border-primary);
  transition: all 0.2s;
  margin-bottom: 8px;
}

.theme-option.active .theme-preview {
  border-color: var(--primary-color);
  box-shadow: 0 0 0 2px var(--primary-color);
}

.theme-preview[data-theme="light"] {
  background: #FFFFFF;
}

.theme-preview[data-theme="dark"] {
  background: #000000;
}

.theme-preview[data-theme="oled"] {
  background: #000000;
}

.preview-bar {
  height: 20%;
  background: var(--overlay-light);
}

.theme-preview[data-theme="light"] .preview-bar {
  background: rgba(0, 0, 0, 0.05);
}

.theme-preview[data-theme="dark"] .preview-bar,
.theme-preview[data-theme="oled"] .preview-bar {
  background: rgba(255, 255, 255, 0.1);
}

.preview-content {
  padding: 8px;
  display: flex;
  gap: 6px;
}

.preview-circle {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #007AFF;
  flex-shrink: 0;
}

.preview-lines {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  justify-content: center;
}

.preview-line {
  height: 4px;
  border-radius: 2px;
  background: var(--overlay-medium);
}

.theme-preview[data-theme="light"] .preview-line {
  background: rgba(0, 0, 0, 0.1);
}

.theme-preview[data-theme="dark"] .preview-line,
.theme-preview[data-theme="oled"] .preview-line {
  background: rgba(255, 255, 255, 0.2);
}

.preview-line.short {
  width: 60%;
}

.theme-name {
  font-size: 13px;
  font-weight: 500;
  color: var(--text-secondary);
}

.theme-option.active .theme-name {
  color: var(--primary-color);
  font-weight: 600;
}

.theme-check {
  position: absolute;
  top: 4px;
  right: 4px;
  width: 24px;
  height: 24px;
  background: var(--primary-color);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

/* Language Selector */
.language-selector {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 16px;
  padding: 0 8px;
}

.language-option {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-radius: 12px;
  border: 2px solid var(--border-primary);
  background: var(--background-elevated);
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}

.language-option:hover {
  border-color: var(--primary-color);
  background: var(--background-secondary);
}

.language-option.active {
  border-color: var(--primary-color);
  background: var(--primary-color);
  color: white;
}

.language-flag {
  font-size: 24px;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  background: var(--background-primary);
  flex-shrink: 0;
}

.language-option.active .language-flag {
  background: rgba(255, 255, 255, 0.2);
}

.language-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.language-name {
  font-size: 16px;
  font-weight: 500;
  color: var(--text-primary);
}

.language-option.active .language-name {
  color: white;
}

.language-native {
  font-size: 13px;
  color: var(--text-secondary);
}

.language-option.active .language-native {
  color: rgba(255, 255, 255, 0.8);
}

.language-check {
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  flex-shrink: 0;
}

/* Info Items */
.info-item {
  cursor: default;
}

/* Animations */
.settings-app {
  animation: slideUp 0.3s ease-out;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
