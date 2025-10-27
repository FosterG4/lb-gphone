<template>
  <transition name="notification">
    <div 
      :class="['notification', `notification-${notification.type || 'default'}`]"
      :style="{ top: `${80 + index * 90}px` }"
      @click="dismiss"
    >
      <div class="notification-icon">
        <span v-if="notification.type === 'message'">💬</span>
        <span v-else-if="notification.type === 'call'">📞</span>
        <span v-else-if="notification.type === 'app'">📱</span>
        <span v-else-if="notification.type === 'bank'">💰</span>
        <span v-else-if="notification.type === 'error'">⚠️</span>
        <span v-else-if="notification.type === 'success'">✅</span>
        <span v-else-if="notification.type === 'warning'">⚡</span>
        <span v-else>ℹ️</span>
      </div>
      <div class="notification-content">
        <div class="notification-title">{{ notification.title }}</div>
        <div class="notification-message">{{ notification.message }}</div>
      </div>
      <button class="notification-close" @click.stop="dismiss">
        ×
      </button>
    </div>
  </transition>
</template>

<script>
export default {
  name: 'Notification',
  
  props: {
    notification: {
      type: Object,
      required: true
    },
    index: {
      type: Number,
      default: 0
    }
  },
  
  emits: ['close'],
  
  setup(props, { emit }) {
    const dismiss = () => {
      emit('close')
    }
    
    return {
      dismiss
    }
  }
}
</script>

<style scoped>
.notification {
  position: fixed;
  right: 20px;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 15px;
  background: rgba(28, 28, 30, 0.95);
  backdrop-filter: blur(10px);
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  cursor: pointer;
  transition: all 0.3s ease;
  border-left: 4px solid #007aff;
  max-width: 350px;
  z-index: 10000;
}

.notification:hover {
  transform: translateX(-5px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.4);
}

.notification-default {
  border-left-color: #007aff;
}

.notification-message {
  border-left-color: #007aff;
}

.notification-call {
  border-left-color: #34c759;
}

.notification-app {
  border-left-color: #ff9500;
}

.notification-bank {
  border-left-color: #30d158;
}

.notification-error {
  border-left-color: #ff3b30;
}

.notification-success {
  border-left-color: #34c759;
}

.notification-warning {
  border-left-color: #ff9f0a;
}

.notification-icon {
  font-size: 24px;
  flex-shrink: 0;
}

.notification-content {
  flex: 1;
  min-width: 0;
}

.notification-title {
  font-weight: 600;
  font-size: 14px;
  color: #fff;
  margin-bottom: 4px;
}

.notification-message {
  font-size: 13px;
  color: #8e8e93;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.notification-close {
  background: none;
  border: none;
  color: #8e8e93;
  font-size: 24px;
  cursor: pointer;
  padding: 0;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: color 0.2s;
}

.notification-close:hover {
  color: #fff;
}

/* Transition animations */
.notification-enter-active,
.notification-leave-active {
  transition: all 0.3s ease;
}

.notification-enter-from {
  opacity: 0;
  transform: translateX(100%);
}

.notification-leave-to {
  opacity: 0;
  transform: translateX(100%);
}
</style>
