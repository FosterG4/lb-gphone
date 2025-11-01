<template>
  <transition name="broadcast-fade">
    <div v-if="isActive" class="broadcast-share" role="status" aria-live="polite" aria-atomic="true">
      <!-- Broadcast Header -->
      <div class="broadcast-header">
        <h3 class="broadcast-title">{{ $t('contactSharing.sharingContact') }}</h3>
        <button 
          class="stop-btn" 
          @click="handleStopBroadcast"
          :disabled="isStopping"
          aria-label="Stop sharing contact"
        >
          {{ isStopping ? $t('common.loading') : $t('contactSharing.stopSharing') }}
        </button>
      </div>
      
      <!-- Broadcast Body -->
      <div class="broadcast-body">
        <!-- Broadcast Animation -->
        <div class="broadcast-animation" aria-hidden="true">
          <div class="pulse-ring"></div>
          <div class="pulse-ring delay-1"></div>
          <div class="pulse-ring delay-2"></div>
          <svg class="broadcast-icon" width="48" height="48" viewBox="0 0 24 24" fill="none">
            <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <polyline points="16,6 12,2 8,6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <line x1="12" y1="2" x2="12" y2="15" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
          </svg>
        </div>
        
        <!-- Broadcast Text -->
        <div class="broadcast-text">
          <p class="broadcast-message">{{ $t('contactSharing.visibleToNearby') }}</p>
          <p class="countdown" :aria-label="`${timeRemaining} seconds remaining`">
            {{ $t('contactSharing.timeRemaining', { seconds: timeRemaining }) }}
          </p>
        </div>
        
        <!-- Nearby Count -->
        <div class="nearby-count">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <circle cx="9" cy="7" r="4" stroke="currentColor" stroke-width="2"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M16 3.13a4 4 0 0 1 0 7.75" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <span>{{ $t('contactSharing.nearbyCount', { count: nearbyCount }) }}</span>
        </div>
      </div>
    </div>
  </transition>
</template>

<script>
import { ref, computed, watch, onUnmounted } from 'vue'
import { nuiCallback } from '../utils/nui'
import { 
  showBroadcastStartedNotification,
  showBroadcastStoppedNotification 
} from '../utils/notifications'
import { hapticMedium, hapticLight } from '../utils/haptics'

export default {
  name: 'BroadcastShare',
  
  props: {
    isActive: {
      type: Boolean,
      default: false
    },
    nearbyCount: {
      type: Number,
      default: 0
    },
    duration: {
      type: Number,
      default: 10 // 10 seconds default
    }
  },
  
  emits: ['stopped', 'expired'],
  
  setup(props, { emit }) {
    const timeRemaining = ref(props.duration)
    const isStopping = ref(false)
    let countdownInterval = null
    
    // Start countdown when broadcast becomes active
    watch(() => props.isActive, (isActive) => {
      if (isActive) {
        // Trigger haptic feedback when broadcast starts
        hapticMedium()
        
        startCountdown()
        // Show broadcast started notification
        showBroadcastStartedNotification(props.duration)
      } else {
        stopCountdown()
      }
    }, { immediate: true })
    
    // Methods
    const startCountdown = () => {
      // Reset timer
      timeRemaining.value = props.duration
      
      // Clear any existing interval
      if (countdownInterval) {
        clearInterval(countdownInterval)
      }
      
      // Start countdown
      countdownInterval = setInterval(() => {
        timeRemaining.value--
        
        if (timeRemaining.value <= 0) {
          stopCountdown()
          handleExpired()
        }
      }, 1000)
    }
    
    const stopCountdown = () => {
      if (countdownInterval) {
        clearInterval(countdownInterval)
        countdownInterval = null
      }
    }
    
    const handleStopBroadcast = async () => {
      if (isStopping.value) return
      
      // Trigger haptic feedback on stop button press
      hapticLight()
      
      isStopping.value = true
      
      try {
        const response = await nuiCallback('stopBroadcastShare', {})
        
        if (response.success) {
          stopCountdown()
          // Show broadcast stopped notification
          showBroadcastStoppedNotification('manual')
          emit('stopped')
        } else {
          console.error('Failed to stop broadcast:', response.error)
        }
      } catch (error) {
        console.error('Stop broadcast error:', error)
      } finally {
        isStopping.value = false
      }
    }
    
    const handleExpired = () => {
      // Trigger haptic feedback when broadcast expires
      hapticLight()
      
      // Show broadcast stopped notification
      showBroadcastStoppedNotification('expired')
      emit('expired')
    }
    
    // Cleanup on unmount
    onUnmounted(() => {
      stopCountdown()
    })
    
    return {
      timeRemaining,
      isStopping,
      handleStopBroadcast
    }
  }
}
</script>

<style scoped>
/* Broadcast Share Container */
.broadcast-share {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 16px;
  padding: 24px;
  margin: 16px;
  box-shadow: 0 8px 24px rgba(102, 126, 234, 0.3);
  color: #fff;
}

/* Broadcast Header */
.broadcast-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.broadcast-title {
  font-size: 20px;
  font-weight: 600;
  margin: 0;
  color: #fff;
}

