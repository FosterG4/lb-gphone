<template>
  <transition name="modal-fade">
    <div v-if="visible" class="modal-overlay" @click="handleOverlayClick" role="dialog" aria-modal="true" aria-labelledby="modal-title">
      <transition name="modal-slide">
        <div v-if="visible" class="modal-content" @click.stop>
          <!-- Modal Header -->
          <div class="modal-header">
            <button 
              class="modal-close" 
              @click="close"
              aria-label="Close modal"
            >
              {{ $t('common.cancel') }}
            </button>
            <h3 id="modal-title" class="modal-title">{{ player.characterName }}</h3>
            <div class="modal-spacer"></div>
          </div>
          
          <!-- Modal Body -->
          <div class="modal-body">
            <!-- Player Card -->
            <div class="player-card">
              <div class="player-avatar-large" aria-hidden="true">
                <span class="avatar-text-large">{{ getInitials(player.characterName) }}</span>
              </div>
              <div class="player-name">{{ player.characterName }}</div>
              <div class="player-distance">{{ formatDistance(player.distance) }} {{ $t('contactSharing.away') }}</div>
            </div>
            
            <!-- Action Buttons -->
            <div class="action-buttons">
              <button 
                v-if="player.isBroadcasting"
                class="action-btn primary"
                @click="handleAddFromBroadcast"
                :disabled="isLoading"
                :aria-label="`Add ${player.characterName} to contacts`"
              >
                <span v-if="!isLoading" class="btn-content">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    <circle cx="12" cy="7" r="4" stroke="currentColor" stroke-width="2"/>
                    <line x1="12" y1="14" x2="12" y2="20" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                    <line x1="9" y1="17" x2="15" y2="17" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                  </svg>
                  {{ $t('contactSharing.addContact') }}
                </span>
                <span v-else class="btn-loading">
                  <span class="spinner"></span>
                  {{ $t('common.loading') }}
                </span>
              </button>
              
              <button 
                v-else
                class="action-btn primary"
                @click="handleSendShareRequest"
                :disabled="isLoading"
                :aria-label="`Send contact share request to ${player.characterName}`"
              >
                <span v-if="!isLoading" class="btn-content">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                    <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    <polyline points="16 6 12 2 8 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    <line x1="12" y1="2" x2="12" y2="15" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                  </svg>
                  {{ $t('contactSharing.shareContact') }}
                </span>
                <span v-else class="btn-loading">
                  <span class="spinner"></span>
                  {{ $t('common.loading') }}
                </span>
              </button>
            </div>
            
            <!-- Error Message -->
            <transition name="error-fade">
              <div v-if="errorMessage" class="error-message" role="alert">
                {{ errorMessage }}
              </div>
            </transition>
          </div>
        </div>
      </transition>
    </div>
  </transition>
</template>

