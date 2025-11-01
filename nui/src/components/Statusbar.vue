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
  name: "Statusbar",
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
  padding: var(--status-bar-padding-y) var(--status-bar-padding-x);
  background: transparent;
  color: var(--status-bar-text-light);
  font-size: var(--status-bar-font-size);
  font-weight: var(--status-bar-font-weight);
  height: var(--status-bar-height);
  position: relative;
  z-index: 1000;
}

.status-left {
  flex: 1;
  display: flex;
  align-items: center;
}

.time {
  font-size: var(--status-bar-time-font-size);
  font-weight: var(--status-bar-font-weight);
  text-shadow: var(--status-bar-shadow);
}

.status-center {
  flex: 0;
  display: flex;
  justify-content: center;
  align-items: center;
}

.notch {
  width: var(--status-bar-notch-width);
  height: var(--status-bar-notch-height);
  background: #000;
  border-radius: 0 0 var(--status-bar-notch-radius) var(--status-bar-notch-radius);
  position: relative;
}

.status-right {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: var(--status-bar-icon-gap);
}

.signal-bars {
  display: flex;
  align-items: flex-end;
  gap: var(--status-bar-signal-bar-gap);
  height: var(--status-bar-battery-height);
}

.bar {
  width: var(--status-bar-signal-bar-width);
  background: rgba(255, 255, 255, var(--status-bar-inactive-opacity));
  border-radius: 1px;
  transition: background var(--status-bar-transition);
}

.bar:nth-child(1) { height: 3px; }
.bar:nth-child(2) { height: 6px; }
.bar:nth-child(3) { height: 9px; }
.bar:nth-child(4) { height: 12px; }

.bar.active {
  background: var(--status-bar-text-light);
}

.wifi-icon {
  color: rgba(255, 255, 255, var(--status-bar-inactive-opacity));
  transition: color var(--status-bar-transition);
}

.wifi-icon.connected {
  color: var(--status-bar-text-light);
}

.battery {
  position: relative;
  width: var(--status-bar-battery-width);
  height: var(--status-bar-battery-height);
  border: 1px solid var(--status-bar-text-light);
  border-radius: 2px;
  background: transparent;
}

.battery-level {
  height: 100%;
  background: var(--status-bar-text-light);
  border-radius: 1px;
  transition: width var(--status-bar-transition);
}

.battery-tip {
  position: absolute;
  right: -3px;
  top: 3px;
  width: var(--status-bar-battery-tip-width);
  height: var(--status-bar-battery-tip-height);
  background: var(--status-bar-text-light);
  border-radius: 0 1px 1px 0;
}

.battery-percentage {
  font-size: var(--status-bar-battery-font-size);
  font-weight: 500;
  text-shadow: var(--status-bar-shadow);
}

/* Theme support */
.light .status-bar {
  color: var(--status-bar-text-dark);
}

.light .bar.active {
  background: var(--status-bar-text-dark);
}

.light .wifi-icon.connected {
  color: var(--status-bar-text-dark);
}

.light .battery {
  border-color: var(--status-bar-text-dark);
}

.light .battery-level {
  background: var(--status-bar-text-dark);
}

.light .battery-tip {
  background: var(--status-bar-text-dark);
}
</style>