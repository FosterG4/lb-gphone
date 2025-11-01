<template>
  <div class="cards-page">
    <!-- Header Actions -->
    <div class="header-actions">
      <IOSButton variant="secondary" @click="addCard" class="add-card-btn">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
          <line x1="12" y1="5" x2="12" y2="19" stroke="currentColor" stroke-width="2"/>
          <line x1="5" y1="12" x2="19" y2="12" stroke="currentColor" stroke-width="2"/>
        </svg>
        Add Card
      </IOSButton>
      
      <IOSButton variant="ghost" @click="scanCard" class="scan-btn">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
          <path d="M9 12l2 2 4-4" stroke="currentColor" stroke-width="2"/>
          <path d="M21 12c-1 0-3-1-3-3s2-3 3-3 3 1 3 3-2 3-3 3" stroke="currentColor" stroke-width="2"/>
          <path d="M3 12c1 0 3-1 3-3s-2-3-3-3-3 1-3 3 2 3 3 3" stroke="currentColor" stroke-width="2"/>
        </svg>
        Scan Card
      </IOSButton>
    </div>

    <!-- Cards Carousel -->
    <div class="cards-carousel" v-if="cards.length > 0">
      <div class="carousel-container" ref="carouselContainer">
        <div 
          class="card-wrapper"
          v-for="(card, index) in cards"
          :key="card.id"
          :class="{ active: index === activeCardIndex }"
          @click="setActiveCard(index)"
        >
          <div class="credit-card" :class="[card.type, card.brand]">
            <div class="card-background">
              <div class="card-pattern"></div>
              <div class="card-gradient"></div>
            </div>
            
            <div class="card-content">
              <!-- Card Header -->
              <div class="card-header">
                <div class="card-logo">
                  <component :is="getCardIcon(card.brand)" :size="32" />
                </div>
                <div class="card-type">
                  {{ card.type.toUpperCase() }}
                </div>
              </div>

              <!-- Card Number -->
              <div class="card-number">
                <span v-if="showCardNumbers[card.id]">
                  {{ formatCardNumber(card.number) }}
                </span>
                <span v-else>
                  •••• •••• •••• {{ card.number.slice(-4) }}
                </span>
                <button 
                  @click.stop="toggleCardNumber(card.id)"
                  class="toggle-number-btn"
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                    <path v-if="showCardNumbers[card.id]" d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="currentColor" stroke-width="2"/>
                    <circle v-if="showCardNumbers[card.id]" cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/>
                    <path v-else d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" stroke="currentColor" stroke-width="2"/>
                    <line v-if="!showCardNumbers[card.id]" x1="1" y1="1" x2="23" y2="23" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </button>
              </div>

              <!-- Card Details -->
              <div class="card-details">
                <div class="card-holder">
                  <span class="label">CARD HOLDER</span>
                  <span class="value">{{ card.holderName }}</span>
                </div>
                <div class="card-expiry">
                  <span class="label">EXPIRES</span>
                  <span class="value">{{ card.expiryDate }}</span>
                </div>
              </div>

              <!-- Card Balance -->
              <div class="card-balance">
                <span class="balance-label">Available Balance</span>
                <span class="balance-amount">${{ formatAmount(card.balance) }}</span>
              </div>
            </div>

            <!-- Card Actions -->
            <div class="card-actions">
              <button @click.stop="freezeCard(card)" class="action-btn freeze">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" stroke="currentColor" stroke-width="2"/>
                  <circle cx="12" cy="16" r="1" fill="currentColor"/>
                </svg>
                {{ card.status === 'frozen' ? 'Unfreeze' : 'Freeze' }}
              </button>
              <button @click.stop="viewCardDetails(card)" class="action-btn details">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/>
                  <path d="M12 1v6M12 17v6M4.22 4.22l4.24 4.24M15.54 15.54l4.24 4.24M1 12h6M17 12h6M4.22 19.78l4.24-4.24M15.54 8.46l4.24-4.24" stroke="currentColor" stroke-width="2"/>
                </svg>
                Details
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Card Indicators -->
      <div class="card-indicators" v-if="cards.length > 1">
        <button
          v-for="(card, index) in cards"
          :key="`indicator-${card.id}`"
          @click="setActiveCard(index)"
          class="indicator"
          :class="{ active: index === activeCardIndex }"
        ></button>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="empty-cards">
      <div class="empty-icon">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none">
          <rect x="1" y="4" width="22" height="16" rx="2" ry="2" stroke="currentColor" stroke-width="2"/>
          <line x1="1" y1="10" x2="23" y2="10" stroke="currentColor" stroke-width="2"/>
        </svg>
      </div>
      <h3>No cards added</h3>
      <p>Add your first card to start managing your finances</p>
      <IOSButton variant="primary" @click="addCard" class="add-first-card">
        Add Your First Card
      </IOSButton>
    </div>

    <!-- Card Statistics -->
    <div v-if="cards.length > 0" class="card-stats">
      <IOSCard variant="glass">
        <template #header>
          <h3>Card Statistics</h3>
        </template>
        
        <template #content>
          <div class="stats-grid">
            <div class="stat-item">
              <div class="stat-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                  <line x1="12" y1="1" x2="12" y2="23" stroke="currentColor" stroke-width="2"/>
                  <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
              <div class="stat-info">
                <span class="stat-label">Total Spent This Month</span>
                <span class="stat-value">${{ formatAmount(monthlySpending) }}</span>
              </div>
            </div>

            <div class="stat-item">
              <div class="stat-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                  <path d="M20 12V8H6a2 2 0 0 1-2-2c0-1.1.9-2 2-2h12v4" stroke="currentColor" stroke-width="2"/>
                  <path d="M4 6v12c0 1.1.9 2 2 2h14v-4" stroke="currentColor" stroke-width="2"/>
                  <path d="M18 12a2 2 0 0 0-2 2c0 1.1.9 2 2 2h4v-4h-4z" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
              <div class="stat-info">
                <span class="stat-label">Cashback Earned</span>
                <span class="stat-value">${{ formatAmount(totalCashback) }}</span>
              </div>
            </div>

            <div class="stat-item">
              <div class="stat-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                  <polyline points="22,12 18,12 15,21 9,3 6,12 2,12" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
              <div class="stat-info">
                <span class="stat-label">Transactions</span>
                <span class="stat-value">{{ totalTransactions }}</span>
              </div>
            </div>

            <div class="stat-item">
              <div class="stat-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                  <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
              <div class="stat-info">
                <span class="stat-label">Average Transaction</span>
                <span class="stat-value">${{ formatAmount(averageTransaction) }}</span>
              </div>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Recent Transactions -->
    <div v-if="cards.length > 0 && recentCardTransactions.length > 0" class="recent-transactions">
      <IOSCard variant="glass">
        <template #header>
          <div class="section-header">
            <h3>Recent Card Transactions</h3>
            <button @click="viewAllTransactions" class="view-all-btn">
              View All
            </button>
          </div>
        </template>
        
        <template #content>
          <div class="transaction-list">
            <TransactionItem
              v-for="transaction in recentCardTransactions.slice(0, 5)"
              :key="transaction.id"
              :transaction="transaction"
              @click="viewTransactionDetails(transaction)"
            />
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Add Card Modal -->
    <IOSModal
      v-model="showAddCardModal"
      title="Add New Card"
      size="medium"
    >
      <div class="add-card-form">
        <div class="form-group">
          <label>Card Number</label>
          <input
            v-model="newCard.number"
            type="text"
            placeholder="1234 5678 9012 3456"
            maxlength="19"
            @input="formatCardNumberInput"
            class="form-input"
          />
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>Expiry Date</label>
            <input
              v-model="newCard.expiryDate"
              type="text"
              placeholder="MM/YY"
              maxlength="5"
              @input="formatExpiryInput"
              class="form-input"
            />
          </div>
          <div class="form-group">
            <label>CVV</label>
            <input
              v-model="newCard.cvv"
              type="text"
              placeholder="123"
              maxlength="4"
              class="form-input"
            />
          </div>
        </div>

        <div class="form-group">
          <label>Cardholder Name</label>
          <input
            v-model="newCard.holderName"
            type="text"
            placeholder="John Doe"
            class="form-input"
          />
        </div>

        <div class="form-group">
          <label>Card Type</label>
          <select v-model="newCard.type" class="form-select">
            <option value="debit">Debit Card</option>
            <option value="credit">Credit Card</option>
            <option value="prepaid">Prepaid Card</option>
          </select>
        </div>

        <div class="form-actions">
          <IOSButton variant="secondary" @click="showAddCardModal = false">
            Cancel
          </IOSButton>
          <IOSButton variant="primary" @click="saveCard" :disabled="!isCardValid">
            Add Card
          </IOSButton>
        </div>
      </div>
    </IOSModal>

    <!-- Card Details Modal -->
    <IOSModal
      v-model="showCardDetailsModal"
      :title="selectedCard?.holderName || 'Card Details'"
      size="medium"
    >
      <div v-if="selectedCard" class="card-details-modal">
        <div class="detail-section">
          <h4>Card Information</h4>
          <div class="detail-grid">
            <div class="detail-item">
              <span class="detail-label">Card Number</span>
              <span class="detail-value">•••• •••• •••• {{ selectedCard.number.slice(-4) }}</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Card Type</span>
              <span class="detail-value">{{ selectedCard.type.charAt(0).toUpperCase() + selectedCard.type.slice(1) }}</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Brand</span>
              <span class="detail-value">{{ selectedCard.brand }}</span>
            </div>
            <div class="detail-item">
              <span class="detail-label">Status</span>
              <span class="detail-value" :class="selectedCard.status">{{ selectedCard.status.charAt(0).toUpperCase() + selectedCard.status.slice(1) }}</span>
            </div>
          </div>
        </div>

        <div class="detail-section">
          <h4>Security Settings</h4>
          <div class="security-options">
            <div class="security-item">
              <div class="security-info">
                <span class="security-label">Online Payments</span>
                <span class="security-description">Allow online transactions</span>
              </div>
              <label class="toggle-switch">
                <input type="checkbox" v-model="selectedCard.settings.onlinePayments" />
                <span class="toggle-slider"></span>
              </label>
            </div>
            
            <div class="security-item">
              <div class="security-info">
                <span class="security-label">ATM Withdrawals</span>
                <span class="security-description">Allow ATM cash withdrawals</span>
              </div>
              <label class="toggle-switch">
                <input type="checkbox" v-model="selectedCard.settings.atmWithdrawals" />
                <span class="toggle-slider"></span>
              </label>
            </div>
            
            <div class="security-item">
              <div class="security-info">
                <span class="security-label">International Transactions</span>
                <span class="security-description">Allow international payments</span>
              </div>
              <label class="toggle-switch">
                <input type="checkbox" v-model="selectedCard.settings.international" />
                <span class="toggle-slider"></span>
              </label>
            </div>
          </div>
        </div>

        <div class="detail-actions">
          <IOSButton variant="danger" @click="removeCard(selectedCard)">
            Remove Card
          </IOSButton>
          <IOSButton variant="primary" @click="saveCardSettings">
            Save Changes
          </IOSButton>
        </div>
      </div>
    </IOSModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, reactive } from 'vue'
