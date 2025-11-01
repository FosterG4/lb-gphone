<template>
  <div class="transactions-page">
    <!-- Search and Filter Header -->
    <div class="search-section">
      <div class="search-bar">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" class="search-icon">
          <circle cx="11" cy="11" r="8" stroke="currentColor" stroke-width="2"/>
          <path d="m21 21-4.35-4.35" stroke="currentColor" stroke-width="2"/>
        </svg>
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search transactions..."
          class="search-input"
        />
        <button v-if="searchQuery" @click="clearSearch" class="clear-btn">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <line x1="18" y1="6" x2="6" y2="18" stroke="currentColor" stroke-width="2"/>
            <line x1="6" y1="6" x2="18" y2="18" stroke="currentColor" stroke-width="2"/>
          </svg>
        </button>
      </div>

      <button @click="showFilters = !showFilters" class="filter-btn" :class="{ active: hasActiveFilters }">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
          <polygon points="22,3 2,3 10,12.46 10,19 14,21 14,12.46" stroke="currentColor" stroke-width="2"/>
        </svg>
        Filter
      </button>
    </div>

    <!-- Filter Panel -->
    <div v-if="showFilters" class="filter-panel">
      <IOSCard variant="glass">
        <template #content>
          <div class="filter-content">
            <!-- Date Range -->
            <div class="filter-group">
              <label class="filter-label">Date Range</label>
              <div class="date-range-buttons">
                <button
                  v-for="range in dateRanges"
                  :key="range.value"
                  @click="setDateRange(range.value)"
                  class="date-range-btn"
                  :class="{ active: selectedDateRange === range.value }"
                >
                  {{ range.label }}
                </button>
              </div>
            </div>

            <!-- Transaction Type -->
            <div class="filter-group">
              <label class="filter-label">Type</label>
              <div class="type-buttons">
                <button
                  v-for="type in transactionTypes"
                  :key="type.value"
                  @click="toggleType(type.value)"
                  class="type-btn"
                  :class="{ active: selectedTypes.includes(type.value) }"
                >
                  {{ type.label }}
                </button>
              </div>
            </div>

            <!-- Amount Range -->
            <div class="filter-group">
              <label class="filter-label">Amount Range</label>
              <div class="amount-inputs">
                <input
                  v-model="minAmount"
                  type="number"
                  placeholder="Min"
                  class="amount-input"
                />
                <span class="amount-separator">to</span>
                <input
                  v-model="maxAmount"
                  type="number"
                  placeholder="Max"
                  class="amount-input"
                />
              </div>
            </div>

            <!-- Filter Actions -->
            <div class="filter-actions">
              <IOSButton variant="secondary" @click="clearFilters">
                Clear All
              </IOSButton>
              <IOSButton variant="primary" @click="applyFilters">
                Apply Filters
              </IOSButton>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Transactions List -->
    <div class="transactions-list">
      <!-- Loading State -->
      <div v-if="loading" class="loading-state">
        <div class="loading-spinner"></div>
        <span>Loading transactions...</span>
      </div>

      <!-- Empty State -->
      <div v-else-if="filteredTransactions.length === 0" class="empty-state">
        <div class="empty-icon">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none">
            <rect x="2" y="3" width="20" height="14" rx="2" ry="2" stroke="currentColor" stroke-width="2"/>
            <line x1="8" y1="21" x2="16" y2="21" stroke="currentColor" stroke-width="2"/>
            <line x1="12" y1="17" x2="12" y2="21" stroke="currentColor" stroke-width="2"/>
          </svg>
        </div>
        <h3 class="empty-title">No transactions found</h3>
        <p class="empty-description">
          {{ searchQuery ? 'Try adjusting your search or filters' : 'Your transactions will appear here' }}
        </p>
      </div>

      <!-- Transactions by Date -->
      <div v-else class="transactions-container">
        <div
          v-for="group in groupedTransactions"
          :key="group.date"
          class="transaction-group"
        >
          <div class="group-header">
            <h3 class="group-date">{{ formatGroupDate(group.date) }}</h3>
            <span class="group-total">{{ formatGroupTotal(group.transactions) }}</span>
          </div>

          <div class="group-transactions">
            <TransactionItem
              v-for="transaction in group.transactions"
              :key="transaction.id"
              :transaction="transaction"
              @click="viewTransactionDetails(transaction)"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Load More Button -->
    <div v-if="hasMoreTransactions && !loading" class="load-more-section">
      <IOSButton variant="secondary" full-width @click="loadMoreTransactions">
        Load More Transactions
      </IOSButton>
    </div>

    <!-- Transaction Details Modal -->
    <IOSModal
      v-model="showTransactionDetails"
      title="Transaction Details"
      size="medium"
    >
      <div v-if="selectedTransaction" class="transaction-details">
        <div class="detail-header">
          <div class="detail-icon" :class="selectedTransaction.type">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
              <path v-if="selectedTransaction.amount > 0" d="M12 2v20M5 9l7-7 7 7" stroke="currentColor" stroke-width="2"/>
              <path v-else d="M12 22V2M19 15l-7 7-7-7" stroke="currentColor" stroke-width="2"/>
            </svg>
          </div>
          <div class="detail-amount" :class="selectedTransaction.type">
            {{ selectedTransaction.amount > 0 ? '+' : '' }}{{ formatCurrency(Math.abs(selectedTransaction.amount)) }}
          </div>
        </div>

        <div class="detail-info">
          <div class="detail-row">
            <span class="detail-label">To/From</span>
            <span class="detail-value">{{ selectedTransaction.description }}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Date</span>
            <span class="detail-value">{{ formatTransactionDate(selectedTransaction.date) }}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Category</span>
            <span class="detail-value">{{ selectedTransaction.category }}</span>
          </div>
          <div class="detail-row">
            <span class="detail-label">Transaction ID</span>
            <span class="detail-value">{{ selectedTransaction.id }}</span>
          </div>
          <div v-if="selectedTransaction.note" class="detail-row">
            <span class="detail-label">Note</span>
            <span class="detail-value">{{ selectedTransaction.note }}</span>
          </div>
        </div>

        <div class="detail-actions">
          <IOSButton variant="secondary" full-width @click="shareTransaction">
            Share Transaction
          </IOSButton>
        </div>
      </div>
    </IOSModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useStore } from 'vuex'
