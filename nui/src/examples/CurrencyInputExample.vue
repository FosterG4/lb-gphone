<template>
  <div class="currency-input-examples">
    <h2>Currency Input Examples</h2>
    
    <!-- Basic Usage -->
    <section class="example-section">
      <h3>Basic Usage</h3>
      <CurrencyInput
        v-model="basicAmount"
        :placeholder="$t('bank.amount')"
        @validate="handleValidation"
      />
      <p class="result">Amount: {{ basicAmount }}</p>
    </section>
    
    <!-- With Minimum Amount -->
    <section class="example-section">
      <h3>With Minimum Amount ($100)</h3>
      <CurrencyInput
        v-model="minAmount"
        :placeholder="$t('bank.amount')"
        :min-amount="100"
        :helper-text="$t('bank.limit')"
      />
      <p class="result">Amount: {{ minAmount }}</p>
    </section>
    
    <!-- Allow Zero -->
    <section class="example-section">
      <h3>Allow Zero Amount</h3>
      <CurrencyInput
        v-model="zeroAmount"
        :placeholder="$t('bank.amount')"
        :allow-zero="true"
      />
      <p class="result">Amount: {{ zeroAmount }}</p>
    </section>
    
    <!-- Validate on Input -->
    <section class="example-section">
      <h3>Validate on Input (Real-time)</h3>
      <CurrencyInput
        v-model="realtimeAmount"
        :placeholder="$t('bank.amount')"
        :validate-on-input="true"
      />
      <p class="result">Amount: {{ realtimeAmount }}</p>
    </section>
    
    <!-- Transfer Form Example -->
    <section class="example-section">
      <h3>Transfer Form Example</h3>
      <form @submit.prevent="handleTransfer">
        <div class="form-group">
          <label>{{ $t('bank.recipient') }}</label>
          <input 
            v-model="transferRecipient" 
            type="text" 
            :placeholder="$t('bank.recipient')"
            class="text-input"
          />
        </div>
        
        <div class="form-group">
          <label>{{ $t('bank.amount') }}</label>
          <CurrencyInput
            v-model="transferAmount"
            :placeholder="$t('bank.amount')"
            :helper-text="`${$t('bank.available')}: ${formatCurrency(availableBalance)}`"
            :max-amount="availableBalance"
            @enter="handleTransfer"
          />
        </div>
        
        <button 
          type="submit" 
          class="submit-button"
          :disabled="!transferAmount || !transferRecipient"
        >
          {{ $t('bank.transfer') }}
        </button>
      </form>
      
      <div v-if="transferResult" class="transfer-result" :class="transferResult.type">
        {{ transferResult.message }}
      </div>
    </section>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import CurrencyInput from '../components/CurrencyInput.vue'
import { formatCurrency } from '../utils/currency'
import { showSuccess, showError, showCurrencyError } from '../utils/notifications'

export default {
  name: 'CurrencyInputExample',
  components: {
    CurrencyInput
  },
  setup() {
    const { t } = useI18n()
    
    // Example amounts
    const basicAmount = ref(null)
    const minAmount = ref(null)
    const zeroAmount = ref(null)
    const realtimeAmount = ref(null)
    
    // Transfer form
    const transferRecipient = ref('')
    const transferAmount = ref(null)
    const availableBalance = ref(50000)
    const transferResult = ref(null)
    
    const handleValidation = (validation) => {
      console.log('Validation result:', validation)
      
      if (!validation.isValid && validation.error) {
        // Show error notification
        showCurrencyError(validation, { t })
      }
    }
    
    const handleTransfer = () => {
      if (!transferAmount.value || !transferRecipient.value) {
        showError(t('bank.invalid'), t('bank.failed'))
        return
      }
      
      if (transferAmount.value > availableBalance.value) {
        showError(t('currency.errors.insufficientFunds'), t('bank.insufficient'))
        transferResult.value = {
          type: 'error',
          message: t('currency.errors.insufficientFunds')
        }
        return
      }
      
      // Simulate successful transfer
      showSuccess(
        `${t('bank.transfer')} ${formatCurrency(transferAmount.value)} ${t('common.success')}`,
        t('bank.success')
      )
      
      transferResult.value = {
        type: 'success',
        message: t('bank.success')
      }
      
      // Reset form
      setTimeout(() => {
        transferAmount.value = null
        transferRecipient.value = ''
        transferResult.value = null
      }, 3000)
    }
    
    return {
      basicAmount,
      minAmount,
      zeroAmount,
      realtimeAmount,
      transferRecipient,
      transferAmount,
      availableBalance,
      transferResult,
      handleValidation,
      handleTransfer,
      formatCurrency
    }
  }
}
</script>

<style scoped>
.currency-input-examples {
  padding: 20px;
  max-width: 600px;
  margin: 0 auto;
}

h2 {
  font-size: 24px;
  margin-bottom: 20px;
  color: var(--text-primary, #000);
}

.example-section {
  margin-bottom: 30px;
  padding: 20px;
  background: var(--card-bg, #fff);
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

h3 {
  font-size: 18px;
  margin-bottom: 15px;
  color: var(--text-primary, #000);
}

.result {
  margin-top: 10px;
  font-size: 14px;
  color: var(--text-secondary, #666);
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-size: 14px;
  font-weight: 500;
  color: var(--text-primary, #000);
}

.text-input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid var(--input-border, #ddd);
  border-radius: 8px;
  font-size: 16px;
  background: var(--input-bg, #f5f5f5);
  color: var(--text-primary, #000);
}

.text-input:focus {
  outline: none;
  border-color: var(--primary-color, #007aff);
  background: var(--input-bg-focus, #fff);
}

.submit-button {
  width: 100%;
  padding: 12px;
  background: var(--primary-color, #007aff);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.submit-button:hover:not(:disabled) {
  background: var(--primary-color-dark, #0051d5);
  transform: translateY(-1px);
}

.submit-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.transfer-result {
  margin-top: 15px;
  padding: 12px;
  border-radius: 8px;
  font-size: 14px;
  animation: slideDown 0.3s ease;
}

.transfer-result.success {
  background: var(--success-bg, #d4edda);
  color: var(--success-color, #155724);
  border: 1px solid var(--success-border, #c3e6cb);
}

.transfer-result.error {
  background: var(--error-bg, #f8d7da);
  color: var(--error-color, #721c24);
  border: 1px solid var(--error-border, #f5c6cb);
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