import { useStore } from 'vuex'
import { formatCurrency } from '../../../utils/currency'
import { h } from 'vue'

// SVG Icons
const CreditCard = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '20', height: '14', x: '2', y: '5', rx: '2' }),
  h('line', { x1: '2', x2: '22', y1: '10', y2: '10' })
])

const Smartphone = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '14', height: '20', x: '5', y: '2', rx: '2', ry: '2' }),
  h('line', { x1: '12', x2: '12.01', y1: '18', y2: '18' })
])

const Banknote = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '20', height: '12', x: '2', y: '6', rx: '2' }),
  h('circle', { cx: '12', cy: '12', r: '2' }),
  h('path', { d: 'M6 12h.01M18 12h.01' })
])

// Components
import IOSCard from '../../ios/IOSCard.vue'
import IOSModal from '../../ios/IOSModal.vue'
import IOSButton from '../../ios/IOSButton.vue'
import TransactionItem from '../TransactionItem.vue'

const store = useStore()

// State
const activeCardIndex = ref(0)
const showCardNumbers = ref({})
const showAddCardModal = ref(false)
const showCardDetailsModal = ref(false)
const selectedCard = ref(null)
const carouselContainer = ref(null)

// New card form
const newCard = reactive({
  number: '',
  expiryDate: '',
  cvv: '',
  holderName: '',
  type: 'debit'
})

