<template>
  <div class="home-app">
    <div class="app-header">
      <h1>Home</h1>
    </div>

    <div class="app-content">
      <!-- Property List -->
      <div v-if="!selectedProperty" class="property-list">
        <div v-if="properties.length === 0" class="empty-state">
          <p>No properties found</p>
        </div>

        <div
          v-for="property in properties"
          :key="property.id"
          class="property-card"
          @click="selectProperty(property)"
        >
          <div class="property-icon">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
            </svg>
          </div>
          <div class="property-info">
            <h3>{{ property.property_name || 'Property #' + property.property_id }}</h3>
            <p class="property-location">
              {{ formatLocation(property.location_x, property.location_y) }}
            </p>
            <div class="property-status">
              <span :class="['status-badge', property.locked ? 'locked' : 'unlocked']">
                {{ property.locked ? 'Locked' : 'Unlocked' }}
              </span>
            </div>
          </div>
          <div class="property-arrow">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path d="M8.59 16.59L13.17 12 8.59 7.41 10 6l6 6-6 6-1.41-1.41z"/>
            </svg>
          </div>
        </div>
      </div>

      <!-- Property Details -->
      <div v-else class="property-details">
        <button class="back-button" @click="selectedProperty = null">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
            <path d="M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z"/>
          </svg>
          Back
        </button>

        <div class="property-header">
          <h2>{{ selectedProperty.property_name || 'Property #' + selectedProperty.property_id }}</h2>
          <p class="property-id">ID: {{ selectedProperty.property_id }}</p>
        </div>

        <!-- Lock/Unlock Toggle -->
        <div class="lock-section">
          <div class="lock-status">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path v-if="selectedProperty.locked" d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
              <path v-else d="M12 17c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm6-9h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6h1.9c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm0 12H6V10h12v10z"/>
            </svg>
            <span>{{ selectedProperty.locked ? 'Locked' : 'Unlocked' }}</span>
          </div>
          <button 
            class="toggle-lock-button"
            @click="toggleLock"
            :disabled="lockLoading"
          >
            {{ lockLoading ? 'Processing...' : (selectedProperty.locked ? 'Unlock' : 'Lock') }}
          </button>
        </div>

        <!-- Key Management -->
        <div class="key-management">
          <div class="section-header">
            <h3>Key Management</h3>
            <button class="grant-key-button" @click="showGrantKeyModal = true">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/>
              </svg>
              Grant Key
            </button>
          </div>

          <div v-if="propertyKeys.length === 0" class="empty-state">
            <p>No keys granted</p>
          </div>

          <div v-else class="key-list">
            <div
              v-for="key in propertyKeys"
              :key="key.id"
              class="key-item"
            >
              <div class="key-info">
                <h4>{{ key.holder_name || key.holder_number }}</h4>
                <p class="key-granted">Granted {{ formatDate(key.granted_at) }}</p>
                <p v-if="key.expires_at" class="key-expires">
                  Expires {{ formatDate(key.expires_at) }}
                </p>
              </div>
              <button 
                class="revoke-button"
                @click="revokeKey(key.id)"
                :disabled="revokeLoading === key.id"
              >
                {{ revokeLoading === key.id ? '...' : 'Revoke' }}
              </button>
            </div>
          </div>
        </div>

        <!-- Access Logs -->
        <div class="access-logs">
          <h3>Access Logs</h3>
          
          <div v-if="accessLogs.length === 0" class="empty-state">
            <p>No recent access</p>
          </div>

          <div v-else class="log-list">
            <div
              v-for="log in accessLogs"
              :key="log.id"
              class="log-item"
            >
              <div class="log-icon">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                  <path v-if="log.action === 'unlock'" d="M12 17c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm6-9h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6h1.9c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm0 12H6V10h12v10z"/>
                  <path v-else d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
                </svg>
              </div>
              <div class="log-info">
                <p class="log-action">{{ formatAction(log.action) }}</p>
                <p class="log-user">{{ log.user_name || log.user_number }}</p>
                <p class="log-time">{{ formatDate(log.timestamp) }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Grant Key Modal -->
    <div v-if="showGrantKeyModal" class="modal-overlay" @click="closeGrantKeyModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>Grant Key</h3>
          <button class="close-button" @click="closeGrantKeyModal">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
              <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
            </svg>
          </button>
        </div>

        <div class="modal-body">
          <div class="form-group">
            <label>Select Contact</label>
            <select v-model="selectedContact" class="form-control">
              <option value="">-- Select a contact --</option>
              <option 
                v-for="contact in contacts" 
                :key="contact.id"
                :value="contact.phone_number"
              >
                {{ contact.name }} ({{ contact.phone_number }})
              </option>
            </select>
          </div>

          <div class="form-group">
            <label>Expiration (Optional)</label>
            <select v-model="keyExpiration" class="form-control">
              <option value="">Permanent</option>
              <option value="1">1 Hour</option>
              <option value="24">24 Hours</option>
              <option value="168">1 Week</option>
              <option value="720">1 Month</option>
            </select>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn-cancel" @click="closeGrantKeyModal">Cancel</button>
          <button 
            class="btn-confirm" 
            @click="confirmGrantKey"
            :disabled="!selectedContact || grantLoading"
          >
            {{ grantLoading ? 'Granting...' : 'Grant Key' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex';
import { nuiCallback } from '../utils/nui';

export default {
  name: 'Home',
  
  data() {
    return {
      selectedProperty: null,
      lockLoading: false,
      showGrantKeyModal: false,
      selectedContact: '',
      keyExpiration: '',
      grantLoading: false,
      revokeLoading: null,
      propertyKeys: [],
      accessLogs: []
    };
  },
  
  computed: {
    ...mapState('phone', ['phoneNumber']),
    ...mapState('contacts', ['contacts']),
    
    properties() {
      return this.$store.state.home?.properties || [];
    }
  },
  
  watch: {
    selectedProperty(newProperty) {
      if (newProperty) {
        this.loadPropertyKeys();
        this.loadAccessLogs();
      }
    }
  },
  
  mounted() {
    this.loadProperties();
    this.loadContacts();
  },
  
  methods: {
    ...mapActions('contacts', ['fetchContacts']),
    
    async loadProperties() {
      try {
        const response = await nuiCallback('home:getProperties', {});
        
        if (response.success) {
          this.$store.commit('home/SET_PROPERTIES', response.properties || []);
        } else {
          throw new Error(response.message || 'Failed to load properties');
        }
      } catch (error) {
        console.error('Failed to load properties:', error);
        this.$store.dispatch('phone/showNotification', {
          title: 'Home',
          message: 'Failed to load properties',
          type: 'error'
        });
      }
    },
    
    async loadContacts() {
      try {
        await this.fetchContacts();
      } catch (error) {
        console.error('Failed to load contacts:', error);
      }
    },
    
    async loadPropertyKeys() {
      if (!this.selectedProperty) return;
      
      try {
        const response = await nuiCallback('home:getPropertyKeys', {
          propertyId: this.selectedProperty.id
        });
        
        if (response.success) {
          this.propertyKeys = response.keys || [];
        }
      } catch (error) {
        console.error('Failed to load property keys:', error);
      }
    },
    
    async loadAccessLogs() {
      if (!this.selectedProperty) return;
      
      try {
        const response = await nuiCallback('home:getAccessLogs', {
          propertyId: this.selectedProperty.id
        });
        
        if (response.success) {
          this.accessLogs = response.logs || [];
        }
      } catch (error) {
        console.error('Failed to load access logs:', error);
      }
    },
    
    selectProperty(property) {
      this.selectedProperty = property;
    },
    
    async toggleLock() {
      if (this.lockLoading) return;
      
      this.lockLoading = true;
      const action = this.selectedProperty.locked ? 'unlock' : 'lock';
      
      try {
        const response = await nuiCallback('home:toggleLock', {
          propertyId: this.selectedProperty.id,
          action: action
        });
        
        if (response.success) {
          this.selectedProperty.locked = !this.selectedProperty.locked;
          
          // Update in store
          this.$store.commit('home/UPDATE_PROPERTY', {
            id: this.selectedProperty.id,
            updates: { locked: this.selectedProperty.locked }
          });
          
          this.$store.dispatch('phone/showNotification', {
            title: 'Home',
            message: `Property ${action}ed successfully`,
            type: 'success'
          });
          
          // Reload access logs
          this.loadAccessLogs();
        } else {
          throw new Error(response.message || `Failed to ${action} property`);
        }
      } catch (error) {
        console.error('Toggle lock failed:', error);
        this.$store.dispatch('phone/showNotification', {
          title: 'Home',
          message: error.message || 'Failed to toggle lock',
          type: 'error'
        });
      } finally {
        this.lockLoading = false;
      }
    },
    
    closeGrantKeyModal() {
      this.showGrantKeyModal = false;
      this.selectedContact = '';
      this.keyExpiration = '';
    },
    
    async confirmGrantKey() {
      if (!this.selectedContact || this.grantLoading) return;
      
      this.grantLoading = true;
      
      try {
        const response = await nuiCallback('home:grantKey', {
          propertyId: this.selectedProperty.id,
          targetNumber: this.selectedContact,
          expirationHours: this.keyExpiration ? parseInt(this.keyExpiration) : null
        });
        
        if (response.success) {
          this.$store.dispatch('phone/showNotification', {
            title: 'Home',
            message: 'Key granted successfully',
            type: 'success'
          });
          
          this.closeGrantKeyModal();
          this.loadPropertyKeys();
        } else {
          throw new Error(response.message || 'Failed to grant key');
        }
      } catch (error) {
        console.error('Grant key failed:', error);
        this.$store.dispatch('phone/showNotification', {
          title: 'Home',
          message: error.message || 'Failed to grant key',
          type: 'error'
        });
      } finally {
        this.grantLoading = false;
      }
    },
    
    async revokeKey(keyId) {
      const confirmed = confirm('Are you sure you want to revoke this key?');
      if (!confirmed) return;
      
      this.revokeLoading = keyId;
      
      try {
        const response = await nuiCallback('home:revokeKey', {
          keyId: keyId
        });
        
        if (response.success) {
          this.$store.dispatch('phone/showNotification', {
            title: 'Home',
            message: 'Key revoked successfully',
            type: 'success'
          });
          
          this.loadPropertyKeys();
        } else {
          throw new Error(response.message || 'Failed to revoke key');
        }
      } catch (error) {
        console.error('Revoke key failed:', error);
        this.$store.dispatch('phone/showNotification', {
          title: 'Home',
          message: error.message || 'Failed to revoke key',
          type: 'error'
        });
      } finally {
        this.revokeLoading = null;
      }
    },
    
    formatLocation(x, y) {
      if (x === null || y === null) return 'Unknown location';
      return `${Math.round(x)}, ${Math.round(y)}`;
    },
    
    formatDate(dateString) {
      if (!dateString) return 'Unknown';
      
      const date = new Date(dateString);
      const now = new Date();
      const diffMs = now - date;
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMs / 3600000);
      const diffDays = Math.floor(diffMs / 86400000);
      
      if (diffMins < 1) return 'Just now';
      if (diffMins < 60) return `${diffMins}m ago`;
      if (diffHours < 24) return `${diffHours}h ago`;
      if (diffDays < 7) return `${diffDays}d ago`;
      
      return date.toLocaleDateString();
    },
    
    formatAction(action) {
      const actions = {
        'lock': 'Locked',
        'unlock': 'Unlocked',
        'key_grant': 'Key Granted',
        'key_revoke': 'Key Revoked',
        'access': 'Accessed'
      };
      return actions[action] || action;
    }
  }
};
</script>

<style scoped>
.home-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--app-background);
  color: var(--text-primary);
}

