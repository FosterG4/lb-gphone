<template>
  <div class="lockscreen" @click="startUnlock">
    <div class="lockscreen-wallpaper"></div>
    
    <div class="lockscreen-content">
      <div class="lock-time">
        <div class="lock-hours">{{ hours }}</div>
        <div class="lock-minutes">{{ minutes }}</div>
      </div>
      
      <div class="lock-date">{{ dateString }}</div>
      
      <div class="lock-notifications" v-if="notifications.length > 0">
        <div 
          v-for="notification in notifications.slice(0, 3)" 
          :key="notification.id"
          class="lock-notification"
        >
          <div class="notification-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="white">
              <path d="M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2zm-2 1H8v-6c0-2.48 1.51-4.5 4-4.5s4 2.02 4 4.5v6z"/>
            </svg>
          </div>
          <div class="notification-content">
            <div class="notification-title">{{ notification.title }}</div>
            <div class="notification-message">{{ notification.message }}</div>
          </div>
        </div>
      </div>
      
      <div class="unlock-indicator" :class="{ 'unlocking': isUnlocking }">
        <div class="unlock-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="white">
            <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zM9 6c0-1.66 1.34-3 3-3s3 1.34 3 3v2H9V6zm9 14H6V10h12v10zm-6-3c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2z"/>
          </svg>
        </div>
        <div class="unlock-text">{{ unlockText }}</div>
      </div>
    </div>
    
    <div class="unlock-animation" v-if="isUnlocking">
      <div class="unlock-circle"></div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useStore } from 'vuex'

export default {
  name: 'Lockscreen',
  emits: ['unlock'],
  setup(props, { emit }) {
    const store = useStore()
    const currentTime = ref(new Date())
    const isUnlocking = ref(false)
    let timeInterval = null
    
    const hours = computed(() => {
      return currentTime.value.getHours().toString().padStart(2, '0')
    })
    
    const minutes = computed(() => {
      return currentTime.value.getMinutes().toString().padStart(2, '0')
    })
    
    const dateString = computed(() => {
      const options = { weekday: 'long', month: 'long', day: 'numeric' }
      return currentTime.value.toLocaleDateString('en-US', options)
    })
    
    const notifications = computed(() => store.state.phone.notifications)
    
    const unlockText = computed(() => {
      return isUnlocking.value ? 'Unlocking...' : 'Tap to unlock'
    })
    
    const startUnlock = () => {
      if (isUnlocking.value) return
      
      isUnlocking.value = true
      
      setTimeout(() => {
        emit('unlock')
        isUnlocking.value = false
      }, 800)
    }
    
    const updateTime = () => {
      currentTime.value = new Date()
    }
    
    onMounted(() => {
      updateTime()
      timeInterval = setInterval(updateTime, 1000)
    })
    
    onUnmounted(() => {
      if (timeInterval) clearInterval(timeInterval)
    })
    
    return {
      hours,
      minutes,
      dateString,
      notifications,
      isUnlocking,
      unlockText,
      startUnlock
    }
  }
}
</script>

<style scoped>
.lockscreen {
  flex: 1;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
  cursor: pointer;
}

.lockscreen-wallpaper {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #1e3c72 0%, #2a5298 50%, #7e22ce 100%);
  z-index: 0;
}

.lockscreen-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: space-between;
  padding: 60px 20px 40px;
  z-index: 1;
  position: relative;
}

.lock-time {
  display: flex;
  flex-direction: column;
  align-items: center;
  color: #fff;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.lock-hours {
  font-size: 80px;
  font-weight: 300;
  line-height: 1;
  font-variant-numeric: tabular-nums;
}

.lock-minutes {
  font-size: 80px;
  font-weight: 300;
  line-height: 1;
  font-variant-numeric: tabular-nums;
}

.lock-date {
  color: #fff;
  font-size: 18px;
  font-weight: 500;
  margin-top: -20px;
  text-shadow: 0 1px 4px rgba(0, 0, 0, 0.3);
}

.lock-notifications {
  width: 100%;
  max-width: 340px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 20px;
}

.lock-notification {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(20px);
  border-radius: 16px;
  padding: 12px;
  display: flex;
  gap: 12px;
  align-items: flex-start;
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.notification-icon {
  width: 32px;
  height: 32px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.notification-content {
  flex: 1;
  min-width: 0;
}

.notification-title {
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 2px;
}

.notification-message {
  color: rgba(255, 255, 255, 0.9);
  font-size: 13px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.unlock-indicator {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  transition: transform 0.3s;
}

.unlock-indicator.unlocking {
  transform: scale(1.1);
}

.unlock-icon {
  width: 48px;
  height: 48px;
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.3s;
}

.unlock-indicator:hover .unlock-icon {
  background: rgba(255, 255, 255, 0.3);
}

.unlock-text {
  color: #fff;
  font-size: 14px;
  font-weight: 500;
  text-shadow: 0 1px 4px rgba(0, 0, 0, 0.3);
}

.unlock-animation {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  z-index: 10;
  pointer-events: none;
}

.unlock-circle {
  width: 100px;
  height: 100px;
  border: 3px solid rgba(255, 255, 255, 0.8);
  border-radius: 50%;
  animation: unlockPulse 0.8s ease-out;
}

@keyframes unlockPulse {
  0% {
    transform: scale(0);
    opacity: 1;
  }
  100% {
    transform: scale(4);
    opacity: 0;
  }
}

/* Responsive adjustments */
@media (max-width: 1600px) and (max-height: 900px) {
  .lockscreen-content {
    padding: 50px 20px 35px;
  }
  
  .lock-hours,
  .lock-minutes {
    font-size: 72px;
  }
  
  .lock-date {
    font-size: 16px;
  }
  
  .lock-notifications {
    max-width: 300px;
  }
  
  .notification-title {
    font-size: 13px;
  }
  
  .notification-message {
    font-size: 12px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .lockscreen-content {
    padding: 40px 16px 30px;
  }
  
  .lock-hours,
  .lock-minutes {
    font-size: 64px;
  }
  
  .lock-date {
    font-size: 14px;
    margin-top: -15px;
  }
  
  .lock-notifications {
    max-width: 260px;
    gap: 6px;
  }
  
  .lock-notification {
    padding: 10px;
    border-radius: 12px;
  }
  
  .notification-icon {
    width: 28px;
    height: 28px;
  }
  
  .notification-title {
    font-size: 12px;
  }
  
  .notification-message {
    font-size: 11px;
  }
  
  .unlock-icon {
    width: 42px;
    height: 42px;
  }
  
  .unlock-text {
    font-size: 13px;
  }
}
</style>
