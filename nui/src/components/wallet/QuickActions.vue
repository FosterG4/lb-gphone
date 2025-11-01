<template>
  <div class="quick-actions">
    <div class="quick-actions__title">Quick Actions</div>
    <div class="quick-actions__grid">
      <button
        v-for="action in actions"
        :key="action.id"
        class="quick-actions__item"
        @click="handleActionClick(action)"
      >
        <div class="quick-actions__icon" :style="{ backgroundColor: action.color }">
          <component :is="action.icon" :size="24" />
        </div>
        <span class="quick-actions__label">{{ action.label }}</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed, h } from 'vue'

// SVG Icons
const Send = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'm22 2-7 20-4-9-9-4Z' }),
  h('path', { d: 'M22 2 11 13' })
])

const Download = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4' }),
  h('polyline', { points: '7,10 12,15 17,10' }),
  h('line', { x1: '12', x2: '12', y1: '15', y2: '3' })
])

const CreditCard = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '20', height: '14', x: '2', y: '5', rx: '2' }),
  h('line', { x1: '2', x2: '22', y1: '10', y2: '10' })
])

const Smartphone = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '14', height: '20', x: '5', y: '2', rx: '2', ry: '2' }),
  h('line', { x1: '12', x2: '12.01', y1: '18', y2: '18' })
])

const QrCode = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '5', height: '5', x: '3', y: '3', rx: '1' }),
  h('rect', { width: '5', height: '5', x: '16', y: '3', rx: '1' }),
  h('rect', { width: '5', height: '5', x: '3', y: '16', rx: '1' }),
  h('path', { d: 'm21 16-3.5-3.5-1 1' }),
  h('path', { d: 'm21 21-3.5-3.5-1 1' }),
  h('path', { d: 'm21 11-3.5-3.5-1 1' })
])

const Plus = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M5 12h14' }),
  h('path', { d: 'm12 5 0 14' })
])

const ArrowUpDown = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'm21 16-4 4-4-4' }),
  h('path', { d: 'M17 20V4' }),
  h('path', { d: 'm3 8 4-4 4 4' }),
  h('path', { d: 'M7 4v16' })
])

const Wallet = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1' }),
  h('path', { d: 'M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4' })
])

const props = defineProps({
  customActions: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['action-click'])

const defaultActions = [
  {
    id: 'send',
    label: 'Send',
    icon: Send,
    color: '#007AFF'
  },
  {
    id: 'request',
    label: 'Request',
    icon: Download,
    color: '#34C759'
  },
  {
    id: 'pay',
    label: 'Pay',
    icon: CreditCard,
    color: '#FF3B30'
  },
  {
    id: 'top-up',
    label: 'Top Up',
    icon: Plus,
    color: '#FF9500'
  },
  {
    id: 'scan',
    label: 'Scan',
    icon: QrCode,
    color: '#AF52DE'
  },
  {
    id: 'transfer',
    label: 'Transfer',
    icon: ArrowUpDown,
    color: '#5AC8FA'
  },
  {
    id: 'mobile',
    label: 'Mobile',
    icon: Smartphone,
    color: '#FF2D92'
  },
  {
    id: 'more',
    label: 'More',
    icon: Wallet,
    color: '#8E8E93'
  }
]

const actions = computed(() => {
  return props.customActions.length > 0 ? props.customActions : defaultActions
})

const handleActionClick = (action) => {
  emit('action-click', action)
}
</script>

<style scoped>
.quick-actions {
  margin-bottom: 32px;
}

.quick-actions__title {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
  font-size: 20px;
  font-weight: 600;
  color: #1d1d1f;
  margin-bottom: 16px;
}

.quick-actions__grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.quick-actions__item {
  display: flex;
  flex-direction: column;
  align-items: center;
  background: none;
  border: none;
  cursor: pointer;
  padding: 16px 8px;
  border-radius: 16px;
  transition: all 0.2s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

.quick-actions__item:hover {
  background: rgba(0, 0, 0, 0.05);
  transform: translateY(-2px);
}

.quick-actions__item:active {
  transform: scale(0.95);
}

.quick-actions__icon {
  width: 56px;
  height: 56px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  margin-bottom: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.quick-actions__label {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  font-size: 12px;
  font-weight: 500;
  color: #1d1d1f;
  text-align: center;
  line-height: 1.2;
}

/* Responsive adjustments */
@media (max-width: 375px) {
  .quick-actions__grid {
    gap: 12px;
  }

  .quick-actions__item {
    padding: 12px 4px;
  }

  .quick-actions__icon {
    width: 48px;
    height: 48px;
  }

  .quick-actions__label {
    font-size: 11px;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .quick-actions__title {
    color: #f2f2f7;
  }

  .quick-actions__item:hover {
    background: rgba(255, 255, 255, 0.1);
  }

  .quick-actions__label {
    color: #f2f2f7;
  }
}
</style>