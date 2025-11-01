<template>
  <transition name="slide-down">
    <div v-if="visible" class="share-notification" role="alert" aria-live="assertive">
      <!-- Notification Content -->
      <div class="notification-content">
        <div class="notification-icon" aria-hidden="true">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <circle cx="12" cy="7" r="4" stroke="currentColor" stroke-width="2"/>
          </svg>
        </div>
        
        <div class="notification-text">
          <div class="notification-title">{{ $t('contactSharing.contactRequest') }}</div>
          <div class="notification-message">
            {{ $t('contactSharing.wantsToShare', { name: request.senderName }) }}
          </div>
        </div>
      </div>
      
      <!-- Action Buttons -->
      <div class="notification-actions">
        <button 
          class="notification-btn decline"
          @click="handleDecline"
          :disabled="isProcessing"
          aria-label="Decline contact request"
        >
          {{ $t('contactSharing.decline') }}
        </button>
        
        <button 
          class="notification-btn accept"
          @click="handleAccept"
          :disabled="isProcessing"
          aria-label="Accept contact request"
        >
          {{ $t('contactSharing.accept') }}
        </button>
      </div>
      
      <!-- Timer Progress Bar -->
      <div class="notification-timer" aria-hidden="true">
        <div 
          class="timer-bar" 
          :style="{ width: timerProgress + '%' }"
        ></div>
      </div>
    </div>
  </transition>
</template>

<script>
import { ref, computed, watch, onUnmounted } from 'vue'
import { nuiCallback } from '../utils/nui'
import { 
  showContactAddedNotification,
  showShareDeclinedNotification 
} from '../utils/notifications'
import { hapticNotification, hapticSuccess, hapticLight } from '../utils/haptics'

