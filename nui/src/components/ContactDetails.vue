<template>
  <div class="contact-details">
    <!-- Header -->
    <header class="contact-header">
      <button 
        class="back-btn" 
        @click="goBack"
        aria-label="Go back to contacts list"
      >
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="m15 18-6-6 6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        <span>Contacts</span>
      </button>
      <button 
        class="edit-btn" 
        @click="editContact"
        :aria-label="`Edit contact ${contact.contact_name}`"
      >
        Edit
      </button>
    </header>

    <!-- Contact Info -->
    <div class="contact-info-section">
      <div class="contact-avatar-large" aria-hidden="true">
        <span class="avatar-text-large">{{ getInitials(contact.contact_name) }}</span>
      </div>
      <h1 class="contact-name-large" id="contact-name">{{ contact.contact_name }}</h1>
    </div>

    <!-- Broadcast Share Component (only for My Card) -->
    <BroadcastShare 
      v-if="contact.isMyCard"
      :isActive="isBroadcasting"
      :nearbyCount="nearbyPlayersCount"
      :duration="10"
      @stopped="handleBroadcastStopped"
      @expired="handleBroadcastExpired"
    />

    <!-- Action Buttons (hide when broadcasting on My Card) -->
    <div 
      v-if="!contact.isMyCard || !isBroadcasting"
      class="action-buttons" 
      role="group" 
      aria-labelledby="contact-name" 
      aria-label="Contact actions"
    >
      <button 
        v-if="!contact.isMyCard"
        class="action-btn message-btn" 
        @click="sendMessage"
        :aria-label="`Send message to ${contact.contact_name}`"
      >
        <div class="action-icon" aria-hidden="true">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
        <span class="action-label">message</span>
      </button>
      
      <button 
        v-if="!contact.isMyCard"
        class="action-btn call-btn" 
        @click="makeCall"
        :aria-label="`Call ${contact.contact_name} at ${formatPhoneNumber(contact.contact_number)}`"
      >
        <div class="action-icon" aria-hidden="true">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" stroke="currentColor" stroke-width="2"/>
          </svg>
        </div>
        <span class="action-label">call</span>
      </button>
      
      <button 
        v-if="!contact.isMyCard"
        class="action-btn video-btn" 
        @click="videoCall"
        :aria-label="`Video call ${contact.contact_name}`"
      >
        <div class="action-icon" aria-hidden="true">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <polygon points="23 7 16 12 23 17 23 7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <rect x="1" y="5" width="15" height="14" rx="2" ry="2" stroke="currentColor" stroke-width="2"/>
          </svg>
        </div>
        <span class="action-label">video</span>
      </button>
      
      <button 
        class="action-btn share-btn" 
        @click="shareContact"
        :aria-label="contact.isMyCard ? 'Share my contact with nearby players' : `Share contact ${contact.contact_name}`"
      >
        <div class="action-icon" aria-hidden="true">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <polyline points="16,6 12,2 8,6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <line x1="12" y1="2" x2="12" y2="15" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
          </svg>
        </div>
        <span class="action-label">{{ contact.isMyCard ? 'share my contact' : 'share' }}</span>
      </button>
    </div>

    <!-- Contact Details -->
    <div class="contact-details-section">
      <div class="detail-item">
        <div class="detail-label">phone</div>
        <div class="detail-value phone-number" @click="copyNumber">
          {{ formatPhoneNumber(contact.contact_number) }}
        </div>
      </div>
    </div>

    <!-- Related Contacts Section -->
    <div v-if="relatedContacts.length > 0" class="related-contacts-section">
      <div class="section-divider"></div>
      <div class="related-contacts">
        <div 
          v-for="relatedContact in relatedContacts" 
          :key="relatedContact.id"
          class="related-contact-item"
          @click="viewRelatedContact(relatedContact)"
        >
          <div class="related-contact-avatar">
            <span class="avatar-text">{{ getInitials(relatedContact.name) }}</span>
          </div>
          <div class="related-contact-info">
            <div class="related-contact-name">{{ relatedContact.name }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Copy Number Section -->
    <div class="copy-section">
      <div class="section-divider"></div>
      <button 
        class="copy-number-btn" 
        @click="copyNumber"
        :aria-label="`Copy phone number ${formatPhoneNumber(contact.contact_number)} to clipboard`"
      >
        <span>Copy Number</span>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <rect x="9" y="9" width="13" height="13" rx="2" ry="2" stroke="currentColor" stroke-width="2"/>
          <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" stroke="currentColor" stroke-width="2"/>
        </svg>
      </button>
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

    <!-- Toast for copy feedback -->
    <div v-if="showCopyToast" class="copy-toast">
      Number copied to clipboard
    </div>
  </div>
</template>

<script>
import { computed, ref } from 'vue'
import { useStore } from 'vuex'
import BroadcastShare from './BroadcastShare.vue'
import { nuiCallback } from '../utils/nui'

export default {
  name: 'ContactDetails',
  
  components: {
    BroadcastShare
  },
  
  setup() {
    const store = useStore()
    const showCopyToast = ref(false)
    const isBroadcasting = ref(false)
    const nearbyPlayersCount = ref(0)
    
    // Get selected contact from store
    const contact = computed(() => {
      return store.state.contacts?.selectedContact || {
        id: 'default',
        contact_name: "LB's Phone",
        contact_number: '(123) 456-7890'
      }
    })

    // Mock related contacts (in real app, this would come from store)
    const relatedContacts = computed(() => {
      // Return sample related contacts for demo
      return [
        { id: 'related1', name: 'Breze' },
        { id: 'related2', name: 'Loaf Scripts' }
      ]
    })
    
    // Methods
    const getInitials = (name) => {
      return name.split(' ').map(n => n.charAt(0)).join('').toUpperCase().slice(0, 2)
    }

    const formatPhoneNumber = (number) => {
      const cleaned = number.replace(/\D/g, '')
      if (cleaned.length === 10) {
        return `(${cleaned.slice(0, 3)}) ${cleaned.slice(3, 6)}-${cleaned.slice(6)}`
      }
      return number
    }

    const goBack = () => {
      store.commit('phone/setCurrentApp', 'contacts')
    }

    const editContact = () => {
      // Navigate to edit contact screen
      console.log('Edit contact:', contact.value)
    }

    const sendMessage = () => {
      // Navigate to messages with this contact
      store.commit('phone/setCurrentApp', 'messages')
      store.commit('messages/setActiveContact', contact.value)
    }

    const makeCall = () => {
      // Initiate call
      store.commit('phone/setCurrentApp', 'dialer')
      store.dispatch('calls/initiateCall', {
        number: contact.value.contact_number,
        name: contact.value.contact_name
      })
    }

    const videoCall = () => {
      // Initiate video call
      console.log('Video call to:', contact.value.contact_name)
    }

    const shareContact = async () => {
      // For "My Card", start broadcast share
      if (contact.value.isMyCard) {
        await startBroadcastShare()
      } else {
        // For other contacts, share contact (future implementation)
        console.log('Share contact:', contact.value.contact_name)
      }
    }
    
    const startBroadcastShare = async () => {
      if (isBroadcasting.value) return
      
      try {
        const response = await nuiCallback('startBroadcastShare', {})
        
        if (response.success) {
          isBroadcasting.value = true
          // Update nearby count if provided
          if (response.nearbyCount !== undefined) {
            nearbyPlayersCount.value = response.nearbyCount
          }
        } else {
          console.error('Failed to start broadcast:', response.error)
          // Show error notification
          showCopyToast.value = true
          setTimeout(() => {
            showCopyToast.value = false
          }, 2000)
        }
      } catch (error) {
        console.error('Start broadcast error:', error)
      }
    }
    
    const handleBroadcastStopped = () => {
      isBroadcasting.value = false
      nearbyPlayersCount.value = 0
    }
    
    const handleBroadcastExpired = () => {
      isBroadcasting.value = false
      nearbyPlayersCount.value = 0
    }
    
    // Listen for nearby players updates
    window.addEventListener('message', (event) => {
      if (event.data.type === 'nearbyPlayersUpdate' && isBroadcasting.value) {
        nearbyPlayersCount.value = event.data.players?.length || 0
      }
    })

    const copyNumber = async () => {
      try {
        await navigator.clipboard.writeText(contact.value.contact_number)
        showCopyToast.value = true
        setTimeout(() => {
          showCopyToast.value = false
        }, 2000)
      } catch (err) {
        console.error('Failed to copy number:', err)
      }
    }

    const viewRelatedContact = (relatedContact) => {
      // Navigate to related contact details
      console.log('View related contact:', relatedContact.name)
    }
    
    return {
      contact,
      relatedContacts,
      showCopyToast,
      isBroadcasting,
      nearbyPlayersCount,
      getInitials,
      formatPhoneNumber,
      goBack,
      editContact,
      sendMessage,
      makeCall,
      videoCall,
      shareContact,
      copyNumber,
      viewRelatedContact,
      handleBroadcastStopped,
      handleBroadcastExpired
    }
  }
}
</script>

<style scoped>
.contact-details {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: #f2f2f7;
  color: #000;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* Header */
.contact-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  background: #f2f2f7;
  border-bottom: 1px solid #e5e5ea;
}

.back-btn {
  display: flex;
  align-items: center;
  background: none;
  border: none;
  color: #007aff;
  font-size: 17px;
  cursor: pointer;
  padding: 0;
}

.back-btn svg {
  margin-right: 4px;
}

.edit-btn {
  background: none;
  border: none;
  color: #007aff;
  font-size: 17px;
  font-weight: 400;
  cursor: pointer;
  padding: 0;
}

/* Contact Info Section */
.contact-info-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 20px 32px;
  background: #f2f2f7;
}

