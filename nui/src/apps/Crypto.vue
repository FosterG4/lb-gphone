<template>
  <div class="crypto-app">
    <div class="portfolio-section">
      <div class="portfolio-header">
        <div class="portfolio-label">Portfolio Value</div>
        <div class="portfolio-value">${{ formatMoney(totalPortfolioValue) }}</div>
      </div>
    </div>
    
    <div class="crypto-list">
      <div 
        v-for="crypto in availableCryptos" 
        :key="crypto.symbol"
        class="crypto-item"
        @click="selectCrypto(crypto)"
        :class="{ active: selectedCrypto?.symbol === crypto.symbol }"
      >
        <div class="crypto-info">
          <div class="crypto-icon">{{ crypto.icon }}</div>
          <div class="crypto-details">
            <div class="crypto-name">{{ crypto.name }}</div>
            <div class="crypto-symbol">{{ crypto.symbol }}</div>
          </div>
        </div>
        
        <div class="crypto-price-info">
          <div class="crypto-price">${{ formatPrice(crypto.currentPrice) }}</div>
          <div 
            class="crypto-change" 
            :class="crypto.priceChange >= 0 ? 'positive' : 'negative'"
          >
            {{ crypto.priceChange >= 0 ? '+' : '' }}{{ crypto.priceChange.toFixed(2) }}%
          </div>
        </div>
        
        <div class="crypto-holdings">
          <div class="holdings-amount">{{ formatCryptoAmount(getHoldings(crypto.symbol)) }}</div>
          <div class="holdings-value">${{ formatMoney(getHoldingsValue(crypto.symbol)) }}</div>
        </div>
      </div>
    </div>
    
    <div v-if="selectedCrypto" class="trade-section">
      <div class="trade-tabs">
        <button 
          @click="tradeMode = 'buy'" 
          class="trade-tab"
          :class="{ active: tradeMode === 'buy' }"
        >
          Buy
        </button>
        <button 
          @click="tradeMode = 'sell'" 
          class="trade-tab"
          :class="{ active: tradeMode === 'sell' }"
        >
          Sell
        </button>
      </div>
      
      <div class="trade-form">
        <div class="form-group">
          <label>Amount ({{ selectedCrypto.symbol }})</label>
          <input 
            v-model.number="tradeAmount" 
            type="number" 
            placeholder="0.00"
            class="form-input"
            :disabled="isTrading"
            step="0.00000001"
            min="0"
          />
        </div>
        
        <div class="trade-summary">
          <div class="summary-row">
            <span>Price per {{ selectedCrypto.symbol }}</span>
            <span>${{ formatPrice(selectedCrypto.currentPrice) }}</span>
          </div>
          <div class="summary-row">
            <span>Total Cost</span>
            <span>${{ formatMoney(tradeTotalCost) }}</span>
          </div>
          <div v-if="tradeMode === 'buy'" class="summary-row">
            <span>Available Balance</span>
            <span>${{ formatMoney(cashBalance) }}</span>
          </div>
          <div v-if="tradeMode === 'sell'" class="summary-row">
            <span>Available {{ selectedCrypto.symbol }}</span>
            <span>{{ formatCryptoAmount(getHoldings(selectedCrypto.symbol)) }}</span>
          </div>
        </div>
        
        <button 
          @click="handleTrade" 
          class="trade-button"
          :class="tradeMode"
          :disabled="!canTrade || isTrading"
        >
          {{ isTrading ? 'Processing...' : (tradeMode === 'buy' ? 'Buy' : 'Sell') }} {{ selectedCrypto.symbol }}
        </button>
        
        <div v-if="tradeError" class="error-message">
          {{ tradeError }}
        </div>
        
        <div v-if="tradeSuccess" class="success-message">
          {{ tradeSuccessMessage }}
        </div>
      </div>
    </div>
    
    <div v-else class="empty-state">
      Select a cryptocurrency to trade
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useStore } from 'vuex'

