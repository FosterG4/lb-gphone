<template>
  <div class="safezone-app">
    <!-- Header -->
    <div class="app-header">
      <div class="header-content">
        <h1 class="app-title">SafeZone</h1>
        <p class="app-subtitle">Emergency &amp; Safety</p>
      </div>
      <div class="emergency-status" :class="{ 'active': emergencyActive }">
        <div class="status-indicator"></div>
        <span>{{ emergencyActive ? 'Emergency Active' : 'Safe' }}</span>
      </div>
    </div>

    <!-- Emergency Panic Button -->
    <div class="panic-section">
      <button 
        class="panic-button" 
        :class="{ 'active': emergencyActive, 'countdown': panicCountdown > 0 }"
        @click="handlePanicButton"
        @mousedown="startPanicHold"
        @mouseup="stopPanicHold"
        @mouseleave="stopPanicHold"
      >
        <div class="panic-icon">
          <i class="fas fa-exclamation-triangle"></i>
        </div>
        <div class="panic-text">
          <span v-if="panicCountdown > 0" class="countdown-text">
            Releasing in {{ panicCountdown }}s
          </span>
          <span v-else-if="emergencyActive" class="active-text">
            Emergency Active
          </span>
          <span v-else class="default-text">
            Hold for Emergency
          </span>
        </div>
        <div class="panic-subtitle">
          {{ emergencyActive ? 'Tap to cancel' : 'Hold for 3 seconds' }}
        </div>
      </button>
    </div>

    <!-- Navigation Tabs -->
    <div class="nav-tabs">
      <button 
        v-for="tab in tabs" 
        :key="tab.id"
        class="nav-tab"
        :class="{ 'active': activeTab === tab.id }"
        @click="activeTab = tab.id"
      >
        <i :class="tab.icon"></i>
        <span>{{ tab.label }}</span>
      </button>
    </div>

    <!-- Tab Content -->
    <div class="tab-content">
      <!-- Emergency Contacts Tab -->
      <div v-if="activeTab === 'contacts'" class="contacts-tab">
        <div class="section-header">
          <h3>Emergency Contacts</h3>
          <button class="add-btn" @click="showAddContactModal = true">
            <i class="fas fa-plus"></i>
          </button>
        </div>
        
        <div class="contacts-list">
          <div 
            v-for="contact in emergencyContacts" 
            :key="contact.id"
            class="contact-item"
          >
            <div class="contact-info">
              <div class="contact-name">{{ contact.name }}</div>
              <div class="contact-relation">{{ contact.relation }}</div>
              <div class="contact-number">{{ contact.number }}</div>
            </div>
            <div class="contact-actions">
              <button class="call-btn" @click="callContact(contact)">
                <i class="fas fa-phone"></i>
              </button>
              <button class="edit-btn" @click="editContact(contact)">
                <i class="fas fa-edit"></i>
              </button>
              <button class="delete-btn" @click="deleteContact(contact.id)">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          </div>
        </div>

        <div v-if="emergencyContacts.length === 0" class="empty-state">
          <i class="fas fa-address-book"></i>
          <p>No emergency contacts added</p>
          <button class="add-contact-btn" @click="showAddContactModal = true">
            Add Emergency Contact
          </button>
        </div>
      </div>

      <!-- Quick Dial Tab -->
      <div v-if="activeTab === 'dial'" class="dial-tab">
        <div class="section-header">
          <h3>Emergency Numbers</h3>
        </div>
        
        <div class="emergency-numbers">
          <div 
            v-for="number in emergencyNumbers" 
            :key="number.id"
            class="emergency-number"
            @click="dialEmergencyNumber(number)"
          >
            <div class="number-icon">
              <i :class="number.icon"></i>
            </div>
            <div class="number-info">
              <div class="number-name">{{ number.name }}</div>
              <div class="number-desc">{{ number.description }}</div>
              <div class="number-value">{{ number.number }}</div>
            </div>
            <div class="dial-icon">
              <i class="fas fa-phone"></i>
            </div>
          </div>
        </div>
      </div>

      <!-- Safety Tips Tab -->
      <div v-if="activeTab === 'tips'" class="tips-tab">
        <div class="section-header">
          <h3>Safety Tips</h3>
        </div>
        
        <div class="tips-list">
          <div 
            v-for="tip in safetyTips" 
            :key="tip.id"
            class="tip-item"
            :class="{ 'expanded': expandedTip === tip.id }"
            @click="toggleTip(tip.id)"
          >
            <div class="tip-header">
              <div class="tip-icon">
                <i :class="tip.icon"></i>
              </div>
              <div class="tip-title">{{ tip.title }}</div>
              <div class="tip-toggle">
                <i class="fas fa-chevron-down"></i>
              </div>
            </div>
            <div class="tip-content" v-if="expandedTip === tip.id">
              <p>{{ tip.content }}</p>
              <div v-if="tip.steps" class="tip-steps">
                <ol>
                  <li v-for="step in tip.steps" :key="step">{{ step }}</li>
                </ol>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Settings Tab -->
      <div v-if="activeTab === 'settings'" class="settings-tab">
        <div class="section-header">
          <h3>Safety Settings</h3>
        </div>
        
        <div class="settings-list">
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-name">Auto Emergency Alert</div>
              <div class="setting-desc">Automatically alert contacts during emergency</div>
            </div>
            <div class="setting-control">
              <label class="toggle">
                <input type="checkbox" v-model="settings.autoAlert">
                <span class="slider"></span>
              </label>
            </div>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-name">Location Sharing</div>
              <div class="setting-desc">Share location with emergency contacts</div>
            </div>
            <div class="setting-control">
              <label class="toggle">
                <input type="checkbox" v-model="settings.shareLocation">
                <span class="slider"></span>
              </label>
            </div>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-name">Police Alert</div>
              <div class="setting-desc">Alert police during panic button activation</div>
            </div>
            <div class="setting-control">
              <label class="toggle">
                <input type="checkbox" v-model="settings.policeAlert">
                <span class="slider"></span>
              </label>
            </div>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-name">Silent Mode</div>
              <div class="setting-desc">Send alerts without sound or vibration</div>
            </div>
            <div class="setting-control">
              <label class="toggle">
                <input type="checkbox" v-model="settings.silentMode">
                <span class="slider"></span>
              </label>
            </div>
          </div>
        </div>
        
        <div class="settings-actions">
          <button class="save-settings-btn" @click="saveSettings">
            Save Settings
          </button>
          <button class="test-alert-btn" @click="testEmergencyAlert">
            Test Emergency Alert
          </button>
        </div>
      </div>
    </div>

    <!-- Add Contact Modal -->
    <div v-if="showAddContactModal" class="modal-overlay" @click="closeAddContactModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>{{ editingContact ? 'Edit Contact' : 'Add Emergency Contact' }}</h3>
          <button class="close-btn" @click="closeAddContactModal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>Name</label>
            <input 
              type="text" 
              v-model="contactForm.name" 
              placeholder="Contact name"
              maxlength="50"
            >
          </div>
          <div class="form-group">
            <label>Relation</label>
            <select v-model="contactForm.relation">
              <option value="">Select relation</option>
              <option value="Family">Family</option>
              <option value="Friend">Friend</option>
              <option value="Colleague">Colleague</option>
              <option value="Doctor">Doctor</option>
              <option value="Lawyer">Lawyer</option>
              <option value="Other">Other</option>
            </select>
          </div>
          <div class="form-group">
            <label>Phone Number</label>
            <input 
              type="tel" 
              v-model="contactForm.number" 
              placeholder="Phone number"
              maxlength="15"
            >
          </div>
        </div>
        <div class="modal-footer">
          <button class="cancel-btn" @click="closeAddContactModal">Cancel</button>
          <button class="save-btn" @click="saveContact" :disabled="!isContactFormValid">
            {{ editingContact ? 'Update' : 'Add' }} Contact
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
  name: 'SafeZone',
  setup() {
    const store = useStore()
    
    // Reactive data
    const activeTab = ref('contacts')
    const emergencyActive = ref(false)
    const panicCountdown = ref(0)
    const panicHoldTimer = ref(null)
    const panicCountdownTimer = ref(null)
    const expandedTip = ref(null)
    const showAddContactModal = ref(false)
    const editingContact = ref(null)
    
    // Emergency contacts
    const emergencyContacts = ref([
      {
        id: 1,
        name: 'John Doe',
        relation: 'Family',
        number: '555-0123'
      },
      {
        id: 2,
        name: 'Jane Smith',
        relation: 'Friend',
        number: '555-0456'
      }
    ])
    
    // Contact form
    const contactForm = ref({
      name: '',
      relation: '',
      number: ''
    })
    
    // Settings
    const settings = ref({
      autoAlert: true,
      shareLocation: true,
      policeAlert: true,
      silentMode: false
    })
    
    // Navigation tabs
    const tabs = [
      { id: 'contacts', label: 'Contacts', icon: 'fas fa-address-book' },
      { id: 'dial', label: 'Emergency', icon: 'fas fa-phone' },
      { id: 'tips', label: 'Safety Tips', icon: 'fas fa-shield-alt' },
      { id: 'settings', label: 'Settings', icon: 'fas fa-cog' }
    ]
    
    // Emergency numbers
    const emergencyNumbers = [
      {
        id: 1,
        name: 'Police',
        description: 'Emergency police services',
        number: '911',
        icon: 'fas fa-shield-alt'
      },
      {
        id: 2,
        name: 'Fire Department',
        description: 'Fire and rescue services',
        number: '911',
        icon: 'fas fa-fire-extinguisher'
      },
      {
        id: 3,
        name: 'Medical Emergency',
        description: 'Ambulance and medical services',
        number: '911',
        icon: 'fas fa-ambulance'
      },
      {
        id: 4,
        name: 'Poison Control',
        description: '24/7 poison emergency hotline',
        number: '1-800-222-1222',
        icon: 'fas fa-skull-crossbones'
      }
    ]
    
    // Safety tips
    const safetyTips = [
      {
        id: 1,
        title: 'Personal Safety',
        icon: 'fas fa-user-shield',
        content: 'Always be aware of your surroundings and trust your instincts.',
        steps: [
          'Stay alert and avoid distractions',
          'Keep emergency contacts updated',
          'Share your location with trusted contacts',
          'Avoid isolated areas when alone'
        ]
      },
      {
        id: 2,
        title: 'Home Security',
        icon: 'fas fa-home',
        content: 'Secure your home and create a safety plan for emergencies.',
        steps: [
          'Lock all doors and windows',
          'Install security systems',
          'Have emergency supplies ready',
          'Know all exit routes'
        ]
      },
      {
        id: 3,
        title: 'Vehicle Safety',
        icon: 'fas fa-car',
        content: 'Maintain your vehicle and practice safe driving habits.',
        steps: [
          'Regular vehicle maintenance',
          'Keep emergency kit in car',
          'Plan your route in advance',
          'Avoid driving when tired'
        ]
      }
    ]
    
    // Computed properties
    const isContactFormValid = computed(() => {
      return contactForm.value.name.trim() && 
             contactForm.value.relation && 
             contactForm.value.number.trim()
    })
    
    // Methods
    const handlePanicButton = () => {
      if (emergencyActive.value) {
        cancelEmergency()
      }
    }
    
    const startPanicHold = () => {
      if (emergencyActive.value) return
      
      panicCountdown.value = 3
      panicHoldTimer.value = setTimeout(() => {
        activateEmergency()
      }, 3000)
      
      panicCountdownTimer.value = setInterval(() => {
        panicCountdown.value--
        if (panicCountdown.value <= 0) {
          clearInterval(panicCountdownTimer.value)
        }
      }, 1000)
    }
    
    const stopPanicHold = () => {
      if (panicHoldTimer.value) {
        clearTimeout(panicHoldTimer.value)
        panicHoldTimer.value = null
      }
      if (panicCountdownTimer.value) {
        clearInterval(panicCountdownTimer.value)
        panicCountdownTimer.value = null
      }
      panicCountdown.value = 0
    }
    
    const activateEmergency = () => {
      emergencyActive.value = true
      panicCountdown.value = 0
      
      // Send emergency alert
      store.dispatch('phone/sendEvent', {
        event: 'safezone:activateEmergency',
        data: {
          contacts: emergencyContacts.value,
          settings: settings.value,
          timestamp: Date.now()
        }
      })
      
      // Show notification
      store.dispatch('phone/addNotification', {
        app: 'SafeZone',
        title: 'Emergency Activated',
        message: 'Emergency alert sent to contacts and authorities',
        type: 'emergency'
      })
    }
    
    const cancelEmergency = () => {
      emergencyActive.value = false
      
      // Send cancel alert
      store.dispatch('phone/sendEvent', {
        event: 'safezone:cancelEmergency',
        data: {
          timestamp: Date.now()
        }
      })
      
      // Show notification
      store.dispatch('phone/addNotification', {
        app: 'SafeZone',
        title: 'Emergency Cancelled',
        message: 'Emergency alert has been cancelled',
        type: 'info'
      })
    }
    
    const callContact = (contact) => {
      store.dispatch('phone/sendEvent', {
        event: 'safezone:callContact',
        data: {
          contact: contact
        }
      })
    }
    
    const editContact = (contact) => {
      editingContact.value = contact
      contactForm.value = { ...contact }
      showAddContactModal.value = true
    }
    
    const deleteContact = (contactId) => {
      emergencyContacts.value = emergencyContacts.value.filter(c => c.id !== contactId)
      
      // Save to backend
      store.dispatch('phone/sendEvent', {
        event: 'safezone:deleteContact',
        data: { contactId }
      })
    }
    
    const dialEmergencyNumber = (number) => {
      store.dispatch('phone/sendEvent', {
        event: 'safezone:dialEmergency',
        data: {
          number: number
        }
      })
    }
    
    const toggleTip = (tipId) => {
      expandedTip.value = expandedTip.value === tipId ? null : tipId
    }
    
    const closeAddContactModal = () => {
      showAddContactModal.value = false
      editingContact.value = null
      contactForm.value = {
        name: '',
        relation: '',
        number: ''
      }
    }
    
    const saveContact = () => {
      if (!isContactFormValid.value) return
      
      if (editingContact.value) {
        // Update existing contact
        const index = emergencyContacts.value.findIndex(c => c.id === editingContact.value.id)
        if (index !== -1) {
          emergencyContacts.value[index] = { ...contactForm.value, id: editingContact.value.id }
        }
      } else {
        // Add new contact
        const newContact = {
          ...contactForm.value,
          id: Date.now()
        }
        emergencyContacts.value.push(newContact)
      }
      
      // Save to backend
      store.dispatch('phone/sendEvent', {
        event: 'safezone:saveContact',
        data: {
          contact: contactForm.value,
          isEdit: !!editingContact.value
        }
      })
      
      closeAddContactModal()
    }
    
    const saveSettings = () => {
      store.dispatch('phone/sendEvent', {
        event: 'safezone:saveSettings',
        data: {
          settings: settings.value
        }
      })
      
      store.dispatch('phone/addNotification', {
        app: 'SafeZone',
        title: 'Settings Saved',
        message: 'Safety settings have been updated',
        type: 'success'
      })
    }
    
    const testEmergencyAlert = () => {
      store.dispatch('phone/sendEvent', {
        event: 'safezone:testAlert',
        data: {
          settings: settings.value
        }
      })
      
      store.dispatch('phone/addNotification', {
        app: 'SafeZone',
        title: 'Test Alert Sent',
        message: 'Emergency alert test completed',
        type: 'info'
      })
    }
    
    const loadSafeZoneData = () => {
      store.dispatch('phone/sendEvent', {
        event: 'safezone:getData'
      })
    }
    
    // Lifecycle
    onMounted(() => {
      loadSafeZoneData()
    })
    
    onUnmounted(() => {
      stopPanicHold()
    })
    
    return {
      // Reactive data
      activeTab,
      emergencyActive,
      panicCountdown,
      expandedTip,
      showAddContactModal,
      editingContact,
      emergencyContacts,
      contactForm,
      settings,
      
      // Static data
      tabs,
      emergencyNumbers,
      safetyTips,
      
      // Computed
      isContactFormValid,
      
      // Methods
      handlePanicButton,
      startPanicHold,
      stopPanicHold,
      callContact,
      editContact,
      deleteContact,
      dialEmergencyNumber,
      toggleTip,
      closeAddContactModal,
      saveContact,
      saveSettings,
      testEmergencyAlert
    }
  }
}
</script>