.app-header {
  padding: 1rem;
  background: var(--header-background);
  border-bottom: 1px solid var(--border-color);
}

.app-header h1 {
  font-size: 1.5rem;
  font-weight: 600;
  margin: 0;
}

.app-content {
  flex: 1;
  overflow-y: auto;
}

/* Property List */
.property-list {
  padding: 1rem;
}

.property-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: var(--card-background);
  border-radius: 0.75rem;
  margin-bottom: 1rem;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
}

.property-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.property-icon {
  width: 48px;
  height: 48px;
  background: var(--primary-color);
  border-radius: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.property-icon svg {
  width: 28px;
  height: 28px;
}

.property-info {
  flex: 1;
}

.property-info h3 {
  margin: 0 0 0.25rem 0;
  font-size: 1.1rem;
  font-weight: 600;
}

.property-location {
  margin: 0 0 0.5rem 0;
  font-size: 0.85rem;
  color: var(--text-secondary);
}

.property-status {
  display: flex;
  gap: 0.5rem;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 1rem;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
}

.status-badge.locked {
  background: #F44336;
  color: white;
}

.status-badge.unlocked {
  background: #4CAF50;
  color: white;
}

.property-arrow svg {
  width: 24px;
  height: 24px;
  color: var(--text-secondary);
}

.empty-state {
  text-align: center;
  padding: 3rem 1rem;
  color: var(--text-secondary);
}

/* Property Details */
.property-details {
  padding: 1rem;
}

.back-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: var(--button-background);
  border: 1px solid var(--border-color);
  border-radius: 0.5rem;
  color: var(--text-primary);
  cursor: pointer;
  margin-bottom: 1rem;
  font-size: 0.9rem;
  transition: background 0.2s;
}

