<template>
  <div class="customization-page">
    <!-- Wallpaper Section -->
    <div class="customization-section">
      <IOSCard variant="glass">
        <template #header>
          <div class="section-header">
            <h3>Wallpaper</h3>
            <button @click="addCustomWallpaper" class="add-btn">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <line x1="12" y1="5" x2="12" y2="19" stroke="currentColor" stroke-width="2"/>
                <line x1="5" y1="12" x2="19" y2="12" stroke="currentColor" stroke-width="2"/>
              </svg>
              Add Custom
            </button>
          </div>
        </template>
        
        <template #content>
          <div class="wallpaper-grid">
            <div
              v-for="wallpaper in wallpapers"
              :key="wallpaper.id"
              @click="selectWallpaper(wallpaper)"
              class="wallpaper-item"
              :class="{ selected: selectedWallpaper?.id === wallpaper.id }"
            >
              <div class="wallpaper-preview" :style="{ backgroundImage: `url(${wallpaper.preview})` }">
                <div v-if="selectedWallpaper?.id === wallpaper.id" class="selected-indicator">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <polyline points="20,6 9,17 4,12" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
              </div>
              <span class="wallpaper-name">{{ wallpaper.name }}</span>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Theme Section -->
    <div class="customization-section">
      <IOSCard variant="glass">
        <template #header>
          <h3>Theme</h3>
        </template>
        
        <template #content>
          <div class="theme-options">
            <div
              v-for="theme in themes"
              :key="theme.id"
              @click="selectTheme(theme)"
              class="theme-item"
              :class="{ selected: selectedTheme?.id === theme.id }"
            >
              <div class="theme-preview">
                <div class="theme-colors">
                  <div
                    v-for="color in theme.colors"
                    :key="color"
                    class="color-dot"
                    :style="{ backgroundColor: color }"
                  ></div>
                </div>
                <div v-if="selectedTheme?.id === theme.id" class="selected-indicator">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                    <polyline points="20,6 9,17 4,12" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
              </div>
              <span class="theme-name">{{ theme.name }}</span>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Ringtone Section -->
    <div class="customization-section">
      <IOSCard variant="glass">
        <template #header>
          <div class="section-header">
            <h3>Ringtone</h3>
            <button @click="addCustomRingtone" class="add-btn">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <line x1="12" y1="5" x2="12" y2="19" stroke="currentColor" stroke-width="2"/>
                <line x1="5" y1="12" x2="19" y2="12" stroke="currentColor" stroke-width="2"/>
              </svg>
              Add Custom
            </button>
          </div>
        </template>
        
        <template #content>
          <div class="ringtone-list">
            <div
              v-for="ringtone in ringtones"
              :key="ringtone.id"
              class="ringtone-item"
              :class="{ selected: selectedRingtone?.id === ringtone.id }"
            >
              <div class="ringtone-info" @click="selectRingtone(ringtone)">
                <div class="ringtone-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" stroke="currentColor" stroke-width="2"/>
                    <path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="ringtone-details">
                  <span class="ringtone-name">{{ ringtone.name }}</span>
                  <span class="ringtone-duration">{{ ringtone.duration }}</span>
                </div>
                <div v-if="selectedRingtone?.id === ringtone.id" class="selected-indicator">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                    <polyline points="20,6 9,17 4,12" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
              </div>
              <button 
                @click="playRingtone(ringtone)"
                class="play-btn"
                :class="{ playing: playingRingtone?.id === ringtone.id }"
              >
                <svg v-if="playingRingtone?.id !== ringtone.id" width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <polygon points="5,3 19,12 5,21" stroke="currentColor" stroke-width="2" fill="currentColor"/>
                </svg>
                <svg v-else width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <rect x="6" y="4" width="4" height="16" stroke="currentColor" stroke-width="2" fill="currentColor"/>
                  <rect x="14" y="4" width="4" height="16" stroke="currentColor" stroke-width="2" fill="currentColor"/>
                </svg>
              </button>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Notification Sounds Section -->
    <div class="customization-section">
      <IOSCard variant="glass">
        <template #header>
          <h3>Notification Sounds</h3>
        </template>
        
        <template #content>
          <div class="notification-sounds">
            <div class="sound-category">
              <h4>Transaction Alerts</h4>
              <div class="sound-options">
                <div
                  v-for="sound in transactionSounds"
                  :key="sound.id"
                  @click="selectTransactionSound(sound)"
                  class="sound-item"
                  :class="{ selected: selectedTransactionSound?.id === sound.id }"
                >
                  <span class="sound-name">{{ sound.name }}</span>
                  <button @click.stop="playSound(sound)" class="play-btn-small">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
                      <polygon points="5,3 19,12 5,21" stroke="currentColor" stroke-width="2" fill="currentColor"/>
                    </svg>
                  </button>
                </div>
              </div>
            </div>

            <div class="sound-category">
              <h4>General Notifications</h4>
              <div class="sound-options">
                <div
                  v-for="sound in notificationSounds"
                  :key="sound.id"
                  @click="selectNotificationSound(sound)"
                  class="sound-item"
                  :class="{ selected: selectedNotificationSound?.id === sound.id }"
                >
                  <span class="sound-name">{{ sound.name }}</span>
                  <button @click.stop="playSound(sound)" class="play-btn-small">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
                      <polygon points="5,3 19,12 5,21" stroke="currentColor" stroke-width="2" fill="currentColor"/>
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- App Icon Section -->
    <div class="customization-section">
      <IOSCard variant="glass">
        <template #header>
          <h3>App Icon</h3>
        </template>
        
        <template #content>
          <div class="app-icon-grid">
            <div
              v-for="icon in appIcons"
              :key="icon.id"
              @click="selectAppIcon(icon)"
              class="app-icon-item"
              :class="{ selected: selectedAppIcon?.id === icon.id }"
            >
              <div class="app-icon-preview">
                <img :src="icon.preview" :alt="icon.name" />
                <div v-if="selectedAppIcon?.id === icon.id" class="selected-indicator">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                    <polyline points="20,6 9,17 4,12" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
              </div>
              <span class="app-icon-name">{{ icon.name }}</span>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Widget Customization -->
    <div class="customization-section">
      <IOSCard variant="glass">
        <template #header>
          <h3>Widget Settings</h3>
        </template>
        
        <template #content>
          <div class="widget-settings">
            <div class="widget-option">
              <div class="widget-info">
                <span class="widget-label">Show Balance Widget</span>
                <span class="widget-description">Display balance on home screen</span>
              </div>
              <label class="toggle-switch">
                <input type="checkbox" :checked="widgetSettings.showBalance" @change="updateWidgetSetting('showBalance', $event.target.checked)" />
                <span class="toggle-slider"></span>
              </label>
            </div>

            <div class="widget-option">
              <div class="widget-info">
                <span class="widget-label">Show Recent Transactions</span>
                <span class="widget-description">Display recent activity</span>
              </div>
              <label class="toggle-switch">
                <input type="checkbox" :checked="widgetSettings.showTransactions" @change="updateWidgetSetting('showTransactions', $event.target.checked)" />
                <span class="toggle-slider"></span>
              </label>
            </div>

            <div class="widget-option">
              <div class="widget-info">
                <span class="widget-label">Show Quick Actions</span>
                <span class="widget-description">Display quick action buttons</span>
              </div>
              <label class="toggle-switch">
                <input type="checkbox" :checked="widgetSettings.showQuickActions" @change="updateWidgetSetting('showQuickActions', $event.target.checked)" />
                <span class="toggle-slider"></span>
              </label>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Preview Section -->
    <div class="customization-section">
      <IOSCard variant="glass">
        <template #header>
          <div class="section-header">
            <h3>Preview</h3>
            <button @click="resetToDefaults" class="reset-btn">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <polyline points="23,4 23,10 17,10" stroke="currentColor" stroke-width="2"/>
                <polyline points="1,20 1,14 7,14" stroke="currentColor" stroke-width="2"/>
                <path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15" stroke="currentColor" stroke-width="2"/>
              </svg>
              Reset to Defaults
            </button>
          </div>
        </template>
        
        <template #content>
          <div class="preview-container">
            <div class="phone-preview">
              <div class="phone-frame">
                <div class="phone-screen" :style="{ backgroundImage: `url(${selectedWallpaper?.preview})` }">
                  <div class="preview-overlay" :style="{ background: selectedTheme?.overlay }">
                    <div class="preview-app-icon">
                      <img v-if="selectedAppIcon" :src="selectedAppIcon.preview" alt="App Icon" />
                    </div>
                    <div class="preview-widget" v-if="widgetSettings.showBalance">
                      <div class="widget-balance">$12,345.67</div>
                      <div class="widget-label">Available Balance</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="preview-info">
              <h4>Current Customization</h4>
              <div class="preview-details">
                <div class="detail-item">
                  <span class="detail-label">Wallpaper:</span>
                  <span class="detail-value">{{ selectedWallpaper?.name || 'Default' }}</span>
                </div>
                <div class="detail-item">
                  <span class="detail-label">Theme:</span>
                  <span class="detail-value">{{ selectedTheme?.name || 'Default' }}</span>
                </div>
                <div class="detail-item">
                  <span class="detail-label">Ringtone:</span>
                  <span class="detail-value">{{ selectedRingtone?.name || 'Default' }}</span>
                </div>
                <div class="detail-item">
                  <span class="detail-label">App Icon:</span>
                  <span class="detail-value">{{ selectedAppIcon?.name || 'Default' }}</span>
                </div>
              </div>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Save Changes -->
    <div class="save-section">
      <IOSButton variant="primary" @click="saveCustomization" class="save-btn">
        Save Changes
      </IOSButton>
    </div>

    <!-- Custom Upload Modals -->
    <IOSModal
      v-model="showWallpaperUpload"
      title="Add Custom Wallpaper"
      size="medium"
    >
      <div class="upload-form">
        <div class="upload-area" @click="triggerWallpaperUpload" @dragover.prevent @drop="handleWallpaperDrop">
          <input ref="wallpaperInput" type="file" accept="image/*" @change="handleWallpaperUpload" style="display: none" />
          <div class="upload-icon">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none">
              <rect x="3" y="3" width="18" height="18" rx="2" ry="2" stroke="currentColor" stroke-width="2"/>
              <circle cx="8.5" cy="8.5" r="1.5" stroke="currentColor" stroke-width="2"/>
              <polyline points="21,15 16,10 5,21" stroke="currentColor" stroke-width="2"/>
            </svg>
          </div>
          <h4>Upload Wallpaper</h4>
          <p>Drag and drop an image or click to browse</p>
          <span class="upload-note">Recommended: 1080x1920 pixels</span>
        </div>
      </div>
    </IOSModal>

    <IOSModal
      v-model="showRingtoneUpload"
      title="Add Custom Ringtone"
      size="medium"
    >
      <div class="upload-form">
        <div class="upload-area" @click="triggerRingtoneUpload" @dragover.prevent @drop="handleRingtoneDrop">
          <input ref="ringtoneInput" type="file" accept="audio/*" @change="handleRingtoneUpload" style="display: none" />
          <div class="upload-icon">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none">
              <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" stroke="currentColor" stroke-width="2"/>
              <path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07" stroke="currentColor" stroke-width="2"/>
            </svg>
          </div>
          <h4>Upload Ringtone</h4>
          <p>Drag and drop an audio file or click to browse</p>
          <span class="upload-note">Supported: MP3, WAV, M4A (max 30 seconds)</span>
        </div>
      </div>
    </IOSModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useStore } from 'vuex'

