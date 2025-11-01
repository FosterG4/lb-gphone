<template>
  <div class="currency-input-wrapper">
    <div class="currency-input-container" :class="{ 'has-error': hasError, 'is-focused': isFocused }">
      <span v-if="showSymbol && symbolPosition === 'before'" class="currency-symbol">
        {{ currencySymbol }}
      </span>
      
      <input
        ref="input"
        type="text"
        :value="displayValue"
        :placeholder="placeholder"
        :disabled="disabled"
        :readonly="readonly"
        class="currency-input"
        @input="handleInput"
        @blur="handleBlur"
        @focus="handleFocus"
        @keydown.enter="handleEnter"
      />
      
      <span v-if="showSymbol && symbolPosition === 'after'" class="currency-symbol">
        {{ currencySymbol }}
      </span>
      
      <button
        v-if="clearable && displayValue"
        type="button"
        class="clear-button"
        @click="handleClear"
        :disabled="disabled"
      >
        ×
      </button>
    </div>
    
    <div v-if="hasError && showError" class="error-message">
      <span class="error-icon">⚠</span>
      <span class="error-text">{{ errorMessage }}</span>
    </div>
    
    <div v-if="helperText && !hasError" class="helper-text">
      {{ helperText }}
    </div>
  </div>
</template>

<script>
import { ref, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { 
  formatCurrencyNumber, 
  parseCurrency, 
  validateCurrencyInput,
  getCurrencySymbol,
  MAX_CURRENCY_VALUE
} from '../utils/currency'

export default {
  name: 'CurrencyInput',
  props: {
    modelValue: {
      type: [Number, String],
      default: null
    },
    placeholder: {
      type: String,
      default: '0.00'
    },
    disabled: {
      type: Boolean,
      default: false
    },
    readonly: {
      type: Boolean,
      default: false
    },
    showSymbol: {
      type: Boolean,
      default: true
    },
    clearable: {
      type: Boolean,
      default: true
    },
    showError: {
      type: Boolean,
      default: true
    },
    helperText: {
      type: String,
      default: ''
    },
    allowZero: {
      type: Boolean,
      default: false
    },
    minAmount: {
      type: Number,
      default: 0
    },
    maxAmount: {
      type: Number,
      default: MAX_CURRENCY_VALUE
    },
    validateOnInput: {
      type: Boolean,
      default: false
    }
  },
  emits: ['update:modelValue', 'validate', 'enter', 'clear'],
  setup(props, { emit }) {
    const { t, locale } = useI18n()
    
    const input = ref(null)
    const displayValue = ref('')
    const isFocused = ref(false)
    const validationError = ref(null)
    
    const currencySymbol = computed(() => getCurrencySymbol(locale.value))
    
    const symbolPosition = computed(() => {
      const positions = {
        'en': 'before',
        'ja': 'before',
        'es': 'after',
        'fr': 'after',
        'de': 'after',
        'pt': 'before'
      }
      return positions[locale.value] || 'before'
    })
    
    const hasError = computed(() => validationError.value !== null)
    
    const errorMessage = computed(() => {
      if (!validationError.value) return ''
      
      // Try to get translated error message
      if (validationError.value.error) {
        return t(validationError.value.error)
      }
      
      return validationError.value.message || t('currency.errors.validationFailed')
    })
    
    // Initialize display value from model value
    watch(() => props.modelValue, (newValue) => {
      if (newValue !== null && newValue !== undefined && !isFocused.value) {
        const numValue = typeof newValue === 'string' ? parseCurrency(newValue) : newValue
        displayValue.value = formatCurrencyNumber(numValue, locale.value)
      } else if (!newValue && !isFocused.value) {
        displayValue.value = ''
      }
    }, { immediate: true })
    
    const handleInput = (event) => {
      const value = event.target.value
      displayValue.value = value
      
      if (props.validateOnInput) {
        validateInput(value)
      } else {
        // Clear error on input if not validating on input
        validationError.value = null
      }
    }
    
    const validateInput = (value) => {
      if (!value || value.trim() === '') {
        validationError.value = null
        emit('update:modelValue', null)
        emit('validate', { isValid: true, amount: null, error: null })
        return true
      }
      
      const validation = validateCurrencyInput(value, {
        allowZero: props.allowZero,
        minAmount: props.minAmount
      })
      
      // Check max amount
      if (validation.isValid && validation.amount > props.maxAmount) {
        validation.isValid = false
        validation.error = 'currency.errors.exceedsMaximum'
        validation.errorKey = 'exceedsMaximum'
        validation.message = `Amount cannot exceed ${formatCurrencyNumber(props.maxAmount, locale.value)}`
      }
      
      if (validation.isValid) {
        validationError.value = null
        emit('update:modelValue', validation.amount)
        emit('validate', validation)
        return true
      } else {
        validationError.value = validation
        emit('validate', validation)
        return false
      }
    }
    
    const handleBlur = (event) => {
      isFocused.value = false
      const value = event.target.value
      
      // Validate on blur
      const isValid = validateInput(value)
      
      // Format the display value if valid
      if (isValid && value) {
        const numValue = parseCurrency(value)
        displayValue.value = formatCurrencyNumber(numValue, locale.value)
      }
    }
    
    const handleFocus = () => {
      isFocused.value = true
      validationError.value = null
    }
    
    const handleEnter = () => {
      const isValid = validateInput(displayValue.value)
      if (isValid) {
        emit('enter', parseCurrency(displayValue.value))
      }
    }
    
    const handleClear = () => {
      displayValue.value = ''
      validationError.value = null
      emit('update:modelValue', null)
      emit('clear')
      input.value?.focus()
    }
    
    const focus = () => {
      input.value?.focus()
    }
    
    return {
      input,
      displayValue,
      isFocused,
      validationError,
      currencySymbol,
      symbolPosition,
      hasError,
      errorMessage,
      handleInput,
      handleBlur,
      handleFocus,
      handleEnter,
      handleClear,
      focus
    }
  }
}
</script>

<style scoped>
.currency-input-wrapper {
  width: 100%;
}

.currency-input-container {
  display: flex;
  align-items: center;
  background: var(--input-bg, #f5f5f5);
  border: 1px solid var(--input-border, #ddd);
  border-radius: 8px;
  padding: 10px 12px;
  transition: all 0.2s ease;
}

.currency-input-container.is-focused {
  border-color: var(--primary-color, #007aff);
  background: var(--input-bg-focus, #fff);
  box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
}

.currency-input-container.has-error {
  border-color: var(--error-color, #ff3b30);
  background: var(--error-bg, #fff5f5);
}

.currency-symbol {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-secondary, #666);
  margin: 0 4px;
  user-select: none;
}

.currency-input {
  flex: 1;
  border: none;
  background: transparent;
  font-size: 16px;
  font-weight: 500;
  color: var(--text-primary, #000);
  outline: none;
  min-width: 0;
}

.currency-input::placeholder {
  color: var(--text-placeholder, #999);
}

.currency-input:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.clear-button {
  background: transparent;
  border: none;
  font-size: 24px;
  color: var(--text-secondary, #666);
  cursor: pointer;
  padding: 0;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.2s ease;
}

.clear-button:hover {
  background: var(--hover-bg, rgba(0, 0, 0, 0.05));
  color: var(--text-primary, #000);
}

.clear-button:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.error-message {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 6px;
  font-size: 13px;
  color: var(--error-color, #ff3b30);
  animation: slideDown 0.2s ease;
}

.error-icon {
  font-size: 14px;
}

.error-text {
  flex: 1;
}

.helper-text {
  margin-top: 6px;
  font-size: 13px;
  color: var(--text-secondary, #666);
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