.back-button:hover {
  background: var(--button-hover-background);
}

.back-button svg {
  width: 20px;
  height: 20px;
}

.property-header {
  margin-bottom: 1.5rem;
}

.property-header h2 {
  margin: 0 0 0.5rem 0;
  font-size: 1.5rem;
  font-weight: 600;
}

.property-id {
  margin: 0;
  font-size: 0.9rem;
  color: var(--text-secondary);
  font-family: monospace;
}

/* Lock Section */
.lock-section {
  background: var(--card-background);
  border-radius: 0.75rem;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.lock-status {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.lock-status svg {
  width: 32px;
  height: 32px;
  color: var(--primary-color);
}

.lock-status span {
  font-size: 1.1rem;
  font-weight: 600;
}

.toggle-lock-button {
  padding: 0.75rem 1.5rem;
  background: var(--primary-color);
  color: white;
  border: none;
  border-radius: 0.5rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.toggle-lock-button:hover:not(:disabled) {
  background: var(--primary-color-dark);
}

.toggle-lock-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Key Management */
.key-management {
  background: var(--card-background);
  border-radius: 0.75rem;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.section-header h3 {
  margin: 0;
  font-size: 1.2rem;
  font-weight: 600;
}

.grant-key-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: var(--primary-color);
  color: white;
  border: none;
  border-radius: 0.5rem;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
}

.grant-key-button:hover {
  background: var(--primary-color-dark);
}

.grant-key-button svg {
  width: 20px;
  height: 20px;
}

.key-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.key-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: var(--background-secondary);
  border-radius: 0.5rem;
}

.key-info h4 {
  margin: 0 0 0.25rem 0;
  font-size: 1rem;
  font-weight: 600;
}

.key-info p {
  margin: 0.25rem 0 0 0;
  font-size: 0.85rem;
  color: var(--text-secondary);
}

.key-granted {
  color: var(--text-secondary);
}

.key-expires {
  color: #FF9800;
}

.revoke-button {
  padding: 0.5rem 1rem;
  background: #F44336;
  color: white;
  border: none;
  border-radius: 0.5rem;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
}

.revoke-button:hover:not(:disabled) {
  background: #D32F2F;
}

.revoke-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Access Logs */
.access-logs {
  background: var(--card-background);
  border-radius: 0.75rem;
  padding: 1.5rem;
}

.access-logs h3 {
  margin: 0 0 1rem 0;
  font-size: 1.2rem;
  font-weight: 600;
}

.log-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  max-height: 300px;
  overflow-y: auto;
}

.log-item {
  display: flex;
  gap: 1rem;
  padding: 0.75rem;
  background: var(--background-secondary);
  border-radius: 0.5rem;
}

.log-icon {
  width: 40px;
  height: 40px;
  background: var(--primary-color-light);
  border-radius: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--primary-color);
  flex-shrink: 0;
}

