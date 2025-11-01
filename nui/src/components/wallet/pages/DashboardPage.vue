<template>
  <div class="dashboard-page">
    <!-- Balance Overview -->
    <BalanceCard
      :balance="totalBalance"
      :change="balanceChange"
      :accounts="accounts"
      :selected-account="selectedAccount"
      @account-change="handleAccountChange"
      @menu-click="openAccountMenu"
    />

    <!-- Quick Actions -->
    <QuickActions
      :actions="quickActions"
      @action-click="handleQuickAction"
    />

    <!-- Recent Transactions -->
    <div class="recent-transactions">
      <div class="section-header">
        <h2 class="section-title">Recent Activity</h2>
        <button class="view-all-btn" @click="viewAllTransactions">
          View All
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <path d="m9 18 6-6-6-6" stroke="currentColor" stroke-width="2"/>
          </svg>
        </button>
      </div>

      <div class="transactions-container">
        <TransactionItem
          v-for="transaction in recentTransactions"
          :key="transaction.id"
          :transaction="transaction"
          @click="viewTransaction(transaction)"
        />
      </div>
    </div>

    <!-- Financial Insights -->
    <div class="insights-section">
      <IOSCard variant="glass" class="insights-card">
        <template #header>
          <div class="insights-header">
            <h3>This Month</h3>
            <span class="insights-period">{{ currentMonth }}</span>
          </div>
        </template>
        
        <template #content>
          <div class="insights-grid">
            <div class="insight-item">
              <div class="insight-icon income">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                  <path d="M12 2v20M5 9l7-7 7 7" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
              <div class="insight-details">
                <span class="insight-label">Income</span>
                <span class="insight-value">{{ formatAmount(monthlyIncome) }}</span>
              </div>
            </div>

            <div class="insight-item">
              <div class="insight-icon expense">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                  <path d="M12 22V2M19 15l-7 7-7-7" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
              <div class="insight-details">
                <span class="insight-label">Expenses</span>
                <span class="insight-value">{{ formatAmount(monthlyExpenses) }}</span>
              </div>
            </div>

            <div class="insight-item">
              <div class="insight-icon savings">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
                  <path d="m9 12 2 2 4-4" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
              <div class="insight-details">
                <span class="insight-label">Savings</span>
                <span class="insight-value">{{ formatAmount(monthlySavings) }}</span>
              </div>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Account Menu Modal -->
    <IOSModal
      v-model="showAccountMenu"
      title="Account Options"
      size="small"
    >
      <div class="account-menu">
        <IOSButton
          variant="secondary"
          full-width
          @click="addAccount"
          class="menu-button"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <line x1="12" y1="5" x2="12" y2="19" stroke="currentColor" stroke-width="2"/>
            <line x1="5" y1="12" x2="19" y2="12" stroke="currentColor" stroke-width="2"/>
          </svg>
          Add Account
        </IOSButton>
        
        <IOSButton
          variant="secondary"
          full-width
          @click="manageAccounts"
          class="menu-button"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/>
            <path d="M12 1v6M12 17v6M4.22 4.22l4.24 4.24M15.54 15.54l4.24 4.24M1 12h6M17 12h6M4.22 19.78l4.24-4.24M15.54 8.46l4.24-4.24" stroke="currentColor" stroke-width="2"/>
          </svg>
          Manage Accounts
        </IOSButton>
      </div>
    </IOSModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useStore } from 'vuex'
import { h } from 'vue'
import { formatCurrency } from '../../../utils/currency'

// SVG Icons
const Send = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'm22 2-7 20-4-9-9-4Z' }),
  h('path', { d: 'M22 2 11 13' })
])

const Receipt = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1-2-1Z' }),
  h('path', { d: 'M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8' }),
  h('path', { d: 'M12 18V6' })
])

const CreditCard = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '20', height: '14', x: '2', y: '5', rx: '2' }),
  h('line', { x1: '2', x2: '22', y1: '10', y2: '10' })
])

const Smartphone = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '14', height: '20', x: '5', y: '2', rx: '2', ry: '2' }),
  h('line', { x1: '12', x2: '12.01', y1: '18', y2: '18' })
])

const DollarSign = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('line', { x1: '12', x2: '12', y1: '2', y2: '22' }),
  h('path', { d: 'M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6' })
])

const TrendingUp = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('polyline', { points: '22,7 13.5,15.5 8.5,10.5 2,17' }),
  h('polyline', { points: '16,7 22,7 22,13' })
])

// Components
import BalanceCard from '../BalanceCard.vue'
import QuickActions from '../QuickActions.vue'
import TransactionItem from '../TransactionItem.vue'
import IOSCard from '../../ios/IOSCard.vue'
import IOSModal from '../../ios/IOSModal.vue'
import IOSButton from '../../ios/IOSButton.vue'

const store = useStore()
const emit = defineEmits(['navigate'])

// State
const selectedAccount = ref('main')
const showAccountMenu = ref(false)

// Quick actions configuration
const quickActions = ref([
  {
    id: 'send',
    label: 'Send',
    icon: Send,
    color: '#007AFF'
  },
  {
    id: 'request',
    label: 'Request',
    icon: Receipt,
    color: '#34C759'
  },
  {
    id: 'pay',
    label: 'Pay',
    icon: CreditCard,
    color: '#FF9500'
  },
  {
    id: 'topup',
    label: 'Top Up',
    icon: Smartphone,
    color: '#AF52DE'
  }
])

