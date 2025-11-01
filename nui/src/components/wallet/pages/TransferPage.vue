<template>
  <div class="transfer-page">
    <!-- Transfer Type Selection -->
    <div class="transfer-types">
      <button
        v-for="type in transferTypes"
        :key="type.id"
        @click="selectedType = type.id"
        class="transfer-type-btn"
        :class="{ active: selectedType === type.id }"
      >
        <div class="type-icon" :style="{ background: type.color }">
          <component :is="type.icon" :size="24" />
        </div>
        <span class="type-label">{{ type.label }}</span>
      </button>
    </div>

    <!-- Transfer Form -->
    <div class="transfer-form">
      <!-- Recipient Selection -->
      <div class="form-section">
        <label class="section-label">{{ getRecipientLabel() }}</label>
        
        <!-- Recent Recipients -->
        <div v-if="recentRecipients.length > 0" class="recent-recipients">
          <div class="recipients-header">
            <span class="recipients-title">Recent</span>
          </div>
          <div class="recipients-list">
            <button
              v-for="recipient in recentRecipients"
              :key="recipient.id"
              @click="selectRecipient(recipient)"
              class="recipient-item"
              :class="{ active: selectedRecipient?.id === recipient.id }"
            >
              <div class="recipient-avatar">
                <span>{{ recipient.name.charAt(0).toUpperCase() }}</span>
              </div>
              <div class="recipient-info">
                <span class="recipient-name">{{ recipient.name }}</span>
                <span class="recipient-detail">{{ recipient.phone || recipient.account }}</span>
              </div>
            </button>
          </div>
        </div>

        <!-- Manual Input -->
        <div class="manual-input">
          <div class="input-group">
            <input
              v-model="recipientInput"
              :placeholder="getRecipientPlaceholder()"
              class="recipient-input"
              @input="searchRecipients"
            />
            <button v-if="recipientInput" @click="clearRecipient" class="clear-input-btn">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <line x1="18" y1="6" x2="6" y2="18" stroke="currentColor" stroke-width="2"/>
                <line x1="6" y1="6" x2="18" y2="18" stroke="currentColor" stroke-width="2"/>
              </svg>
            </button>
          </div>

          <!-- Search Results -->
          <div v-if="searchResults.length > 0" class="search-results">
            <button
              v-for="result in searchResults"
              :key="result.id"
              @click="selectRecipient(result)"
              class="search-result-item"
            >
              <div class="result-avatar">
                <span>{{ result.name.charAt(0).toUpperCase() }}</span>
              </div>
              <div class="result-info">
                <span class="result-name">{{ result.name }}</span>
                <span class="result-detail">{{ result.phone || result.account }}</span>
              </div>
            </button>
          </div>
        </div>
      </div>

      <!-- Amount Input -->
      <div class="form-section">
        <label class="section-label">Amount</label>
        <CurrencyInput
          v-model="amount"
          :min-amount="1"
          :max-amount="999000000000000"
          :validate-on-input="false"
          placeholder="0.00"
          :helper-text="selectedAccount ? `Available: ${formatAmount(selectedAccount.balance)}` : ''"
          @validate="handleAmountValidation"
        />
      </div>

      <!-- Quick Amount Buttons -->
      <div class="quick-amounts">
        <button
          v-for="quickAmount in quickAmounts"
          :key="quickAmount"
          @click="setQuickAmount(quickAmount)"
          class="quick-amount-btn"
        >
          {{ formatAmount(quickAmount) }}
        </button>
      </div>

      <!-- Note Input -->
      <div class="form-section">
        <label class="section-label">Note (Optional)</label>
        <input
          v-model="note"
          placeholder="What's this for?"
          class="note-input"
          maxlength="100"
        />
        <div class="note-counter">{{ note.length }}/100</div>
      </div>

      <!-- Account Selection (for bank transfers) -->
      <div v-if="selectedType === 'bank'" class="form-section">
        <label class="section-label">From Account</label>
        <div class="account-selector">
          <button
            v-for="account in accounts"
            :key="account.id"
            @click="selectedAccount = account"
            class="account-option"
            :class="{ active: selectedAccount?.id === account.id }"
          >
            <div class="account-info">
              <span class="account-name">{{ account.name }}</span>
              <span class="account-balance">{{ formatAmount(account.balance) }}</span>
            </div>
            <div class="account-type">{{ account.type }}</div>
          </button>
        </div>
      </div>
    </div>

    <!-- Transfer Summary -->
    <div v-if="canShowSummary" class="transfer-summary">
      <IOSCard variant="glass">
        <template #content>
          <div class="summary-content">
            <div class="summary-header">
              <h3>Transfer Summary</h3>
            </div>
            
            <div class="summary-details">
              <div class="summary-row">
                <span class="summary-label">To</span>
                <span class="summary-value">{{ selectedRecipient?.name || recipientInput }}</span>
              </div>
              <div class="summary-row">
                <span class="summary-label">Amount</span>
                <span class="summary-value">{{ formatAmount(amount || 0) }}</span>
              </div>
              <div v-if="transferFee > 0" class="summary-row">
                <span class="summary-label">Fee</span>
                <span class="summary-value">{{ formatAmount(transferFee) }}</span>
              </div>
              <div class="summary-row total">
                <span class="summary-label">Total</span>
                <span class="summary-value">{{ formatAmount(totalAmount) }}</span>
              </div>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Transfer Button -->
    <div class="transfer-actions">
      <IOSButton
        variant="primary"
        full-width
        :disabled="!canTransfer"
        @click="initiateTransfer"
        class="transfer-btn"
      >
        {{ getTransferButtonText() }}
      </IOSButton>
    </div>

    <!-- Confirmation Modal -->
    <IOSModal
      v-model="showConfirmation"
      title="Confirm Transfer"
      size="medium"
    >
      <div class="confirmation-content">
        <div class="confirmation-icon">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none">
            <path d="M12 22V2M19 15l-7 7-7-7" stroke="currentColor" stroke-width="2"/>
          </svg>
        </div>
        
        <div class="confirmation-details">
          <h3 class="confirmation-title">Send {{ formatAmount(amount || 0) }}</h3>
          <p class="confirmation-subtitle">to {{ selectedRecipient?.name || recipientInput }}</p>
          
          <div class="confirmation-info">
            <div class="info-row">
              <span class="info-label">Transfer method</span>
              <span class="info-value">{{ getTransferMethodName() }}</span>
            </div>
            <div v-if="transferFee > 0" class="info-row">
              <span class="info-label">Fee</span>
              <span class="info-value">{{ formatAmount(transferFee) }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Total</span>
              <span class="info-value">{{ formatAmount(totalAmount) }}</span>
            </div>
          </div>
        </div>

        <div class="confirmation-actions">
          <IOSButton variant="secondary" @click="showConfirmation = false">
            Cancel
          </IOSButton>
          <IOSButton variant="primary" @click="confirmTransfer" :disabled="processing">
            {{ processing ? 'Processing...' : 'Confirm' }}
          </IOSButton>
        </div>
      </div>
    </IOSModal>

    <!-- Success Modal -->
    <IOSModal
      v-model="showSuccess"
      title="Transfer Successful"
      size="medium"
    >
      <div class="success-content">
        <div class="success-icon">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
            <path d="m9 12 2 2 4-4" stroke="currentColor" stroke-width="2"/>
          </svg>
        </div>
        
        <div class="success-details">
          <h3 class="success-title">Transfer Complete</h3>
          <p class="success-subtitle">
            {{ formatAmount(amount || 0) }} sent to {{ selectedRecipient?.name || recipientInput }}
          </p>
          
          <div class="success-info">
            <div class="info-row">
              <span class="info-label">Transaction ID</span>
              <span class="info-value">{{ transactionId }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">Date</span>
              <span class="info-value">{{ formatDate(new Date()) }}</span>
            </div>
          </div>
        </div>

        <div class="success-actions">
          <IOSButton variant="secondary" @click="shareTransaction">
            Share
          </IOSButton>
          <IOSButton variant="primary" @click="startNewTransfer">
            New Transfer
          </IOSButton>
        </div>
      </div>
    </IOSModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useStore } from 'vuex'
import { h } from 'vue'
import { formatCurrency } from '../../../utils/currency'

// SVG Icons
const Send = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'm22 2-7 20-4-9-9-4Z' }),
  h('path', { d: 'M22 2 11 13' })
])