<script>
import { ref, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { nuiCallback } from '../utils/nui'
import { 
  showContactAddedNotification, 
  showShareSuccessNotification,
  showShareErrorNotification 
} from '../utils/notifications'
import { hapticLight, hapticSuccess, hapticError } from '../utils/haptics'

export default {
  name: 'ShareModal',
  
  props: {
    player: {
      type: Object,
      required: true,
      validator: (player) => {
        return player.source !== undefined &&
               player.characterName !== undefined &&
               player.phoneNumber !== undefined &&
               player.distance !== undefined
      }
    },
    visible: {
      type: Boolean,
      default: false
    }
  },
  
  emits: ['close', 'success'],
  
  setup(props, { emit }) {
    const { t } = useI18n()
    const isLoading = ref(false)
    const errorMessage = ref('')
    
    // Methods
    const getInitials = (name) => {
      if (!name) return '?'
      return name
        .split(' ')
        .map(n => n.charAt(0))
        .join('')
        .toUpperCase()
        .slice(0, 2)
    }
    
    const formatDistance = (meters) => {
      if (meters < 1) {
        return '<1m'
      } else if (meters < 10) {
        return `${meters.toFixed(1)}m`
      } else {
        return `${Math.round(meters)}m`
      }
    }
    
    const handleSendShareRequest = async () => {
      if (isLoading.value) return
      
      // Trigger haptic feedback on button press
      hapticLight()
      
      isLoading.value = true
      errorMessage.value = ''
      
      try {
        const response = await nuiCallback('shareContact', {
          targetSource: props.player.source,
          targetName: props.player.characterName,
          targetNumber: props.player.phoneNumber
        })
        
        if (response.success) {
          // Trigger success haptic feedback
          hapticSuccess()
          
          // Show success notification
          showShareSuccessNotification(props.player.characterName)
          
          emit('success', {
            action: 'share_request',
            player: props.player
          })
          close()
        } else {
          handleError(response.error)
        }
      } catch (error) {
        console.error('Share request error:', error)
        handleError('NETWORK_ERROR')
      } finally {
        isLoading.value = false
      }
    }
    
    const handleAddFromBroadcast = async () => {
      if (isLoading.value) return
      
      // Trigger haptic feedback on button press
      hapticLight()
      
      isLoading.value = true
      errorMessage.value = ''
      
      try {
        const response = await nuiCallback('addFromBroadcast', {
          broadcasterNumber: props.player.phoneNumber,
          broadcasterName: props.player.characterName,
          broadcasterSource: props.player.source
        })
        
        if (response.success) {
          // Trigger success haptic feedback
          hapticSuccess()
          
          // Show contact added notification
          showContactAddedNotification(props.player.characterName)
          
          emit('success', {
            action: 'add_from_broadcast',
            player: props.player
          })
          close()
        } else {
          handleError(response.error)
        }
      } catch (error) {
        console.error('Add from broadcast error:', error)
        handleError('NETWORK_ERROR')
      } finally {
        isLoading.value = false
      }
    }
    
    const handleError = (errorCode) => {
      // Trigger error haptic feedback
      hapticError()
      
      const errorMessages = {
        'PLAYER_TOO_FAR': t('contactSharing.tooFarAway'),
        'CONTACT_ALREADY_EXISTS': t('contactSharing.contactExists'),
        'CANNOT_SHARE_WITH_SELF': t('contactSharing.cannotShareSelf'),
        'PHONE_NOT_OPEN': t('contactSharing.phoneNotOpen'),
        'BROADCAST_NOT_ACTIVE': t('errors.serviceUnavailable'),
        'RATE_LIMIT_EXCEEDED': t('contactSharing.rateLimit'),
        'NETWORK_ERROR': t('errors.networkError'),
        'CALLBACK_FAILED': t('errors.operationFailed')
      }
      
      const message = errorMessages[errorCode] || t('errors.unknownError')
      errorMessage.value = message
      
      // Show error notification with retry option
      const retryCallback = errorCode === 'NETWORK_ERROR' || errorCode === 'CALLBACK_FAILED'
        ? () => {
            // Retry the last action
            if (props.player.isBroadcasting) {
              handleAddFromBroadcast()
            } else {
              handleSendShareRequest()
            }
          }
        : null
      
      showShareErrorNotification(message, retryCallback)
      
      // Auto-clear error after 5 seconds
      setTimeout(() => {
        errorMessage.value = ''
      }, 5000)
    }
    
    const close = () => {
      if (!isLoading.value) {
        // Trigger light haptic feedback on close
        hapticLight()
        errorMessage.value = ''
        emit('close')
      }
    }
    
    const handleOverlayClick = () => {
      close()
    }
    
    return {
      isLoading,
      errorMessage,
      getInitials,
      formatDistance,
      handleSendShareRequest,
      handleAddFromBroadcast,
      close,
      handleOverlayClick
    }
  }
}
</script>

<style scoped>
/* Modal Overlay */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  z-index: 9999;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

/* Modal Content */
.modal-content {
  background: #fff;
  border-radius: 20px 20px 0 0;
  width: 100%;
  max-width: 500px;
  max-height: 80vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.15);
}

/* Modal Header */
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #e5e5ea;
  background: #f9f9f9;
}

.modal-close {
  background: none;
  border: none;
  color: #007aff;
  font-size: 17px;
  font-weight: 400;
  cursor: pointer;
  padding: 0;
  min-width: 60px;
  text-align: left;
}

.modal-close:hover {
  opacity: 0.7;
}

.modal-close:focus {
  outline: 2px solid #007aff;
  outline-offset: 2px;
  border-radius: 4px;
}

.modal-title {
  font-size: 17px;
  font-weight: 600;
  color: #000;
  margin: 0;
  text-align: center;
  flex: 1;
}

.modal-spacer {
  min-width: 60px;
}

/* Modal Body */
.modal-body {
  padding: 32px 20px;
  overflow-y: auto;
  flex: 1;
}

/* Player Card */
.player-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 32px;
}