export default {
  name: 'ShareRequestNotification',
  
  props: {
    request: {
      type: Object,
      required: true,
      validator: (request) => {
        return request.requestId !== undefined &&
               request.senderName !== undefined &&
               request.senderNumber !== undefined &&
               request.expiresAt !== undefined
      }
    },
    visible: {
      type: Boolean,
      default: false
    }
  },
  
  emits: ['accept', 'decline', 'expired'],
  
  setup(props, { emit }) {
    const isProcessing = ref(false)
    const timerProgress = ref(100)
    const timerInterval = ref(null)
    const soundPlayed = ref(false)
    
    // Calculate remaining time
    const remainingTime = computed(() => {
      if (!props.request || !props.request.expiresAt) return 0
      const now = Date.now()
      const remaining = Math.max(0, props.request.expiresAt - now)
      return Math.ceil(remaining / 1000) // Convert to seconds
    })
    
    // Start timer when notification becomes visible
    watch(() => props.visible, (newVisible) => {
      if (newVisible) {
        startTimer()
        playNotificationSound()
      } else {
        stopTimer()
      }
    }, { immediate: true })
    
    // Methods
    const startTimer = () => {
      stopTimer() // Clear any existing timer
      
      const duration = 30000 // 30 seconds in milliseconds
      const startTime = Date.now()
      const expiresAt = props.request?.expiresAt || (startTime + duration)
      
      timerInterval.value = setInterval(() => {
        const now = Date.now()
        const elapsed = now - (expiresAt - duration)
        const progress = Math.max(0, 100 - (elapsed / duration) * 100)
        
        timerProgress.value = progress
        
        // Auto-dismiss when timer expires
        if (progress <= 0 || now >= expiresAt) {
          handleExpired()
        }
      }, 100) // Update every 100ms for smooth animation
    }
    
    const stopTimer = () => {
      if (timerInterval.value) {
        clearInterval(timerInterval.value)
        timerInterval.value = null
      }
    }
    
    const playNotificationSound = () => {
      if (soundPlayed.value) return
      
      try {
        // Trigger notification haptic feedback
        hapticNotification()
        
        // Check if sound is enabled in settings
        const soundEnabled = localStorage.getItem('lb-phone-sound-enabled')
        if (soundEnabled === 'false') return
        
        // Play notification sound
        const audio = new Audio('/sounds/notification.mp3')
        const volume = parseFloat(localStorage.getItem('lb-phone-sound-volume') || '0.5')
        audio.volume = Math.min(1, Math.max(0, volume))
        audio.play().catch(err => {
          console.warn('Could not play notification sound:', err)
        })
        
        soundPlayed.value = true
      } catch (error) {
        console.warn('Error playing notification sound:', error)
      }
    }
    
    const handleAccept = async () => {
      if (isProcessing.value) return
      
      // Trigger haptic feedback on accept
      hapticLight()
      
      isProcessing.value = true
      
      try {
        const response = await nuiCallback('respondToShareRequest', {
          requestId: props.request.requestId,
          accepted: true
        })
        
        if (response.success) {
          // Trigger success haptic feedback
          hapticSuccess()
          
          // Show contact added notification
          showContactAddedNotification(props.request.senderName)
          
          emit('accept', {
            requestId: props.request.requestId,
            senderName: props.request.senderName,
            senderNumber: props.request.senderNumber
          })
        } else {
          console.error('Failed to accept share request:', response.error)
          // Still emit to close notification
          emit('decline', { requestId: props.request.requestId })
        }
      } catch (error) {
        console.error('Error accepting share request:', error)
        emit('decline', { requestId: props.request.requestId })
      } finally {
        isProcessing.value = false
        stopTimer()
      }
    }
    
    const handleDecline = async () => {
      if (isProcessing.value) return
      
      // Trigger haptic feedback on decline
      hapticLight()
      
      isProcessing.value = true
      
      try {
        const response = await nuiCallback('respondToShareRequest', {
          requestId: props.request.requestId,
          accepted: false
        })
        
        emit('decline', {
          requestId: props.request.requestId,
          senderName: props.request.senderName
        })
      } catch (error) {
        console.error('Error declining share request:', error)
        emit('decline', { requestId: props.request.requestId })
      } finally {
        isProcessing.value = false
        stopTimer()
      }
    }
    
    const handleExpired = () => {
      stopTimer()
      emit('expired', {
        requestId: props.request.requestId,
        senderName: props.request.senderName
      })
    }
    
    // Cleanup on unmount
    onUnmounted(() => {
      stopTimer()
    })
    
    return {
      isProcessing,
      timerProgress,
      remainingTime,
      handleAccept,
      handleDecline
    }
  }
}
</script>

<style scoped>
/* Share Notification */
.share-notification {
  position: fixed;
  top: 60px;
  left: 50%;
  transform: translateX(-50%);
  width: calc(100% - 32px);
  max-width: 360px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
  overflow: hidden;
  z-index: 10000;
}

/* Notification Content */
.notification-content {
  display: flex;
  align-items: center;
  padding: 16px;
  gap: 12px;
}

.notification-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.notification-icon svg {
  stroke: #fff;
}

.notification-text {
  flex: 1;
  min-width: 0;
}

.notification-title {
  font-size: 15px;
  font-weight: 600;
  color: #000;
  margin-bottom: 2px;
}