const Building = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z' }),
  h('path', { d: 'M6 12H4a2 2 0 0 0-2 2v8h20v-8a2 2 0 0 0-2-2h-2' }),
  h('path', { d: 'M18 9h2a2 2 0 0 1 2 2v1' }),
  h('path', { d: 'M18 22V4' }),
  h('path', { d: 'M14 6h.01' }),
  h('path', { d: 'M18 6h.01' }),
  h('path', { d: 'M14 10h.01' }),
  h('path', { d: 'M18 10h.01' }),
  h('path', { d: 'M14 14h.01' }),
  h('path', { d: 'M18 14h.01' }),
  h('path', { d: 'M14 18h.01' }),
  h('path', { d: 'M18 18h.01' })
])

const Smartphone = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '14', height: '20', x: '5', y: '2', rx: '2', ry: '2' }),
  h('line', { x1: '12', x2: '12.01', y1: '18', y2: '18' })
])

const CreditCard = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { width: '20', height: '14', x: '2', y: '5', rx: '2' }),
  h('line', { x1: '2', x2: '22', y1: '10', y2: '10' })
])

// Components
import IOSCard from '../../ios/IOSCard.vue'
import IOSModal from '../../ios/IOSModal.vue'
import IOSButton from '../../ios/IOSButton.vue'
import CurrencyInput from '../../CurrencyInput.vue'

