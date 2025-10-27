<template>
  <div class="bank-app">
    <div class="balance-section">
      <div class="balance-label">Account Balance</div>
      <div class="balance-amount">${{ formatMoney(balance) }}</div>
    </div>
    
    <div class="transfer-section">
      <h3 class="section-title">Transfer Money</h3>
      
      <div class="form-group">
        <label>Phone Number</label>
        <input 
          v-model="transferForm.phoneNumber" 
          type="text" 
          placeholder="555-1234"
          class="form-input"
          :disabled="isTransferring"
        />
      </div>
      
      <div class="form-group">
        <label>Amount</label>
        <input 
          v-model.number="transferForm.amount" 
          type="number" 
          placeholder="0.00"
          class="form-input"
          :disabled="isTransferring"
          min="1"
        />
      </div>
      
      <button 
        @click="handleTransfer" 
        class="transfer-button"
        :disabled="!canTransfer || isTransferring"
      >
        {{ isTransferring ? 'Processing...' : 'Send Money' }}
      </button>
      
      <div v-if="transferError" class="error-message">
        {{ transferError }}
      </div>
      
      <div v-if="transferSuccess" class="success-message">
        Transfer successful!
      </div>
    </div>
    
    <div class="history-section">
      <h3 class="section-title">Transaction History</h3>
      
      <div v-if="transactions.length === 0" class="empty-state">
        No transactions yet
      </div>
      
      <div v-else class="transaction-list">
        <div 
          v-for="transaction in transactions" 
          :key="transaction.id"
          class="transaction-item"
          :class="transaction.type"
        >
          <div class="transaction-info">
            <div class="transaction-type">
              {{ transaction.type === 'sent' ? 'Sent to' : 'Received from' }}
            </div>
            <div class="transaction-number">{{ transaction.phoneNumber }}</div>
            <div class="transaction-date">{{ formatDate(transaction.timestamp) }}</div>
          </div>
          <div class="transaction-amount" :class="transaction.type">
            {{ transaction.type === 'sent' ? '-' : '+' }}${{ formatMoney(transaction.amount) }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useStore } from 'vuex'

export default {
  name: 'Bank',
  setup() {
    const store = useStore()
    
    const transferForm = ref({
      phoneNumber: '',
      amount: null
    })
    
    const isTransferring = ref(false)
    const transferError = ref('')
    const transferSuccess = ref(false)
    
    const balance = computed(() => store.state.apps.bank.balance)
    const transactions = computed(() => store.state.apps.bank.transactions)
    
    const canTransfer = computed(() => {
      return transferForm.value.phoneNumber && 
             transferForm.value.amount > 0 &&
             transferForm.value.amount <= balance.value
    })
    
    const formatMoney = (amount) => {
      return amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
    }
    
    const formatDate = (timestamp) => {
      const date = new Date(timestamp)
      const now = new Date()
      const diffMs = now - date
      const diffMins = Math.floor(diffMs / 60000)
      const diffHours = Math.floor(diffMs / 3600000)
      const diffDays = Math.floor(diffMs / 86400000)
      
      if (diffMins < 1) return 'Just now'
      if (diffMins < 60) return `${diffMins}m ago`
      if (diffHours < 24) return `${diffHours}h ago`
      if (diffDays < 7) return `${diffDays}d ago`
      
      return date.toLocaleDateString()
    }
    
    const handleTransfer = async () => {
      if (!canTransfer.value || isTransferring.value) return
      
      transferError.value = ''
      transferSuccess.value = false
      isTransferring.value = true
      
      try {
        const result = await store.dispatch('apps/transferMoney', {
          targetNumber: transferForm.value.phoneNumber,
          amount: transferForm.value.amount
        })
        
        if (result.success) {
          transferSuccess.value = true
          transferForm.value.phoneNumber = ''
          transferForm.value.amount = null
          
          // Clear success message after 3 seconds
          setTimeout(() => {
            transferSuccess.value = false
          }, 3000)
          
          // Show notification
          store.dispatch('phone/showNotification', {
            type: 'success',
            title: 'Transfer Complete',
            message: `Sent $${formatMoney(result.amount)} to ${result.targetNumber}`
          })
        } else {
          transferError.value = result.message || 'Transfer failed'
        }
      } catch (error) {
        console.error('Transfer error:', error)
        transferError.value = 'An error occurred during transfer'
      } finally {
        isTransferring.value = false
      }
    }
    
    onMounted(async () => {
      // Fetch balance and transaction history
      await store.dispatch('apps/fetchBankData')
    })
    
    return {
      transferForm,
      isTransferring,
      transferError,
      transferSuccess,
      balance,
      transactions,
      canTransfer,
      formatMoney,
      formatDate,
      handleTransfer
    }
  }
}
</script>