.contact-avatar-large {
  width: 120px;
  height: 120px;
  border-radius: 60px;
  background: #c7c7cc;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
}

.avatar-text-large {
  font-size: 48px;
  font-weight: 300;
  color: #fff;
}

.contact-name-large {
  font-size: 28px;
  font-weight: 400;
  color: #000;
  margin: 0;
  text-align: center;
}

/* Action Buttons */
.action-buttons {
  display: flex;
  justify-content: space-around;
  padding: 24px 40px 32px;
  background: #f2f2f7;
}

.action-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  background: none;
  border: none;
  cursor: pointer;
  padding: 8px;
  min-width: 60px;
}

.action-icon {
  width: 48px;
  height: 48px;
  border-radius: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 8px;
  transition: background-color 0.2s;
}

.message-btn .action-icon {
  background: #007aff;
  color: #fff;
}

.call-btn .action-icon {
  background: #34c759;
  color: #fff;
}

.video-btn .action-icon {
  background: #007aff;
  color: #fff;
}

.share-btn .action-icon {
  background: #8e8e93;
  color: #fff;
}

.action-icon:hover {
  opacity: 0.8;
}

.action-label {
  font-size: 12px;
  color: #007aff;
  font-weight: 400;
}

/* Contact Details Section */
.contact-details-section {
  background: #fff;
  margin: 0 16px;
  border-radius: 12px;
  overflow: hidden;
}