// Computed properties
const cards = computed(() => store.state.wallet.cards || [])
const transactions = computed(() => store.state.wallet.transactions || [])

const recentCardTransactions = computed(() => {
  return transactions.value
    .filter(t => t.paymentMethod === 'card')
    .sort((a, b) => new Date(b.date) - new Date(a.date))
})

const monthlySpending = computed(() => {
  const now = new Date()
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1)
  
  return Math.abs(transactions.value
    .filter(t => t.paymentMethod === 'card' && new Date(t.date) >= startOfMonth && t.amount < 0)
    .reduce((sum, t) => sum + t.amount, 0))
})

const totalCashback = computed(() => {
  return transactions.value
    .filter(t => t.paymentMethod === 'card' && t.cashback)
    .reduce((sum, t) => sum + (t.cashback || 0), 0)
})

const totalTransactions = computed(() => {
  return transactions.value.filter(t => t.paymentMethod === 'card').length
})

const averageTransaction = computed(() => {
  const cardTransactions = transactions.value.filter(t => t.paymentMethod === 'card' && t.amount < 0)
  if (cardTransactions.length === 0) return 0
  
  const total = Math.abs(cardTransactions.reduce((sum, t) => sum + t.amount, 0))
  return total / cardTransactions.length
})

const isCardValid = computed(() => {
  return newCard.number.replace(/\s/g, '').length >= 13 &&
         newCard.expiryDate.length === 5 &&
         newCard.cvv.length >= 3 &&
         newCard.holderName.trim().length > 0
})