.notification-message {
  font-size: 13px;
  color: #666;
  line-height: 1.3;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Action Buttons */
.notification-actions {
  display: flex;
  border-top: 1px solid rgba(0, 0, 0, 0.1);
}

.notification-btn {
  flex: 1;
  padding: 14px;
  border: none;
  background: none;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s ease;
}

.notification-btn:first-child {
  border-right: 1px solid rgba(0, 0, 0, 0.1);
}

.notification-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.notification-btn:focus {
  outline: 2px solid #007aff;
  outline-offset: -2px;
}

.notification-btn.decline {
  color: #ff3b30;
}

.notification-btn.decline:hover:not(:disabled) {
  background: rgba(255, 59, 48, 0.1);
}

.notification-btn.decline:active:not(:disabled) {
  background: rgba(255, 59, 48, 0.2);
}

.notification-btn.accept {
  color: #007aff;
}

.notification-btn.accept:hover:not(:disabled) {
  background: rgba(0, 122, 255, 0.1);
}

.notification-btn.accept:active:not(:disabled) {
  background: rgba(0, 122, 255, 0.2);
}

/* Timer Progress Bar */
.notification-timer {
  height: 3px;
  background: rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.timer-bar {
  height: 100%;
  background: linear-gradient(90deg, #007aff 0%, #5856d6 100%);
  transition: width 0.1s linear;
}

/* Slide Down Animation */
.slide-down-enter-active {
  animation: slideDown 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.slide-down-leave-active {
  animation: slideUp 0.25s cubic-bezier(0.4, 0, 1, 1);
}

@keyframes slideDown {
  from {
    transform: translate(-50%, -100%);
    opacity: 0;
  }
  to {
    transform: translate(-50%, 0);
    opacity: 1;
  }
}

@keyframes slideUp {
  from {
    transform: translate(-50%, 0);
    opacity: 1;
  }
  to {
    transform: translate(-50%, -100%);
    opacity: 0;
  }
}

/* Responsive Design */
@media (max-width: 480px) {
  .share-notification {
    top: 50px;
    width: calc(100% - 24px);
  }
  
  .notification-content {
    padding: 14px;
  }
  
  .notification-icon {
    width: 36px;
    height: 36px;
  }
  
  .notification-icon svg {
    width: 20px;
    height: 20px;
  }
  
  .notification-title {
    font-size: 14px;
  }
  
  .notification-message {
    font-size: 12px;
  }
  
  .notification-btn {
    padding: 12px;
    font-size: 14px;
  }
}

@media (max-width: 375px) {
  .share-notification {
    top: 45px;
    width: calc(100% - 20px);
  }
  
  .notification-content {
    padding: 12px;
    gap: 10px;
  }
  
  .notification-icon {
    width: 32px;
    height: 32px;
  }
  
  .notification-icon svg {
    width: 18px;
    height: 18px;
  }
  
  .notification-title {
    font-size: 13px;
  }
  
  .notification-message {
    font-size: 11px;
  }
  
  .notification-btn {
    padding: 11px;
    font-size: 13px;
  }
}

@media (max-width: 320px) {
  .share-notification {
    top: 40px;
    width: calc(100% - 16px);
    border-radius: 14px;
  }
  
  .notification-content {
    padding: 10px;
    gap: 8px;
  }
  
  .notification-icon {
    width: 30px;
    height: 30px;
  }
  
  .notification-icon svg {
    width: 16px;
    height: 16px;
  }
  
  .notification-title {
    font-size: 12px;
  }
  
  .notification-message {
    font-size: 10px;
  }
  
  .notification-btn {
    padding: 10px;
    font-size: 12px;
  }
}

/* High contrast mode support */
@media (prefers-contrast: high) {
  .share-notification {
    border: 2px solid #000;
  }
  
  .notification-btn {
    border: 1px solid;
  }
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
  .slide-down-enter-active,
  .slide-down-leave-active {
    animation: none !important;
  }
  
  .share-notification {
    transition: opacity 0.2s ease;
  }
  
  .timer-bar {
    transition: none;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .share-notification {
    background: rgba(28, 28, 30, 0.95);
  }
  
  .notification-title {
    color: #fff;
  }
  
  .notification-message {
    color: #999;
  }
  
  .notification-actions {
    border-top-color: rgba(255, 255, 255, 0.1);
  }
  
  .notification-btn:first-child {
    border-right-color: rgba(255, 255, 255, 0.1);
  }
  
  .notification-timer {
    background: rgba(255, 255, 255, 0.1);
  }
}
</style>
