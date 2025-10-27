<template>
  <div class="statusbar">
    <div class="statusbar-left">
      <span class="time">{{ currentTime }}</span>
    </div>
    
    <div class="statusbar-right">
      <div class="signal-icon" :class="signalClass">
        <div class="signal-bar"></div>
        <div class="signal-bar"></div>
        <div class="signal-bar"></div>
        <div class="signal-bar"></div>
      </div>
      
      <div class="battery-icon" :class="batteryClass">
        <div class="battery-level" :style="{ width: batteryPercentage + '%' }"></div>
        <div class="battery-tip"></div>
      </div>
      
      <span class="battery-percentage">{{ batteryPercentage }}%</span>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted } from 'vue'

export default {
  name: 'Statusbar',
  setup() {
    const currentTime = ref('')
    const batteryPercentage = ref(100)
    const signalStrength = ref(4)
    let timeInterval = null
    let batteryInterval = null
    
    const updateTime = () => {
      const now = new Date()
      const hours = now.getHours().toString().padStart(2, '0')
      const minutes = now.getMinutes().toString().padStart(2, '0')
      currentTime.value = `${hours}:${minutes}`
    }
    
    const updateBattery = () => {
      // Simulate battery drain (very slow)
      if (batteryPercentage.value > 0) {
        batteryPercentage.value = Math.max(0, batteryPercentage.value - 0.1)
      }
    }
    
    const signalClass = computed(() => {
      return `signal-strength-${signalStrength.value}`
    })
    
    const batteryClass = computed(() => {
      if (batteryPercentage.value <= 20) return 'battery-low'
      if (batteryPercentage.value <= 50) return 'battery-medium'
      return 'battery-high'
    })
    
    onMounted(() => {
      updateTime()
      timeInterval = setInterval(updateTime, 1000)
      batteryInterval = setInterval(updateBattery, 60000) // Update every minute
    })
    
    onUnmounted(() => {
      if (timeInterval) clearInterval(timeInterval)
      if (batteryInterval) clearInterval(batteryInterval)
    })
    
    return {
      currentTime,
      batteryPercentage,
      signalClass,
      batteryClass
    }
  }
}
</script>

<style scoped>
.statusbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 20px;
  background: rgba(0, 0, 0, 0.8);
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  height: 44px;
  position: relative;
  z-index: 5;
}

.statusbar-left {
  display: flex;
  align-items: center;
}

.time {
  font-variant-numeric: tabular-nums;
}

.statusbar-right {
  display: flex;
  align-items: center;
  gap: 8px;
}

.signal-icon {
  display: flex;
  align-items: flex-end;
  gap: 2px;
  height: 14px;
}

.signal-bar {
  width: 3px;
  background: rgba(255, 255, 255, 0.3);
  border-radius: 1px;
  transition: background 0.3s;
}

.signal-bar:nth-child(1) {
  height: 4px;
}

.signal-bar:nth-child(2) {
  height: 7px;
}

.signal-bar:nth-child(3) {
  height: 10px;
}

.signal-bar:nth-child(4) {
  height: 13px;
}

.signal-strength-4 .signal-bar {
  background: #fff;
}

.signal-strength-3 .signal-bar:nth-child(-n+3) {
  background: #fff;
}

.signal-strength-2 .signal-bar:nth-child(-n+2) {
  background: #fff;
}

.signal-strength-1 .signal-bar:nth-child(1) {
  background: #fff;
}

.battery-icon {
  position: relative;
  width: 24px;
  height: 12px;
  border: 2px solid #fff;
  border-radius: 3px;
  display: flex;
  align-items: center;
  padding: 1px;
}

.battery-level {
  height: 100%;
  background: #fff;
  border-radius: 1px;
  transition: width 0.3s, background 0.3s;
}

.battery-low .battery-level {
  background: #ff3b30;
}

.battery-medium .battery-level {
  background: #ff9500;
}

.battery-high .battery-level {
  background: #34c759;
}

.battery-tip {
  position: absolute;
  right: -4px;
  top: 50%;
  transform: translateY(-50%);
  width: 2px;
  height: 6px;
  background: #fff;
  border-radius: 0 1px 1px 0;
}

.battery-percentage {
  font-size: 12px;
  font-variant-numeric: tabular-nums;
}

/* Responsive adjustments */
@media (max-width: 1600px) and (max-height: 900px) {
  .statusbar {
    padding: 6px 16px;
    height: 40px;
    font-size: 13px;
  }
  
  .battery-percentage {
    font-size: 11px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .statusbar {
    padding: 6px 12px;
    height: 36px;
    font-size: 12px;
  }
  
  .signal-icon {
    height: 12px;
  }
  
  .signal-bar {
    width: 2px;
  }
  
  .battery-icon {
    width: 20px;
    height: 10px;
  }
  
  .battery-percentage {
    font-size: 10px;
  }
}
</style>
