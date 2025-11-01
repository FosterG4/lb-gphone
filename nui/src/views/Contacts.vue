<template>
  <div class="contacts-app">
    <!-- Header -->
    <div class="contacts-header">
      <h1 id="contacts-title">Contacts</h1>
      <button 
        class="add-contact-btn" 
        @click="showAddModal = true"
        aria-label="Add new contact"
        aria-describedby="contacts-title"
      >
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M12 5v14m-7-7h14" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
        </svg>
      </button>
    </div>

    <!-- Search Bar -->
    <div class="search-container">
      <div class="search-bar" role="search">
        <svg class="search-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <circle cx="11" cy="11" r="8" stroke="currentColor" stroke-width="2"/>
          <path d="m21 21-4.35-4.35" stroke="currentColor" stroke-width="2"/>
        </svg>
        <input 
          type="text" 
          v-model="searchQuery" 
          placeholder="Search contacts"
          class="search-input"
          aria-label="Search contacts"
          autocomplete="off"
        />
      </div>
    </div>

    <!-- Contacts List -->
    <div class="contacts-list">
      <!-- Nearby Players Section -->
      <NearbyPlayers @player-selected="handlePlayerSelected" />
      
      <!-- My Card -->
      <div class="my-card-section">
        <button 
          class="contact-item my-card" 
          @click="viewContactDetails(myCard)"
          aria-label="View my contact card for LB's Phone"
          role="button"
          tabindex="0"
          @keydown.enter="viewContactDetails(myCard)"
          @keydown.space.prevent="viewContactDetails(myCard)"
        >
          <div class="contact-avatar" aria-hidden="true">
            <span class="avatar-text">LP</span>
          </div>
          <div class="contact-info">
            <div class="contact-name">LB's Phone</div>
            <div class="contact-subtitle">My Card</div>
          </div>
          <svg class="chevron-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <path d="m9 18 6-6-6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
      </div>

      <!-- Alphabetical Sections -->
      <div v-for="(group, letter) in groupedContacts" :key="letter" class="contact-group">
        <div class="section-header" role="heading" aria-level="2">{{ letter }}</div>
        <button 
          v-for="contact in group" 
          :key="contact.id"
          class="contact-item"
          @click="viewContactDetails(contact)"
          :aria-label="`View contact details for ${contact.contact_name}, ${formatPhoneNumber(contact.contact_number)}`"
          role="button"
          tabindex="0"
          @keydown.enter="viewContactDetails(contact)"
          @keydown.space.prevent="viewContactDetails(contact)"
        >
          <div class="contact-avatar" aria-hidden="true">
            <span class="avatar-text">{{ getInitials(contact.contact_name) }}</span>
          </div>
          <div class="contact-info">
            <div class="contact-name">{{ contact.contact_name }}</div>
            <div class="contact-number">{{ formatPhoneNumber(contact.contact_number) }}</div>
          </div>
          <svg class="chevron-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <path d="m9 18 6-6-6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
      </div>
      
      <!-- Empty State -->
      <div v-if="filteredContacts.length === 0 && !searchQuery" class="empty-state">
        <div class="empty-icon">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <circle cx="12" cy="7" r="4" stroke="currentColor" stroke-width="2"/>
          </svg>
        </div>
        <h3>No Contacts</h3>
        <p>Add contacts to get started</p>
      </div>

      <!-- No Search Results -->
      <div v-if="filteredContacts.length === 0 && searchQuery" class="empty-state">
        <div class="empty-icon">
          <svg width="64" height="64" viewBox="0 0 24 24" fill="none">
            <circle cx="11" cy="11" r="8" stroke="currentColor" stroke-width="2"/>
            <path d="m21 21-4.35-4.35" stroke="currentColor" stroke-width="2"/>
          </svg>
        </div>
        <h3>No Results</h3>
        <p>No contacts found for "{{ searchQuery }}"</p>
      </div>
    </div>

    <!-- Bottom Tab Navigation -->
    <nav class="bottom-navigation" role="tablist" aria-label="Phone app navigation">
      <button class="nav-item" role="tab" aria-selected="false" aria-label="Favorites" tabindex="0">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26" stroke="currentColor" stroke-width="2" fill="none"/>
        </svg>
        <span>Favorites</span>
      </button>
      <button class="nav-item" role="tab" aria-selected="false" aria-label="Recent calls" tabindex="0">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
          <polyline points="12,6 12,12 16,14" stroke="currentColor" stroke-width="2"/>
        </svg>
        <span>Recents</span>
      </button>
      <button class="nav-item active" role="tab" aria-selected="true" aria-label="Contacts" tabindex="0">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" stroke="currentColor" stroke-width="2"/>
          <circle cx="12" cy="7" r="4" stroke="currentColor" stroke-width="2"/>
        </svg>
        <span>Contacts</span>
      </button>
      <button class="nav-item" role="tab" aria-selected="false" aria-label="Keypad" tabindex="0">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2" stroke="currentColor" stroke-width="2"/>
          <circle cx="9" cy="9" r="2" stroke="currentColor" stroke-width="2"/>
          <path d="M21 15l-3.086-3.086a2 2 0 0 0-2.828 0L6 21" stroke="currentColor" stroke-width="2"/>
        </svg>
        <span>Keypad</span>
      </button>
      <button class="nav-item" role="tab" aria-selected="false" aria-label="Voicemail" tabindex="0">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" stroke="currentColor" stroke-width="2"/>
        </svg>
        <span>Voicemail</span>
      </button>
    </nav>

    <!-- Share Modal -->
    <ShareModal 
      v-if="selectedPlayer"
      :player="selectedPlayer"
      :visible="showShareModal"
      @close="handleShareModalClose"
      @success="handleShareSuccess"
    />

    <!-- Add Contact Modal -->
    <div v-if="showAddModal" class="modal-overlay" @click="closeModals">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <button @click="closeModals" class="modal-cancel">Cancel</button>
          <h3>New Contact</h3>
          <button @click="saveContact" class="modal-save" :disabled="!canSave">Done</button>
        </div>
        
        <div class="modal-body">
          <div class="contact-photo-section">
            <div class="contact-photo-placeholder">
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" stroke="currentColor" stroke-width="2"/>
                <circle cx="12" cy="7" r="4" stroke="currentColor" stroke-width="2"/>
              </svg>
            </div>
            <button class="add-photo-btn">Add Photo</button>
          </div>

          <div class="form-fields">
            <div class="form-group">
              <input 
                type="text" 
                v-model="formData.name" 
                placeholder="First name"
                class="form-input"
              />
            </div>
            
            <div class="form-group">
              <input 
                type="text" 
                v-model="formData.lastName" 
                placeholder="Last name"
                class="form-input"
              />
            </div>
            
            <div class="form-group">
              <input 
                type="tel" 
                v-model="formData.number" 
                placeholder="Phone"
                class="form-input"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { computed, ref } from 'vue'