import { formatCurrency } from '../../../utils/currency'

// Components
import TransactionItem from '../TransactionItem.vue'
import IOSCard from '../../ios/IOSCard.vue'
import IOSModal from '../../ios/IOSModal.vue'
import IOSButton from '../../ios/IOSButton.vue'

const store = useStore()

// State
const searchQuery = ref('')
const showFilters = ref(false)
const selectedDateRange = ref('all')
const selectedTypes = ref(['all'])
const minAmount = ref('')
const maxAmount = ref('')
const loading = ref(false)
const showTransactionDetails = ref(false)
const selectedTransaction = ref(null)
const currentPage = ref(1)
const pageSize = 20

// Filter options
const dateRanges = [
  { label: 'All Time', value: 'all' },
  { label: 'Today', value: 'today' },
  { label: 'This Week', value: 'week' },
  { label: 'This Month', value: 'month' },
  { label: 'Last 3 Months', value: '3months' }
]

const transactionTypes = [
  { label: 'All', value: 'all' },
  { label: 'Income', value: 'income' },
  { label: 'Expense', value: 'expense' },
  { label: 'Transfer', value: 'transfer' }
]

// Computed properties
const transactions = computed(() => store.state.wallet.transactions)

const hasActiveFilters = computed(() => {
  return selectedDateRange.value !== 'all' ||
         !selectedTypes.value.includes('all') ||
         minAmount.value ||
         maxAmount.value ||
         searchQuery.value
})

const filteredTransactions = computed(() => {
  let filtered = [...transactions.value]

  // Search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(t =>
      t.description.toLowerCase().includes(query) ||
      t.category.toLowerCase().includes(query)
    )
  }

  // Date range filter
  if (selectedDateRange.value !== 'all') {
    const now = new Date()
    const startDate = getDateRangeStart(selectedDateRange.value, now)
    filtered = filtered.filter(t => new Date(t.date) >= startDate)
  }

  // Type filter
  if (!selectedTypes.value.includes('all')) {
    filtered = filtered.filter(t => {
      if (selectedTypes.value.includes('income') && t.amount > 0) return true
      if (selectedTypes.value.includes('expense') && t.amount < 0) return true
      if (selectedTypes.value.includes('transfer') && t.type === 'transfer') return true
      return false
    })
  }

  // Amount range filter
  if (minAmount.value || maxAmount.value) {
    filtered = filtered.filter(t => {
      const amount = Math.abs(t.amount)
      const min = minAmount.value ? parseFloat(minAmount.value) : 0
      const max = maxAmount.value ? parseFloat(maxAmount.value) : Infinity
      return amount >= min && amount <= max
    })
  }

  // Sort by date (newest first)
  return filtered.sort((a, b) => new Date(b.date) - new Date(a.date))
})

const groupedTransactions = computed(() => {
  const groups = {}
  const paginatedTransactions = filteredTransactions.value.slice(0, currentPage.value * pageSize)

  paginatedTransactions.forEach(transaction => {
    const date = new Date(transaction.date).toDateString()
    if (!groups[date]) {
      groups[date] = []
    }
    groups[date].push(transaction)
  })

  return Object.keys(groups)
    .sort((a, b) => new Date(b) - new Date(a))
    .map(date => ({
      date,
      transactions: groups[date]
    }))
})