.detail-item {
  padding: 16px 20px;
  border-bottom: 1px solid #e5e5ea;
}

.detail-item:last-child {
  border-bottom: none;
}

.detail-label {
  font-size: 13px;
  color: #8e8e93;
  margin-bottom: 4px;
  text-transform: lowercase;
}

.detail-value {
  font-size: 17px;
  color: #000;
}

.phone-number {
  color: #007aff;
  cursor: pointer;
}

.phone-number:hover {
  opacity: 0.7;
}

/* Related Contacts Section */
.related-contacts-section {
  margin: 24px 16px 0;
}

.section-divider {
  height: 1px;
  background: #e5e5ea;
  margin: 0 20px;
}

.related-contacts {
  background: #fff;
  border-radius: 12px;
  overflow: hidden;
  margin-top: 24px;
}

.related-contact-item {
  display: flex;
  align-items: center;
  padding: 12px 20px;
  border-bottom: 1px solid #e5e5ea;
  cursor: pointer;
  transition: background-color 0.2s;
}

.related-contact-item:last-child {
  border-bottom: none;
}

.related-contact-item:hover {
  background: #f8f8f8;
}

.related-contact-avatar {
  width: 32px;
  height: 32px;
  border-radius: 16px;
  background: #c7c7cc;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 12px;
}

.related-contact-avatar .avatar-text {
  font-size: 12px;
  font-weight: 600;
  color: #fff;
}

.related-contact-name {
  font-size: 17px;
  color: #000;
}

/* Copy Section */
.copy-section {
  margin: 24px 16px 0;
}

.copy-number-btn {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  padding: 16px 20px;
  background: #fff;
  border: none;
  border-radius: 12px;
  font-size: 17px;
  color: #000;
  cursor: pointer;
  transition: background-color 0.2s;
  margin-top: 24px;
}

.copy-number-btn:hover {
  background: #f8f8f8;
}

.copy-number-btn svg {
  color: #8e8e93;
}