export default {
  name: 'Crypto',
  setup() {
    const store = useStore()
    
    const selectedCrypto = ref(null)
    const tradeMode = ref('buy')
    const tradeAmount = ref(null)
    const isTrading = ref(false)
    const tradeError = ref('')
    const tradeSuccess = ref(false)
    const tradeSuccessMessage = ref('')
    
    const portfolio = computed(() => store.state.apps.crypto.portfolio)
    const prices = computed(() => store.state.apps.crypto.prices)
    const cashBalance = computed(() => store.state.apps.bank.balance)
    
    const availableCryptos = computed(() => {
      return Object.keys(prices.value).map(symbol => {
        const priceData = prices.value[symbol]
        return {
          symbol: symbol,
          name: priceData.name,
          icon: priceData.icon,
          currentPrice: priceData.currentPrice,
          previousPrice: priceData.previousPrice || priceData.currentPrice,
          priceChange: priceData.previousPrice 
            ? ((priceData.currentPrice - priceData.previousPrice) / priceData.previousPrice) * 100
            : 0
        }
      })
    })
    
    const totalPortfolioValue = computed(() => {
      return portfolio.value.reduce((total, holding) => {
        const price = prices.value[holding.crypto_type]?.currentPrice || 0
        return total + (holding.amount * price)
      }, 0)
    })
    
    const tradeTotalCost = computed(() => {
      if (!selectedCrypto.value || !tradeAmount.value) return 0
      return tradeAmount.value * selectedCrypto.value.currentPrice
    })
    
    const canTrade = computed(() => {
      if (!selectedCrypto.value || !tradeAmount.value || tradeAmount.value <= 0) {
        return false
      }
      
      if (tradeMode.value === 'buy') {
        return tradeTotalCost.value <= cashBalance.value
      } else {
        const holdings = getHoldings(selectedCrypto.value.symbol)
        return tradeAmount.value <= holdings
      }
    })
    
    const getHoldings = (symbol) => {
      const holding = portfolio.value.find(h => h.crypto_type === symbol)
      return holding ? holding.amount : 0
    }
    
    const getHoldingsValue = (symbol) => {
      const amount = getHoldings(symbol)
      const price = prices.value[symbol]?.currentPrice || 0
      return amount * price
    }
    
    const formatMoney = (amount) => {
      return amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
    }
    
    const formatPrice = (price) => {
      if (price < 1) {
        return price.toFixed(8)
      } else if (price < 100) {
        return price.toFixed(4)
      } else {
        return price.toFixed(2)
      }
    }
    
    const formatCryptoAmount = (amount) => {
      if (amount === 0) return '0'
      if (amount < 0.00001) {
        return amount.toFixed(8)
      } else if (amount < 1) {
        return amount.toFixed(6)
      } else {
        return amount.toFixed(4)
      }
    }
    
    const selectCrypto = (crypto) => {
      selectedCrypto.value = crypto
      tradeAmount.value = null
      tradeError.value = ''
      tradeSuccess.value = false
    }
    
    const handleTrade = async () => {
      if (!canTrade.value || isTrading.value) return
      
      tradeError.value = ''
      tradeSuccess.value = false
      isTrading.value = true
      
      try {
        const result = await store.dispatch('apps/tradeCrypto', {
          cryptoType: selectedCrypto.value.symbol,
          amount: tradeAmount.value,
          action: tradeMode.value
        })
        
        if (result.success) {
          tradeSuccess.value = true
          tradeSuccessMessage.value = tradeMode.value === 'buy'
            ? `Bought ${formatCryptoAmount(tradeAmount.value)} ${selectedCrypto.value.symbol}`
            : `Sold ${formatCryptoAmount(tradeAmount.value)} ${selectedCrypto.value.symbol}`
          
          tradeAmount.value = null
          
          // Clear success message after 3 seconds
          setTimeout(() => {
            tradeSuccess.value = false
          }, 3000)
          
          // Show notification
          store.dispatch('phone/showNotification', {
            type: 'success',
            title: 'Trade Complete',
            message: tradeSuccessMessage.value
          })
        } else {
          tradeError.value = result.message || 'Trade failed'
        }
      } catch (error) {
        console.error('Trade error:', error)
        tradeError.value = 'An error occurred during trade'
      } finally {
        isTrading.value = false
      }
    }
    
    let priceUpdateInterval = null
    
    onMounted(async () => {
      // Fetch initial crypto data
      await store.dispatch('apps/fetchCryptoData')
      
      // Auto-select first crypto if available
      if (availableCryptos.value.length > 0) {
        selectedCrypto.value = availableCryptos.value[0]
      }
    })
    
    onUnmounted(() => {
      if (priceUpdateInterval) {
        clearInterval(priceUpdateInterval)
      }
    })
    
    return {
      selectedCrypto,
      tradeMode,
      tradeAmount,
      isTrading,
      tradeError,
      tradeSuccess,
      tradeSuccessMessage,
      availableCryptos,
      totalPortfolioValue,
      tradeTotalCost,
      canTrade,
      cashBalance,
      getHoldings,
      getHoldingsValue,
      formatMoney,
      formatPrice,
      formatCryptoAmount,
      selectCrypto,
      handleTrade
    }
  }
}
</script>