const hasMoreTransactions = computed(() => {
  return filteredTransactions.value.length > currentPage.value * pageSize
})

// Methods
const getDateRangeStart = (range, now) => {
  switch (range) {
    case 'today':
      return new Date(now.getFullYear(), now.getMonth(), now.getDate())
    case 'week':
      const weekStart = new Date(now)
      weekStart.setDate(now.getDate() - now.getDay())
      return weekStart
    case 'month':
      return new Date(now.getFullYear(), now.getMonth(), 1)
    case '3months':
      return new Date(now.getFullYear(), now.getMonth() - 3, 1)
    default:
      return new Date(0)
  }
}

const setDateRange = (range) => {
  selectedDateRange.value = range
}

const toggleType = (type) => {
  if (type === 'all') {
    selectedTypes.value = ['all']
  } else {
    const index = selectedTypes.value.indexOf('all')
    if (index > -1) {
      selectedTypes.value.splice(index, 1)
    }
    
    const typeIndex = selectedTypes.value.indexOf(type)
    if (typeIndex > -1) {
      selectedTypes.value.splice(typeIndex, 1)
    } else {
      selectedTypes.value.push(type)
    }
    
    if (selectedTypes.value.length === 0) {
      selectedTypes.value = ['all']
    }
  }
}

const clearSearch = () => {
  searchQuery.value = ''
}

const clearFilters = () => {
  selectedDateRange.value = 'all'
  selectedTypes.value = ['all']
  minAmount.value = ''
  maxAmount.value = ''
  searchQuery.value = ''
  showFilters.value = false
}

const applyFilters = () => {
  showFilters.value = false
  currentPage.value = 1
}

const formatGroupDate = (dateString) => {
  const date = new Date(dateString)
  const today = new Date()
  const yesterday = new Date(today)
  yesterday.setDate(yesterday.getDate() - 1)

  if (date.toDateString() === today.toDateString()) {
    return 'Today'
  } else if (date.toDateString() === yesterday.toDateString()) {
    return 'Yesterday'
  } else {
    return date.toLocaleDateString('en-US', { 
      weekday: 'long', 
      month: 'short', 
      day: 'numeric' 
    })
  }
}

const formatGroupTotal = (transactions) => {
  const total = transactions.reduce((sum, t) => sum + t.amount, 0)
  const sign = total >= 0 ? '+' : '-'
  return `${sign}${formatCurrency(Math.abs(total))}`
}

const formatTransactionDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const viewTransactionDetails = (transaction) => {
  selectedTransaction.value = transaction
  showTransactionDetails.value = true
}

const shareTransaction = () => {
  // Handle share transaction
  console.log('Share transaction:', selectedTransaction.value)
}

const loadMoreTransactions = () => {
  currentPage.value++
}

// Initialize data
onMounted(() => {
  store.dispatch('wallet/fetchTransactions')
})

// Reset pagination when filters change
watch([searchQuery, selectedDateRange, selectedTypes, minAmount, maxAmount], () => {
  currentPage.value = 1
})
</script>

<style scoped>
.transactions-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Search and Filter */
.search-section {
  display: flex;
  gap: 12px;
  align-items: center;
}

.search-bar {
  flex: 1;
  position: relative;
  display: flex;
  align-items: center;
}

.search-icon {
  position: absolute;
  left: 16px;
  color: #8e8e93;
  z-index: 2;
}

.search-input {
  width: 100%;
  padding: 12px 16px 12px 48px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  font-size: 16px;
  color: #1d1d1f;
  transition: all 0.2s ease;
}

.search-input:focus {
  outline: none;
  border-color: #007AFF;
  background: rgba(255, 255, 255, 1);
}

.search-input::placeholder {
  color: #8e8e93;
}

.clear-btn {
  position: absolute;
  right: 12px;
  background: none;
  border: none;
  color: #8e8e93;
  cursor: pointer;
  padding: 4px;
  border-radius: 6px;
  transition: all 0.2s ease;
}

.clear-btn:hover {
  background: rgba(0, 0, 0, 0.1);
}

.filter-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  color: #1d1d1f;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.filter-btn:hover {
  background: rgba(255, 255, 255, 1);
}

.filter-btn.active {
  background: #007AFF;
  color: white;
  border-color: #007AFF;
}

/* Filter Panel */
.filter-panel {
  margin-top: -8px;
}

.filter-content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.filter-label {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
}

.date-range-buttons,
.type-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.date-range-btn,
.type-btn {
  padding: 8px 16px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.8);
  color: #1d1d1f;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.date-range-btn:hover,
.type-btn:hover {
  background: rgba(255, 255, 255, 1);
}

