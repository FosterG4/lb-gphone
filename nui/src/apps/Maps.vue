<template>
  <div class="maps-app">
    <div class="maps-header">
      <h1>Maps</h1>
      <button class="add-pin-button" @click="showPinForm = true">
        + Add Pin
      </button>
    </div>

    <div class="maps-content">
      <!-- Map Display -->
      <div class="map-container">
        <div class="map-display" ref="mapDisplay">
          <!-- Player Location Marker -->
          <div 
            v-if="playerLocation"
            class="marker player-marker"
            :style="getMarkerStyle(playerLocation)"
          >
            <div class="marker-icon">📍</div>
            <div class="marker-label">You</div>
          </div>

          <!-- Location Pins -->
          <div 
            v-for="pin in locationPins" 
            :key="pin.id"
            class="marker location-pin"
            :style="getMarkerStyle(pin)"
            @click="selectPin(pin)"
          >
            <div class="marker-icon">📌</div>
            <div class="marker-label">{{ pin.label }}</div>
          </div>

          <!-- Shared Locations -->
          <div 
            v-for="shared in sharedLocations" 
            :key="shared.id"
            class="marker shared-marker"
            :style="getMarkerStyle(shared)"
          >
            <div class="marker-icon">👤</div>
            <div class="marker-label">{{ shared.name }}</div>
          </div>
        </div>
      </div>

      <!-- Controls -->
      <div class="map-controls">
        <button class="control-button" @click="centerOnPlayer">
          <span class="icon">🎯</span>
          Center
        </button>
        <button class="control-button" @click="showPinList = !showPinList">
          <span class="icon">📋</span>
          Pins ({{ locationPins.length }})
        </button>
        <button class="control-button" @click="showShareLocation">
          <span class="icon">📤</span>
          Share
        </button>
      </div>

      <!-- Pin List Panel -->
      <div v-if="showPinList" class="pin-list-panel">
        <div class="panel-header">
          <h3>Saved Locations</h3>
          <button class="close-button" @click="showPinList = false">×</button>
        </div>
        <div class="pin-list">
          <div v-if="locationPins.length === 0" class="empty-state">
            <p>No saved locations</p>
          </div>
          <div 
            v-for="pin in locationPins" 
            :key="pin.id"
            class="pin-item"
            :class="{ selected: selectedPin && selectedPin.id === pin.id }"
          >
            <div class="pin-info" @click="selectPin(pin)">
              <div class="pin-label">{{ pin.label }}</div>
              <div class="pin-coords">{{ formatCoords(pin.x, pin.y) }}</div>
            </div>
            <div class="pin-actions">
              <button class="action-button" @click="setWaypoint(pin)">
                <span class="icon">🧭</span>
              </button>
              <button class="action-button" @click="editPin(pin)">
                <span class="icon">✏️</span>
              </button>
              <button class="action-button delete" @click="deletePin(pin.id)">
                <span class="icon">🗑️</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add/Edit Pin Modal -->
    <div v-if="showPinForm" class="modal-overlay" @click="closePinForm">
      <div class="modal-content" @click.stop>
        <h2>{{ editingPin ? 'Edit Location' : 'Add Location' }}</h2>
        <div class="form-group">
          <label>Label</label>
          <input 
            type="text" 
            v-model="pinForm.label"
            placeholder="Home, Work, etc."
            maxlength="100"
            required
          />
        </div>
        <div class="form-group">
          <label>Use Current Location</label>
          <button 
            class="use-current-button"
            @click="useCurrentLocation"
            :disabled="!playerLocation"
          >
            📍 Use My Location
          </button>
        </div>
        <div class="form-group">
          <label>Coordinates</label>
          <div class="coords-input">
            <input 
              type="number" 
              v-model.number="pinForm.x"
              placeholder="X"
              step="0.01"
              required
            />
            <input 
              type="number" 
              v-model.number="pinForm.y"
              placeholder="Y"
              step="0.01"
              required
            />
          </div>
        </div>
        <div class="form-actions">
          <button class="cancel-button" @click="closePinForm">Cancel</button>
          <button class="save-button" @click="savePin">Save</button>
        </div>
      </div>
    </div>

    <!-- Share Location Modal -->
    <div v-if="showShareModal" class="modal-overlay" @click="closeShareModal">
      <div class="modal-content" @click.stop>
        <h2>Share Location</h2>
        <div class="form-group">
          <label>Select Contact</label>
          <select v-model="shareForm.contactNumber" required>
            <option value="">Choose a contact...</option>
            <option 
              v-for="contact in contacts" 
              :key="contact.id"
              :value="contact.contact_number"
            >
              {{ contact.contact_name }}
            </option>
          </select>
        </div>
        <div class="form-group">
          <label>Duration</label>
          <select v-model.number="shareForm.duration">
            <option :value="300">5 minutes</option>
            <option :value="900">15 minutes</option>
            <option :value="1800">30 minutes</option>
            <option :value="3600">1 hour</option>
          </select>
        </div>
        <div class="form-group">
          <label>Message (Optional)</label>
          <textarea 
            v-model="shareForm.message"
            placeholder="I'm sharing my location with you..."
            maxlength="200"
            rows="3"
          ></textarea>
        </div>
        <div class="form-actions">
          <button class="cancel-button" @click="closeShareModal">Cancel</button>
          <button class="save-button" @click="shareLocation">Share</button>
        </div>
      </div>
    </div>

    <!-- Pin Details Panel -->
    <div v-if="selectedPin && !showPinList" class="pin-details-panel">
      <div class="panel-header">
        <h3>{{ selectedPin.label }}</h3>
        <button class="close-button" @click="selectedPin = null">×</button>
      </div>
      <div class="panel-content">
        <div class="detail-item">
          <span class="detail-label">Coordinates:</span>
          <span class="detail-value">{{ formatCoords(selectedPin.x, selectedPin.y) }}</span>
        </div>
        <div class="detail-actions">
          <button class="action-button-large" @click="setWaypoint(selectedPin)">
            🧭 Set Waypoint
          </button>
          <button class="action-button-large" @click="editPin(selectedPin)">
            ✏️ Edit
          </button>
          <button class="action-button-large delete" @click="deletePin(selectedPin.id)">
            🗑️ Delete
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { fetchNui } from '../utils/nui';