const store = useStore()

// State
const selectedType = ref('phone')
const selectedRecipient = ref(null)
const selectedAccount = ref(null)
const recipientInput = ref('')
const amount = ref(null)
const note = ref('')
const searchResults = ref([])
const showConfirmation = ref(false)
const showSuccess = ref(false)
const processing = ref(false)
const transactionId = ref('')
const amountValidation = ref({ isValid: true, error: null })

// Transfer types
const transferTypes = [
  {
    id: 'phone',
    label: 'Phone',
    icon: Smartphone,
    color: '#007AFF'
  },
  {
    id: 'bank',
    label: 'Bank',
    icon: Building,
    color: '#34C759'
  },
  {
    id: 'card',
    label: 'Card',
    icon: CreditCard,
    color: '#FF9500'
  }
]

// Quick amounts
const quickAmounts = [10, 25, 50, 100, 250, 500]

// Computed properties
const accounts = computed(() => store.state.wallet.accounts)
const contacts = computed(() => store.state.contacts.contacts || [])

const recentRecipients = computed(() => {
  // Get recent transfer recipients from transaction history
  const recentTransfers = store.state.wallet.transactions
    .filter(t => t.type === 'transfer' && t.amount < 0)
    .slice(0, 5)
    .map(t => ({
      id: t.recipientId,
      name: t.description,
      phone: t.recipientPhone,
      account: t.recipientAccount
    }))
  
  return recentTransfers
})

const canShowSummary = computed(() => {
  return (selectedRecipient.value || recipientInput.value) && amount.value && amount.value > 0 && amountValidation.value.isValid
})

const transferFee = computed(() => {
  const transferAmount = amount.value || 0
  
  switch (selectedType.value) {
    case 'phone':
      return 0 // Free phone transfers
    case 'bank':
      return transferAmount > 1000 ? 5.00 : 0 // $5 fee for transfers over $1000
    case 'card':
      return transferAmount * 0.029 // 2.9% fee for card transfers
    default:
      return 0
  }
})

const totalAmount = computed(() => {
  return (amount.value || 0) + transferFee.value
})

const canTransfer = computed(() => {
  const hasRecipient = selectedRecipient.value || recipientInput.value
  const hasAmount = amount.value && amount.value > 0
  const hasValidAmount = amountValidation.value.isValid
  const hasBalance = selectedAccount.value ? selectedAccount.value.balance >= totalAmount.value : true
  
  return hasRecipient && hasAmount && hasValidAmount && hasBalance && !processing.value
})

// Methods
const getRecipientLabel = () => {
  switch (selectedType.value) {
    case 'phone':
      return 'Send to'
    case 'bank':
      return 'Bank Account'
    case 'card':
      return 'Card Number'
    default:
      return 'Recipient'
  }
}

const getRecipientPlaceholder = () => {
  switch (selectedType.value) {
    case 'phone':
      return 'Phone number or name'
    case 'bank':
      return 'Account number or routing number'
    case 'card':
      return 'Card number'
    default:
      return 'Enter recipient'
  }
}

const getTransferButtonText = () => {
  if (!canTransfer.value) {
    if (!amount.value) return 'Enter Amount'
    if (!amountValidation.value.isValid) return 'Invalid Amount'
    if (!selectedRecipient.value && !recipientInput.value) return 'Select Recipient'
    if (selectedAccount.value && selectedAccount.value.balance < totalAmount.value) return 'Insufficient Balance'
  }
  return `Send ${formatAmount(amount.value || 0)}`
}

