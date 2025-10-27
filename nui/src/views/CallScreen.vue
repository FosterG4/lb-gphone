<template>
  <div class="call-screen">
    <div class="call-info">
      <div class="caller-avatar">
        <span class="avatar-icon">👤</span>
      </div>
      
      <div class="caller-details">
        <div class="caller-name">{{ callerName }}</div>
        <div class="caller-number">{{ callerNumber }}</div>
      </div>
      
      <div class="call-status">
        <span v-if="callState === 'ringing' && isIncoming">Incoming call...</span>
        <span v-else-if="callState === 'ringing' && !isIncoming">Calling...</span>
        <span v-else-if="callState === 'active'">{{ formattedDuration }}</span>
      </div>
    </div>
    
    <div class="call-actions">
      <button 
        v-if="callState === 'ringing' && isIncoming"
        @click="acceptCall"
        class="call-action-btn accept-btn"
      >
        <span class="btn-icon">✓</span>
        <span class="btn-label">Accept</span>
      </button>
      
      <button 
        @click="endCall"
        class="call-action-btn end-btn"
      >
        <span class="btn-icon">✕</span>
        <span class="btn-label">{{ callState === 'ringing' && !isIncoming ? 'Cancel' : 'End Call' }}</span>
      </button>
    </div>
    
    <div v-if="callState === 'active'" class="call-controls">
      <button class="control-btn" @click="toggleMute">
        <span class="control-icon">{{ isMuted ? '🔇' : '🔊' }}</span>
        <span class="control-label">{{ isMuted ? 'Unmute' : 'Mute' }}</span>
      </button>
      
      <button class="control-btn" @click="toggleSpeaker">
        <span class="control-icon">{{ isSpeaker ? '📢' : '🔈' }}</span>
        <span class="control-label">{{ isSpeaker ? 'Speaker' : 'Earpiece' }}</span>
      </button>
    </div>
  </div>
</template>

<script>
import { computed, ref, watch, onUnmounted } from 'vue'
import { useStore } from 'vuex'

export default {
  name: 'CallScreen',
  
  setup() {
    const store = useStore()
    const isMuted = ref(false)
    const isSpeaker = ref(false)
    const duration = ref(0)
    let durationInterval = null
    
    const currentCall = computed(() => store.state.calls.currentCall)
    const callState = computed(() => store.state.calls.state)
    
    const callerName = computed(() => {
      if (!currentCall.value) return 'Unknown'
      return currentCall.value.callerName || currentCall.value.number || 'Unknown'
    })
    
    const callerNumber = computed(() => {
      if (!currentCall.value) return ''
      return currentCall.value.number || ''
    })
    
    const isIncoming = computed(() => {
      if (!currentCall.value) return false
      return currentCall.value.direction === 'incoming'
    })
    
    const formattedDuration = computed(() => {
      const minutes = Math.floor(duration.value / 60)
      const seconds = duration.value % 60
      return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
    })
    
    // Watch for call state changes
    watch(callState, (newState) => {
      if (newState === 'active') {
        // Start duration timer
        duration.value = 0
        durationInterval = setInterval(() => {
          duration.value++
        }, 1000)
      } else {
        // Stop duration timer
        if (durationInterval) {
          clearInterval(durationInterval)
          durationInterval = null
        }
        duration.value = 0
      }
    })
    
    const acceptCall = async () => {
      await store.dispatch('calls/acceptCall')
    }
    
    const endCall = async () => {
      await store.dispatch('calls/endCall')
    }
    
    const toggleMute = () => {
      isMuted.value = !isMuted.value
      // TODO: Implement actual mute functionality with pma-voice
    }
    
    const toggleSpeaker = () => {
      isSpeaker.value = !isSpeaker.value
      // TODO: Implement speaker mode if needed
    }
    
    // Cleanup on unmount
    onUnmounted(() => {
      if (durationInterval) {
        clearInterval(durationInterval)
      }
    })
    
    return {
      callState,
      callerName,
      callerNumber,
      isIncoming,
      formattedDuration,
      isMuted,
      isSpeaker,
      acceptCall,
      endCall,
      toggleMute,
      toggleSpeaker
    }
  }
}
</script>

<style scoped>
.call-screen {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: linear-gradient(135deg, #1c1c1e 0%, #2c2c2e 100%);
  color: #fff;
  padding: 40px 20px;
  justify-content: space-between;
}

.call-info {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  flex: 1;
  justify-content: center;
}

.caller-avatar {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  background: #3c3c3e;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 30px;
  border: 3px solid #444;
}

.avatar-icon {
  font-size: 60px;
}

.caller-details {
  margin-bottom: 20px;
}

.caller-name {
  font-size: 32px;
  font-weight: 600;
  margin-bottom: 8px;
}

.caller-number {
  font-size: 18px;
  color: #888;
  letter-spacing: 1px;
}

.call-status {
  font-size: 16px;
  color: #aaa;
  margin-top: 10px;
}

.call-actions {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin: 30px 0;
}

.call-action-btn {
  width: 70px;
  height: 70px;
  border-radius: 50%;
  border: none;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  transition: transform 0.2s, opacity 0.2s;
}

.call-action-btn:hover {
  transform: scale(1.05);
  opacity: 0.9;
}

.call-action-btn:active {
  transform: scale(0.95);
}

.accept-btn {
  background: #34c759;
  color: white;
}

.end-btn {
  background: #ff3b30;
  color: white;
}

.btn-icon {
  font-size: 28px;
  font-weight: bold;
}

.btn-label {
  font-size: 10px;
  margin-top: 4px;
  font-weight: 500;
}

.call-controls {
  display: flex;
  justify-content: center;
  gap: 30px;
  padding: 20px 0;
}

.control-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  background: transparent;
  border: none;
  color: #fff;
  cursor: pointer;
  padding: 10px;
  transition: opacity 0.2s;
}

.control-btn:hover {
  opacity: 0.7;
}

.control-icon {
  font-size: 32px;
  margin-bottom: 8px;
}

.control-label {
  font-size: 12px;
  color: #888;
}
</style>
