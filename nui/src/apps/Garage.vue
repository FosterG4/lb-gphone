<template>
  <div class="garage-app">
    <div class="app-header">
      <h1>Garage</h1>
      <div class="view-toggle">
        <button 
          :class="{ active: viewMode === 'list' }" 
          @click="viewMode = 'list'"
        >
          <i class="icon-list"></i>
        </button>
        <button 
          :class="{ active: viewMode === 'map' }" 
          @click="viewMode = 'map'"
        >
          <i class="icon-map"></i>
        </button>
      </div>
    </div>

    <!-- List View -->
    <div v-if="viewMode === 'list'" class="vehicle-list">
      <div 
        v-for="vehicle in vehicles" 
        :key="vehicle.plate" 
        class="vehicle-card"
        @click="selectVehicle(vehicle)"
      >
        <div class="vehicle-thumbnail">
          <img 
            :src="getVehicleThumbnail(vehicle.model)" 
            :alt="vehicle.model"
            @error="handleImageError"
          >
          <span 
            class="status-badge" 
            :class="getStatusClass(vehicle.status)"
          >
            {{ vehicle.status }}
          </span>
        </div>
        
        <div class="vehicle-info">
          <h3 class="vehicle-model">{{ formatVehicleName(vehicle.model) }}</h3>
          <p class="vehicle-plate">{{ vehicle.plate }}</p>
          <p class="vehicle-location">
            <i class="icon-location"></i>
            {{ vehicle.location || 'Unknown' }}
          </p>
        </div>

        <div class="vehicle-actions">
          <button 
            v-if="vehicle.status === 'stored' && valetEnabled"
            class="btn-valet"
            @click.stop="requestValet(vehicle)"
            :disabled="valetInProgress"
          >
            <i class="icon-car"></i>
            Valet
          </button>
          <button 
            class="btn-locate"
            @click.stop="locateVehicle(vehicle)"
            :disabled="vehicle.status !== 'out'"
          >
            <i class="icon-pin"></i>
            Locate
          </button>
        </div>
      </div>

      <div v-if="vehicles.length === 0" class="empty-state">
        <i class="icon-car-empty"></i>
        <p>No vehicles found</p>
      </div>
    </div>

    <!-- Map View -->
    <div v-if="viewMode === 'map'" class="map-view">
      <div class="map-container" ref="mapContainer">
        <div 
          v-for="vehicle in vehiclesWithLocation" 
          :key="vehicle.plate"
          class="vehicle-marker"
          :style="getMarkerPosition(vehicle)"
          @click="selectVehicle(vehicle)"
        >
          <div class="marker-icon" :class="getStatusClass(vehicle.status)">
            <i class="icon-car"></i>
          </div>
          <div class="marker-label">{{ vehicle.plate }}</div>
        </div>
      </div>
      
      <div v-if="selectedVehicle" class="vehicle-details-panel">
        <button class="close-btn" @click="selectedVehicle = null">×</button>
        <h3>{{ formatVehicleName(selectedVehicle.model) }}</h3>
        <p class="plate">{{ selectedVehicle.plate }}</p>
        <p class="status">
          Status: 
          <span :class="getStatusClass(selectedVehicle.status)">
            {{ selectedVehicle.status }}
          </span>
        </p>
        <p class="location">
          <i class="icon-location"></i>
          {{ selectedVehicle.location || 'Unknown' }}
        </p>
        
        <div class="panel-actions">
          <button 
            v-if="selectedVehicle.status === 'stored' && valetEnabled"
            class="btn-primary"
            @click="requestValet(selectedVehicle)"
            :disabled="valetInProgress"
          >
            <i class="icon-car"></i>
            Request Valet (${{ valetCost }})
          </button>
          <button 
            v-if="selectedVehicle.status === 'out'"
            class="btn-secondary"
            @click="setWaypoint(selectedVehicle)"
          >
            <i class="icon-waypoint"></i>
            Set Waypoint
          </button>
        </div>
      </div>
    </div>

    <!-- Valet Progress Modal -->
    <div v-if="valetInProgress" class="modal-overlay">
      <div class="modal-content">
        <div class="loading-spinner"></div>
        <h3>Requesting Valet Service</h3>
        <p>Your vehicle is being delivered...</p>
        <p class="countdown">{{ valetCountdown }}s</p>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex';
import { sendNUIMessage } from '../utils/nui';