.stop-btn {
  background: rgba(255, 255, 255, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: #fff;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

.stop-btn:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-1px);
}

.stop-btn:active:not(:disabled) {
  transform: translateY(0);
}

.stop-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.stop-btn:focus {
  outline: 2px solid rgba(255, 255, 255, 0.5);
  outline-offset: 2px;
}

/* Broadcast Body */
.broadcast-body {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
}

/* Broadcast Animation */
.broadcast-animation {
  position: relative;
  width: 120px;
  height: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.pulse-ring {
  position: absolute;
  width: 100%;
  height: 100%;
  border: 3px solid rgba(255, 255, 255, 0.6);
  border-radius: 50%;
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

.pulse-ring.delay-1 {
  animation-delay: 0.4s;
}

.pulse-ring.delay-2 {
  animation-delay: 0.8s;
}

@keyframes pulse {
  0% {
    transform: scale(0.8);
    opacity: 1;
  }
  100% {
    transform: scale(1.4);
    opacity: 0;
  }
}

.broadcast-icon {
  position: relative;
  z-index: 1;
  color: #fff;
  filter: drop-shadow(0 2px 8px rgba(0, 0, 0, 0.2));
}

/* Broadcast Text */
.broadcast-text {
  text-align: center;
}

.broadcast-message {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.95);
  margin: 0 0 8px 0;
  line-height: 1.4;
}

.countdown {
  font-size: 24px;
  font-weight: 700;
  color: #fff;
  margin: 0;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

/* Nearby Count */
.nearby-count {
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(255, 255, 255, 0.15);
  padding: 10px 20px;
  border-radius: 20px;
  font-size: 15px;
  font-weight: 600;
  color: #fff;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
}

.nearby-count svg {
  flex-shrink: 0;
}

/* Transitions */
.broadcast-fade-enter-active,
.broadcast-fade-leave-active {
  transition: all 0.3s ease;
}

.broadcast-fade-enter-from {
  opacity: 0;
  transform: translateY(-20px);
}

.broadcast-fade-leave-to {
  opacity: 0;
  transform: translateY(20px);
}

/* Responsive Design */
@media (max-width: 480px) {
  .broadcast-share {
    padding: 20px;
    margin: 12px;
  }
  
  .broadcast-header {
    margin-bottom: 20px;
  }
  
  .broadcast-title {
    font-size: 18px;
  }
  
  .stop-btn {
    padding: 7px 14px;
    font-size: 14px;
  }
  
  .broadcast-animation {
    width: 100px;
    height: 100px;
  }
  
  .broadcast-icon {
    width: 40px;
    height: 40px;
  }
  
  .broadcast-message {
    font-size: 15px;
  }
  
  .countdown {
    font-size: 22px;
  }
  
  .nearby-count {
    padding: 8px 16px;
    font-size: 14px;
  }
}

@media (max-width: 375px) {
  .broadcast-share {
    padding: 18px;
    margin: 10px;
  }
  
  .broadcast-header {
    margin-bottom: 18px;
  }
  
  .broadcast-title {
    font-size: 17px;
  }
  
  .stop-btn {
    padding: 6px 12px;
    font-size: 13px;
  }
  
  .broadcast-body {
    gap: 16px;
  }
  
  .broadcast-animation {
    width: 90px;
    height: 90px;
  }
  
  .broadcast-icon {
    width: 36px;
    height: 36px;
  }
  
  .broadcast-message {
    font-size: 14px;
  }
  
  .countdown {
    font-size: 20px;
  }
  
  .nearby-count {
    padding: 7px 14px;
    font-size: 13px;
  }
}

@media (max-width: 320px) {
  .broadcast-share {
    padding: 16px;
    margin: 8px;
    border-radius: 14px;
  }
  
  .broadcast-header {
    margin-bottom: 16px;
  }
  
  .broadcast-title {
    font-size: 16px;
  }
  
  .stop-btn {
    padding: 5px 10px;
    font-size: 12px;
  }
  
  .broadcast-body {
    gap: 14px;
  }
  
  .broadcast-animation {
    width: 80px;
    height: 80px;
  }
  
  .broadcast-icon {
    width: 32px;
    height: 32px;
  }
  
  .broadcast-message {
    font-size: 13px;
  }
  
  .countdown {
    font-size: 18px;
  }
  
  .nearby-count {
    padding: 6px 12px;
    font-size: 12px;
  }
  
  .nearby-count svg {
    width: 16px;
    height: 16px;
  }
}

/* High contrast mode support */
@media (prefers-contrast: high) {
  .broadcast-share {
    border: 2px solid #fff;
  }
  
  .stop-btn {
    border: 2px solid #fff;
  }
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
  .pulse-ring {
    animation: none !important;
  }
  
  .broadcast-fade-enter-active,
  .broadcast-fade-leave-active,
  .stop-btn {
    transition: none !important;
  }
}

/* Dark mode support (component already has dark styling) */
@media (prefers-color-scheme: dark) {
  /* Component is already styled for dark appearance */
  /* No additional changes needed */
}
</style>