<style scoped>
.bank-app {
  flex: 1;
  overflow-y: auto;
  background: #000;
  color: #fff;
}

.balance-section {
  background: linear-gradient(135deg, #007aff 0%, #0051d5 100%);
  padding: 40px 20px;
  text-align: center;
}

.balance-label {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  margin-bottom: 8px;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.balance-amount {
  font-size: 48px;
  font-weight: 700;
  color: #fff;
}

.transfer-section,
.history-section {
  padding: 24px 20px;
}

.section-title {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 16px;
  color: #fff;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.7);
  margin-bottom: 8px;
}

.form-input {
  width: 100%;
  padding: 12px 16px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  color: #fff;
  font-size: 16px;
  transition: all 0.2s;
}

.form-input:focus {
  outline: none;
  background: rgba(255, 255, 255, 0.15);
  border-color: #007aff;
}

.form-input:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.form-input::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.transfer-button {
  width: 100%;
  padding: 14px;
  background: #007aff;
  border: none;
  border-radius: 8px;
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  margin-top: 8px;
}

.transfer-button:hover:not(:disabled) {
  background: #0051d5;
}

.transfer-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.error-message {
  margin-top: 12px;
  padding: 12px;
  background: rgba(255, 59, 48, 0.2);
  border: 1px solid rgba(255, 59, 48, 0.4);
  border-radius: 8px;
  color: #ff3b30;
  font-size: 14px;
}

.success-message {
  margin-top: 12px;
  padding: 12px;
  background: rgba(52, 199, 89, 0.2);
  border: 1px solid rgba(52, 199, 89, 0.4);
  border-radius: 8px;
  color: #34c759;
  font-size: 14px;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
  color: rgba(255, 255, 255, 0.5);
  font-size: 14px;
}

.transaction-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.transaction-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  border-left: 3px solid transparent;
}

.transaction-item.sent {
  border-left-color: #ff3b30;
}

.transaction-item.received {
  border-left-color: #34c759;
}

.transaction-info {
  flex: 1;
}

.transaction-type {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.7);
  margin-bottom: 4px;
}

.transaction-number {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
  margin-bottom: 4px;
}

.transaction-date {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.5);
}

.transaction-amount {
  font-size: 18px;
  font-weight: 700;
}

.transaction-amount.sent {
  color: #ff3b30;
}

.transaction-amount.received {
  color: #34c759;
}

/* Responsive adjustments */
@media (max-width: 1600px) and (max-height: 900px) {
  .balance-section {
    padding: 32px 16px;
  }
  
  .balance-amount {
    font-size: 40px;
  }
  
  .transfer-section,
  .history-section {
    padding: 20px 16px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .balance-section {
    padding: 24px 12px;
  }
  
  .balance-amount {
    font-size: 36px;
  }
  
  .transfer-section,
  .history-section {
    padding: 16px 12px;
  }
  
  .section-title {
    font-size: 16px;
  }
  
  .form-input {
    padding: 10px 12px;
    font-size: 14px;
  }
  
  .transfer-button {
    padding: 12px;
    font-size: 14px;
  }
}
</style>