const getTransferMethodName = () => {
  const type = transferTypes.find(t => t.id === selectedType.value)
  return type ? type.label : 'Unknown'
}

const formatAmount = (amount) => {
  return formatCurrency(amount)
}

const formatDate = (date) => {
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const selectRecipient = (recipient) => {
  selectedRecipient.value = recipient
  recipientInput.value = recipient.name
  searchResults.value = []
}

const clearRecipient = () => {
  selectedRecipient.value = null
  recipientInput.value = ''
  searchResults.value = []
}

const searchRecipients = () => {
  if (!recipientInput.value || recipientInput.value.length < 2) {
    searchResults.value = []
    return
  }

  const query = recipientInput.value.toLowerCase()
  searchResults.value = contacts.value
    .filter(contact => 
      contact.name.toLowerCase().includes(query) ||
      contact.phone.includes(query)
    )
    .slice(0, 5)
    .map(contact => ({
      id: contact.id,
      name: contact.name,
      phone: contact.phone
    }))
}

const setQuickAmount = (quickAmount) => {
  amount.value = quickAmount
}

const handleAmountValidation = (validation) => {
  amountValidation.value = validation
}

const initiateTransfer = () => {
  showConfirmation.value = true
}

const confirmTransfer = async () => {
  processing.value = true
  
  try {
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    // Generate transaction ID
    transactionId.value = 'TXN' + Date.now().toString().slice(-8)
    
    // Create transaction record
    const transaction = {
      id: transactionId.value,
      type: 'transfer',
      amount: -Math.abs(amount.value),
      description: selectedRecipient.value?.name || recipientInput.value,
      category: 'Transfer',
      date: new Date().toISOString(),
      accountId: selectedAccount.value?.id || 'main',
      recipientId: selectedRecipient.value?.id,
      recipientPhone: selectedRecipient.value?.phone,
      note: note.value,
      fee: transferFee.value
    }
    
    // Add transaction to store
    store.commit('wallet/ADD_TRANSACTION', transaction)
    
    // Update account balance
    if (selectedAccount.value) {
      store.commit('wallet/UPDATE_ACCOUNT_BALANCE', {
        accountId: selectedAccount.value.id,
        amount: -totalAmount.value
      })
    }
    
    showConfirmation.value = false
    showSuccess.value = true
    
  } catch (error) {
    console.error('Transfer failed:', error)
    // Handle error
  } finally {
    processing.value = false
  }
}

const shareTransaction = () => {
  // Handle share transaction
  console.log('Share transaction:', transactionId.value)
}

const startNewTransfer = () => {
  // Reset form
  selectedRecipient.value = null
  recipientInput.value = ''
  amount.value = null
  note.value = ''
  amountValidation.value = { isValid: true, error: null }
  showSuccess.value = false
}

// Initialize data
onMounted(() => {
  store.dispatch('wallet/fetchAccounts')
  store.dispatch('contacts/fetchContacts')
  
  // Set default account
  if (accounts.value.length > 0) {
    selectedAccount.value = accounts.value[0]
  }
})

// Watch for account changes
watch(accounts, (newAccounts) => {
  if (newAccounts.length > 0 && !selectedAccount.value) {
    selectedAccount.value = newAccounts[0]
  }
})
</script>

<style scoped>
.transfer-page {
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding-bottom: 20px;
}

/* Transfer Types */
.transfer-types {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.transfer-type-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 16px 12px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 16px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.transfer-type-btn:hover {
  background: rgba(255, 255, 255, 1);
  transform: translateY(-2px);
}

.transfer-type-btn.active {
  background: rgba(0, 122, 255, 0.1);
  border-color: #007AFF;
}

.type-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.type-label {
  font-size: 14px;
  font-weight: 600;
  color: #1d1d1f;
}

/* Transfer Form */
.transfer-form {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.form-section {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.section-label {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
}

/* Recent Recipients */
.recent-recipients {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.recipients-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.recipients-title {
  font-size: 14px;
  font-weight: 500;
  color: #8e8e93;
}

.recipients-list {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding-bottom: 8px;
}

.recipient-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 12px;
  background: rgba(255, 255, 255, 0.8);
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
  min-width: 80px;
}

.recipient-item:hover {
  background: rgba(255, 255, 255, 1);
}

.recipient-item.active {
  background: rgba(0, 122, 255, 0.1);
  border-color: #007AFF;
}

.recipient-avatar {
  width: 40px;
  height: 40px;
  border-radius: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: 600;
  font-size: 16px;
}

.recipient-info {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.recipient-name {
  font-size: 12px;
  font-weight: 600;
  color: #1d1d1f;
}

.recipient-detail {
  font-size: 10px;
  color: #8e8e93;
}

/* Manual Input */
.manual-input {
  position: relative;
}

.input-group {
  position: relative;
  display: flex;
  align-items: center;
}

.recipient-input {
  width: 100%;
  padding: 16px 20px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  font-size: 16px;
  color: #1d1d1f;
  transition: all 0.2s ease;
}

.recipient-input:focus {
  outline: none;
  border-color: #007AFF;
  background: rgba(255, 255, 255, 1);
}

.recipient-input::placeholder {
  color: #8e8e93;
}

.clear-input-btn {
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

.clear-input-btn:hover {
  background: rgba(0, 0, 0, 0.1);
}

/* Search Results */
.search-results {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  margin-top: 4px;
  overflow: hidden;
  z-index: 10;
}

.search-result-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
  cursor: pointer;
  transition: background-color 0.2s ease;
  width: 100%;
  text-align: left;
}

.search-result-item:last-child {
  border-bottom: none;
}

.search-result-item:hover {
  background: rgba(0, 122, 255, 0.1);
}

.result-avatar {
  width: 32px;
  height: 32px;
  border-radius: 16px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: 600;
  font-size: 14px;
}

.result-info {
  display: flex;
  flex-direction: column;
}

.result-name {
  font-size: 14px;
  font-weight: 600;
  color: #1d1d1f;
}

.result-detail {
  font-size: 12px;
  color: #8e8e93;
}

/* Amount Input */
.amount-input-container {
  position: relative;
  display: flex;
  align-items: center;
}

.currency-symbol {
  position: absolute;
  left: 20px;
  font-size: 24px;
  font-weight: 600;
  color: #1d1d1f;
  z-index: 2;
}

.amount-input {
  width: 100%;
  padding: 20px 20px 20px 48px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  font-size: 24px;
  font-weight: 600;
  color: #1d1d1f;
  transition: all 0.2s ease;
}

.amount-input:focus {
  outline: none;
  border-color: #007AFF;
  background: rgba(255, 255, 255, 1);
}

.amount-input::placeholder {
  color: #8e8e93;
}

.balance-info {
  font-size: 14px;
  color: #8e8e93;
  margin-top: 4px;
}

/* Quick Amounts */
.quick-amounts {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.quick-amount-btn {
  padding: 12px 16px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.8);
  color: #1d1d1f;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.quick-amount-btn:hover {
  background: rgba(255, 255, 255, 1);
  transform: translateY(-1px);
}

/* Note Input */
.note-input {
  width: 100%;
  padding: 16px 20px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  font-size: 16px;
  color: #1d1d1f;
  transition: all 0.2s ease;
}

.note-input:focus {
  outline: none;
  border-color: #007AFF;
  background: rgba(255, 255, 255, 1);
}

.note-input::placeholder {
  color: #8e8e93;
}

.note-counter {
  font-size: 12px;
  color: #8e8e93;
  text-align: right;
  margin-top: 4px;
}

/* Account Selection */
.account-selector {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.account-option {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.8);
  cursor: pointer;
  transition: all 0.2s ease;
  text-align: left;
}

.account-option:hover {
  background: rgba(255, 255, 255, 1);
}

.account-option.active {
  background: rgba(0, 122, 255, 0.1);
  border-color: #007AFF;
}

.account-info {
  display: flex;
  flex-direction: column;
}

.account-name {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
}

.account-balance {
  font-size: 14px;
  color: #8e8e93;
}

.account-type {
  font-size: 12px;
  color: #8e8e93;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* Transfer Summary */
.transfer-summary {
  margin-top: 8px;
}

.summary-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.summary-header h3 {
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.summary-details {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.summary-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
}

.summary-row.total {
  border-top: 1px solid rgba(0, 0, 0, 0.1);
  padding-top: 12px;
  margin-top: 4px;
}

.summary-label {
  font-size: 16px;
  color: #8e8e93;
}

.summary-value {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
}

.summary-row.total .summary-label,
.summary-row.total .summary-value {
  font-weight: 700;
  font-size: 18px;
}

/* Transfer Actions */
.transfer-actions {
  margin-top: 8px;
}

.transfer-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Modal Content */
.confirmation-content,
.success-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 24px;
  text-align: center;
}

.confirmation-icon,
.success-icon {
  width: 80px;
  height: 80px;
  border-radius: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.confirmation-icon {
  background: linear-gradient(135deg, #FF9500, #FF9F0A);
}

.success-icon {
  background: linear-gradient(135deg, #34C759, #30D158);
}

.confirmation-details,
.success-details {
  display: flex;
  flex-direction: column;
  gap: 16px;
  width: 100%;
}

.confirmation-title,
.success-title {
  font-size: 24px;
  font-weight: 700;
  color: #1d1d1f;
  margin: 0;
}

.confirmation-subtitle,
.success-subtitle {
  font-size: 16px;
  color: #8e8e93;
  margin: 0;
}

.confirmation-info,
.success-info {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 16px;
  background: rgba(0, 0, 0, 0.05);
  border-radius: 12px;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.info-label {
  font-size: 14px;
  color: #8e8e93;
}

.info-value {
  font-size: 14px;
  font-weight: 600;
  color: #1d1d1f;
}

.confirmation-actions,
.success-actions {
  display: flex;
  gap: 12px;
  width: 100%;
}

/* Responsive Design */
@media (max-width: 375px) {
  .transfer-types {
    grid-template-columns: 1fr;
    gap: 8px;
  }

  .transfer-type-btn {
    flex-direction: row;
    justify-content: flex-start;
    padding: 12px 16px;
  }

  .type-icon {
    width: 40px;
    height: 40px;
  }

  .recipients-list {
    grid-template-columns: repeat(2, 1fr);
  }

  .quick-amounts {
    grid-template-columns: repeat(2, 1fr);
  }

  .amount-input {
    font-size: 20px;
    padding: 16px 16px 16px 40px;
  }

  .currency-symbol {
    left: 16px;
    font-size: 20px;
  }

  .confirmation-actions,
  .success-actions {
    flex-direction: column;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .transfer-type-btn {
    background: rgba(28, 28, 30, 0.95);
    border-color: rgba(255, 255, 255, 0.1);
  }

  .transfer-type-btn:hover {
    background: rgba(28, 28, 30, 1);
  }

  .transfer-type-btn.active {
    background: rgba(10, 132, 255, 0.2);
    border-color: #0A84FF;
  }

  .type-label {
    color: #f2f2f7;
  }

  .section-label {
    color: #f2f2f7;
  }

  .recipient-item {
    background: rgba(44, 44, 46, 0.8);
    border-color: rgba(255, 255, 255, 0.1);
  }

  .recipient-item:hover {
    background: rgba(44, 44, 46, 1);
  }

  .recipient-item.active {
    background: rgba(10, 132, 255, 0.2);
    border-color: #0A84FF;
  }

  .recipient-name {
    color: #f2f2f7;
  }

  .recipient-input,
  .amount-input,
  .note-input {
    background: rgba(28, 28, 30, 0.95);
    border-color: rgba(255, 255, 255, 0.1);
    color: #f2f2f7;
  }

  .recipient-input:focus,
  .amount-input:focus,
  .note-input:focus {
    background: rgba(28, 28, 30, 1);
    border-color: #0A84FF;
  }

  .currency-symbol {
    color: #f2f2f7;
  }

  .search-results {
    background: rgba(28, 28, 30, 0.95);
    border-color: rgba(255, 255, 255, 0.1);
  }

  .search-result-item:hover {
    background: rgba(10, 132, 255, 0.2);
  }

  .result-name {
    color: #f2f2f7;
  }

  .quick-amount-btn {
    background: rgba(44, 44, 46, 0.8);
    border-color: rgba(255, 255, 255, 0.1);
    color: #f2f2f7;
  }

  .quick-amount-btn:hover {
    background: rgba(44, 44, 46, 1);
  }

  .account-option {
    background: rgba(44, 44, 46, 0.8);
    border-color: rgba(255, 255, 255, 0.1);
  }

  .account-option:hover {
    background: rgba(44, 44, 46, 1);
  }

  .account-option.active {
    background: rgba(10, 132, 255, 0.2);
    border-color: #0A84FF;
  }

  .account-name {
    color: #f2f2f7;
  }

  .summary-value {
    color: #f2f2f7;
  }

  .confirmation-title,
  .success-title {
    color: #f2f2f7;
  }

  .info-value {
    color: #f2f2f7;
  }

  .confirmation-info,
  .success-info {
    background: rgba(255, 255, 255, 0.05);
  }
}
</style>