export default {
  name: 'Maps',
  data() {
    return {
      playerLocation: null,
      locationPins: [],
      sharedLocations: [],
      contacts: [],
      selectedPin: null,
      showPinList: false,
      showPinForm: false,
      showShareModal: false,
      editingPin: null,
      pinForm: {
        label: '',
        x: 0,
        y: 0
      },
      shareForm: {
        contactNumber: '',
        duration: 1800,
        message: ''
      },
      mapScale: 1,
      mapOffset: { x: 0, y: 0 },
      locationUpdateInterval: null
    };
  },
  mounted() {
    this.loadData();
    this.startLocationTracking();
  },
  beforeUnmount() {
    this.stopLocationTracking();
  },
  methods: {
    async loadData() {
      try {
        // Load player location
        const locationResponse = await fetchNui('getPlayerLocation');
        if (locationResponse.success) {
          this.playerLocation = locationResponse.location;
        }

        // Load location pins
        const pinsResponse = await fetchNui('getLocationPins');
        if (pinsResponse.success) {
          this.locationPins = pinsResponse.pins || [];
        }

        // Load shared locations
        const sharedResponse = await fetchNui('getSharedLocations');
        if (sharedResponse.success) {
          this.sharedLocations = sharedResponse.locations || [];
        }

        // Load contacts for sharing
        const contactsResponse = await fetchNui('getContacts');
        if (contactsResponse.success) {
          this.contacts = contactsResponse.contacts || [];
        }
      } catch (error) {
        console.error('Failed to load maps data:', error);
      }
    },

    startLocationTracking() {
      // Update player location every 5 seconds
      this.locationUpdateInterval = setInterval(async () => {
        try {
          const response = await fetchNui('getPlayerLocation');
          if (response.success) {
            this.playerLocation = response.location;
          }
        } catch (error) {
          console.error('Failed to update location:', error);
        }
      }, 5000);
    },

    stopLocationTracking() {
      if (this.locationUpdateInterval) {
        clearInterval(this.locationUpdateInterval);
      }
    },

    getMarkerStyle(location) {
      // Convert game coordinates to map display coordinates
      // This is a simplified version - actual implementation would need proper coordinate mapping
      const x = (location.x + 4000) / 8000 * 100; // Normalize to 0-100%
      const y = (location.y + 4000) / 8000 * 100;
      
      return {
        left: `${x}%`,
        top: `${y}%`
      };
    },

    formatCoords(x, y) {
      return `${x.toFixed(2)}, ${y.toFixed(2)}`;
    },

    centerOnPlayer() {
      if (this.playerLocation) {
        // Center map on player location
        // In a real implementation, this would adjust the map view
        console.log('Centering on player location');
      }
    },

    selectPin(pin) {
      this.selectedPin = pin;
      this.showPinList = false;
    },

    async setWaypoint(pin) {
      try {
        const response = await fetchNui('setWaypoint', {
          x: pin.x,
          y: pin.y
        });
        
        if (response.success) {
          // Show success notification
          this.$emit('notification', {
            title: 'Maps',
            message: `Waypoint set to ${pin.label}`,
            icon: 'maps'
          });
        }
      } catch (error) {
        console.error('Failed to set waypoint:', error);
      }
    },

    editPin(pin) {
      this.editingPin = pin;
      this.pinForm = {
        label: pin.label,
        x: pin.x,
        y: pin.y
      };
      this.showPinForm = true;
      this.selectedPin = null;
    },

    async deletePin(pinId) {
      if (!confirm('Are you sure you want to delete this location?')) {
        return;
      }

      try {
        const response = await fetchNui('deleteLocationPin', { pinId });
        
        if (response.success) {
          this.locationPins = this.locationPins.filter(p => p.id !== pinId);
          if (this.selectedPin && this.selectedPin.id === pinId) {
            this.selectedPin = null;
          }
        }
      } catch (error) {
        console.error('Failed to delete pin:', error);
      }
    },

    useCurrentLocation() {
      if (this.playerLocation) {
        this.pinForm.x = this.playerLocation.x;
        this.pinForm.y = this.playerLocation.y;
      }
    },

    async savePin() {
      if (!this.pinForm.label || this.pinForm.x === 0 || this.pinForm.y === 0) {
        alert('Please fill in all fields');
        return;
      }

      try {
        const pinData = {
          label: this.pinForm.label,
          x: this.pinForm.x,
          y: this.pinForm.y
        };

        if (this.editingPin) {
          const response = await fetchNui('updateLocationPin', {
            pinId: this.editingPin.id,
            ...pinData
          });
          
          if (response.success) {
            const index = this.locationPins.findIndex(p => p.id === this.editingPin.id);
            if (index !== -1) {
              this.locationPins[index] = { ...this.locationPins[index], ...response.pin };
            }
          }
        } else {
          const response = await fetchNui('createLocationPin', pinData);
          
          if (response.success) {
            this.locationPins.push(response.pin);
          }
        }

        this.closePinForm();
      } catch (error) {
        console.error('Failed to save pin:', error);
      }
    },

    closePinForm() {
      this.showPinForm = false;
      this.editingPin = null;
      this.pinForm = {
        label: '',
        x: 0,
        y: 0
      };
    },

    showShareLocation() {
      if (!this.playerLocation) {
        alert('Unable to get your current location');
        return;
      }
      this.showShareModal = true;
    },

    async shareLocation() {
      if (!this.shareForm.contactNumber) {
        alert('Please select a contact');
        return;
      }

      try {
        const response = await fetchNui('shareLocation', {
          contactNumber: this.shareForm.contactNumber,
          duration: this.shareForm.duration,
          message: this.shareForm.message,
          x: this.playerLocation.x,
          y: this.playerLocation.y
        });

        if (response.success) {
          this.$emit('notification', {
            title: 'Maps',
            message: 'Location shared successfully',
            icon: 'maps'
          });
          this.closeShareModal();
        }
      } catch (error) {
        console.error('Failed to share location:', error);
      }
    },

    closeShareModal() {
      this.showShareModal = false;
      this.shareForm = {
        contactNumber: '',
        duration: 1800,
        message: ''
      };
    }
  }
};
</script>

