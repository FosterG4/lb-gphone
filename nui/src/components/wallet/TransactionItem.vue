<template>
  <div 
    class="transaction-item"
    :class="{ 'transaction-item--clickable': clickable }"
    @click="handleClick"
  >
    <div class="transaction-item__icon">
      <div 
        class="transaction-item__icon-bg"
        :style="{ backgroundColor: iconColor }"
      >
        <component :is="iconComponent" :size="20" />
      </div>
    </div>

    <div class="transaction-item__content">
      <div class="transaction-item__main">
        <div class="transaction-item__title">{{ transaction.title || transaction.description }}</div>
        <div class="transaction-item__amount" :class="amountClass">
          {{ formattedAmount }}
        </div>
      </div>
      <div class="transaction-item__details">
        <div class="transaction-item__subtitle">
          {{ transaction.category || transaction.type }}
        </div>
        <div class="transaction-item__time">{{ formattedTime }}</div>
      </div>
    </div>

    <div v-if="showChevron" class="transaction-item__chevron">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
        <path d="M9 18l6-6-6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
    </div>
  </div>
</template>

<script setup>
import { computed, h } from 'vue'
import { formatCurrency } from '../../utils/currency'

// SVG Icons
const ArrowUpRight = () => h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'm7 17 10-10' }),
  h('path', { d: 'M7 7h10v10' })
])

const ArrowDownLeft = () => h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M17 7 7 17' }),
  h('path', { d: 'M17 17H7V7' })
])

const CreditCard = () => h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '20', height: '14', x: '2', y: '5', rx: '2' }),
  h('line', { x1: '2', x2: '22', y1: '10', y2: '10' })
])

const Smartphone = () => h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '14', height: '20', x: '5', y: '2', rx: '2', ry: '2' }),
  h('line', { x1: '12', x2: '12.01', y1: '18', y2: '18' })
])

const Car = () => h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9L18.4 10H5.6L3.5 11.1C2.7 11.3 2 12.1 2 13v3c0 .6.4 1 1 1h2' }),
  h('circle', { cx: '7', cy: '17', r: '2' }),
  h('path', { d: 'M9 17h6' }),
  h('circle', { cx: '17', cy: '17', r: '2' })
])

const ShoppingBag = () => h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z' }),
  h('path', { d: 'M3 6h18' }),
  h('path', { d: 'M16 10a4 4 0 0 1-8 0' })
])

const Coffee = () => h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M10 2v2a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2V2' }),
  h('path', { d: 'M7 8h10v9a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2Z' }),
  h('path', { d: 'M7 15h10' })
])

const Home = () => h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'm3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z' }),
  h('polyline', { points: '9,22 9,12 15,12 15,22' })
])

const Gamepad2 = () => h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('line', { x1: '6', x2: '10', y1: '12', y2: '12' }),
  h('line', { x1: '8', x2: '8', y1: '10', y2: '14' }),
  h('line', { x1: '15', x2: '15.01', y1: '13', y2: '13' }),
  h('line', { x1: '18', x2: '18.01', y1: '11', y2: '11' }),
  h('rect', { width: '20', height: '12', x: '2', y: '6', rx: '2' })
])

const DollarSign = () => h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('line', { x1: '12', x2: '12', y1: '2', y2: '22' }),
  h('path', { d: 'M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6' })
])