import { useStore } from 'vuex'
import NearbyPlayers from '../components/NearbyPlayers.vue'
import ShareModal from '../components/ShareModal.vue'

export default {
  name: 'Contacts',
  
  components: {
    NearbyPlayers,
    ShareModal
  },
  
  setup() {
    const store = useStore()
    
    // State
    const showAddModal = ref(false)
    const showShareModal = ref(false)
    const selectedPlayer = ref(null)
    const formData = ref({
      name: '',
      lastName: '',
      number: ''
    })
    
    // My Card data
    const myCard = {
      id: 'my-card',
      contact_name: "LB's Phone",
      contact_number: '(123) 456-7890',
      isMyCard: true
    }
    
    // Computed
    const searchQuery = computed({
      get: () => store.state.contacts?.searchQuery || '',
      set: (value) => store.commit('contacts/setSearchQuery', value)
    })
    
    const filteredContacts = computed(() => {
      const contacts = store.getters['contacts/filteredContacts'] || []
      return contacts.filter(contact => !contact.isMyCard)
    })

    const groupedContacts = computed(() => {
      const groups = {}
      filteredContacts.value.forEach(contact => {
        const firstLetter = contact.contact_name.charAt(0).toUpperCase()
        if (!groups[firstLetter]) {
          groups[firstLetter] = []
        }
        groups[firstLetter].push(contact)
      })
      
      // Sort groups alphabetically
      const sortedGroups = {}
      Object.keys(groups).sort().forEach(key => {
        sortedGroups[key] = groups[key].sort((a, b) => 
          a.contact_name.localeCompare(b.contact_name)
        )
      })
      
      return sortedGroups
    })

    const canSave = computed(() => {
      return formData.value.name.trim() && formData.value.number.trim()
    })
    
    // Methods
    const getInitials = (name) => {
      return name.split(' ').map(n => n.charAt(0)).join('').toUpperCase().slice(0, 2)
    }

    const formatPhoneNumber = (number) => {
      // Simple phone number formatting
      const cleaned = number.replace(/\D/g, '')
      if (cleaned.length === 10) {
        return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6)}`
      }
      return number
    }

    const viewContactDetails = (contact) => {
      // Navigate to contact details
      store.commit('phone/setCurrentApp', 'contact-details')
      store.commit('contacts/setSelectedContact', contact)
    }
    
    const closeModals = () => {
      showAddModal.value = false
      formData.value = { name: '', lastName: '', number: '' }
    }
    
    const saveContact = async () => {
      if (!canSave.value) return
      
      const fullName = `${formData.value.name.trim()} ${formData.value.lastName.trim()}`.trim()
      
      const response = await store.dispatch('contacts/addContact', {
        name: fullName,
        number: formData.value.number.trim()
      })
      
      if (response?.success) {
        closeModals()
      } else {
        // Handle error
        console.error('Failed to save contact')
      }
    }
    
    const handlePlayerSelected = (player) => {
      selectedPlayer.value = player
      showShareModal.value = true
    }
    
    const handleShareModalClose = () => {
      showShareModal.value = false
      selectedPlayer.value = null
    }
    
    const handleShareSuccess = (data) => {
      // Handle successful share operation
      console.log('Share success:', data)
      
      // Show success notification
      if (data.action === 'share_request') {
        // Show notification that request was sent
        store.dispatch('notifications/show', {
          title: 'Contact Request Sent',
          message: `Request sent to ${data.player.characterName}`,
          type: 'success'
        })
      } else if (data.action === 'add_from_broadcast') {
        // Show notification that contact was added
        store.dispatch('notifications/show', {
          title: 'Contact Added',
          message: `${data.player.characterName} added to contacts`,
          type: 'success'
        })
        
        // Refresh contacts list
        store.dispatch('contacts/fetchContacts')
      }
    }
    
    return {
      searchQuery,
      filteredContacts,
      groupedContacts,
      showAddModal,
      showShareModal,
      selectedPlayer,
      formData,
      myCard,
      canSave,
      getInitials,
      formatPhoneNumber,
      viewContactDetails,
      closeModals,
      saveContact,
      handlePlayerSelected,
      handleShareModalClose,
      handleShareSuccess
    }
  }
}
</script>

<style scoped>
.contacts-app {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: #f2f2f7;
  color: #000;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* Header */
.contacts-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px 8px;
  background: #f2f2f7;
  border-bottom: 1px solid #e5e5ea;
}

.contacts-header h1 {
  font-size: 34px;
  font-weight: 700;
  margin: 0;
  color: #000;
}

.add-contact-btn {
  width: 44px;
  height: 44px;
  border-radius: 22px;
  background: transparent;
  border: none;
  color: #007aff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.2s;
}

.add-contact-btn:hover {
  background: rgba(0, 122, 255, 0.1);
}

/* Search */
.search-container {
  padding: 8px 16px 16px;
  background: #f2f2f7;
}

.search-bar {
  position: relative;
  display: flex;
  align-items: center;
  background: #e5e5ea;
  border-radius: 10px;
  padding: 8px 12px;
}

.search-icon {
  color: #8e8e93;
  margin-right: 8px;
  flex-shrink: 0;
}

.search-input {
  flex: 1;
  border: none;
  background: transparent;
  font-size: 17px;
  color: #000;
  outline: none;
}

.search-input::placeholder {
  color: #8e8e93;
}

/* Contacts List */
.contacts-list {
  flex: 1;
  overflow-y: auto;
  background: #fff;
}

.my-card-section {
  border-bottom: 1px solid #e5e5ea;
  margin-bottom: 20px;
}

.contact-group {
  margin-bottom: 20px;
}

.section-header {
  padding: 8px 20px 4px;
  font-size: 13px;
  font-weight: 600;
  color: #8e8e93;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  background: #f2f2f7;
  border-bottom: 1px solid #e5e5ea;
}

.contact-item {
  display: flex;
  align-items: center;
  padding: 12px 20px;
  background: #fff;
  border-bottom: 1px solid #e5e5ea;
  cursor: pointer;
  transition: background-color 0.2s;
  min-height: 64px;
}

.contact-item:hover {
  background: #f8f8f8;
}

.contact-item:active {
  background: #e5e5ea;
}

.my-card {
  background: #fff;
}

.contact-avatar {
  width: 40px;
  height: 40px;
  border-radius: 20px;
  background: #c7c7cc;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
  flex-shrink: 0;
}

.avatar-text {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
}

.contact-info {
  flex: 1;
  min-width: 0;
}

.contact-name {
  font-size: 17px;
  font-weight: 400;
  color: #000;
  margin-bottom: 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.contact-subtitle,
.contact-number {
  font-size: 15px;
  color: #8e8e93;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.chevron-icon {
  color: #c7c7cc;
  margin-left: 8px;
  flex-shrink: 0;
}

/* Empty State */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 40px;
  text-align: center;
}

.empty-icon {
  margin-bottom: 16px;
  color: #c7c7cc;
}

.empty-state h3 {
  font-size: 20px;
  font-weight: 600;
  color: #000;
  margin: 0 0 8px;
}

.empty-state p {
  font-size: 15px;
  color: #8e8e93;
  margin: 0;
}

/* Bottom Navigation */
.bottom-navigation {
  display: flex;
  background: #f8f8f8;
  border-top: 1px solid #e5e5ea;
  padding: 8px 0 34px;
  justify-content: space-around;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 4px 8px;
  cursor: pointer;
  transition: color 0.2s;
  color: #8e8e93;
  min-width: 44px;
}

.nav-item.active {
  color: #007aff;
}

.nav-item svg {
  margin-bottom: 4px;
}

.nav-item span {
  font-size: 10px;
  font-weight: 500;
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  justify-content: center;
  align-items: flex-start;
  z-index: 1000;
  padding-top: 60px;
}

.modal-content {
  background: #f2f2f7;
  border-radius: 12px;
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
  padding: 16px 20px;
  background: #f2f2f7;
  border-bottom: 1px solid #e5e5ea;
}

.modal-header h3 {
  font-size: 17px;
  font-weight: 600;
  margin: 0;
  color: #000;
}

.modal-cancel,
.modal-save {
  background: none;
  border: none;
  font-size: 17px;
  cursor: pointer;
  padding: 0;
}

.modal-cancel {
  color: #007aff;
}

.modal-save {
  color: #007aff;
  font-weight: 600;
}

.modal-save:disabled {
  color: #c7c7cc;
  cursor: not-allowed;
}

.modal-body {
  flex: 1;
  overflow-y: auto;
  background: #fff;
}

.contact-photo-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 32px 20px;
  background: #f2f2f7;
}

.contact-photo-placeholder {
  width: 100px;
  height: 100px;
  border-radius: 50px;
  background: #e5e5ea;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 12px;
  color: #8e8e93;
}

.add-photo-btn {
  background: none;
  border: none;
  color: #007aff;
  font-size: 17px;
  cursor: pointer;
}

.form-fields {
  background: #fff;
}

.form-group {
  border-bottom: 1px solid #e5e5ea;
}

.form-input {
  width: 100%;
  padding: 16px 20px;
  border: none;
  background: transparent;
  font-size: 17px;
  color: #000;
  outline: none;
}

.form-input::placeholder {
  color: #c7c7cc;
}

/* Responsive Design */
/* Large phones and small tablets */
@media (max-width: 480px) {
  .contacts-header h1 {
    font-size: 30px;
  }
  
  .search-container {
    padding: 10px 16px 18px;
  }
  
  .contact-item {
    padding: 12px 16px;
  }
  
  .contact-avatar {
    width: 36px;
    height: 36px;
  }
  
  .contact-info {
    margin-left: 12px;
  }
  
  .contact-name {
    font-size: 16px;
  }
  
  .contact-number {
    font-size: 13px;
  }
}

/* Small phones */
@media (max-width: 375px) {
  .contacts-header h1 {
    font-size: 28px;
  }
  
  .contact-item {
    padding: 10px 16px;
  }
  
  .search-container {
    padding: 8px 12px 16px;
  }
  
  .contact-avatar {
    width: 32px;
    height: 32px;
  }
  
  .contact-info {
    margin-left: 10px;
  }
  
  .contact-name {
    font-size: 15px;
  }
  
  .contact-number {
    font-size: 12px;
  }
  
  .section-header {
    padding: 6px 16px;
    font-size: 12px;
  }
}

/* Very small phones */
@media (max-width: 320px) {
  .contacts-header {
    padding: 12px 16px;
  }
  
  .contacts-header h1 {
    font-size: 26px;
  }
  
  .search-container {
    padding: 6px 12px 14px;
  }
  
  .search-bar {
    padding: 8px 12px;
  }
  
  .contact-item {
    padding: 8px 12px;
  }
  
  .contact-avatar {
    width: 28px;
    height: 28px;
  }
  
  .contact-info {
    margin-left: 8px;
  }
  
  .contact-name {
    font-size: 14px;
  }
  
  .contact-number {
    font-size: 11px;
  }
  
  .bottom-navigation {
    padding: 8px 0;
  }
  
  .nav-item {
    padding: 4px 8px;
  }
  
  .nav-icon {
    width: 20px;
    height: 20px;
  }
  
  .nav-label {
    font-size: 9px;
  }
}

/* Button styling for accessibility */
.contact-item {
  border: none;
  background: transparent;
  text-align: left;
  width: 100%;
  cursor: pointer;
}

.contact-item:focus {
  outline: 2px solid #007aff;
  outline-offset: -2px;
}

.nav-item {
  border: none;
  background: transparent;
  cursor: pointer;
}

.nav-item:focus {
  outline: 2px solid #007aff;
  outline-offset: -2px;
}

.add-contact-btn:focus {
  outline: 2px solid #007aff;
  outline-offset: 2px;
}

.search-input:focus {
  outline: 2px solid #007aff;
  outline-offset: -2px;
}

/* High contrast mode support */
@media (prefers-contrast: high) {
  .contact-item {
    border: 1px solid;
  }
  
  .nav-item {
    border: 1px solid;
  }
  
  .search-bar {
    border: 2px solid;
  }
}

/* Accessibility */
@media (prefers-reduced-motion: reduce) {
  * {
    transition: none !important;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .contacts-app {
    background: #000;
    color: #fff;
  }
  
  .contacts-header {
    background: #000;
    border-bottom-color: #38383a;
  }
  
  .contacts-header h1 {
    color: #fff;
  }
  
  .search-container {
    background: #000;
  }
  
  .search-bar {
    background: #38383a;
  }
  
  .search-input {
    color: #fff;
  }
  
  .contacts-list {
    background: #1c1c1e;
  }
  
  .section-header {
    background: #000;
    border-bottom-color: #38383a;
  }
  
  .contact-item {
    background: #1c1c1e;
    border-bottom-color: #38383a;
  }
  
  .contact-item:hover {
    background: #2c2c2e;
  }
  
  .contact-name {
    color: #fff;
  }
  
  .bottom-navigation {
    background: #1c1c1e;
    border-top-color: #38383a;
  }
}
</style>