<style scoped>
.safezone-app {
  height: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  overflow-y: auto;
}

.app-header {
  padding: 20px;
  text-align: center;
  background: rgba(0, 0, 0, 0.2);
}

.header-content .app-title {
  font-size: 24px;
  font-weight: bold;
  margin: 0;
}

.header-content .app-subtitle {
  font-size: 14px;
  opacity: 0.8;
  margin: 5px 0 0 0;
}

.emergency-status {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-top: 15px;
  padding: 8px 16px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  font-size: 14px;
}

.emergency-status.active {
  background: rgba(255, 0, 0, 0.3);
  animation: pulse 2s infinite;
}

.status-indicator {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #4ade80;
}

.emergency-status.active .status-indicator {
  background: #ef4444;
}

.panic-section {
  padding: 30px 20px;
  display: flex;
  justify-content: center;
}

.panic-button {
  width: 200px;
  height: 200px;
  border-radius: 50%;
  border: 4px solid rgba(255, 255, 255, 0.3);
  background: linear-gradient(135deg, #ef4444, #dc2626);
  color: white;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.panic-button:hover {
  transform: scale(1.05);
  border-color: rgba(255, 255, 255, 0.5);
}

.panic-button.countdown {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  animation: pulse 1s infinite;
}

.panic-button.active {
  background: linear-gradient(135deg, #10b981, #059669);
}

.panic-icon {
  font-size: 48px;
  margin-bottom: 10px;
}

.panic-text {
  font-size: 16px;
  font-weight: bold;
  text-align: center;
}

.panic-subtitle {
  font-size: 12px;
  opacity: 0.8;
  margin-top: 5px;
  text-align: center;
}

.countdown-text {
  font-size: 18px;
  animation: pulse 1s infinite;
}

.nav-tabs {
  display: flex;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 0;
}

.nav-tab {
  flex: 1;
  padding: 15px 10px;
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.7);
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
}

.nav-tab.active {
  color: white;
  background: rgba(255, 255, 255, 0.1);
}

.nav-tab i {
  font-size: 18px;
}

.nav-tab span {
  font-size: 12px;
}

.tab-content {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-header h3 {
  margin: 0;
  font-size: 18px;
}

.add-btn {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.contacts-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.contact-item {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 15px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.contact-info .contact-name {
  font-weight: bold;
  font-size: 16px;
}

.contact-info .contact-relation {
  font-size: 14px;
  opacity: 0.8;
  margin: 2px 0;
}

.contact-info .contact-number {
  font-size: 14px;
  opacity: 0.7;
}

.contact-actions {
  display: flex;
  gap: 10px;
}

.contact-actions button {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.call-btn {
  background: #10b981;
  color: white;
}

.edit-btn {
  background: #3b82f6;
  color: white;
}

.delete-btn {
  background: #ef4444;
  color: white;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
}

.empty-state i {
  font-size: 48px;
  opacity: 0.5;
  margin-bottom: 15px;
}

.empty-state p {
  opacity: 0.7;
  margin-bottom: 20px;
}

.add-contact-btn {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: white;
  padding: 12px 24px;
  border-radius: 8px;
  cursor: pointer;
}

.emergency-numbers {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.emergency-number {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 15px;
  display: flex;
  align-items: center;
  gap: 15px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.emergency-number:hover {
  background: rgba(255, 255, 255, 0.2);
}

.number-icon {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
}

.number-info {
  flex: 1;
}

.number-info .number-name {
  font-weight: bold;
  font-size: 16px;
}

.number-info .number-desc {
  font-size: 14px;
  opacity: 0.8;
  margin: 2px 0;
}

.number-info .number-value {
  font-size: 14px;
  opacity: 0.7;
}

.dial-icon {
  font-size: 18px;
  opacity: 0.7;
}

.tips-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.tip-item {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.3s ease;
}

.tip-item:hover {
  background: rgba(255, 255, 255, 0.15);
}

.tip-header {
  padding: 15px;
  display: flex;
  align-items: center;
  gap: 15px;
}

.tip-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
}

.tip-title {
  flex: 1;
  font-weight: bold;
  font-size: 16px;
}

.tip-toggle {
  transition: transform 0.3s ease;
}

.tip-item.expanded .tip-toggle {
  transform: rotate(180deg);
}

.tip-content {
  padding: 0 15px 15px 15px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.tip-content p {
  margin: 15px 0;
  opacity: 0.9;
}

.tip-steps {
  margin-top: 15px;
}

.tip-steps ol {
  margin: 0;
  padding-left: 20px;
}

.tip-steps li {
  margin: 8px 0;
  opacity: 0.8;
}

.settings-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
  margin-bottom: 30px;
}

.setting-item {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 15px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.setting-info .setting-name {
  font-weight: bold;
  font-size: 16px;
}

.setting-info .setting-desc {
  font-size: 14px;
  opacity: 0.8;
  margin-top: 2px;
}

.toggle {
  position: relative;
  display: inline-block;
  width: 50px;
  height: 24px;
}

.toggle input {
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
  background-color: rgba(255, 255, 255, 0.3);
  transition: 0.4s;
  border-radius: 24px;
}

.slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: 0.4s;
  border-radius: 50%;
}

input:checked + .slider {
  background-color: #10b981;
}

input:checked + .slider:before {
  transform: translateX(26px);
}

.settings-actions {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.save-settings-btn,
.test-alert-btn {
  padding: 15px;
  border: none;
  border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
}

.save-settings-btn {
  background: #10b981;
  color: white;
}

.test-alert-btn {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: #1f2937;
  border-radius: 12px;
  width: 90%;
  max-width: 400px;
  max-height: 80vh;
  overflow-y: auto;
}

.modal-header {
  padding: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h3 {
  margin: 0;
  color: white;
}

.close-btn {
  background: none;
  border: none;
  color: white;
  font-size: 18px;
  cursor: pointer;
}

.modal-body {
  padding: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  color: white;
  font-weight: bold;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 12px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  font-size: 16px;
}

.form-group input::placeholder {
  color: rgba(255, 255, 255, 0.5);
}

.modal-footer {
  padding: 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  gap: 15px;
}

.cancel-btn,
.save-btn {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
}

.cancel-btn {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.save-btn {
  background: #10b981;
  color: white;
}

.save-btn:disabled {
  background: rgba(255, 255, 255, 0.2);
  opacity: 0.5;
  cursor: not-allowed;
}

@keyframes pulse {
  0% { opacity: 1; }
  50% { opacity: 0.7; }
  100% { opacity: 1; }
}
</style>