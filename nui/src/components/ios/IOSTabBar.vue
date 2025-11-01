<template>
  <div class="ios-tab-bar">
    <div class="ios-tab-bar__container">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        :class="[
          'ios-tab-bar__item',
          { 'ios-tab-bar__item--active': activeTab === tab.id }
        ]"
        @click="handleTabClick(tab.id)"
      >
        <div class="ios-tab-bar__icon">
          <component :is="tab.icon" :size="24" />
        </div>
        <span class="ios-tab-bar__label">{{ tab.label }}</span>
        <div v-if="tab.badge" class="ios-tab-bar__badge">
          {{ tab.badge }}
        </div>
      </button>
    </div>
  </div>
</template>

<script setup>
import { defineEmits } from 'vue'

const props = defineProps({
  tabs: {
    type: Array,
    required: true,
    validator: (tabs) => {
      return tabs.every(tab => 
        tab.id && tab.label && tab.icon
      )
    }
  },
  activeTab: {
    type: String,
    required: true
  }
})

const emit = defineEmits(['tab-change'])

const handleTabClick = (tabId) => {
  if (tabId !== props.activeTab) {
    emit('tab-change', tabId)
  }
}
</script>

<style scoped>
.ios-tab-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(248, 248, 248, 0.95);
  backdrop-filter: blur(20px);
  border-top: 1px solid rgba(0, 0, 0, 0.1);
  padding-bottom: env(safe-area-inset-bottom, 0);
  z-index: 100;
}

.ios-tab-bar__container {
  display: flex;
  align-items: center;
  justify-content: space-around;
  padding: 8px 0;
  max-width: 100%;
}

.ios-tab-bar__item {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: none;
  border: none;
  cursor: pointer;
  padding: 8px 12px;
  border-radius: 12px;
  transition: all 0.2s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  min-width: 60px;
  flex: 1;
  max-width: 80px;
}

.ios-tab-bar__item:active {
  transform: scale(0.95);
}

.ios-tab-bar__item--active {
  background: rgba(0, 122, 255, 0.1);
}

.ios-tab-bar__icon {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 4px;
  color: #8e8e93;
  transition: color 0.2s;
}

.ios-tab-bar__item--active .ios-tab-bar__icon {
  color: #007AFF;
}

.ios-tab-bar__label {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  font-size: 10px;
  font-weight: 500;
  color: #8e8e93;
  transition: color 0.2s;
  text-align: center;
  line-height: 1.2;
}

.ios-tab-bar__item--active .ios-tab-bar__label {
  color: #007AFF;
  font-weight: 600;
}

.ios-tab-bar__badge {
  position: absolute;
  top: 4px;
  right: 8px;
  background: #FF3B30;
  color: white;
  font-size: 10px;
  font-weight: 600;
  padding: 2px 6px;
  border-radius: 10px;
  min-width: 16px;
  height: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  line-height: 1;
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .ios-tab-bar {
    background: rgba(28, 28, 30, 0.95);
    border-top: 1px solid rgba(255, 255, 255, 0.1);
  }

  .ios-tab-bar__item--active {
    background: rgba(0, 122, 255, 0.2);
  }

  .ios-tab-bar__icon,
  .ios-tab-bar__label {
    color: #8e8e93;
  }

  .ios-tab-bar__item--active .ios-tab-bar__icon,
  .ios-tab-bar__item--active .ios-tab-bar__label {
    color: #0A84FF;
  }
}

/* Responsive adjustments */
@media (max-width: 375px) {
  .ios-tab-bar__label {
    font-size: 9px;
  }
  
  .ios-tab-bar__item {
    padding: 6px 8px;
    min-width: 50px;
  }
}
</style>