/* Bottom Navigation */
.bottom-navigation {
  display: flex;
  background: #f8f8f8;
  border-top: 1px solid #e5e5ea;
  padding: 8px 0 34px;
  justify-content: space-around;
  margin-top: auto;
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

/* Copy Toast */
.copy-toast {
  position: fixed;
  bottom: 120px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(0, 0, 0, 0.8);
  color: #fff;
  padding: 12px 20px;
  border-radius: 20px;
  font-size: 15px;
  z-index: 1000;
  animation: fadeInOut 2s ease-in-out;
}

@keyframes fadeInOut {
  0%, 100% { opacity: 0; transform: translateX(-50%) translateY(10px); }
  10%, 90% { opacity: 1; transform: translateX(-50%) translateY(0); }
}

/* Responsive Design */
/* Large phones and small tablets */
@media (max-width: 480px) {
  .contact-info-section {
    padding: 36px 24px 28px;
  }
  
  .contact-avatar-large {
    width: 110px;
    height: 110px;
    border-radius: 55px;
  }
  
  .avatar-text-large {
    font-size: 44px;
  }
  
  .contact-name-large {
    font-size: 26px;
    margin-top: 16px;
  }
  
  .action-buttons {
    padding: 24px 36px 28px;
    gap: 24px;
  }
  
  .action-btn {
    width: 60px;
    height: 60px;
  }
  
  .action-btn svg {
    width: 24px;
    height: 24px;
  }
  
  .action-label {
    font-size: 12px;
    margin-top: 6px;
  }
}

/* Small phones */
@media (max-width: 375px) {
  .contact-info-section {
    padding: 32px 20px 24px;
  }
  
  .contact-avatar-large {
    width: 100px;
    height: 100px;
    border-radius: 50px;
  }
  
  .avatar-text-large {
    font-size: 40px;
  }
  
  .contact-name-large {
    font-size: 24px;
  }
  
  .action-buttons {
    padding: 20px 32px 24px;
  }
  
  .action-btn {
    width: 56px;
    height: 56px;
  }
  
  .action-btn svg {
    width: 22px;
    height: 22px;
  }
  
  .action-label {
    font-size: 11px;
  }
  
  .contact-details-section,
  .related-contacts {
    margin: 16px 0;
  }
  
  .detail-item,
  .related-contact-item {
    padding: 12px 20px;
  }
}

/* Very small phones */
@media (max-width: 320px) {
  .contact-header {
    padding: 12px 16px;
  }
  
  .contact-info-section {
    padding: 28px 16px 20px;
  }
  
  .contact-avatar-large {
    width: 90px;
    height: 90px;
    border-radius: 45px;
  }
  
  .avatar-text-large {
    font-size: 36px;
  }
  
  .contact-name-large {
    font-size: 22px;
    margin-top: 12px;
  }
  
  .action-buttons {
    padding: 16px 24px 20px;
    gap: 16px;
  }
  
  .action-btn {
    width: 52px;
    height: 52px;
  }
  
  .action-btn svg {
    width: 20px;
    height: 20px;
  }
  
  .action-label {
    font-size: 10px;
    margin-top: 4px;
  }
  
  .contact-details-section,
  .related-contacts {
    margin: 12px 0;
  }
  
  .detail-item,
  .related-contact-item {
    padding: 10px 16px;
  }
  
  .detail-label,
  .related-contact-name {
    font-size: 15px;
  }
  
  .detail-value,
  .related-contact-number {
    font-size: 14px;
  }
  
  .copy-number-btn {
    padding: 12px 16px;
    font-size: 15px;
    margin-top: 16px;
  }
  
  .bottom-navigation {
    padding: 6px 0 28px;
  }
  
  .nav-item {
    padding: 3px 6px;
  }
  
  .nav-item svg {
    width: 20px;
    height: 20px;
  }
  
  .nav-item span {
    font-size: 9px;
  }
}

/* Button styling for accessibility */
.back-btn,
.edit-btn,
.action-btn,
.copy-number-btn {
  border: none;
  background: transparent;
  cursor: pointer;
}

.back-btn:focus,
.edit-btn:focus,
.action-btn:focus,
.copy-number-btn:focus {
  outline: 2px solid #007aff;
  outline-offset: 2px;
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

/* High contrast mode support */
@media (prefers-contrast: high) {
  .action-btn,
  .copy-number-btn,
  .nav-item {
    border: 1px solid;
  }
  
  .contact-avatar-large {
    border: 2px solid;
  }
}

/* Accessibility */
@media (prefers-reduced-motion: reduce) {
  * {
    transition: none !important;
    animation: none !important;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .contact-details {
    background: #000;
    color: #fff;
  }
  
  .contact-header {
    background: #000;
    border-bottom-color: #38383a;
  }
  
  .contact-info-section {
    background: #000;
  }
  
  .contact-name-large {
    color: #fff;
  }
  
  .contact-details-section,
  .related-contacts,
  .copy-number-btn {
    background: #1c1c1e;
  }
  
  .detail-item,
  .related-contact-item {
    border-bottom-color: #38383a;
  }
  
  .detail-value,
  .related-contact-name {
    color: #fff;
  }
  
  .copy-number-btn:hover,
  .related-contact-item:hover {
    background: #2c2c2e;
  }
  
  .bottom-navigation {
    background: #1c1c1e;
    border-top-color: #38383a;
  }
}
</style>