// Components
import IOSCard from '../../ios/IOSCard.vue'
import IOSModal from '../../ios/IOSModal.vue'
import IOSButton from '../../ios/IOSButton.vue'

const store = useStore()

// State
const showWallpaperUpload = ref(false)
const showRingtoneUpload = ref(false)
const playingRingtone = ref(null)
const wallpaperInput = ref(null)
const ringtoneInput = ref(null)

// Computed properties
const customization = computed(() => store.state.wallet.customization || {})
const widgetSettings = computed(() => store.state.wallet.widgetSettings || {})

const selectedWallpaper = computed(() => customization.value.wallpaper)
const selectedTheme = computed(() => customization.value.theme)
const selectedRingtone = computed(() => customization.value.ringtone)
const selectedAppIcon = computed(() => customization.value.appIcon)
const selectedTransactionSound = computed(() => customization.value.transactionSound)
const selectedNotificationSound = computed(() => customization.value.notificationSound)

// Mock data
const wallpapers = [
  { id: 1, name: 'Ocean Waves', preview: 'https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=ocean%20waves%20blue%20gradient%20abstract%20wallpaper&image_size=portrait_16_9' },
  { id: 2, name: 'Mountain Peak', preview: 'https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=mountain%20peak%20sunset%20gradient%20wallpaper&image_size=portrait_16_9' },
  { id: 3, name: 'City Lights', preview: 'https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=city%20lights%20night%20urban%20wallpaper&image_size=portrait_16_9' },
  { id: 4, name: 'Forest Path', preview: 'https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=forest%20path%20green%20nature%20wallpaper&image_size=portrait_16_9' },
  { id: 5, name: 'Space Galaxy', preview: 'https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=space%20galaxy%20stars%20nebula%20wallpaper&image_size=portrait_16_9' },
  { id: 6, name: 'Abstract Art', preview: 'https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=abstract%20art%20colorful%20geometric%20wallpaper&image_size=portrait_16_9' }
]