export default {
  name: 'Garage',
  
  data() {
    return {
      viewMode: 'list', // 'list' or 'map'
      selectedVehicle: null,
      valetInProgress: false,
      valetCountdown: 30,
      valetTimer: null
    };
  },
  
  computed: {
    ...mapState('garage', ['vehicles', 'valetEnabled', 'valetCost']),
    
    vehiclesWithLocation() {
      return this.vehicles.filter(v => 
        v.location_x !== null && 
        v.location_y !== null
      );
    }
  },
  
  mounted() {
    this.loadVehicles();
  },
  
  beforeUnmount() {
    if (this.valetTimer) {
      clearInterval(this.valetTimer);
    }
  },
  
  methods: {
    ...mapActions('garage', ['fetchVehicles', 'requestValetService', 'updateVehicleLocation']),
    
    async loadVehicles() {
      try {
        await this.fetchVehicles();
      } catch (error) {
        console.error('Failed to load vehicles:', error);
        this.$store.dispatch('phone/showNotification', {
          title: 'Garage',
          message: 'Failed to load vehicles',
          type: 'error'
        });
      }
    },
    
    selectVehicle(vehicle) {
      this.selectedVehicle = vehicle;
    },
    
    async requestValet(vehicle) {
      if (this.valetInProgress) return;
      
      // Confirm valet request
      const confirmed = confirm(
        `Request valet service for ${this.formatVehicleName(vehicle.model)}?\nCost: $${this.valetCost}`
      );
      
      if (!confirmed) return;
      
      this.valetInProgress = true;
      this.valetCountdown = 30;
      
      // Start countdown timer
      this.valetTimer = setInterval(() => {
        this.valetCountdown--;
        if (this.valetCountdown <= 0) {
          clearInterval(this.valetTimer);
        }
      }, 1000);
      
      try {
        const result = await this.requestValetService(vehicle.plate);
        
        if (result.success) {
          this.$store.dispatch('phone/showNotification', {
            title: 'Valet Service',
            message: `${this.formatVehicleName(vehicle.model)} is being delivered`,
            type: 'success'
          });
          
          // Reload vehicles after valet
          setTimeout(() => {
            this.loadVehicles();
          }, 2000);
        } else {
          throw new Error(result.message || 'Valet request failed');
        }
      } catch (error) {
        console.error('Valet request failed:', error);
        this.$store.dispatch('phone/showNotification', {
          title: 'Valet Service',
          message: error.message || 'Failed to request valet',
          type: 'error'
        });
      } finally {
        this.valetInProgress = false;
        if (this.valetTimer) {
          clearInterval(this.valetTimer);
          this.valetTimer = null;
        }
      }
    },
    
    locateVehicle(vehicle) {
      if (vehicle.status !== 'out') {
        this.$store.dispatch('phone/showNotification', {
          title: 'Garage',
          message: 'Vehicle must be out to locate',
          type: 'warning'
        });
        return;
      }
      
      // Switch to map view and select vehicle
      this.viewMode = 'map';
      this.selectedVehicle = vehicle;
      
      // Request location update from server
      sendNUIMessage('garage:locateVehicle', { plate: vehicle.plate });
    },
    
    setWaypoint(vehicle) {
      if (!vehicle.location_x || !vehicle.location_y) {
        this.$store.dispatch('phone/showNotification', {
          title: 'Garage',
          message: 'Vehicle location unknown',
          type: 'warning'
        });
        return;
      }
      
      sendNUIMessage('garage:setWaypoint', {
        x: vehicle.location_x,
        y: vehicle.location_y,
        z: vehicle.location_z || 0
      });
      
      this.$store.dispatch('phone/showNotification', {
        title: 'Garage',
        message: 'Waypoint set to vehicle location',
        type: 'success'
      });
    },
    
    getVehicleThumbnail(model) {
      // Return placeholder or actual vehicle image
      return `/assets/vehicles/${model.toLowerCase()}.png`;
    },
    
    handleImageError(event) {
      // Fallback to default vehicle image
      event.target.src = '/assets/vehicles/default.png';
    },
    
    formatVehicleName(model) {
      // Convert model hash/name to readable format
      return model.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
    },
    
    getStatusClass(status) {
      const statusMap = {
        'out': 'status-out',
        'stored': 'status-stored',
        'impounded': 'status-impounded'
      };
      return statusMap[status] || 'status-unknown';
    },
    
    getMarkerPosition(vehicle) {
      // Convert game coordinates to map pixel coordinates
      // This is a simplified version - actual implementation depends on map system
      const mapWidth = 1000;
      const mapHeight = 1000;
      
      // Normalize coordinates (assuming game world is -4000 to 4000)
      const normalizedX = ((vehicle.location_x + 4000) / 8000) * mapWidth;
      const normalizedY = ((vehicle.location_y + 4000) / 8000) * mapHeight;
      
      return {
        left: `${normalizedX}px`,
        top: `${normalizedY}px`
      };
    }
  }
};
</script>

<style scoped>
.garage-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--app-background);
  color: var(--text-primary);
}

.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: var(--header-background);
  border-bottom: 1px solid var(--border-color);
}

.app-header h1 {
  font-size: 1.5rem;
  font-weight: 600;
  margin: 0;
}

.view-toggle {
  display: flex;
  gap: 0.5rem;
}