const props = defineProps({
  transaction: {
    type: Object,
    required: true
  },
  clickable: {
    type: Boolean,
    default: true
  },
  showChevron: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits(['click'])

const iconComponent = computed(() => {
  const category = props.transaction.category?.toLowerCase() || props.transaction.type?.toLowerCase()
  
  const iconMap = {
    'transfer': props.transaction.amount > 0 ? ArrowDownLeft : ArrowUpRight,
    'payment': CreditCard,
    'mobile': Smartphone,
    'transport': Car,
    'shopping': ShoppingBag,
    'food': Coffee,
    'housing': Home,
    'entertainment': Gamepad2,
    'income': ArrowDownLeft,
    'expense': ArrowUpRight,
    'deposit': ArrowDownLeft,
    'withdrawal': ArrowUpRight
  }
  
  return iconMap[category] || DollarSign
})

const iconColor = computed(() => {
  const category = props.transaction.category?.toLowerCase() || props.transaction.type?.toLowerCase()
  
  const colorMap = {
    'transfer': '#007AFF',
    'payment': '#FF3B30',
    'mobile': '#34C759',
    'transport': '#FF9500',
    'shopping': '#AF52DE',
    'food': '#FF2D92',
    'housing': '#5AC8FA',
    'entertainment': '#FFCC00',
    'income': '#30D158',
    'expense': '#FF453A',
    'deposit': '#30D158',
    'withdrawal': '#FF453A'
  }
  
  return colorMap[category] || '#8E8E93'
})

const formattedAmount = computed(() => {
  const amount = Math.abs(props.transaction.amount)
  const sign = props.transaction.amount >= 0 ? '+' : '-'
  
  return `${sign}${formatCurrency(amount)}`
})

const amountClass = computed(() => {
  if (props.transaction.amount > 0) return 'transaction-item__amount--positive'
  if (props.transaction.amount < 0) return 'transaction-item__amount--negative'
  return 'transaction-item__amount--neutral'
})

const formattedTime = computed(() => {
  if (!props.transaction.date && !props.transaction.timestamp) return ''
  
  const date = new Date(props.transaction.date || props.transaction.timestamp)
  const now = new Date()
  const diffInHours = (now - date) / (1000 * 60 * 60)
  
  if (diffInHours < 1) {
    const minutes = Math.floor(diffInHours * 60)
    return `${minutes}m ago`
  } else if (diffInHours < 24) {
    const hours = Math.floor(diffInHours)
    return `${hours}h ago`
  } else if (diffInHours < 48) {
    return 'Yesterday'
  } else {
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric' 
    })
  }
})

const handleClick = () => {
  if (props.clickable) {
    emit('click', props.transaction)
  }
}
</script>

<style scoped>
.transaction-item {
  display: flex;
  align-items: center;
  padding: 16px 0;
  border-bottom: 1px solid rgba(0, 0, 0, 0.1);
  transition: background-color 0.2s;
}

.transaction-item:last-child {
  border-bottom: none;
}

.transaction-item--clickable {
  cursor: pointer;
}

.transaction-item--clickable:hover {
  background: rgba(0, 0, 0, 0.02);
}

.transaction-item--clickable:active {
  background: rgba(0, 0, 0, 0.05);
}

.transaction-item__icon {
  margin-right: 16px;
}

.transaction-item__icon-bg {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.transaction-item__content {
  flex: 1;
  min-width: 0;
}

.transaction-item__main {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 4px;
}

.transaction-item__title {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  font-size: 16px;
  font-weight: 500;
  color: #1d1d1f;
  truncate: true;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.transaction-item__amount {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  font-size: 16px;
  font-weight: 600;
  margin-left: 12px;
}

.transaction-item__amount--positive {
  color: #30D158;
}

.transaction-item__amount--negative {
  color: #FF453A;
}

.transaction-item__amount--neutral {
  color: #8E8E93;
}

.transaction-item__details {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.transaction-item__subtitle {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  font-size: 14px;
  font-weight: 400;
  color: #8e8e93;
  truncate: true;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.transaction-item__time {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  font-size: 14px;
  font-weight: 400;
  color: #8e8e93;
  margin-left: 12px;
}

.transaction-item__chevron {
  margin-left: 12px;
  color: #c7c7cc;
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .transaction-item {
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  }

  .transaction-item--clickable:hover {
    background: rgba(255, 255, 255, 0.05);
  }

  .transaction-item--clickable:active {
    background: rgba(255, 255, 255, 0.1);
  }

  .transaction-item__title {
    color: #f2f2f7;
  }

  .transaction-item__subtitle,
  .transaction-item__time {
    color: #8e8e93;
  }

  .transaction-item__chevron {
    color: #48484a;
  }
}
</style>