.player-avatar-large {
  width: 100px;
  height: 100px;
  border-radius: 50px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.avatar-text-large {
  font-size: 40px;
  font-weight: 600;
  color: #fff;
}

.player-name {
  font-size: 24px;
  font-weight: 600;
  color: #000;
  margin-bottom: 4px;
  text-align: center;
}

.player-distance {
  font-size: 15px;
  color: #8e8e93;
  text-align: center;
}

/* Action Buttons */
.action-buttons {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.action-btn {
  width: 100%;
  padding: 16px 24px;
  border: none;
  border-radius: 12px;
  font-size: 17px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 56px;
}

.action-btn.primary {
  background: #007aff;
  color: #fff;
}

.action-btn.primary:hover:not(:disabled) {
  background: #0051d5;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 122, 255, 0.3);
}

.action-btn.primary:active:not(:disabled) {
  transform: translateY(0);
  box-shadow: 0 2px 8px rgba(0, 122, 255, 0.2);
}

.action-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.action-btn:focus {
  outline: 2px solid #007aff;
  outline-offset: 2px;
}

.btn-content {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-loading {
  display: flex;
  align-items: center;
  gap: 12px;
}

/* Spinner */
.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Error Message */
.error-message {
  margin-top: 16px;
  padding: 12px 16px;
  background: #ffebee;
  border: 1px solid #ef5350;
  border-radius: 8px;
  color: #c62828;
  font-size: 14px;
  text-align: center;
  line-height: 1.4;
}

/* Transitions */
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.3s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.modal-slide-enter-active {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.modal-slide-leave-active {
  transition: transform 0.25s cubic-bezier(0.4, 0, 1, 1);
}

.modal-slide-enter-from {
  transform: translateY(100%);
}

.modal-slide-leave-to {
  transform: translateY(100%);
}

.error-fade-enter-active,
.error-fade-leave-active {
  transition: all 0.3s ease;
}

.error-fade-enter-from,
.error-fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

/* Responsive Design */
@media (max-width: 480px) {
  .modal-body {
    padding: 28px 20px;
  }
  
  .player-avatar-large {
    width: 90px;
    height: 90px;
  }
  
  .avatar-text-large {
    font-size: 36px;
  }
  
  .player-name {
    font-size: 22px;
  }
  
  .action-btn {
    padding: 14px 20px;
    font-size: 16px;
    min-height: 52px;
  }
}

@media (max-width: 375px) {
  .modal-header {
    padding: 14px 16px;
  }
  
  .modal-body {
    padding: 24px 16px;
  }
  
  .player-card {
    margin-bottom: 28px;
  }
  
  .player-avatar-large {
    width: 80px;
    height: 80px;
  }
  
  .avatar-text-large {
    font-size: 32px;
  }
  
  .player-name {
    font-size: 20px;
  }
  
  .player-distance {
    font-size: 14px;
  }
  
  .action-btn {
    padding: 12px 18px;
    font-size: 15px;
    min-height: 48px;
  }
}

@media (max-width: 320px) {
  .modal-header {
    padding: 12px 12px;
  }
  
  .modal-close {
    font-size: 16px;
    min-width: 50px;
  }
  
  .modal-title {
    font-size: 16px;
  }
  
  .modal-spacer {
    min-width: 50px;
  }
  
  .modal-body {
    padding: 20px 12px;
  }
  
  .player-card {
    margin-bottom: 24px;
  }
  
  .player-avatar-large {
    width: 70px;
    height: 70px;
  }
  
  .avatar-text-large {
    font-size: 28px;
  }
  
  .player-name {
    font-size: 18px;
  }
  
  .player-distance {
    font-size: 13px;
  }
  
  .action-btn {
    padding: 10px 16px;
    font-size: 14px;
    min-height: 44px;
  }
  
  .error-message {
    font-size: 13px;
    padding: 10px 12px;
  }
}

/* High contrast mode support */
@media (prefers-contrast: high) {
  .modal-content {
    border: 2px solid #000;
  }
  
  .action-btn {
    border: 2px solid;
  }
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
  .modal-fade-enter-active,
  .modal-fade-leave-active,
  .modal-slide-enter-active,
  .modal-slide-leave-active,
  .error-fade-enter-active,
  .error-fade-leave-active,
  .action-btn,
  .spinner {
    transition: none !important;
    animation: none !important;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .modal-overlay {
    background: rgba(0, 0, 0, 0.7);
  }
  
  .modal-content {
    background: #1c1c1e;
  }
  
  .modal-header {
    background: #000;
    border-bottom-color: #38383a;
  }
  
  .modal-title,
  .player-name {
    color: #fff;
  }
  
  .error-message {
    background: #3a1f1f;
    border-color: #d32f2f;
    color: #ff6b6b;
  }
}
</style>
