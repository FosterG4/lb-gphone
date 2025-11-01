<template>
  <div class="finder-app">
    <!-- Header -->
    <div class="finder-header">
      <h1>Find My Devices</h1>
      <button @click="refreshDevices" class="refresh-btn" :disabled="isRefreshing">
        <i :class="isRefreshing ? 'fas fa-spinner fa-spin' : 'fas fa-sync-alt'"></i>
      </button>
    </div>

    <!-- Navigation tabs -->
    <div class="nav-tabs">
      <button 
        @click="activeTab = 'devices'"
        class="nav-tab"
        :class="{ active: activeTab === 'devices' }"
      >
        <i class="fas fa-mobile-alt"></i>
        Devices
      </button>
      <button 
        @click="activeTab = 'map'"
        class="nav-tab"
        :class="{ active: activeTab === 'map' }"
      >
        <i class="fas fa-map-marked-alt"></i>
        Map View
      </button>
      <button 
        @click="activeTab = 'settings'"
        class="nav-tab"
        :class="{ active: activeTab === 'settings' }"
      >
        <i class="fas fa-cog"></i>
        Settings
      </button>
    </div>

    <!-- Devices Tab -->
    <div v-if="activeTab === 'devices'" class="tab-content">
      <div v-if="devices.length === 0" class="empty-state">
        <i class="fas fa-search"></i>
        <h3>No Devices Found</h3>
        <p>Register your devices to track their locations</p>
        <button @click="showAddDevice = true" class="add-device-btn">
          <i class="fas fa-plus"></i>
          Add Device
        </button>
      </div>

      <div v-else class="device-list">
        <div class="list-header">
          <h2>My Devices ({{ devices.length }})</h2>
          <button @click="showAddDevice = true" class="add-btn">
            <i class="fas fa-plus"></i>
          </button>
        </div>

        <div 
          v-for="device in devices" 
          :key="device.id"
          class="device-item"
          :class="{ 
            online: device.status === 'online',
            offline: device.status === 'offline',
            lost: device.status === 'lost'
          }"
        >
          <div class="device-icon">
            <i :class="getDeviceIcon(device.type)"></i>
            <div class="status-indicator" :class="device.status"></div>
          </div>

          <div class="device-info">
            <div class="device-name">{{ device.name }}</div>
            <div class="device-type">{{ device.type }}</div>
            <div class="device-location" v-if="device.location">
              <i class="fas fa-map-marker-alt"></i>
              {{ device.location.address || 'Unknown Location' }}
            </div>
            <div class="last-seen">
              Last seen: {{ formatLastSeen(device.lastSeen) }}
            </div>
          </div>

          <div class="device-actions">
            <button 
              @click="locateDevice(device)"
              class="action-btn locate-btn"
              :disabled="device.status === 'offline'"
              :title="device.status === 'offline' ? 'Device is offline' : 'Show on map'"
            >
              <i class="fas fa-map-marker-alt"></i>
            </button>
            
            <button 
              @click="playSound(device)"
              class="action-btn sound-btn"
              :disabled="device.status === 'offline'"
              :title="device.status === 'offline' ? 'Device is offline' : 'Play sound'"
            >
              <i class="fas fa-volume-up"></i>
            </button>
            
            <button 
              @click="markAsLost(device)"
              class="action-btn lost-btn"
              :class="{ active: device.status === 'lost' }"
              :title="device.status === 'lost' ? 'Mark as found' : 'Mark as lost'"
            >
              <i class="fas fa-exclamation-triangle"></i>
            </button>
            
            <button 
              @click="removeDevice(device)"
              class="action-btn remove-btn"
              title="Remove device"
            >
              <i class="fas fa-trash"></i>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Map Tab -->
    <div v-if="activeTab === 'map'" class="tab-content">
      <div class="map-container">
        <div class="map-header">
          <h2>Device Locations</h2>
          <div class="map-controls">
            <button @click="centerMap" class="map-btn">
              <i class="fas fa-crosshairs"></i>
              Center
            </button>
            <button @click="toggleSatellite" class="map-btn">
              <i class="fas fa-satellite"></i>
              {{ mapMode === 'satellite' ? 'Street' : 'Satellite' }}
            </button>
          </div>
        </div>

        <div class="map-view" ref="mapContainer">
          <!-- Map will be rendered here -->
          <div class="map-placeholder">
            <i class="fas fa-map"></i>
            <p>Interactive map showing device locations</p>
            <div class="map-legend">
              <div class="legend-item">
                <div class="legend-dot online"></div>
                <span>Online</span>
              </div>
              <div class="legend-item">
                <div class="legend-dot offline"></div>
                <span>Offline</span>
              </div>
              <div class="legend-item">
                <div class="legend-dot lost"></div>
                <span>Lost</span>
              </div>
            </div>
          </div>
        </div>

        <div class="device-markers">
          <div 
            v-for="device in devicesWithLocation" 
            :key="device.id"
            @click="selectDevice(device)"
            class="device-marker"
            :class="{ 
              selected: selectedDevice && selectedDevice.id === device.id,
              [device.status]: true 
            }"
          >
            <i :class="getDeviceIcon(device.type)"></i>
            <div class="marker-label">{{ device.name }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Settings Tab -->
    <div v-if="activeTab === 'settings'" class="tab-content">
      <div class="settings-section">
        <h2>Tracking Settings</h2>
        
        <div class="setting-item">
          <div class="setting-info">
            <div class="setting-title">Location Services</div>
            <div class="setting-description">Allow apps to access your location</div>
          </div>
          <label class="toggle-switch">
            <input type="checkbox" v-model="settings.locationEnabled" @change="updateSettings">
            <span class="slider"></span>
          </label>
        </div>

        <div class="setting-item">
          <div class="setting-info">
            <div class="setting-title">Auto-Refresh</div>
            <div class="setting-description">Automatically update device locations</div>
          </div>
          <label class="toggle-switch">
            <input type="checkbox" v-model="settings.autoRefresh" @change="updateSettings">
            <span class="slider"></span>
          </label>
        </div>

        <div class="setting-item">
          <div class="setting-info">
            <div class="setting-title">Sound Alerts</div>
            <div class="setting-description">Play sound when device is found</div>
          </div>
          <label class="toggle-switch">
            <input type="checkbox" v-model="settings.soundAlerts" @change="updateSettings">
            <span class="slider"></span>
          </label>
        </div>

        <div class="setting-item">
          <div class="setting-info">
            <div class="setting-title">Refresh Interval</div>
            <div class="setting-description">How often to update locations</div>
          </div>
          <select v-model="settings.refreshInterval" @change="updateSettings" class="setting-select">
            <option value="30">30 seconds</option>
            <option value="60">1 minute</option>
            <option value="300">5 minutes</option>
            <option value="600">10 minutes</option>
          </select>
        </div>
      </div>

      <div class="settings-section">
        <h2>Privacy & Security</h2>
        
        <div class="setting-item">
          <div class="setting-info">
            <div class="setting-title">Share Location</div>
            <div class="setting-description">Allow others to see your device locations</div>
          </div>
          <label class="toggle-switch">
            <input type="checkbox" v-model="settings.shareLocation" @change="updateSettings">
            <span class="slider"></span>
          </label>
        </div>

        <div class="setting-item">
          <div class="setting-info">
            <div class="setting-title">Lost Mode Notifications</div>
            <div class="setting-description">Send alerts when device is marked as lost</div>
          </div>
          <label class="toggle-switch">
            <input type="checkbox" v-model="settings.lostModeNotifications" @change="updateSettings">
            <span class="slider"></span>
          </label>
        </div>
      </div>

      <div class="settings-section">
        <h2>Data Management</h2>
        
        <button @click="exportData" class="settings-btn">
          <i class="fas fa-download"></i>
          Export Location Data
        </button>
        
        <button @click="clearHistory" class="settings-btn danger">
          <i class="fas fa-trash"></i>
          Clear Location History
        </button>
      </div>
    </div>

    <!-- Add Device Modal -->
    <div v-if="showAddDevice" class="modal-overlay" @click="showAddDevice = false">
      <div class="modal" @click.stop>
        <h3>Add New Device</h3>
        
        <div class="form-group">
          <label>Device Name</label>
          <input 
            v-model="newDevice.name" 
            type="text" 
            placeholder="My iPhone"
            class="form-input"
          />
        </div>
        
        <div class="form-group">
          <label>Device Type</label>
          <select v-model="newDevice.type" class="form-select">
            <option value="phone">Phone</option>
            <option value="tablet">Tablet</option>
            <option value="laptop">Laptop</option>
            <option value="vehicle">Vehicle</option>
            <option value="watch">Watch</option>
            <option value="other">Other</option>
          </select>
        </div>
        
        <div class="form-group">
          <label>Device ID</label>
          <input 
            v-model="newDevice.deviceId" 
            type="text" 
            placeholder="Enter device identifier"
            class="form-input"
          />
        </div>
        
        <div class="modal-actions">
          <button @click="showAddDevice = false" class="cancel-btn">Cancel</button>
          <button @click="addDevice" class="add-btn" :disabled="!canAddDevice">Add Device</button>
        </div>
      </div>
    </div>

    <!-- Device Details Modal -->
    <div v-if="selectedDevice" class="modal-overlay" @click="selectedDevice = null">
      <div class="modal device-modal" @click.stop>
        <div class="device-header">
          <div class="device-icon large">
            <i :class="getDeviceIcon(selectedDevice.type)"></i>
          </div>
          <div class="device-title">
            <h3>{{ selectedDevice.name }}</h3>
            <p>{{ selectedDevice.type }}</p>
          </div>
          <button @click="selectedDevice = null" class="close-btn">
            <i class="fas fa-times"></i>
          </button>
        </div>

        <div class="device-status">
          <div class="status-badge" :class="selectedDevice.status">
            {{ selectedDevice.status.toUpperCase() }}
          </div>
          <div class="battery-info" v-if="selectedDevice.battery">
            <i class="fas fa-battery-three-quarters"></i>
            {{ selectedDevice.battery }}%
          </div>
        </div>

        <div class="device-details">
          <div class="detail-item">
            <span class="label">Last Seen:</span>
            <span class="value">{{ formatLastSeen(selectedDevice.lastSeen) }}</span>
          </div>
          <div class="detail-item" v-if="selectedDevice.location">
            <span class="label">Location:</span>
            <span class="value">{{ selectedDevice.location.address }}</span>
          </div>
          <div class="detail-item" v-if="selectedDevice.location">
            <span class="label">Coordinates:</span>
            <span class="value">{{ selectedDevice.location.lat }}, {{ selectedDevice.location.lng }}</span>
          </div>
        </div>

        <div class="device-actions-modal">
          <button @click="locateDevice(selectedDevice)" class="action-btn-modal locate">
            <i class="fas fa-map-marker-alt"></i>
            Show on Map
          </button>
          <button @click="playSound(selectedDevice)" class="action-btn-modal sound">
            <i class="fas fa-volume-up"></i>
            Play Sound
          </button>
          <button @click="markAsLost(selectedDevice)" class="action-btn-modal lost">
            <i class="fas fa-exclamation-triangle"></i>
            {{ selectedDevice.status === 'lost' ? 'Mark as Found' : 'Mark as Lost' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useStore } from 'vuex'

export default {
  name: 'Finder',
  setup() {
    const store = useStore()
    
    const activeTab = ref('devices')
    const isRefreshing = ref(false)
    const showAddDevice = ref(false)
    const selectedDevice = ref(null)
    const mapMode = ref('street')
    
    const newDevice = ref({
      name: '',
      type: 'phone',
      deviceId: ''
    })
    
    const settings = ref({
      locationEnabled: true,
      autoRefresh: true,
      soundAlerts: true,
      refreshInterval: 60,
      shareLocation: false,
      lostModeNotifications: true
    })
    
    const devices = computed(() => store.state.apps.finder.devices)
    const devicesWithLocation = computed(() => 
      devices.value.filter(device => device.location && device.location.lat && device.location.lng)
    )
    
    const canAddDevice = computed(() => 
      newDevice.value.name.trim() && newDevice.value.deviceId.trim()
    )
    
    const getDeviceIcon = (type) => {
      const icons = {
        phone: 'fas fa-mobile-alt',
        tablet: 'fas fa-tablet-alt',
        laptop: 'fas fa-laptop',
        vehicle: 'fas fa-car',
        watch: 'fas fa-clock',
        other: 'fas fa-microchip'
      }
      return icons[type] || icons.other
    }
    
    const formatLastSeen = (timestamp) => {
      if (!timestamp) return 'Never'
      
      const date = new Date(timestamp)
      const now = new Date()
      const diffMs = now - date
      const diffMins = Math.floor(diffMs / 60000)
      const diffHours = Math.floor(diffMs / 3600000)
      const diffDays = Math.floor(diffMs / 86400000)
      
      if (diffMins < 1) return 'Just now'
      if (diffMins < 60) return `${diffMins}m ago`
      if (diffHours < 24) return `${diffHours}h ago`
      if (diffDays < 7) return `${diffDays}d ago`
      
      return date.toLocaleDateString()
    }
    
    const refreshDevices = async () => {
      isRefreshing.value = true
      try {
        await store.dispatch('apps/refreshDeviceLocations')
      } finally {
        isRefreshing.value = false
      }
    }
    
    const addDevice = async () => {
      if (!canAddDevice.value) return
      
      const deviceData = {
        name: newDevice.value.name.trim(),
        type: newDevice.value.type,
        deviceId: newDevice.value.deviceId.trim()
      }
      
      const result = await store.dispatch('apps/addDevice', deviceData)
      
      if (result.success) {
        newDevice.value = { name: '', type: 'phone', deviceId: '' }
        showAddDevice.value = false
        
        store.dispatch('phone/showNotification', {
          type: 'success',
          title: 'Device Added',
          message: `${deviceData.name} has been added to your devices`
        })
      } else {
        store.dispatch('phone/showNotification', {
          type: 'error',
          title: 'Error',
          message: result.message || 'Failed to add device'
        })
      }
    }
    
    const removeDevice = async (device) => {
      if (confirm(`Remove ${device.name} from your devices?`)) {
        const result = await store.dispatch('apps/removeDevice', device.id)
        
        if (result.success) {
          store.dispatch('phone/showNotification', {
            type: 'success',
            title: 'Device Removed',
            message: `${device.name} has been removed`
          })
        }
      }
    }
    
    const locateDevice = (device) => {
      if (device.status === 'offline') return
      
      selectedDevice.value = device
      activeTab.value = 'map'
      
      // Center map on device location
      if (device.location) {
        // Map centering logic would go here
        console.log('Centering map on:', device.location)
      }
    }
    
    const playSound = async (device) => {
      if (device.status === 'offline') return
      
      const result = await store.dispatch('apps/playDeviceSound', device.id)
      
      if (result.success) {
        store.dispatch('phone/showNotification', {
          type: 'success',
          title: 'Sound Playing',
          message: `Playing sound on ${device.name}`
        })
      } else {
        store.dispatch('phone/showNotification', {
          type: 'error',
          title: 'Error',
          message: result.message || 'Failed to play sound'
        })
      }
    }
    
    const markAsLost = async (device) => {
      const isLost = device.status === 'lost'
      const result = await store.dispatch('apps/toggleDeviceLostStatus', {
        deviceId: device.id,
        isLost: !isLost
      })
      
      if (result.success) {
        store.dispatch('phone/showNotification', {
          type: isLost ? 'success' : 'warning',
          title: isLost ? 'Device Found' : 'Device Marked as Lost',
          message: `${device.name} has been marked as ${isLost ? 'found' : 'lost'}`
        })
      }
    }
    
    const selectDevice = (device) => {
      selectedDevice.value = device
    }
    
    const centerMap = () => {
      // Center map on user's current location
      console.log('Centering map on user location')
    }
    
    const toggleSatellite = () => {
      mapMode.value = mapMode.value === 'street' ? 'satellite' : 'street'
    }
    
    const updateSettings = async () => {
      await store.dispatch('apps/updateFinderSettings', settings.value)
    }
    
    const exportData = async () => {
      const result = await store.dispatch('apps/exportLocationData')
      
      if (result.success) {
        store.dispatch('phone/showNotification', {
          type: 'success',
          title: 'Data Exported',
          message: 'Location data has been exported'
        })
      }
    }
    
    const clearHistory = async () => {
      if (confirm('Clear all location history? This action cannot be undone.')) {
        const result = await store.dispatch('apps/clearLocationHistory')
        
        if (result.success) {
          store.dispatch('phone/showNotification', {
            type: 'success',
            title: 'History Cleared',
            message: 'Location history has been cleared'
          })
        }
      }
    }
    
    // Auto-refresh interval
    let refreshInterval = null
    
    onMounted(async () => {
      await store.dispatch('apps/initializeFinder')
      
      // Set up auto-refresh if enabled
      if (settings.value.autoRefresh) {
        refreshInterval = setInterval(() => {
          refreshDevices()
        }, settings.value.refreshInterval * 1000)
      }
    })
    
    onUnmounted(() => {
      if (refreshInterval) {
        clearInterval(refreshInterval)
      }
    })
    
    return {
      activeTab,
      isRefreshing,
      showAddDevice,
      selectedDevice,
      mapMode,
      newDevice,
      settings,
      devices,
      devicesWithLocation,
      canAddDevice,
      getDeviceIcon,
      formatLastSeen,
      refreshDevices,
      addDevice,
      removeDevice,
      locateDevice,
      playSound,
      markAsLost,
      selectDevice,
      centerMap,
      toggleSatellite,
      updateSettings,
      exportData,
      clearHistory
    }
  }
}
</script>

<style scoped>
.finder-app {
  flex: 1;
  overflow-y: auto;
  background: #000;
  color: #fff;
}

.finder-header {
  background: linear-gradient(135deg, #007aff 0%, #0051d5 100%);
  padding: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.finder-header h1 {
  font-size: 24px;
  font-weight: 600;
  margin: 0;
}

.refresh-btn {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: #fff;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 16px;
  transition: all 0.2s;
}

.refresh-btn:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.3);
  transform: scale(1.1);
}

.refresh-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.nav-tabs {
  display: flex;
  background: #111;
  border-bottom: 1px solid #333;
}

.nav-tab {
  flex: 1;
  padding: 12px 8px;
  background: none;
  border: none;
  color: #999;
  font-size: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.nav-tab.active {
  color: #007aff;
  background: #1a1a1a;
}

.nav-tab i {
  font-size: 16px;
}

.tab-content {
  padding: 20px;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #999;
}

.empty-state i {
  font-size: 48px;
  margin-bottom: 16px;
  color: #333;
}

.empty-state h3 {
  font-size: 20px;
  margin-bottom: 8px;
  color: #fff;
}

.add-device-btn {
  background: #007aff;
  color: #fff;
  border: none;
  padding: 12px 24px;
  border-radius: 25px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  margin-top: 20px;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
}

.add-device-btn:hover {
  background: #0056b3;
  transform: translateY(-1px);
}

.list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.list-header h2 {
  font-size: 20px;
  font-weight: 600;
}

.add-btn {
  background: #007aff;
  color: #fff;
  border: none;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 16px;
  transition: all 0.2s;
}

.add-btn:hover {
  background: #0056b3;
  transform: scale(1.1);
}

.device-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.device-item {
  background: #111;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 16px;
  transition: all 0.2s;
  border-left: 4px solid transparent;
}

.device-item.online {
  border-left-color: #34c759;
}

.device-item.offline {
  border-left-color: #8e8e93;
}

.device-item.lost {
  border-left-color: #ff3b30;
  background: #2a1a1a;
}

.device-item:hover {
  background: #222;
}

.device-icon {
  position: relative;
  width: 50px;
  height: 50px;
  background: #333;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  color: #007aff;
}

.device-icon.large {
  width: 60px;
  height: 60px;
  font-size: 24px;
}

.status-indicator {
  position: absolute;
  bottom: -2px;
  right: -2px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: 2px solid #111;
}

.status-indicator.online {
  background: #34c759;
}

.status-indicator.offline {
  background: #8e8e93;
}

.status-indicator.lost {
  background: #ff3b30;
}

.device-info {
  flex: 1;
}

.device-name {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 4px;
}

.device-type {
  font-size: 14px;
  color: #007aff;
  margin-bottom: 4px;
  text-transform: capitalize;
}

.device-location {
  font-size: 12px;
  color: #999;
  margin-bottom: 2px;
  display: flex;
  align-items: center;
  gap: 4px;
}

.last-seen {
  font-size: 11px;
  color: #666;
}

.device-actions {
  display: flex;
  gap: 8px;
}

.action-btn {
  background: #333;
  border: none;
  color: #fff;
  width: 36px;
  height: 36px;
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.2s;
}

.action-btn:hover:not(:disabled) {
  transform: scale(1.1);
}

.action-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.locate-btn:hover:not(:disabled) {
  background: #007aff;
}

.sound-btn:hover:not(:disabled) {
  background: #34c759;
}

.lost-btn:hover:not(:disabled) {
  background: #ff9500;
}

.lost-btn.active {
  background: #ff3b30;
}

.remove-btn:hover:not(:disabled) {
  background: #ff3b30;
}

.map-container {
  background: #111;
  border-radius: 12px;
  overflow: hidden;
}

.map-header {
  background: #222;
  padding: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.map-header h2 {
  font-size: 18px;
  font-weight: 600;
}

.map-controls {
  display: flex;
  gap: 8px;
}

.map-btn {
  background: #333;
  border: none;
  color: #fff;
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.map-btn:hover {
  background: #444;
}

.map-view {
  height: 300px;
  position: relative;
  background: #1a1a1a;
}

.map-placeholder {
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #666;
}

.map-placeholder i {
  font-size: 48px;
  margin-bottom: 16px;
}

.map-legend {
  display: flex;
  gap: 16px;
  margin-top: 16px;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
}

.legend-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
}

.legend-dot.online {
  background: #34c759;
}

.legend-dot.offline {
  background: #8e8e93;
}

.legend-dot.lost {
  background: #ff3b30;
}

.device-markers {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
}

.device-marker {
  position: absolute;
  background: #007aff;
  color: #fff;
  padding: 8px;
  border-radius: 8px;
  cursor: pointer;
  pointer-events: auto;
  transition: all 0.2s;
  font-size: 12px;
  text-align: center;
  min-width: 60px;
}

.device-marker:hover {
  transform: scale(1.1);
}

.device-marker.selected {
  background: #ff9500;
  transform: scale(1.2);
}

.device-marker.online {
  background: #34c759;
}

.device-marker.offline {
  background: #8e8e93;
}

.device-marker.lost {
  background: #ff3b30;
}

.marker-label {
  margin-top: 4px;
  font-size: 10px;
}

.settings-section {
  margin-bottom: 32px;
}

.settings-section h2 {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 16px;
  color: #007aff;
}

.setting-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 0;
  border-bottom: 1px solid #333;
}

.setting-info {
  flex: 1;
}

.setting-title {
  font-size: 16px;
  font-weight: 500;
  margin-bottom: 4px;
}

.setting-description {
  font-size: 14px;
  color: #999;
}

.toggle-switch {
  position: relative;
  display: inline-block;
  width: 50px;
  height: 28px;
}

.toggle-switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #333;
  transition: 0.3s;
  border-radius: 28px;
}

.slider:before {
  position: absolute;
  content: "";
  height: 20px;
  width: 20px;
  left: 4px;
  bottom: 4px;
  background-color: white;
  transition: 0.3s;
  border-radius: 50%;
}

input:checked + .slider {
  background-color: #007aff;
}

input:checked + .slider:before {
  transform: translateX(22px);
}

.setting-select {
  background: #333;
  border: none;
  color: #fff;
  padding: 8px 12px;
  border-radius: 6px;
  font-size: 14px;
}

.settings-btn {
  background: #333;
  border: none;
  color: #fff;
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
  margin-right: 12px;
  margin-bottom: 12px;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
}

.settings-btn:hover {
  background: #444;
}

.settings-btn.danger {
  background: #ff3b30;
}

.settings-btn.danger:hover {
  background: #d70015;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: #222;
  border-radius: 12px;
  padding: 24px;
  width: 90%;
  max-width: 400px;
  max-height: 80vh;
  overflow-y: auto;
}

.modal h3 {
  margin-bottom: 20px;
  font-size: 20px;
  font-weight: 600;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  margin-bottom: 6px;
  font-size: 14px;
  font-weight: 500;
}

.form-input,
.form-select {
  width: 100%;
  background: #333;
  border: none;
  border-radius: 8px;
  padding: 12px;
  color: #fff;
  font-size: 16px;
}

.form-input:focus,
.form-select:focus {
  outline: 2px solid #007aff;
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 24px;
}

.cancel-btn {
  background: none;
  border: 1px solid #666;
  color: #fff;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}

.cancel-btn:hover {
  background: #333;
}

.device-modal {
  max-width: 500px;
}

.device-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 20px;
  position: relative;
}

.device-title h3 {
  margin: 0 0 4px 0;
  font-size: 20px;
}

.device-title p {
  margin: 0;
  color: #999;
  text-transform: capitalize;
}

.close-btn {
  position: absolute;
  top: 0;
  right: 0;
  background: none;
  border: none;
  color: #999;
  font-size: 18px;
  cursor: pointer;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  transition: all 0.2s;
}

.close-btn:hover {
  background: #333;
  color: #fff;
}

.device-status {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 20px;
}

.status-badge {
  padding: 6px 12px;
  border-radius: 16px;
  font-size: 12px;
  font-weight: 600;
}

.status-badge.online {
  background: #34c759;
  color: #000;
}

.status-badge.offline {
  background: #8e8e93;
  color: #fff;
}

.status-badge.lost {
  background: #ff3b30;
  color: #fff;
}

.battery-info {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #999;
  font-size: 14px;
}

.device-details {
  margin-bottom: 24px;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid #333;
}

.detail-item .label {
  color: #999;
  font-size: 14px;
}

.detail-item .value {
  color: #fff;
  font-size: 14px;
  text-align: right;
}

.device-actions-modal {
  display: flex;
  gap: 12px;
}

.action-btn-modal {
  flex: 1;
  background: #333;
  border: none;
  color: #fff;
  padding: 12px;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  transition: all 0.2s;
}

.action-btn-modal:hover {
  transform: translateY(-2px);
}

.action-btn-modal.locate:hover {
  background: #007aff;
}

.action-btn-modal.sound:hover {
  background: #34c759;
}

.action-btn-modal.lost:hover {
  background: #ff9500;
}

.action-btn-modal i {
  font-size: 18px;
}
</style>