const themes = [
  { id: 1, name: 'Default', colors: ['#007AFF', '#34C759', '#FF9500'], overlay: 'rgba(0, 0, 0, 0.1)' },
  { id: 2, name: 'Dark Mode', colors: ['#0A84FF', '#30D158', '#FF9F0A'], overlay: 'rgba(0, 0, 0, 0.3)' },
  { id: 3, name: 'Ocean', colors: ['#007AFF', '#5AC8FA', '#4CD964'], overlay: 'rgba(0, 122, 255, 0.1)' },
  { id: 4, name: 'Sunset', colors: ['#FF9500', '#FF3B30', '#FF2D92'], overlay: 'rgba(255, 149, 0, 0.1)' },
  { id: 5, name: 'Forest', colors: ['#34C759', '#30D158', '#32D74B'], overlay: 'rgba(52, 199, 89, 0.1)' },
  { id: 6, name: 'Purple', colors: ['#AF52DE', '#BF5AF2', '#DA70D6'], overlay: 'rgba(175, 82, 222, 0.1)' }
]

const ringtones = [
  { id: 1, name: 'Default', duration: '0:30', url: '/sounds/default.mp3' },
  { id: 2, name: 'Chime', duration: '0:15', url: '/sounds/chime.mp3' },
  { id: 3, name: 'Bell', duration: '0:20', url: '/sounds/bell.mp3' },
  { id: 4, name: 'Marimba', duration: '0:25', url: '/sounds/marimba.mp3' },
  { id: 5, name: 'Guitar', duration: '0:30', url: '/sounds/guitar.mp3' },
  { id: 6, name: 'Piano', duration: '0:28', url: '/sounds/piano.mp3' }
]