// Methods
const formatAmount = (amount) => {
  return formatCurrency(amount)
}

const formatCardNumber = (number) => {
  return number.replace(/(.{4})/g, '$1 ').trim()
}

const formatCardNumberInput = (event) => {
  let value = event.target.value.replace(/\s/g, '').replace(/\D/g, '')
  value = value.substring(0, 16)
  value = value.replace(/(.{4})/g, '$1 ').trim()
  newCard.number = value
}

const formatExpiryInput = (event) => {
  let value = event.target.value.replace(/\D/g, '')
  if (value.length >= 2) {
    value = value.substring(0, 2) + '/' + value.substring(2, 4)
  }
  newCard.expiryDate = value
}

const getCardIcon = (brand) => {
  const icons = {
    'visa': CreditCard,
    'mastercard': CreditCard,
    'amex': CreditCard,
    'discover': CreditCard,
    'default': CreditCard
  }
  return icons[brand.toLowerCase()] || icons.default
}

const getCardBrand = (number) => {
  const cleanNumber = number.replace(/\s/g, '')
  
  if (cleanNumber.startsWith('4')) return 'Visa'
  if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) return 'Mastercard'
  if (cleanNumber.startsWith('3')) return 'American Express'
  if (cleanNumber.startsWith('6')) return 'Discover'
  
  return 'Unknown'
}

const setActiveCard = (index) => {
  activeCardIndex.value = index
}

const toggleCardNumber = (cardId) => {
  showCardNumbers.value[cardId] = !showCardNumbers.value[cardId]
}

const addCard = () => {
  // Reset form
  Object.assign(newCard, {
    number: '',
    expiryDate: '',
    cvv: '',
    holderName: '',
    type: 'debit'
  })
  showAddCardModal.value = true
}

const scanCard = () => {
  // Implement card scanning functionality
  console.log('Scan card')
}

const saveCard = () => {
  const cardData = {
    id: Date.now().toString(),
    number: newCard.number.replace(/\s/g, ''),
    expiryDate: newCard.expiryDate,
    holderName: newCard.holderName,
    type: newCard.type,
    brand: getCardBrand(newCard.number),
    balance: 0,
    status: 'active',
    settings: {
      onlinePayments: true,
      atmWithdrawals: true,
      international: false
    }
  }

  store.dispatch('wallet/addCard', cardData)
  showAddCardModal.value = false
}

const freezeCard = (card) => {
  const newStatus = card.status === 'frozen' ? 'active' : 'frozen'
  store.dispatch('wallet/updateCardStatus', { cardId: card.id, status: newStatus })
}

const viewCardDetails = (card) => {
  selectedCard.value = { ...card }
  showCardDetailsModal.value = true
}

const saveCardSettings = () => {
  store.dispatch('wallet/updateCardSettings', {
    cardId: selectedCard.value.id,
    settings: selectedCard.value.settings
  })
  showCardDetailsModal.value = false
}

const removeCard = (card) => {
  if (confirm('Are you sure you want to remove this card?')) {
    store.dispatch('wallet/removeCard', card.id)
    showCardDetailsModal.value = false
  }
}

const viewAllTransactions = () => {
  // Navigate to transactions page with card filter
  console.log('View all card transactions')
}

