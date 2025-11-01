<template>
  <IOSCard variant="glass" :elevated="true" class="balance-card">
    <div class="balance-card__content">
      <!-- Account Selector -->
      <div class="balance-card__header">
        <select :value="selectedAccount" @change="$emit('update:selectedAccount', $event.target.value)" class="balance-card__selector">
          <option v-for="account in accounts" :key="account.id" :value="account.id">
            {{ account.name }}
          </option>
        </select>
        <button class="balance-card__menu" @click="$emit('menu-click')">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="1" fill="currentColor"/>
            <circle cx="19" cy="12" r="1" fill="currentColor"/>
            <circle cx="5" cy="12" r="1" fill="currentColor"/>
          </svg>
        </button>
      </div>

      <!-- Balance Display -->
      <div class="balance-card__balance">
        <div class="balance-card__amount">
          <span class="balance-card__currency">{{ currencySymbol }}</span>
          <span class="balance-card__value">{{ formattedBalance }}</span>
        </div>
        <div class="balance-card__change" :class="changeClass">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
            <path 
              :d="changeIcon" 
              stroke="currentColor" 
              stroke-width="2" 
              stroke-linecap="round" 
              stroke-linejoin="round"
            />
          </svg>
          <span>{{ formattedChange }}</span>
        </div>
      </div>

      <!-- Account Info -->
      <div class="balance-card__info">
        <div class="balance-card__account-number">
          •••• •••• •••• {{ currentAccount?.number?.slice(-4) || '0000' }}
        </div>
        <div class="balance-card__account-type">
          {{ currentAccount?.type || 'Checking Account' }}
        </div>
      </div>
    </div>
  </IOSCard>
</template>

<script setup>
import { computed } from 'vue'
import IOSCard from '../ios/IOSCard.vue'
import { formatCurrency, getCurrencySymbol } from '../../utils/currency'

const props = defineProps({
  accounts: {
    type: Array,
    default: () => []
  },
  selectedAccount: {
    type: String,
    default: ''
  },
  balance: {
    type: Number,
    default: 0
  },
  change: {
    type: Number,
    default: 0
  },
  changePercent: {
    type: Number,
    default: 0
  }
})

const emit = defineEmits(['update:selectedAccount', 'menu-click'])

const currentAccount = computed(() => {
  return props.accounts.find(account => account.id === props.selectedAccount) || props.accounts[0]
})

const currencySymbol = computed(() => {
  return getCurrencySymbol()
})

const formattedBalance = computed(() => {
  // Format without currency symbol since we display it separately
  const formatted = formatCurrency(Math.abs(props.balance))
  // Remove currency symbol from formatted string
  return formatted.replace(/[$¥€R\s]/g, '').trim()
})

const formattedChange = computed(() => {
  const change = Math.abs(props.changePercent)
  return `${change.toFixed(2)}%`
})

const changeClass = computed(() => {
  if (props.changePercent > 0) return 'balance-card__change--positive'
  if (props.changePercent < 0) return 'balance-card__change--negative'
  return 'balance-card__change--neutral'
})

const changeIcon = computed(() => {
  if (props.changePercent > 0) return 'M7 14l5-5 5 5'
  if (props.changePercent < 0) return 'M17 10l-5 5-5-5'
  return 'M5 12h14'
})
</script>

<style scoped>
.balance-card {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  margin-bottom: 24px;
}

.balance-card__content {
  padding: 24px;
}

.balance-card__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.balance-card__selector {
  background: rgba(255, 255, 255, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 12px;
  color: white;
  padding: 8px 12px;
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  font-size: 14px;
  font-weight: 500;
  outline: none;
  cursor: pointer;
}

.balance-card__selector option {
  background: #1c1c1e;
  color: white;
}

.balance-card__menu {
  background: rgba(255, 255, 255, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 10px;
  color: white;
  padding: 8px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.balance-card__menu:hover {
  background: rgba(255, 255, 255, 0.3);
}

.balance-card__balance {
  text-align: center;
  margin-bottom: 24px;
}

.balance-card__amount {
  display: flex;
  align-items: baseline;
  justify-content: center;
  margin-bottom: 8px;
}

.balance-card__currency {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
  font-size: 24px;
  font-weight: 300;
  margin-right: 4px;
}

.balance-card__value {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
  font-size: 36px;
  font-weight: 600;
  letter-spacing: -0.02em;
}

.balance-card__change {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  font-size: 14px;
  font-weight: 500;
}

.balance-card__change--positive {
  color: #30d158;
}

.balance-card__change--negative {
  color: #ff453a;
}

.balance-card__change--neutral {
  color: rgba(255, 255, 255, 0.7);
}

.balance-card__info {
  text-align: center;
}

.balance-card__account-number {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  font-size: 16px;
  font-weight: 500;
  margin-bottom: 4px;
  letter-spacing: 0.02em;
}

.balance-card__account-type {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  font-size: 14px;
  font-weight: 400;
  color: rgba(255, 255, 255, 0.8);
}

/* Responsive adjustments */
@media (max-width: 375px) {
  .balance-card__content {
    padding: 20px;
  }

  .balance-card__currency {
    font-size: 20px;
  }

  .balance-card__value {
    font-size: 32px;
  }
}
</style>