const transactionSounds = [
  { id: 1, name: 'Ding', url: '/sounds/ding.mp3' },
  { id: 2, name: 'Chime', url: '/sounds/chime.mp3' },
  { id: 3, name: 'Bell', url: '/sounds/bell.mp3' },
  { id: 4, name: 'Pop', url: '/sounds/pop.mp3' }
]

const notificationSounds = [
  { id: 1, name: 'Default', url: '/sounds/notification.mp3' },
  { id: 2, name: 'Gentle', url: '/sounds/gentle.mp3' },
  { id: 3, name: 'Alert', url: '/sounds/alert.mp3' },
  { id: 4, name: 'Soft', url: '/sounds/soft.mp3' }
]

const appIcons = [
  { id: 1, name: 'Default', preview: 'https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=wallet%20app%20icon%20blue%20gradient%20ios%20style&image_size=square' },
  { id: 2, name: 'Classic', preview: 'https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=wallet%20app%20icon%20green%20classic%20ios%20style&image_size=square' },
  { id: 3, name: 'Modern', preview: 'https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=wallet%20app%20icon%20purple%20modern%20ios%20style&image_size=square' },
  { id: 4, name: 'Minimal', preview: 'https://trae-api-sg.mchost.guru/api/ide/v1/text_to_image?prompt=wallet%20app%20icon%20black%20minimal%20ios%20style&image_size=square' }
]