<style scoped>
.crypto-app {
  flex: 1;
  overflow-y: auto;
  background: #000;
  color: #fff;
}

.portfolio-section {
  background: linear-gradient(135deg, #f7931a 0%, #d97706 100%);
  padding: 40px 20px;
}

.portfolio-header {
  text-align: center;
}

.portfolio-label {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  margin-bottom: 8px;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.portfolio-value {
  font-size: 48px;
  font-weight: 700;
  color: #fff;
}

.crypto-list {
  padding: 16px;
}

.crypto-item {
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 16px;
  align-items: center;
  padding: 16px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  margin-bottom: 12px;
  cursor: pointer;
  transition: all 0.2s;
  border: 2px solid transparent;
}

.crypto-item:hover {
  background: rgba(255, 255, 255, 0.08);
}

.crypto-item.active {
  border-color: #f7931a;
  background: rgba(247, 147, 26, 0.1);
}

.crypto-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.crypto-icon {
  width: 40px;
  height: 40px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
}

.crypto-details {
  display: flex;
  flex-direction: column;
}

.crypto-name {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
}

.crypto-symbol {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.6);
}

.crypto-price-info {
  text-align: right;
}

.crypto-price {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
  margin-bottom: 4px;
}

.crypto-change {
  font-size: 12px;
  font-weight: 600;
}

.crypto-change.positive {
  color: #34c759;
}

.crypto-change.negative {
  color: #ff3b30;
}

.crypto-holdings {
  text-align: right;
}

.holdings-amount {
  font-size: 14px;
  font-weight: 600;
  color: #fff;
  margin-bottom: 4px;
}

.holdings-value {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.6);
}

.trade-section {
  padding: 20px;
  background: rgba(255, 255, 255, 0.03);
}

.trade-tabs {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  margin-bottom: 20px;
}

.trade-tab {
  padding: 12px;
  background: rgba(255, 255, 255, 0.05);
  border: none;
  border-radius: 8px;
  color: rgba(255, 255, 255, 0.6);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.trade-tab.active {
  background: #f7931a;
  color: #fff;
}

.trade-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
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
  border-color: #f7931a;
}

.form-input:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.form-input::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.trade-summary {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  padding: 16px;
}

.summary-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  font-size: 14px;
}

.summary-row:not(:last-child) {
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.summary-row span:first-child {
  color: rgba(255, 255, 255, 0.7);
}

.summary-row span:last-child {
  color: #fff;
  font-weight: 600;
}

.trade-button {
  width: 100%;
  padding: 14px;
  border: none;
  border-radius: 8px;
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.trade-button.buy {
  background: #34c759;
}

.trade-button.buy:hover:not(:disabled) {
  background: #2da84a;
}

.trade-button.sell {
  background: #ff3b30;
}

.trade-button.sell:hover:not(:disabled) {
  background: #d93025;
}

.trade-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.error-message {
  padding: 12px;
  background: rgba(255, 59, 48, 0.2);
  border: 1px solid rgba(255, 59, 48, 0.4);
  border-radius: 8px;
  color: #ff3b30;
  font-size: 14px;
}

.success-message {
  padding: 12px;
  background: rgba(52, 199, 89, 0.2);
  border: 1px solid rgba(52, 199, 89, 0.4);
  border-radius: 8px;
  color: #34c759;
  font-size: 14px;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: rgba(255, 255, 255, 0.5);
  font-size: 14px;
}

/* Responsive adjustments */
@media (max-width: 1600px) and (max-height: 900px) {
  .portfolio-section {
    padding: 32px 16px;
  }
  
  .portfolio-value {
    font-size: 40px;
  }
  
  .crypto-list {
    padding: 12px;
  }
  
  .trade-section {
    padding: 16px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .portfolio-section {
    padding: 24px 12px;
  }
  
  .portfolio-value {
    font-size: 36px;
  }
  
  .crypto-list {
    padding: 8px;
  }
  
  .crypto-item {
    padding: 12px;
    margin-bottom: 8px;
  }
  
  .crypto-icon {
    width: 36px;
    height: 36px;
    font-size: 18px;
  }
  
  .trade-section {
    padding: 12px;
  }
  
  .form-input {
    padding: 10px 12px;
    font-size: 14px;
  }
  
  .trade-button {
    padding: 12px;
    font-size: 14px;
  }
}
</style>