<style scoped>
.maps-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--background-color);
  color: var(--text-color);
}

.maps-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid var(--border-color);
}

.maps-header h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.add-pin-button {
  padding: 8px 16px;
  background: var(--primary-color);
  color: white;
  border: none;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}

.maps-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  position: relative;
}

.map-container {
  flex: 1;
  position: relative;
  overflow: hidden;
  background: #1a1a1a;
}

.map-display {
  width: 100%;
  height: 100%;
  position: relative;
  background-image: 
    linear-gradient(rgba(255, 255, 255, 0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.05) 1px, transparent 1px);
  background-size: 50px 50px;
}

.marker {
  position: absolute;
  transform: translate(-50%, -100%);
  cursor: pointer;
  transition: all 0.3s;
}

.marker:hover {
  transform: translate(-50%, -100%) scale(1.2);
}

.marker-icon {
  font-size: 24px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
}

.marker-label {
  position: absolute;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.8);
  color: white;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  white-space: nowrap;
  margin-top: 4px;
}

.player-marker .marker-icon {
  color: #4CAF50;
}

.location-pin .marker-icon {
  color: #FF5722;
}

.shared-marker .marker-icon {
  color: #2196F3;
}

.map-controls {
  display: flex;
  gap: 10px;
  padding: 15px;
  background: var(--card-background);
  border-top: 1px solid var(--border-color);
}