// Methods
const selectWallpaper = (wallpaper) => {
  store.dispatch('wallet/updateCustomization', { wallpaper })
}

const selectTheme = (theme) => {
  store.dispatch('wallet/updateCustomization', { theme })
}

const selectRingtone = (ringtone) => {
  store.dispatch('wallet/updateCustomization', { ringtone })
}

const selectAppIcon = (icon) => {
  store.dispatch('wallet/updateCustomization', { appIcon: icon })
}

const selectTransactionSound = (sound) => {
  store.dispatch('wallet/updateCustomization', { transactionSound: sound })
}

const selectNotificationSound = (sound) => {
  store.dispatch('wallet/updateCustomization', { notificationSound: sound })
}

const playRingtone = (ringtone) => {
  if (playingRingtone.value?.id === ringtone.id) {
    // Stop playing
    playingRingtone.value = null
  } else {
    // Start playing
    playingRingtone.value = ringtone
    // Simulate playing for 3 seconds
    setTimeout(() => {
      playingRingtone.value = null
    }, 3000)
  }
}

const playSound = (sound) => {
  // Play sound preview
  console.log('Playing sound:', sound.name)
}

const updateWidgetSetting = (key, value) => {
  store.dispatch('wallet/updateWidgetSetting', { key, value })
}

const addCustomWallpaper = () => {
  showWallpaperUpload.value = true
}

const addCustomRingtone = () => {
  showRingtoneUpload.value = true
}

const triggerWallpaperUpload = () => {
  wallpaperInput.value?.click()
}

const triggerRingtoneUpload = () => {
  ringtoneInput.value?.click()
}

const handleWallpaperUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    // Handle wallpaper upload
    console.log('Uploading wallpaper:', file.name)
    showWallpaperUpload.value = false
  }
}

const handleRingtoneUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    // Handle ringtone upload
    console.log('Uploading ringtone:', file.name)
    showRingtoneUpload.value = false
  }
}

const handleWallpaperDrop = (event) => {
  event.preventDefault()
  const file = event.dataTransfer.files[0]
  if (file && file.type.startsWith('image/')) {
    console.log('Dropped wallpaper:', file.name)
    showWallpaperUpload.value = false
  }
}

const handleRingtoneDrop = (event) => {
  event.preventDefault()
  const file = event.dataTransfer.files[0]
  if (file && file.type.startsWith('audio/')) {
    console.log('Dropped ringtone:', file.name)
    showRingtoneUpload.value = false
  }
}

const resetToDefaults = () => {
  if (confirm('Reset all customizations to default settings?')) {
    store.dispatch('wallet/resetCustomization')
  }
}

const saveCustomization = () => {
  store.dispatch('wallet/saveCustomization')
  // Show success message
  console.log('Customization saved!')
}

// Initialize data
onMounted(() => {
  store.dispatch('wallet/fetchCustomization')
  store.dispatch('wallet/fetchWidgetSettings')
})
</script>

<style scoped>
.customization-page {
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding-bottom: 20px;
}

.customization-section {
  margin-bottom: 8px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.section-header h3 {
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.add-btn,
.reset-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  background: none;
  border: none;
  color: #007AFF;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s ease;
}

.add-btn:hover,
.reset-btn:hover {
  opacity: 0.7;
}

/* Wallpaper Grid */
.wallpaper-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 16px;
  margin-top: 16px;
}

.wallpaper-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.wallpaper-item:hover {
  transform: translateY(-2px);
}

.wallpaper-preview {
  width: 100%;
  height: 160px;
  border-radius: 12px;
  background-size: cover;
  background-position: center;
  position: relative;
  overflow: hidden;
  border: 2px solid transparent;
  transition: all 0.2s ease;
}

.wallpaper-item.selected .wallpaper-preview {
  border-color: #007AFF;
}

.wallpaper-name {
  font-size: 12px;
  font-weight: 500;
  color: #1d1d1f;
  text-align: center;
}