.date-range-btn.active,
.type-btn.active {
  background: #007AFF;
  color: white;
  border-color: #007AFF;
}

.amount-inputs {
  display: flex;
  align-items: center;
  gap: 12px;
}

.amount-input {
  flex: 1;
  padding: 12px 16px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.8);
  font-size: 16px;
  color: #1d1d1f;
}

.amount-input:focus {
  outline: none;
  border-color: #007AFF;
  background: rgba(255, 255, 255, 1);
}

.amount-separator {
  color: #8e8e93;
  font-weight: 500;
}

.filter-actions {
  display: flex;
  gap: 12px;
  margin-top: 8px;
}

/* Transactions List */
.transactions-list {
  flex: 1;
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 40px 20px;
  color: #8e8e93;
}

.loading-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid rgba(0, 122, 255, 0.3);
  border-top: 3px solid #007AFF;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 40px 20px;
  text-align: center;
}

.empty-icon {
  color: #8e8e93;
  opacity: 0.6;
}

.empty-title {
  font-size: 20px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.empty-description {
  font-size: 16px;
  color: #8e8e93;
  margin: 0;
  max-width: 280px;
}

.transactions-container {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.transaction-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.group-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 4px;
}

.group-date {
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.group-total {
  font-size: 16px;
  font-weight: 600;
  color: #8e8e93;
}

.group-transactions {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  border-radius: 16px;
  overflow: hidden;
  border: 1px solid rgba(0, 0, 0, 0.1);
}

/* Load More */
.load-more-section {
  margin-top: 8px;
}

/* Transaction Details Modal */
.transaction-details {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.detail-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  text-align: center;
  padding: 20px 0;
}

.detail-icon {
  width: 60px;
  height: 60px;
  border-radius: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.detail-icon.income {
  background: linear-gradient(135deg, #34C759, #30D158);
}

.detail-icon.expense {
  background: linear-gradient(135deg, #FF3B30, #FF453A);
}

.detail-amount {
  font-size: 32px;
  font-weight: 700;
}

.detail-amount.income {
  color: #34C759;
}

.detail-amount.expense {
  color: #FF3B30;
}

.detail-info {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid rgba(0, 0, 0, 0.1);
}

.detail-row:last-child {
  border-bottom: none;
}

.detail-label {
  font-size: 16px;
  color: #8e8e93;
  font-weight: 500;
}

.detail-value {
  font-size: 16px;
  color: #1d1d1f;
  font-weight: 500;
  text-align: right;
  max-width: 60%;
  word-break: break-word;
}

/* Responsive Design */
@media (max-width: 375px) {
  .search-section {
    flex-direction: column;
    gap: 12px;
  }

  .filter-btn {
    width: 100%;
    justify-content: center;
  }

  .amount-inputs {
    flex-direction: column;
    gap: 8px;
  }

  .amount-separator {
    display: none;
  }

  .filter-actions {
    flex-direction: column;
  }

  .group-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .search-input {
    background: rgba(28, 28, 30, 0.95);
    border-color: rgba(255, 255, 255, 0.1);
    color: #f2f2f7;
  }

  .search-input:focus {
    background: rgba(28, 28, 30, 1);
    border-color: #0A84FF;
  }

  .search-input::placeholder {
    color: #8e8e93;
  }

  .filter-btn {
    background: rgba(28, 28, 30, 0.95);
    border-color: rgba(255, 255, 255, 0.1);
    color: #f2f2f7;
  }

  .filter-btn:hover {
    background: rgba(28, 28, 30, 1);
  }

  .filter-btn.active {
    background: #0A84FF;
    border-color: #0A84FF;
  }

  .filter-label {
    color: #f2f2f7;
  }

  .date-range-btn,
  .type-btn {
    background: rgba(44, 44, 46, 0.8);
    border-color: rgba(255, 255, 255, 0.1);
    color: #f2f2f7;
  }

  .date-range-btn:hover,
  .type-btn:hover {
    background: rgba(44, 44, 46, 1);
  }

  .date-range-btn.active,
  .type-btn.active {
    background: #0A84FF;
    border-color: #0A84FF;
  }

  .amount-input {
    background: rgba(44, 44, 46, 0.8);
    border-color: rgba(255, 255, 255, 0.1);
    color: #f2f2f7;
  }

  .amount-input:focus {
    background: rgba(44, 44, 46, 1);
    border-color: #0A84FF;
  }

  .empty-title,
  .group-date {
    color: #f2f2f7;
  }

  .group-transactions {
    background: rgba(28, 28, 30, 0.95);
    border-color: rgba(255, 255, 255, 0.1);
  }

  .detail-value {
    color: #f2f2f7;
  }

  .detail-row {
    border-bottom-color: rgba(255, 255, 255, 0.1);
  }
}
</style>