.log-icon svg {
  width: 24px;
  height: 24px;
}

.log-info {
  flex: 1;
}

.log-action {
  margin: 0 0 0.25rem 0;
  font-weight: 600;
  font-size: 0.95rem;
}

.log-user {
  margin: 0.25rem 0;
  font-size: 0.85rem;
  color: var(--text-secondary);
}

.log-time {
  margin: 0.25rem 0 0 0;
  font-size: 0.75rem;
  color: var(--text-tertiary);
}

/* Modal */
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
  border-radius: 1rem;
  width: 90%;
  max-width: 400px;
  max-height: 80vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid var(--border-color);
}

.modal-header h3 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
}

.close-button {
  width: 32px;
  height: 32px;
  background: var(--button-background);
  border: none;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.2s;
}

.close-button:hover {
  background: var(--button-hover-background);
}

.close-button svg {
  width: 20px;
  height: 20px;
}

.modal-body {
  padding: 1.5rem;
  overflow-y: auto;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group:last-child {
  margin-bottom: 0;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  font-size: 0.9rem;
}

.form-control {
  width: 100%;
  padding: 0.75rem;
  background: var(--input-background);
  border: 1px solid var(--border-color);
  border-radius: 0.5rem;
  color: var(--text-primary);
  font-size: 0.95rem;
}

.form-control:focus {
  outline: none;
  border-color: var(--primary-color);
}

.modal-footer {
  display: flex;
  gap: 0.75rem;
  padding: 1.5rem;
  border-top: 1px solid var(--border-color);
}

.btn-cancel,
.btn-confirm {
  flex: 1;
  padding: 0.75rem;
  border: none;
  border-radius: 0.5rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-cancel {
  background: var(--button-background);
  color: var(--text-primary);
}

.btn-cancel:hover {
  background: var(--button-hover-background);
}

.btn-confirm {
  background: var(--primary-color);
  color: white;
}

.btn-confirm:hover:not(:disabled) {
  background: var(--primary-color-dark);
}

.btn-confirm:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>