.selected-indicator {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: #007AFF;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Theme Options */
.theme-options {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 16px;
  margin-top: 16px;
}

.theme-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.theme-item:hover {
  transform: translateY(-2px);
}

.theme-preview {
  width: 100%;
  height: 80px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.8);
  border: 2px solid transparent;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.theme-item.selected .theme-preview {
  border-color: #007AFF;
}

.theme-colors {
  display: flex;
  gap: 4px;
}

.color-dot {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: 1px solid rgba(0, 0, 0, 0.1);
}

.theme-name {
  font-size: 12px;
  font-weight: 500;
  color: #1d1d1f;
  text-align: center;
}

/* Ringtone List */
.ringtone-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 16px;
}

.ringtone-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  border: 1px solid rgba(0, 0, 0, 0.05);
  transition: all 0.2s ease;
}

.ringtone-item:hover {
  background: rgba(255, 255, 255, 0.8);
}

.ringtone-item.selected {
  border-color: #007AFF;
  background: rgba(0, 122, 255, 0.05);
}

.ringtone-info {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
  cursor: pointer;
}

.ringtone-icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: rgba(0, 122, 255, 0.1);
  color: #007AFF;
  display: flex;
  align-items: center;
  justify-content: center;
}

.ringtone-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.ringtone-name {
  font-size: 14px;
  font-weight: 500;
  color: #1d1d1f;
}

.ringtone-duration {
  font-size: 12px;
  color: #8e8e93;
}

.play-btn {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: none;
  background: #007AFF;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
}

.play-btn:hover {
  background: #0056CC;
}

.play-btn.playing {
  background: #FF3B30;
}

/* Notification Sounds */
.notification-sounds {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-top: 16px;
}

.sound-category h4 {
  font-size: 14px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0 0 12px 0;
}

.sound-options {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sound-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 8px;
  border: 1px solid rgba(0, 0, 0, 0.05);
  cursor: pointer;
  transition: all 0.2s ease;
}

.sound-item:hover {
  background: rgba(255, 255, 255, 0.8);
}

.sound-item.selected {
  border-color: #007AFF;
  background: rgba(0, 122, 255, 0.05);
}

.sound-name {
  font-size: 13px;
  font-weight: 500;
  color: #1d1d1f;
}

.play-btn-small {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  border: none;
  background: #007AFF;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
}

.play-btn-small:hover {
  background: #0056CC;
}

/* App Icon Grid */
.app-icon-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
  gap: 16px;
  margin-top: 16px;
}

.app-icon-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.app-icon-item:hover {
  transform: translateY(-2px);
}

.app-icon-preview {
  width: 80px;
  height: 80px;
  border-radius: 16px;
  position: relative;
  overflow: hidden;
  border: 2px solid transparent;
  transition: all 0.2s ease;
  margin: 0 auto;
}

.app-icon-item.selected .app-icon-preview {
  border-color: #007AFF;
}

.app-icon-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.app-icon-name {
  font-size: 12px;
  font-weight: 500;
  color: #1d1d1f;
  text-align: center;
}

/* Widget Settings */
.widget-settings {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 16px;
}

.widget-option {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  border: 1px solid rgba(0, 0, 0, 0.05);
}

.widget-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.widget-label {
  font-size: 14px;
  font-weight: 500;
  color: #1d1d1f;
}

.widget-description {
  font-size: 12px;
  color: #8e8e93;
}

/* Toggle Switch */
.toggle-switch {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
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
  background-color: #ccc;
  transition: 0.3s;
  border-radius: 24px;
}

.toggle-slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: 0.3s;
  border-radius: 50%;
}

input:checked + .toggle-slider {
  background-color: #007AFF;
}

input:checked + .toggle-slider:before {
  transform: translateX(20px);
}

/* Preview Section */
.preview-container {
  display: flex;
  gap: 24px;
  align-items: flex-start;
  margin-top: 16px;
}

.phone-preview {
  flex-shrink: 0;
}

.phone-frame {
  width: 180px;
  height: 320px;
  background: #1d1d1f;
  border-radius: 24px;
  padding: 8px;
  position: relative;
}