.view-toggle button {
  padding: 0.5rem 1rem;
  background: var(--button-background);
  border: 1px solid var(--border-color);
  border-radius: 0.5rem;
  color: var(--text-secondary);
  cursor: pointer;
  transition: all 0.2s;
}

.view-toggle button.active {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.vehicle-list {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
}

.vehicle-card {
  display: flex;
  gap: 1rem;
  padding: 1rem;
  background: var(--card-background);
  border-radius: 0.75rem;
  margin-bottom: 1rem;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
}

.vehicle-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.vehicle-thumbnail {
  position: relative;
  width: 100px;
  height: 70px;
  border-radius: 0.5rem;
  overflow: hidden;
  background: var(--thumbnail-background);
}

.vehicle-thumbnail img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.status-badge {
  position: absolute;
  top: 0.25rem;
  right: 0.25rem;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
}

.status-out {
  background: #4CAF50;
  color: white;
}

.status-stored {
  background: #2196F3;
  color: white;
}

.status-impounded {
  background: #F44336;
  color: white;
}

.status-unknown {
  background: #9E9E9E;
  color: white;
}

.vehicle-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.vehicle-model {
  font-size: 1.1rem;
  font-weight: 600;
  margin: 0 0 0.25rem 0;
}

.vehicle-plate {
  font-size: 0.9rem;
  color: var(--text-secondary);
  margin: 0 0 0.5rem 0;
  font-family: monospace;
}

.vehicle-location {
  font-size: 0.85rem;
  color: var(--text-secondary);
  display: flex;
  align-items: center;
  gap: 0.25rem;
  margin: 0;
}

.vehicle-actions {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  justify-content: center;
}

.btn-valet,
.btn-locate {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 0.5rem;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  white-space: nowrap;
}

.btn-valet {
  background: var(--primary-color);
  color: white;
}

.btn-valet:hover:not(:disabled) {
  background: var(--primary-color-dark);
}

.btn-locate {
  background: var(--secondary-color);
  color: white;
}

.btn-locate:hover:not(:disabled) {
  background: var(--secondary-color-dark);
}

.btn-valet:disabled,
.btn-locate:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem;
  color: var(--text-secondary);
}

.empty-state i {
  font-size: 4rem;
  margin-bottom: 1rem;
  opacity: 0.5;
}

.map-view {
  flex: 1;
  position: relative;
  overflow: hidden;
}

.map-container {
  width: 100%;
  height: 100%;
  background: var(--map-background);
  position: relative;
}

.vehicle-marker {
  position: absolute;
  transform: translate(-50%, -50%);
  cursor: pointer;
  z-index: 10;
}

.marker-icon {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1rem;
  color: white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  transition: transform 0.2s;
}

.marker-icon:hover {
  transform: scale(1.2);
}

.marker-label {
  position: absolute;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  margin-top: 0.25rem;
  padding: 0.25rem 0.5rem;
  background: rgba(0, 0, 0, 0.8);
  color: white;
  border-radius: 0.25rem;
  font-size: 0.75rem;
  white-space: nowrap;
}

.vehicle-details-panel {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: var(--card-background);
  padding: 1.5rem;
  border-top-left-radius: 1rem;
  border-top-right-radius: 1rem;
  box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.1);
  z-index: 20;
}

.close-btn {
  position: absolute;
  top: 1rem;
  right: 1rem;
  width: 32px;
  height: 32px;
  border: none;
  background: var(--button-background);
  border-radius: 50%;
  font-size: 1.5rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--text-primary);
}

.vehicle-details-panel h3 {
  margin: 0 0 0.5rem 0;
  font-size: 1.25rem;
}

.vehicle-details-panel .plate {
  font-family: monospace;
  color: var(--text-secondary);
  margin: 0 0 0.5rem 0;
}

.vehicle-details-panel .status,
.vehicle-details-panel .location {
  margin: 0.5rem 0;
  font-size: 0.9rem;
}

.panel-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 1rem;
}

.btn-primary,
.btn-secondary {
  flex: 1;
  padding: 0.75rem;
  border: none;
  border-radius: 0.5rem;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  transition: all 0.2s;
}

.btn-primary {
  background: var(--primary-color);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: var(--primary-color-dark);
}

.btn-secondary {
  background: var(--secondary-color);
  color: white;
}

.btn-secondary:hover:not(:disabled) {
  background: var(--secondary-color-dark);
}

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
  background: var(--card-background);
  padding: 2rem;
  border-radius: 1rem;
  text-align: center;
  max-width: 300px;
}

.loading-spinner {
  width: 50px;
  height: 50px;
  border: 4px solid var(--border-color);
  border-top-color: var(--primary-color);
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.modal-content h3 {
  margin: 0 0 0.5rem 0;
}

.modal-content p {
  margin: 0.5rem 0;
  color: var(--text-secondary);
}

.countdown {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--primary-color);
  margin-top: 1rem !important;
}
</style>