.control-button {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
  padding: 12px;
  background: var(--background-color);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  color: var(--text-color);
  cursor: pointer;
  font-size: 12px;
  transition: all 0.3s;
}

.control-button:hover {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.control-button .icon {
  font-size: 20px;
}

.pin-list-panel,
.pin-details-panel {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  max-height: 50%;
  background: var(--background-color);
  border-top: 1px solid var(--border-color);
  border-radius: 12px 12px 0 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.3);
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  border-bottom: 1px solid var(--border-color);
}

.panel-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
}

.close-button {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--card-background);
  border: none;
  border-radius: 50%;
  color: var(--text-color);
  font-size: 24px;
  cursor: pointer;
}

.pin-list {
  flex: 1;
  overflow-y: auto;
  padding: 10px;
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: var(--text-color);
  opacity: 0.5;
}

.pin-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  background: var(--card-background);
  border-radius: 8px;
  margin-bottom: 10px;
  transition: all 0.3s;
}

.pin-item:hover,
.pin-item.selected {
  background: var(--primary-color);
  color: white;
}

.pin-info {
  flex: 1;
  cursor: pointer;
}

.pin-label {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 4px;
}

.pin-coords {
  font-size: 12px;
  opacity: 0.7;
}

.pin-actions {
  display: flex;
  gap: 8px;
}

.action-button {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--background-color);
  border: 1px solid var(--border-color);
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s;
}

.action-button:hover {
  background: var(--primary-color);
  border-color: var(--primary-color);
}

.action-button.delete:hover {
  background: var(--accent-color);
  border-color: var(--accent-color);
}

.action-button .icon {
  font-size: 16px;
}

.panel-content {
  padding: 20px;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  padding: 12px 0;
  border-bottom: 1px solid var(--border-color);
}

.detail-label {
  font-weight: 600;
  opacity: 0.7;
}

.detail-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 20px;
}

.action-button-large {
  width: 100%;
  padding: 12px;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  color: var(--text-color);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.action-button-large:hover {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.action-button-large.delete:hover {
  background: var(--accent-color);
  border-color: var(--accent-color);
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: var(--background-color);
  padding: 30px;
  border-radius: 12px;
  width: 90%;
  max-width: 400px;
  max-height: 80vh;
  overflow-y: auto;
}

.modal-content h2 {
  margin: 0 0 20px 0;
  font-size: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  font-size: 14px;
}

.form-group input[type="text"],
.form-group input[type="number"],
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 12px;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  color: var(--text-color);
  font-size: 16px;
}

.form-group textarea {
  resize: vertical;
  font-family: inherit;
}

.coords-input {
  display: flex;
  gap: 10px;
}

.coords-input input {
  flex: 1;
}

.use-current-button {
  width: 100%;
  padding: 12px;
  background: var(--primary-color);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}

.use-current-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 30px;
}

.form-actions button {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
}

.cancel-button {
  background: var(--card-background);
  color: var(--text-color);
}

.save-button {
  background: var(--primary-color);
  color: white;
}
</style>