.phone-screen {
  width: 100%;
  height: 100%;
  border-radius: 16px;
  background-size: cover;
  background-position: center;
  position: relative;
  overflow: hidden;
}

.preview-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
}

.preview-app-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  overflow: hidden;
}

.preview-app-icon img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.preview-widget {
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(20px);
  border-radius: 12px;
  padding: 12px 16px;
  text-align: center;
}

.widget-balance {
  font-size: 18px;
  font-weight: 700;
  color: #1d1d1f;
}

.widget-label {
  font-size: 10px;
  color: #8e8e93;
  margin-top: 2px;
}

.preview-info {
  flex: 1;
}

.preview-info h4 {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0 0 16px 0;
}

.preview-details {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.detail-label {
  font-size: 14px;
  color: #8e8e93;
}

.detail-value {
  font-size: 14px;
  font-weight: 500;
  color: #1d1d1f;
}

/* Save Section */
.save-section {
  display: flex;
  justify-content: center;
  margin-top: 8px;
}

.save-btn {
  min-width: 200px;
}

/* Upload Form */
.upload-form {
  padding: 20px 0;
}

.upload-area {
  border: 2px dashed #007AFF;
  border-radius: 12px;
  padding: 40px 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s ease;
}

.upload-area:hover {
  background: rgba(0, 122, 255, 0.02);
}

.upload-icon {
  color: #007AFF;
  margin-bottom: 16px;
}

.upload-area h4 {
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0 0 8px 0;
}

.upload-area p {
  font-size: 14px;
  color: #8e8e93;
  margin: 0 0 8px 0;
}

.upload-note {
  font-size: 12px;
  color: #8e8e93;
  font-style: italic;
}

/* Responsive Design */
@media (max-width: 768px) {
  .wallpaper-grid {
    grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
  }

  .theme-options {
    grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  }

  .app-icon-grid {
    grid-template-columns: repeat(auto-fill, minmax(80px, 1fr));
  }

  .preview-container {
    flex-direction: column;
    align-items: center;
  }

  .phone-frame {
    width: 160px;
    height: 280px;
  }

  .preview-app-icon {
    width: 50px;
    height: 50px;
  }
}

@media (max-width: 375px) {
  .wallpaper-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .theme-options {
    grid-template-columns: repeat(2, 1fr);
  }

  .app-icon-grid {
    grid-template-columns: repeat(3, 1fr);
  }

  .ringtone-item {
    padding: 10px 12px;
  }

  .widget-option {
    padding: 12px;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .section-header h3 {
    color: #f2f2f7;
  }

  .wallpaper-name,
  .theme-name,
  .app-icon-name {
    color: #f2f2f7;
  }

  .ringtone-item {
    background: rgba(44, 44, 46, 0.5);
    border-color: rgba(255, 255, 255, 0.05);
  }

  .ringtone-item:hover {
    background: rgba(44, 44, 46, 0.8);
  }

  .ringtone-item.selected {
    background: rgba(0, 122, 255, 0.1);
    border-color: #0A84FF;
  }

  .ringtone-name {
    color: #f2f2f7;
  }

  .sound-item {
    background: rgba(44, 44, 46, 0.5);
    border-color: rgba(255, 255, 255, 0.05);
  }

  .sound-item:hover {
    background: rgba(44, 44, 46, 0.8);
  }

  .sound-item.selected {
    background: rgba(0, 122, 255, 0.1);
    border-color: #0A84FF;
  }

  .sound-name {
    color: #f2f2f7;
  }

  .sound-category h4 {
    color: #f2f2f7;
  }

  .widget-option {
    background: rgba(44, 44, 46, 0.5);
    border-color: rgba(255, 255, 255, 0.05);
  }

  .widget-label {
    color: #f2f2f7;
  }

  .preview-info h4 {
    color: #f2f2f7;
  }

  .detail-value {
    color: #f2f2f7;
  }

  .upload-area h4 {
    color: #f2f2f7;
  }

  .toggle-slider {
    background-color: #48484a;
  }

  input:checked + .toggle-slider {
    background-color: #0A84FF;
  }
}
</style>