const viewTransactionDetails = (transaction) => {
  // View transaction details
  console.log('View transaction:', transaction)
}

// Initialize data
onMounted(() => {
  store.dispatch('wallet/fetchCards')
  store.dispatch('wallet/fetchTransactions')
})
</script>

<style scoped>
.cards-page {
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding-bottom: 20px;
}

/* Header Actions */
.header-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.add-card-btn,
.scan-btn {
  display: flex;
  align-items: center;
  gap: 8px;
}

/* Cards Carousel */
.cards-carousel {
  position: relative;
}

.carousel-container {
  display: flex;
  gap: 16px;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  padding: 8px;
  margin: -8px;
}

.carousel-container::-webkit-scrollbar {
  display: none;
}

.card-wrapper {
  flex: 0 0 auto;
  scroll-snap-align: center;
  transition: all 0.3s ease;
  transform: scale(0.95);
  opacity: 0.7;
}

.card-wrapper.active {
  transform: scale(1);
  opacity: 1;
}

.credit-card {
  width: 340px;
  height: 200px;
  border-radius: 16px;
  position: relative;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.3s ease;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.credit-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
}

.credit-card.debit {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.credit-card.credit {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
}

.credit-card.prepaid {
  background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
}

.card-background {
  position: absolute;
  inset: 0;
  opacity: 0.1;
}

.card-pattern {
  position: absolute;
  inset: 0;
  background-image: radial-gradient(circle at 20% 80%, rgba(255, 255, 255, 0.2) 0%, transparent 50%),
                    radial-gradient(circle at 80% 20%, rgba(255, 255, 255, 0.2) 0%, transparent 50%);
}

.card-gradient {
  position: absolute;
  inset: 0;
  background: linear-gradient(45deg, rgba(255, 255, 255, 0.1) 0%, transparent 100%);
}

.card-content {
  position: relative;
  z-index: 2;
  padding: 20px;
  height: 100%;
  display: flex;
  flex-direction: column;
  color: white;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.card-logo {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  backdrop-filter: blur(10px);
}

.card-type {
  font-size: 12px;
  font-weight: 600;
  opacity: 0.8;
}

.card-number {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 18px;
  font-weight: 600;
  font-family: 'SF Mono', monospace;
  letter-spacing: 2px;
  margin-bottom: 16px;
}

.toggle-number-btn {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  border-radius: 6px;
  padding: 4px;
  color: white;
  cursor: pointer;
  transition: all 0.2s ease;
  backdrop-filter: blur(10px);
}

.toggle-number-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.card-details {
  display: flex;
  justify-content: space-between;
  margin-bottom: auto;
}

.card-holder,
.card-expiry {
  display: flex;
  flex-direction: column;
}

.label {
  font-size: 10px;
  font-weight: 600;
  opacity: 0.7;
  margin-bottom: 4px;
}

.value {
  font-size: 14px;
  font-weight: 600;
}

.card-balance {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.balance-label {
  font-size: 10px;
  opacity: 0.7;
  margin-bottom: 4px;
}

.balance-amount {
  font-size: 16px;
  font-weight: 700;
}

.card-actions {
  position: absolute;
  bottom: 16px;
  right: 16px;
  display: flex;
  gap: 8px;
  opacity: 0;
  transition: all 0.3s ease;
}

.credit-card:hover .card-actions {
  opacity: 1;
}

.action-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 12px;
  background: rgba(255, 255, 255, 0.2);
  border: none;
  border-radius: 8px;
  color: white;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  backdrop-filter: blur(10px);
}

.action-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.action-btn.freeze {
  background: rgba(255, 59, 48, 0.2);
}

.action-btn.freeze:hover {
  background: rgba(255, 59, 48, 0.3);
}

/* Card Indicators */
.card-indicators {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin-top: 16px;
}

.indicator {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  border: none;
  background: rgba(0, 0, 0, 0.2);
  cursor: pointer;
  transition: all 0.2s ease;
}

.indicator.active {
  background: #007AFF;
  transform: scale(1.2);
}

/* Empty State */
.empty-cards {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  padding: 60px 20px;
  text-align: center;
}

.empty-icon {
  color: #8e8e93;
  opacity: 0.6;
}

.empty-cards h3 {
  font-size: 20px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.empty-cards p {
  font-size: 16px;
  color: #8e8e93;
  margin: 0;
}

/* Card Statistics */
.card-stats {
  margin-top: 8px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 16px;
  margin-top: 16px;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  border: 1px solid rgba(0, 0, 0, 0.05);
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: linear-gradient(135deg, #007AFF, #0A84FF);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.stat-info {
  display: flex;
  flex-direction: column;
}

.stat-label {
  font-size: 14px;
  color: #8e8e93;
  font-weight: 500;
}

.stat-value {
  font-size: 20px;
  font-weight: 700;
  color: #1d1d1f;
  margin-top: 4px;
}

/* Recent Transactions */
.recent-transactions {
  margin-top: 8px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.section-header h3 {
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.view-all-btn {
  background: none;
  border: none;
  color: #007AFF;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s ease;
}

.view-all-btn:hover {
  opacity: 0.7;
}

.transaction-list {
  background: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid rgba(0, 0, 0, 0.05);
  margin-top: 16px;
}

/* Add Card Modal */
.add-card-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.form-group label {
  font-size: 14px;
  font-weight: 600;
  color: #1d1d1f;
}

.form-input,
.form-select {
  padding: 12px 16px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 8px;
  font-size: 16px;
  background: rgba(255, 255, 255, 0.8);
  transition: all 0.2s ease;
}

.form-input:focus,
.form-select:focus {
  outline: none;
  border-color: #007AFF;
  background: white;
}

.form-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 8px;
}

/* Card Details Modal */
.card-details-modal {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.detail-section h4 {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0 0 16px 0;
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.detail-label {
  font-size: 12px;
  color: #8e8e93;
  font-weight: 500;
}

.detail-value {
  font-size: 14px;
  font-weight: 600;
  color: #1d1d1f;
}

.detail-value.active {
  color: #34C759;
}

.detail-value.frozen {
  color: #FF3B30;
}

.security-options {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.security-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  border: 1px solid rgba(0, 0, 0, 0.05);
}

.security-info {
  display: flex;
  flex-direction: column;
}

.security-label {
  font-size: 14px;
  font-weight: 600;
  color: #1d1d1f;
}

.security-description {
  font-size: 12px;
  color: #8e8e93;
}

.toggle-switch {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
}

.toggle-switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.toggle-slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #ccc;
  transition: 0.3s;
  border-radius: 24px;
}

.toggle-slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: 0.3s;
  border-radius: 50%;
}

input:checked + .toggle-slider {
  background-color: #007AFF;
}

input:checked + .toggle-slider:before {
  transform: translateX(20px);
}

.detail-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 8px;
}

/* Responsive Design */
@media (max-width: 768px) {
  .header-actions {
    justify-content: center;
  }

  .credit-card {
    width: 300px;
    height: 180px;
  }

  .card-number {
    font-size: 16px;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .detail-grid {
    grid-template-columns: 1fr;
  }

  .form-actions,
  .detail-actions {
    flex-direction: column;
  }
}

@media (max-width: 375px) {
  .credit-card {
    width: 280px;
    height: 160px;
  }

  .card-content {
    padding: 16px;
  }

  .card-number {
    font-size: 14px;
    letter-spacing: 1px;
  }

  .balance-amount {
    font-size: 14px;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .empty-cards h3 {
    color: #f2f2f7;
  }

  .section-header h3 {
    color: #f2f2f7;
  }

  .stat-item {
    background: rgba(44, 44, 46, 0.5);
    border-color: rgba(255, 255, 255, 0.05);
  }

  .stat-value {
    color: #f2f2f7;
  }

  .transaction-list {
    background: rgba(44, 44, 46, 0.5);
    border-color: rgba(255, 255, 255, 0.05);
  }

  .form-input,
  .form-select {
    background: rgba(44, 44, 46, 0.8);
    border-color: rgba(255, 255, 255, 0.1);
    color: #f2f2f7;
  }

  .form-input:focus,
  .form-select:focus {
    background: rgba(44, 44, 46, 1);
    border-color: #0A84FF;
  }

  .form-group label {
    color: #f2f2f7;
  }

  .detail-section h4 {
    color: #f2f2f7;
  }

  .detail-value {
    color: #f2f2f7;
  }

  .security-item {
    background: rgba(44, 44, 46, 0.5);
    border-color: rgba(255, 255, 255, 0.05);
  }

  .security-label {
    color: #f2f2f7;
  }

  .toggle-slider {
    background-color: #48484a;
  }

  input:checked + .toggle-slider {
    background-color: #0A84FF;
  }
}
</style>