// Computed properties
const accounts = computed(() => store.state.wallet.accounts)
const transactions = computed(() => store.state.wallet.transactions)
const analytics = computed(() => store.state.wallet.analytics)

const totalBalance = computed(() => {
  const account = accounts.value.find(acc => acc.id === selectedAccount.value)
  return account ? account.balance : 0
})

const balanceChange = computed(() => {
  const account = accounts.value.find(acc => acc.id === selectedAccount.value)
  return account ? account.change : 0
})

const recentTransactions = computed(() => {
  return transactions.value
    .filter(t => t.accountId === selectedAccount.value)
    .slice(0, 5)
})

const currentMonth = computed(() => {
  return new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
})

const monthlyIncome = computed(() => {
  const currentDate = new Date()
  const currentMonth = currentDate.getMonth()
  const currentYear = currentDate.getFullYear()
  
  return transactions.value
    .filter(t => {
      const transactionDate = new Date(t.date)
      return transactionDate.getMonth() === currentMonth &&
             transactionDate.getFullYear() === currentYear &&
             t.amount > 0
    })
    .reduce((sum, t) => sum + t.amount, 0)
})

const monthlyExpenses = computed(() => {
  const currentDate = new Date()
  const currentMonth = currentDate.getMonth()
  const currentYear = currentDate.getFullYear()
  
  return Math.abs(transactions.value
    .filter(t => {
      const transactionDate = new Date(t.date)
      return transactionDate.getMonth() === currentMonth &&
             transactionDate.getFullYear() === currentYear &&
             t.amount < 0
    })
    .reduce((sum, t) => sum + t.amount, 0))
})

const monthlySavings = computed(() => {
  return monthlyIncome.value - monthlyExpenses.value
})

// Methods
const formatAmount = (amount) => {
  return formatCurrency(amount)
}

const handleAccountChange = (accountId) => {
  selectedAccount.value = accountId
}

const openAccountMenu = () => {
  showAccountMenu.value = true
}

const handleQuickAction = (actionId) => {
  switch (actionId) {
    case 'send':
      emit('navigate', 'transfer')
      break
    case 'request':
      // Handle request money
      console.log('Request money')
      break
    case 'pay':
      // Handle pay bills
      console.log('Pay bills')
      break
    case 'topup':
      // Handle top up
      console.log('Top up')
      break
  }
}

const viewAllTransactions = () => {
  emit('navigate', 'transactions')
}

const viewTransaction = (transaction) => {
  // Handle transaction details view
  console.log('View transaction:', transaction)
}

const addAccount = () => {
  showAccountMenu.value = false
  // Handle add account
  console.log('Add account')
}

const manageAccounts = () => {
  showAccountMenu.value = false
  emit('navigate', 'settings')
}

// Initialize data
onMounted(() => {
  store.dispatch('wallet/fetchAccounts')
  store.dispatch('wallet/fetchTransactions')
  store.dispatch('wallet/fetchAnalytics')
})
</script>

<style scoped>
.dashboard-page {
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding-bottom: 20px;
}

/* Recent Transactions */
.recent-transactions {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.section-title {
  font-size: 20px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.view-all-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  background: none;
  border: none;
  color: #007AFF;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: opacity 0.2s ease;
}

.view-all-btn:hover {
  opacity: 0.7;
}

.transactions-container {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  border-radius: 16px;
  overflow: hidden;
  border: 1px solid rgba(0, 0, 0, 0.1);
}

/* Financial Insights */
.insights-section {
  margin-top: 8px;
}

.insights-card {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(20px);
}

.insights-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.insights-header h3 {
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.insights-period {
  font-size: 14px;
  color: #8e8e93;
  font-weight: 500;
}

.insights-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
  margin-top: 16px;
}

.insight-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  border: 1px solid rgba(0, 0, 0, 0.05);
}

.insight-icon {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.insight-icon.income {
  background: linear-gradient(135deg, #34C759, #30D158);
}

.insight-icon.expense {
  background: linear-gradient(135deg, #FF3B30, #FF453A);
}

.insight-icon.savings {
  background: linear-gradient(135deg, #007AFF, #0A84FF);
}

.insight-details {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.insight-label {
  font-size: 14px;
  color: #8e8e93;
  font-weight: 500;
}

.insight-value {
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin-top: 2px;
}

/* Account Menu */
.account-menu {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 8px 0;
}

.menu-button {
  justify-content: flex-start;
  gap: 12px;
}

/* Responsive Design */
@media (max-width: 375px) {
  .dashboard-page {
    gap: 20px;
  }

  .section-title {
    font-size: 18px;
  }

  .insights-grid {
    gap: 12px;
  }

  .insight-item {
    padding: 10px;
  }

  .insight-value {
    font-size: 16px;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .section-title {
    color: #f2f2f7;
  }

  .transactions-container {
    background: rgba(28, 28, 30, 0.95);
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .insights-card {
    background: rgba(28, 28, 30, 0.8);
  }

  .insights-header h3 {
    color: #f2f2f7;
  }

  .insight-item {
    background: rgba(44, 44, 46, 0.5);
    border: 1px solid rgba(255, 255, 255, 0.05);
  }

  .insight-value {
    color: #f2f2f7;
  }
}
</style>