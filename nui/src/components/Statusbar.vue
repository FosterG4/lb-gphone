<template>
  <div class="status-bar">
    <div class="status-left">
      <span class="time">{{ currentTime }}</span>
    </div>
    
    <div class="status-center">
      <div class="notch"></div>
    </div>
    
    <div class="status-right">
      <div class="signal-bars">
        <div class="bar" :class="{ active: signalStrength >= 1 }"></div>
        <div class="bar" :class="{ active: signalStrength >= 2 }"></div>
        <div class="bar" :class="{ active: signalStrength >= 3 }"></div>
        <div class="bar" :class="{ active: signalStrength >= 4 }"></div>
      </div>
      
      <div class="wifi-icon" :class="{ connected: wifiConnected }">
        <WifiIcon />
      </div>
      
      <div class="battery">
        <div class="battery-level" :style="{ width: batteryLevel + '%' }"></div>
        <div class="battery-tip"></div>
      </div>
      
      <span class="battery-percentage">{{ batteryLevel }}%</span>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted } from "vue";
import { h } from "vue";

const WifiIcon = () =>
  h(
    "svg",
    {
      width: "16",
      height: "16",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M1 9l2 2c4.97-4.97 13.03-4.97 18 0l2-2C16.93 2.93 7.07 2.93 1 9zm8 8l3 3 3-3c-1.65-1.66-4.34-1.66-6 0zm-4-4l2 2c2.76-2.76 7.24-2.76 10 0l2-2C15.14 9.14 8.87 9.14 5 13z",
      }),
    ]
  );

export default {
  name: "StatusBar",
  components: {
    WifiIcon,
  },
  props: {
    signalStrength: {
      type: Number,
      default: 4,
      validator: (value) => value >= 0 && value <= 4
    },
    wifiConnected: {
      type: Boolean,
      default: true
    },
    batteryLevel: {
      type: Number,
      default: 87,
      validator: (value) => value >= 0 && value <= 100
    }
  },
  setup(props) {
    const currentTime = ref("");
    let timeInterval = null;

    const updateTime = () => {
      const now = new Date();
      const hours = now.getHours().toString().padStart(2, "0");
      const minutes = now.getMinutes().toString().padStart(2, "0");
      currentTime.value = `${hours}:${minutes}`;
    };

    onMounted(() => {
      updateTime();
      timeInterval = setInterval(updateTime, 60000); // Update every minute, not second
    });

    onUnmounted(() => {
      if (timeInterval) {
        clearInterval(timeInterval);
        timeInterval = null;
      }
    });

    return {
      currentTime,
      signalStrength: props.signalStrength,
      wifiConnected: props.wifiConnected,
      batteryLevel: props.batteryLevel,
    };
  },
};
</script>

<style scoped>
.status-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 20px 8px 20px;
  background: transparent;
  color: white;
  font-size: 14px;
  font-weight: 600;
  height: 44px;
  position: relative;
  z-index: 1000;
}

.status-left {
  flex: 1;
  display: flex;
  align-items: center;
}

.time {
  font-size: 16px;
  font-weight: 600;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
}

.status-center {
  flex: 0;
  display: flex;
  justify-content: center;
  align-items: center;
}

.notch {
  width: 120px;
  height: 24px;
  background: #000;
  border-radius: 0 0 12px 12px;
  position: relative;
}

.status-right {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 6px;
}

.signal-bars {
  display: flex;
  align-items: flex-end;
  gap: 2px;
  height: 12px;
}

.bar {
  width: 3px;
  background: rgba(255, 255, 255, 0.3);
  border-radius: 1px;
  transition: background 0.3s;
}

.bar:nth-child(1) { height: 3px; }
.bar:nth-child(2) { height: 6px; }
.bar:nth-child(3) { height: 9px; }
.bar:nth-child(4) { height: 12px; }

.bar.active {
  background: white;
}

.wifi-icon {
  color: rgba(255, 255, 255, 0.3);
  transition: color 0.3s;
}

.wifi-icon.connected {
  color: white;
}

.battery {
  position: relative;
  width: 24px;
  height: 12px;
  border: 1px solid white;
  border-radius: 2px;
  background: transparent;
}

.battery-level {
  height: 100%;
  background: white;
  border-radius: 1px;
  transition: width 0.3s;
}

.battery-tip {
  position: absolute;
  right: -3px;
  top: 3px;
  width: 2px;
  height: 6px;
  background: white;
  border-radius: 0 1px 1px 0;
}

.battery-percentage {
  font-size: 12px;
  font-weight: 500;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
}

/* Dark theme support */
.dark .status-bar {
  color: white;
}

.light .status-bar {
  color: #1c1c1e;
}

.light .bar.active {
  background: #1c1c1e;
}

.light .wifi-icon.connected {
  color: #1c1c1e;
}

.light .battery {
  border-color: #1c1c1e;
}

.light .battery-level {
  background: #1c1c1e;
}

.light .battery-tip {
  background: #1c1c1e;
}

/* Responsive design */
@media (max-width: 1600px) and (max-height: 900px) {
  .status-bar {
    padding: 6px 18px;
    height: 40px;
  }

  .time {
    font-size: 15px;
  }

  .notch {
    width: 110px;
    height: 22px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .status-bar {
    padding: 4px 16px;
    height: 36px;
  }

  .time {
    font-size: 14px;
  }

  .notch {
    width: 100px;
    height: 20px;
  }

  .battery {
    width: 20px;
    height: 10px;
  }

  .battery-percentage {
    font-size: 11px;
  }
}
</style>