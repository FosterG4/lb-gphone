<template>
  <div class="cryptox-app">
    <!-- Header with portfolio overview -->
    <div class="portfolio-overview">
      <div class="portfolio-card">
        <div class="portfolio-label">{{ $t('cryptox.portfolio.totalValue') }}</div>
        <div class="portfolio-value">{{ formatMoney(totalPortfolioValue) }}</div>
        <div class="portfolio-change" :class="portfolioChangeClass">
          {{ portfolioChangeText }}
        </div>
      </div>
      
      <div class="portfolio-stats">
        <div class="stat-item">
          <div class="stat-label">{{ $t('cryptox.portfolio.dailyPnL') }}</div>
          <div class="stat-value" :class="dailyPnL >= 0 ? 'positive' : 'negative'">
            {{ dailyPnL >= 0 ? '+' : '' }}{{ formatMoney(Math.abs(dailyPnL)) }}
          </div>
        </div>
        <div class="stat-item">
          <div class="stat-label">{{ $t('cryptox.portfolio.totalPnL') }}</div>
          <div class="stat-value" :class="totalPnL >= 0 ? 'positive' : 'negative'">
            {{ totalPnL >= 0 ? '+' : '' }}{{ formatMoney(Math.abs(totalPnL)) }}
          </div>
        </div>
      </div>
    </div>

    <!-- Navigation tabs -->
    <div class="nav-tabs">
      <button 
        v-for="tab in tabs" 
        :key="tab.id"
        @click="activeTab = tab.id"
        class="nav-tab"
        :class="{ active: activeTab === tab.id }"
      >
        <i :class="tab.icon"></i>
        {{ tab.label }}
      </button>
    </div>

    <!-- Tab content -->
    <div class="tab-content">
      <!-- Markets Tab -->
      <div v-if="activeTab === 'markets'" class="markets-tab">
        <div class="market-filters">
          <div class="filter-buttons">
            <button 
              v-for="filter in marketFilters" 
              :key="filter"
              @click="selectedMarketFilter = filter"
              class="filter-button"
              :class="{ active: selectedMarketFilter === filter }"
            >
              {{ filter }}
            </button>
          </div>
          
          <div class="search-container">
            <input 
              v-model="searchQuery" 
              type="text" 
              :placeholder="$t('cryptox.markets.searchPlaceholder')"
              class="search-input"
            />
          </div>
        </div>

        <div class="crypto-list">
          <div 
            v-for="crypto in filteredCryptos" 
            :key="crypto.symbol"
            class="crypto-item"
            @click="selectCrypto(crypto)"
          >
            <div class="crypto-info">
              <div class="crypto-icon">{{ crypto.icon }}</div>
              <div class="crypto-details">
                <div class="crypto-name">{{ crypto.name }}</div>
                <div class="crypto-symbol">{{ crypto.symbol }}</div>
              </div>
            </div>
            
            <div class="crypto-price-info">
              <div class="crypto-price">{{ formatMoney(crypto.currentPrice) }}</div>
              <div 
                class="crypto-change" 
                :class="crypto.priceChange >= 0 ? 'positive' : 'negative'"
              >
                {{ crypto.priceChange >= 0 ? '+' : '' }}{{ crypto.priceChange.toFixed(2) }}%
              </div>
            </div>
            
            <div class="crypto-chart-mini">
              <canvas 
                :ref="`chart-${crypto.symbol}`"
                width="60" 
                height="30"
                class="mini-chart"
              ></canvas>
            </div>
          </div>
        </div>
      </div>

      <!-- Portfolio Tab -->
      <div v-if="activeTab === 'portfolio'" class="portfolio-tab">
        <div class="portfolio-summary">
          <div class="summary-cards">
            <div class="summary-card">
              <div class="card-label">{{ $t('cryptox.portfolio.holdings') }}</div>
              <div class="card-value">{{ portfolio.length }}</div>
            </div>
            <div class="summary-card">
              <div class="card-label">{{ $t('cryptox.portfolio.bestPerformer') }}</div>
              <div class="card-value">{{ bestPerformer?.symbol || $t('cryptox.portfolio.na') }}</div>
              <div class="card-change positive">
                {{ bestPerformer ? '+' + bestPerformer.change.toFixed(2) + '%' : '' }}
              </div>
            </div>
            <div class="summary-card">
              <div class="card-label">{{ $t('cryptox.portfolio.worstPerformer') }}</div>
              <div class="card-value">{{ worstPerformer?.symbol || $t('cryptox.portfolio.na') }}</div>
              <div class="card-change negative">
                {{ worstPerformer ? worstPerformer.change.toFixed(2) + '%' : '' }}
              </div>
            </div>
          </div>
        </div>

        <div class="holdings-list">
          <div 
            v-for="holding in portfolioHoldings" 
            :key="holding.symbol"
            class="holding-item"
            @click="selectCrypto(holding)"
          >
            <div class="holding-info">
              <div class="crypto-icon">{{ holding.icon }}</div>
              <div class="holding-details">
                <div class="holding-name">{{ holding.name }}</div>
                <div class="holding-amount">{{ formatCryptoAmount(holding.amount) }} {{ holding.symbol }}</div>
              </div>
            </div>
            
            <div class="holding-values">
              <div class="holding-value">{{ formatMoney(holding.value) }}</div>
              <div class="holding-pnl" :class="holding.pnl >= 0 ? 'positive' : 'negative'">
                {{ holding.pnl >= 0 ? '+' : '' }}{{ formatMoney(Math.abs(holding.pnl)) }}
              </div>
            </div>
            
            <div class="holding-percentage">
              {{ ((holding.value / totalPortfolioValue) * 100).toFixed(1) }}%
            </div>
          </div>
        </div>
      </div>

      <!-- Trade Tab -->
      <div v-if="activeTab === 'trade'" class="trade-tab">
        <div v-if="!selectedCrypto" class="empty-state">
          <i class="icon-trending-up"></i>
          <h3>{{ $t('cryptox.trade.selectCrypto') }}</h3>
          <p>{{ $t('cryptox.trade.selectCryptoDesc') }}</p>
        </div>

        <div v-else class="trade-interface">
          <div class="crypto-header">
            <div class="crypto-info">
              <div class="crypto-icon large">{{ selectedCrypto.icon }}</div>
              <div class="crypto-details">
                <div class="crypto-name">{{ selectedCrypto.name }}</div>
                <div class="crypto-symbol">{{ selectedCrypto.symbol }}</div>
              </div>
            </div>
            <div class="crypto-price">
              <div class="current-price">{{ formatMoney(selectedCrypto.currentPrice) }}</div>
              <div class="price-change" :class="selectedCrypto.priceChange >= 0 ? 'positive' : 'negative'">
                {{ selectedCrypto.priceChange >= 0 ? '+' : '' }}{{ selectedCrypto.priceChange.toFixed(2) }}%
              </div>
            </div>
          </div>

          <div class="price-chart">
            <div class="chart-controls">
              <div class="timeframe-buttons">
                <button 
                  v-for="timeframe in timeframes" 
                  :key="timeframe"
                  @click="selectedTimeframe = timeframe"
                  class="timeframe-button"
                  :class="{ active: selectedTimeframe === timeframe }"
                >
                  {{ timeframe }}
                </button>
              </div>
            </div>
            <canvas 
              ref="priceChart"
              class="price-chart-canvas"
              width="350" 
              height="200"
            ></canvas>
          </div>

          <div class="trade-form">
            <div class="trade-tabs">
              <button 
                @click="tradeMode = 'buy'" 
                class="trade-tab-button"
                :class="{ active: tradeMode === 'buy' }"
              >
                {{ $t('cryptox.trade.buy') }}
              </button>
              <button 
                @click="tradeMode = 'sell'" 
                class="trade-tab-button"
                :class="{ active: tradeMode === 'sell' }"
              >
                {{ $t('cryptox.trade.sell') }}
              </button>
            </div>

            <div class="order-type">
              <select v-model="orderType" class="order-select">
                <option value="market">{{ $t('cryptox.trade.marketOrder') }}</option>
                <option value="limit">{{ $t('cryptox.trade.limitOrder') }}</option>
              </select>
            </div>

            <div class="form-group">
              <label>{{ $t('cryptox.trade.amount') }} ({{ selectedCrypto.symbol }})</label>
              <input 
                v-model.number="tradeAmount" 
                type="number" 
                placeholder="0.00"
                class="form-input"
                :disabled="isTrading"
                step="0.00000001"
                min="0"
              />
              <div class="amount-buttons">
                <button 
                  v-for="percentage in [25, 50, 75, 100]" 
                  :key="percentage"
                  @click="setTradePercentage(percentage)"
                  class="percentage-button"
                >
                  {{ percentage }}%
                </button>
              </div>
            </div>

            <div v-if="orderType === 'limit'" class="form-group">
              <label>{{ $t('cryptox.trade.limitPrice') }}</label>
              <input 
                v-model.number="limitPrice" 
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
                <span>{{ $t('cryptox.trade.pricePerUnit', { symbol: selectedCrypto.symbol }) }}</span>
                <span>{{ formatMoney(effectivePrice) }}</span>
              </div>
              <div class="summary-row">
                <span>{{ $t('cryptox.trade.totalCost') }}</span>
                <span>{{ formatMoney(tradeTotalCost) }}</span>
              </div>
              <div class="summary-row">
                <span>{{ $t('cryptox.trade.fees') }}</span>
                <span>{{ formatMoney(tradeFees) }}</span>
              </div>
              <div class="summary-row total">
                <span>{{ $t(tradeMode === 'buy' ? 'cryptox.trade.totalCost' : 'cryptox.trade.totalReceived') }}</span>
                <span>{{ formatMoney(tradeMode === 'buy' ? tradeTotalCost + tradeFees : tradeTotalCost - tradeFees) }}</span>
              </div>
              
              <div v-if="tradeMode === 'buy'" class="summary-row">
                <span>{{ $t('cryptox.trade.availableBalance') }}</span>
                <span>{{ formatMoney(cashBalance) }}</span>
              </div>
              <div v-if="tradeMode === 'sell'" class="summary-row">
                <span>{{ $t('cryptox.trade.available', { symbol: selectedCrypto.symbol }) }}</span>
                <span>{{ formatCryptoAmount(getHoldings(selectedCrypto.symbol)) }}</span>
              </div>
            </div>

            <button 
              @click="handleTrade" 
              class="trade-button"
              :class="tradeMode"
              :disabled="!canTrade || isTrading"
            >
              {{ isTrading ? $t('cryptox.trade.processing') : $t(`cryptox.trade.${tradeMode}Button`, { symbol: selectedCrypto.symbol }) }}
            </button>

            <div v-if="tradeError" class="error-message">
              {{ tradeError }}
            </div>

            <div v-if="tradeSuccess" class="success-message">
              {{ tradeSuccessMessage }}
            </div>
          </div>
        </div>
      </div>

      <!-- History Tab -->
      <div v-if="activeTab === 'history'" class="history-tab">
        <div class="history-filters">
          <select v-model="historyFilter" class="filter-select">
            <option value="all">{{ $t('cryptox.history.allTransactions') }}</option>
            <option value="buy">{{ $t('cryptox.history.buys') }}</option>
            <option value="sell">{{ $t('cryptox.history.sells') }}</option>
          </select>
          
          <select v-model="historyPeriod" class="filter-select">
            <option value="week">{{ $t('cryptox.history.thisWeek') }}</option>
            <option value="month">{{ $t('cryptox.history.thisMonth') }}</option>
            <option value="quarter">{{ $t('cryptox.history.thisQuarter') }}</option>
            <option value="year">{{ $t('cryptox.history.thisYear') }}</option>
            <option value="all">{{ $t('cryptox.history.allTime') }}</option>
          </select>
        </div>

        <div class="transaction-list">
          <div 
            v-for="transaction in filteredHistory" 
            :key="transaction.id"
            class="transaction-item"
          >
            <div class="transaction-icon" :class="transaction.type">
              <i :class="transaction.type === 'buy' ? 'icon-trending-up' : 'icon-trending-down'"></i>
            </div>
            <div class="transaction-details">
              <div class="transaction-crypto">
                {{ transaction.type.toUpperCase() }} {{ transaction.cryptoSymbol }}
              </div>
              <div class="transaction-amount">
                {{ formatCryptoAmount(transaction.amount) }} {{ transaction.cryptoSymbol }}
              </div>
              <div class="transaction-date">{{ formatDate(transaction.timestamp) }}</div>
            </div>
            <div class="transaction-value">
              <div class="transaction-price">{{ formatMoney(transaction.price) }}</div>
              <div class="transaction-total">{{ formatMoney(transaction.total) }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Alerts Tab -->
      <div v-if="activeTab === 'alerts'" class="alerts-tab">
        <div class="alerts-header">
          <h3>{{ $t('cryptox.alerts.priceAlerts') }}</h3>
          <button @click="showAlertModal = true" class="add-button">
            <i class="icon-plus"></i>
            {{ $t('cryptox.alerts.addAlert') }}
          </button>
        </div>

        <div class="alerts-list">
          <div 
            v-for="alert in priceAlerts" 
            :key="alert.id"
            class="alert-item"
            :class="{ triggered: alert.triggered }"
          >
            <div class="alert-info">
              <div class="alert-crypto">{{ alert.cryptoSymbol }}</div>
              <div class="alert-condition">
                {{ $t(`cryptox.alerts.${alert.condition}`) }} {{ formatMoney(alert.targetPrice) }}
              </div>
              <div class="alert-status">
                {{ alert.triggered ? $t('cryptox.alerts.triggered') : $t('cryptox.alerts.active') }}
              </div>
            </div>
            <div class="alert-actions">
              <button @click="deleteAlert(alert.id)" class="action-button delete">
                <i class="icon-trash"></i>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Alert Modal -->
    <div v-if="showAlertModal" class="modal-overlay" @click="showAlertModal = false">
      <div class="modal" @click.stop>
        <div class="modal-header">
          <h3>{{ $t('cryptox.alerts.createAlert') }}</h3>
          <button @click="showAlertModal = false" class="close-button">×</button>
        </div>
        <div class="modal-content">
          <div class="form-group">
            <label>{{ $t('cryptox.alerts.cryptocurrency') }}</label>
            <select v-model="alertForm.cryptoSymbol" class="form-select">
              <option v-for="crypto in availableCryptos" :key="crypto.symbol" :value="crypto.symbol">
                {{ crypto.name }} ({{ crypto.symbol }})
              </option>
            </select>
          </div>
          
          <div class="form-group">
            <label>{{ $t('cryptox.alerts.condition') }}</label>
            <select v-model="alertForm.condition" class="form-select">
              <option value="above">{{ $t('cryptox.alerts.priceGoesAbove') }}</option>
              <option value="below">{{ $t('cryptox.alerts.priceGoesBelow') }}</option>
            </select>
          </div>
          
          <div class="form-group">
            <label>{{ $t('cryptox.alerts.targetPrice') }}</label>
            <input 
              v-model.number="alertForm.targetPrice" 
              type="number" 
              placeholder="0.00"
              class="form-input"
              step="0.00000001"
              min="0"
            />
          </div>
          
          <button @click="createAlert" class="create-button">
            {{ $t('cryptox.alerts.createAlert') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useStore } from 'vuex'
import { useI18n } from 'vue-i18n'
import { formatCurrency, validateCurrency } from '@/utils/currency'

export default {
  name: 'CryptoX',
  setup() {
    const store = useStore()
    const { t, locale } = useI18n()
    
    // Reactive data
    const activeTab = ref('markets')
    const selectedCrypto = ref(null)
    const selectedMarketFilter = ref('All')
    const searchQuery = ref('')
    const tradeMode = ref('buy')
    const orderType = ref('market')
    const tradeAmount = ref(null)
    const limitPrice = ref(null)
    const selectedTimeframe = ref('1D')
    const historyFilter = ref('all')
    const historyPeriod = ref('month')
    const showAlertModal = ref(false)
    const isTrading = ref(false)
    const tradeError = ref('')
    const tradeSuccess = ref(false)
    const tradeSuccessMessage = ref('')
    
    const alertForm = ref({
      cryptoSymbol: '',
      condition: 'above',
      targetPrice: null
    })

    // Computed properties
    const portfolio = computed(() => store.state.apps.cryptox?.portfolio || [])
    const prices = computed(() => store.state.apps.cryptox?.prices || {})
    const transactions = computed(() => store.state.apps.cryptox?.transactions || [])
    const priceAlerts = computed(() => store.state.apps.cryptox?.alerts || [])
    const cashBalance = computed(() => store.state.apps.bank?.balance || 0)
    
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
            : 0,
          marketCap: priceData.marketCap || 0,
          volume24h: priceData.volume24h || 0
        }
      })
    })

    const filteredCryptos = computed(() => {
      let filtered = availableCryptos.value

      if (selectedMarketFilter.value !== 'All') {
        // Filter logic based on market filter
        if (selectedMarketFilter.value === 'Gainers') {
          filtered = filtered.filter(c => c.priceChange > 0)
        } else if (selectedMarketFilter.value === 'Losers') {
          filtered = filtered.filter(c => c.priceChange < 0)
        }
      }

      if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase()
        filtered = filtered.filter(c => 
          c.name.toLowerCase().includes(query) ||
          c.symbol.toLowerCase().includes(query)
        )
      }

      return filtered.sort((a, b) => b.marketCap - a.marketCap)
    })

    const portfolioHoldings = computed(() => {
      return portfolio.value.map(holding => {
        const priceData = prices.value[holding.crypto_type]
        const currentValue = holding.amount * (priceData?.currentPrice || 0)
        const purchaseValue = holding.purchase_price * holding.amount
        
        return {
          symbol: holding.crypto_type,
          name: priceData?.name || holding.crypto_type,
          icon: priceData?.icon || '₿',
          amount: holding.amount,
          value: currentValue,
          pnl: currentValue - purchaseValue,
          purchasePrice: holding.purchase_price,
          currentPrice: priceData?.currentPrice || 0
        }
      })
    })

    const totalPortfolioValue = computed(() => {
      return portfolioHoldings.value.reduce((total, holding) => total + holding.value, 0)
    })

    const totalPnL = computed(() => {
      return portfolioHoldings.value.reduce((total, holding) => total + holding.pnl, 0)
    })

    const dailyPnL = computed(() => {
      // Calculate 24h P&L based on price changes
      return portfolioHoldings.value.reduce((total, holding) => {
        const priceData = prices.value[holding.symbol]
        if (priceData && priceData.previousPrice) {
          const dailyChange = (priceData.currentPrice - priceData.previousPrice) * holding.amount
          return total + dailyChange
        }
        return total
      }, 0)
    })

    const bestPerformer = computed(() => {
      if (portfolioHoldings.value.length === 0) return null
      return portfolioHoldings.value.reduce((best, holding) => {
        const change = ((holding.currentPrice - holding.purchasePrice) / holding.purchasePrice) * 100
        const bestChange = best ? ((best.currentPrice - best.purchasePrice) / best.purchasePrice) * 100 : -Infinity
        return change > bestChange ? { ...holding, change } : best
      }, null)
    })

    const worstPerformer = computed(() => {
      if (portfolioHoldings.value.length === 0) return null
      return portfolioHoldings.value.reduce((worst, holding) => {
        const change = ((holding.currentPrice - holding.purchasePrice) / holding.purchasePrice) * 100
        const worstChange = worst ? ((worst.currentPrice - worst.purchasePrice) / worst.purchasePrice) * 100 : Infinity
        return change < worstChange ? { ...holding, change } : worst
      }, null)
    })

    const effectivePrice = computed(() => {
      if (!selectedCrypto.value) return 0
      return orderType.value === 'limit' ? (limitPrice.value || 0) : selectedCrypto.value.currentPrice
    })

    const tradeTotalCost = computed(() => {
      if (!selectedCrypto.value || !tradeAmount.value) return 0
      return tradeAmount.value * effectivePrice.value
    })

    const tradeFees = computed(() => {
      return tradeTotalCost.value * 0.001 // 0.1% fee
    })

    const canTrade = computed(() => {
      if (!selectedCrypto.value || !tradeAmount.value || tradeAmount.value <= 0) {
        return false
      }
      
      if (orderType.value === 'limit' && (!limitPrice.value || limitPrice.value <= 0)) {
        return false
      }
      
      if (tradeMode.value === 'buy') {
        return (tradeTotalCost.value + tradeFees.value) <= cashBalance.value
      } else {
        const holdings = getHoldings(selectedCrypto.value.symbol)
        return tradeAmount.value <= holdings
      }
    })

    const filteredHistory = computed(() => {
      let filtered = transactions.value

      if (historyFilter.value !== 'all') {
        filtered = filtered.filter(t => t.type === historyFilter.value)
      }

      // Filter by period
      const now = Date.now()
      const periodMs = {
        week: 7 * 24 * 60 * 60 * 1000,
        month: 30 * 24 * 60 * 60 * 1000,
        quarter: 90 * 24 * 60 * 60 * 1000,
        year: 365 * 24 * 60 * 60 * 1000
      }

      if (historyPeriod.value !== 'all' && periodMs[historyPeriod.value]) {
        const cutoff = now - periodMs[historyPeriod.value]
        filtered = filtered.filter(t => t.timestamp >= cutoff)
      }

      return filtered.sort((a, b) => b.timestamp - a.timestamp)
    })

    const portfolioChangeClass = computed(() => {
      return totalPnL.value >= 0 ? 'positive' : 'negative'
    })

    const portfolioChangeText = computed(() => {
      const percentage = totalPortfolioValue.value > 0 ? (totalPnL.value / (totalPortfolioValue.value - totalPnL.value)) * 100 : 0
      return `${totalPnL.value >= 0 ? '+' : ''}${percentage.toFixed(2)}% all time`
    })

    // Tab configuration
    const tabs = computed(() => [
      { id: 'markets', label: t('cryptox.tabs.markets'), icon: 'icon-trending-up' },
      { id: 'portfolio', label: t('cryptox.tabs.portfolio'), icon: 'icon-pie-chart' },
      { id: 'trade', label: t('cryptox.tabs.trade'), icon: 'icon-activity' },
      { id: 'history', label: t('cryptox.tabs.history'), icon: 'icon-clock' },
      { id: 'alerts', label: t('cryptox.tabs.alerts'), icon: 'icon-bell' }
    ])

    const marketFilters = ['All', 'Gainers', 'Losers', 'Volume']
    const timeframes = ['1H', '4H', '1D', '1W', '1M']

    // Methods
    const formatMoney = (amount) => {
      return formatCurrency(amount, locale.value)
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
      if (amount < 1) {
        return amount.toFixed(8)
      } else {
        return amount.toFixed(4)
      }
    }

    const formatDate = (timestamp) => {
      const date = new Date(timestamp)
      return date.toLocaleDateString() + ' ' + date.toLocaleTimeString()
    }

    const selectCrypto = (crypto) => {
      selectedCrypto.value = crypto
      activeTab.value = 'trade'
      
      // Draw price chart
      nextTick(() => {
        drawPriceChart()
      })
    }

    const getHoldings = (symbol) => {
      const holding = portfolio.value.find(h => h.crypto_type === symbol)
      return holding ? holding.amount : 0
    }

    const setTradePercentage = (percentage) => {
      if (!selectedCrypto.value) return
      
      if (tradeMode.value === 'buy') {
        const maxAmount = (cashBalance.value * (percentage / 100)) / effectivePrice.value
        tradeAmount.value = maxAmount
      } else {
        const holdings = getHoldings(selectedCrypto.value.symbol)
        tradeAmount.value = holdings * (percentage / 100)
      }
    }

    const handleTrade = async () => {
      if (!canTrade.value || isTrading.value) return
      
      isTrading.value = true
      tradeError.value = ''
      tradeSuccess.value = false
      
      try {
        const result = await store.dispatch('apps/cryptoxTrade', {
          cryptoType: selectedCrypto.value.symbol,
          amount: tradeAmount.value,
          action: tradeMode.value,
          orderType: orderType.value,
          limitPrice: limitPrice.value
        })
        
        if (result.success) {
          tradeSuccess.value = true
          tradeSuccessMessage.value = `${tradeMode.value === 'buy' ? 'Bought' : 'Sold'} ${formatCryptoAmount(tradeAmount.value)} ${selectedCrypto.value.symbol}`
          
          // Reset form
          tradeAmount.value = null
          limitPrice.value = null
          
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

    const createAlert = async () => {
      if (!alertForm.value.cryptoSymbol || !alertForm.value.targetPrice) return
      
      try {
        const result = await store.dispatch('apps/cryptoxCreateAlert', {
          cryptoSymbol: alertForm.value.cryptoSymbol,
          condition: alertForm.value.condition,
          targetPrice: alertForm.value.targetPrice
        })
        
        if (result.success) {
          showAlertModal.value = false
          alertForm.value = {
            cryptoSymbol: '',
            condition: 'above',
            targetPrice: null
          }
          
          store.dispatch('phone/showNotification', {
            type: 'success',
            title: 'Alert Created',
            message: `Price alert created for ${alertForm.value.cryptoSymbol}`
          })
        }
      } catch (error) {
        console.error('Create alert error:', error)
      }
    }

    const deleteAlert = async (alertId) => {
      try {
        await store.dispatch('apps/cryptoxDeleteAlert', { alertId })
      } catch (error) {
        console.error('Delete alert error:', error)
      }
    }

    const drawPriceChart = () => {
      const canvas = document.querySelector('.price-chart-canvas')
      if (!canvas || !selectedCrypto.value) return
      
      const ctx = canvas.getContext('2d')
      const width = canvas.width
      const height = canvas.height
      
      // Clear canvas
      ctx.clearRect(0, 0, width, height)
      
      // Generate sample price data
      const priceHistory = generatePriceHistory(selectedCrypto.value.currentPrice)
      
      // Draw chart
      ctx.strokeStyle = selectedCrypto.value.priceChange >= 0 ? '#4caf50' : '#f44336'
      ctx.lineWidth = 2
      ctx.beginPath()
      
      priceHistory.forEach((price, index) => {
        const x = (index / (priceHistory.length - 1)) * width
        const y = height - ((price - Math.min(...priceHistory)) / (Math.max(...priceHistory) - Math.min(...priceHistory))) * height
        
        if (index === 0) {
          ctx.moveTo(x, y)
        } else {
          ctx.lineTo(x, y)
        }
      })
      
      ctx.stroke()
    }

    const generatePriceHistory = (currentPrice) => {
      const points = 50
      const history = []
      let price = currentPrice * 0.95 // Start 5% below current
      
      for (let i = 0; i < points; i++) {
        const change = (Math.random() - 0.5) * 0.02 // ±1% change
        price *= (1 + change)
        history.push(price)
      }
      
      // Ensure last price matches current price
      history[history.length - 1] = currentPrice
      
      return history
    }

    const drawMiniCharts = () => {
      filteredCryptos.value.forEach(crypto => {
        const canvas = document.querySelector(`[data-chart="${crypto.symbol}"]`)
        if (!canvas) return
        
        const ctx = canvas.getContext('2d')
        const width = 60
        const height = 30
        
        // Clear canvas
        ctx.clearRect(0, 0, width, height)
        
        // Generate mini chart data
        const priceHistory = generatePriceHistory(crypto.currentPrice).slice(-10)
        
        // Draw mini chart
        ctx.strokeStyle = crypto.priceChange >= 0 ? '#4caf50' : '#f44336'
        ctx.lineWidth = 1
        ctx.beginPath()
        
        priceHistory.forEach((price, index) => {
          const x = (index / (priceHistory.length - 1)) * width
          const y = height - ((price - Math.min(...priceHistory)) / (Math.max(...priceHistory) - Math.min(...priceHistory))) * height
          
          if (index === 0) {
            ctx.moveTo(x, y)
          } else {
            ctx.lineTo(x, y)
          }
        })
        
        ctx.stroke()
      })
    }

    onMounted(async () => {
      // Fetch CryptoX data
      await store.dispatch('apps/fetchCryptoxData')
      
      // Draw mini charts after data loads
      nextTick(() => {
        drawMiniCharts()
      })
    })

    return {
      activeTab,
      selectedCrypto,
      selectedMarketFilter,
      searchQuery,
      tradeMode,
      orderType,
      tradeAmount,
      limitPrice,
      selectedTimeframe,
      historyFilter,
      historyPeriod,
      showAlertModal,
      isTrading,
      tradeError,
      tradeSuccess,
      tradeSuccessMessage,
      alertForm,
      portfolio,
      prices,
      transactions,
      priceAlerts,
      cashBalance,
      availableCryptos,
      filteredCryptos,
      portfolioHoldings,
      totalPortfolioValue,
      totalPnL,
      dailyPnL,
      bestPerformer,
      worstPerformer,
      effectivePrice,
      tradeTotalCost,
      tradeFees,
      canTrade,
      filteredHistory,
      portfolioChangeClass,
      portfolioChangeText,
      tabs,
      marketFilters,
      timeframes,
      formatMoney,
      formatPrice,
      formatCryptoAmount,
      formatDate,
      selectCrypto,
      getHoldings,
      setTradePercentage,
      handleTrade,
      createAlert,
      deleteAlert
    }
  }
}
</script>

<style scoped>
.cryptox-app {
  flex: 1;
  overflow-y: auto;
  background: #000;
  color: #fff;
}

.portfolio-overview {
  padding: 20px;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
}

.portfolio-card {
  text-align: center;
  margin-bottom: 20px;
}

.portfolio-label {
  font-size: 14px;
  color: #888;
  margin-bottom: 5px;
}

.portfolio-value {
  font-size: 32px;
  font-weight: bold;
  margin-bottom: 5px;
}

.portfolio-change {
  font-size: 12px;
}

.portfolio-change.positive {
  color: #4caf50;
}

.portfolio-change.negative {
  color: #f44336;
}

.portfolio-stats {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
}

.stat-item {
  text-align: center;
  padding: 15px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 10px;
}

.stat-label {
  font-size: 12px;
  color: #888;
  margin-bottom: 5px;
}

.stat-value {
  font-size: 18px;
  font-weight: bold;
}

.stat-value.positive {
  color: #4caf50;
}

.stat-value.negative {
  color: #f44336;
}

.nav-tabs {
  display: flex;
  background: #1a1a1a;
  overflow-x: auto;
}

.nav-tab {
  flex: 1;
  padding: 15px 10px;
  background: none;
  border: none;
  color: #888;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
}

.nav-tab.active {
  color: #007aff;
  background: rgba(0, 122, 255, 0.1);
}

.nav-tab i {
  font-size: 16px;
}

.tab-content {
  flex: 1;
  padding: 20px;
}

.market-filters {
  margin-bottom: 20px;
}

.filter-buttons {
  display: flex;
  gap: 10px;
  margin-bottom: 15px;
  overflow-x: auto;
}

.filter-button {
  padding: 8px 16px;
  background: #1a1a1a;
  border: 1px solid #333;
  border-radius: 20px;
  color: #888;
  cursor: pointer;
  white-space: nowrap;
  transition: all 0.3s ease;
}

.filter-button.active {
  background: #007aff;
  color: #fff;
  border-color: #007aff;
}

.search-container {
  position: relative;
}

.search-input {
  width: 100%;
  padding: 12px;
  background: #1a1a1a;
  border: 1px solid #333;
  border-radius: 10px;
  color: #fff;
  font-size: 16px;
}

.crypto-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.crypto-item {
  display: flex;
  align-items: center;
  padding: 15px;
  background: #1a1a1a;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.crypto-item:hover {
  background: #2a2a2a;
}

.crypto-info {
  display: flex;
  align-items: center;
  flex: 1;
}

.crypto-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #333;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 15px;
  font-size: 18px;
}

.crypto-icon.large {
  width: 50px;
  height: 50px;
  font-size: 24px;
}

.crypto-details {
  flex: 1;
}

.crypto-name {
  font-weight: 500;
  margin-bottom: 5px;
}

.crypto-symbol {
  font-size: 12px;
  color: #888;
}

.crypto-price-info {
  text-align: right;
  margin-right: 15px;
}

.crypto-price {
  font-weight: bold;
  margin-bottom: 5px;
}

.crypto-change {
  font-size: 12px;
}

.crypto-change.positive {
  color: #4caf50;
}

.crypto-change.negative {
  color: #f44336;
}

.crypto-chart-mini {
  width: 60px;
  height: 30px;
}

.mini-chart {
  width: 100%;
  height: 100%;
}

.portfolio-summary {
  margin-bottom: 30px;
}

.summary-cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 15px;
}

.summary-card {
  padding: 15px;
  background: #1a1a1a;
  border-radius: 10px;
  text-align: center;
}

.card-label {
  font-size: 12px;
  color: #888;
  margin-bottom: 5px;
}

.card-value {
  font-size: 18px;
  font-weight: bold;
  margin-bottom: 5px;
}

.card-change {
  font-size: 12px;
}

.card-change.positive {
  color: #4caf50;
}

.card-change.negative {
  color: #f44336;
}

.holdings-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.holding-item {
  display: flex;
  align-items: center;
  padding: 15px;
  background: #1a1a1a;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.holding-item:hover {
  background: #2a2a2a;
}

.holding-info {
  display: flex;
  align-items: center;
  flex: 1;
}

.holding-details {
  flex: 1;
}

.holding-name {
  font-weight: 500;
  margin-bottom: 5px;
}

.holding-amount {
  font-size: 12px;
  color: #888;
}

.holding-values {
  text-align: right;
  margin-right: 15px;
}

.holding-value {
  font-weight: bold;
  margin-bottom: 5px;
}

.holding-pnl {
  font-size: 12px;
}

.holding-pnl.positive {
  color: #4caf50;
}

.holding-pnl.negative {
  color: #f44336;
}

.holding-percentage {
  font-size: 12px;
  color: #888;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #888;
}

.empty-state i {
  font-size: 48px;
  margin-bottom: 20px;
  color: #333;
}

.empty-state h3 {
  margin-bottom: 10px;
  color: #fff;
}

.trade-interface {
  max-width: 400px;
  margin: 0 auto;
}

.crypto-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding: 20px;
  background: #1a1a1a;
  border-radius: 10px;
}

.crypto-info {
  display: flex;
  align-items: center;
}

.crypto-price {
  text-align: right;
}

.current-price {
  font-size: 24px;
  font-weight: bold;
  margin-bottom: 5px;
}

.price-change {
  font-size: 14px;
}

.price-change.positive {
  color: #4caf50;
}

.price-change.negative {
  color: #f44336;
}

.price-chart {
  margin-bottom: 30px;
  padding: 20px;
  background: #1a1a1a;
  border-radius: 10px;
}

.chart-controls {
  margin-bottom: 20px;
}

.timeframe-buttons {
  display: flex;
  gap: 5px;
}

.timeframe-button {
  padding: 8px 12px;
  background: #333;
  border: none;
  border-radius: 5px;
  color: #888;
  cursor: pointer;
  transition: all 0.3s ease;
}

.timeframe-button.active {
  background: #007aff;
  color: #fff;
}

.price-chart-canvas {
  width: 100%;
  height: 200px;
  border-radius: 5px;
}

.trade-form {
  background: #1a1a1a;
  padding: 20px;
  border-radius: 10px;
}

.trade-tabs {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  margin-bottom: 20px;
  background: #333;
  border-radius: 5px;
  overflow: hidden;
}

.trade-tab-button {
  padding: 12px;
  background: none;
  border: none;
  color: #888;
  cursor: pointer;
  transition: all 0.3s ease;
}

.trade-tab-button.active {
  background: #007aff;
  color: #fff;
}

.order-type {
  margin-bottom: 20px;
}

.order-select {
  width: 100%;
  padding: 12px;
  background: #333;
  border: 1px solid #555;
  border-radius: 5px;
  color: #fff;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  color: #888;
  font-size: 14px;
}

.form-input {
  width: 100%;
  padding: 12px;
  background: #333;
  border: 1px solid #555;
  border-radius: 5px;
  color: #fff;
  font-size: 16px;
}

.amount-buttons {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 5px;
  margin-top: 10px;
}

.percentage-button {
  padding: 8px;
  background: #333;
  border: none;
  border-radius: 3px;
  color: #888;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.3s ease;
}

.percentage-button:hover {
  background: #555;
  color: #fff;
}

.trade-summary {
  margin-bottom: 20px;
  padding: 15px;
  background: #333;
  border-radius: 5px;
}

.summary-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 14px;
}

.summary-row.total {
  border-top: 1px solid #555;
  padding-top: 8px;
  font-weight: bold;
}

.trade-button {
  width: 100%;
  padding: 15px;
  border: none;
  border-radius: 10px;
  color: #fff;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
}

.trade-button.buy {
  background: #4caf50;
}

.trade-button.sell {
  background: #f44336;
}

.trade-button:disabled {
  background: #333;
  cursor: not-allowed;
}

.error-message {
  margin-top: 10px;
  padding: 10px;
  background: rgba(244, 67, 54, 0.2);
  border: 1px solid #f44336;
  border-radius: 5px;
  color: #f44336;
  font-size: 14px;
}

.success-message {
  margin-top: 10px;
  padding: 10px;
  background: rgba(76, 175, 80, 0.2);
  border: 1px solid #4caf50;
  border-radius: 5px;
  color: #4caf50;
  font-size: 14px;
}

.history-filters {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

.filter-select {
  padding: 10px;
  background: #1a1a1a;
  border: 1px solid #333;
  border-radius: 5px;
  color: #fff;
}

.transaction-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.transaction-item {
  display: flex;
  align-items: center;
  padding: 15px;
  background: #1a1a1a;
  border-radius: 10px;
}

.transaction-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 15px;
}

.transaction-icon.buy {
  background: rgba(76, 175, 80, 0.2);
  color: #4caf50;
}

.transaction-icon.sell {
  background: rgba(244, 67, 54, 0.2);
  color: #f44336;
}

.transaction-details {
  flex: 1;
}

.transaction-crypto {
  font-weight: 500;
  margin-bottom: 5px;
}

.transaction-amount {
  font-size: 12px;
  color: #888;
  margin-bottom: 2px;
}

.transaction-date {
  font-size: 12px;
  color: #666;
}

.transaction-value {
  text-align: right;
}

.transaction-price {
  font-weight: bold;
  margin-bottom: 5px;
}

.transaction-total {
  font-size: 12px;
  color: #888;
}

.alerts-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.alerts-header h3 {
  margin: 0;
}

.add-button {
  padding: 10px 15px;
  background: #007aff;
  border: none;
  border-radius: 5px;
  color: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 5px;
}

.alerts-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.alert-item {
  display: flex;
  align-items: center;
  padding: 15px;
  background: #1a1a1a;
  border-radius: 10px;
}

.alert-item.triggered {
  border-left: 4px solid #4caf50;
}

.alert-info {
  flex: 1;
}

.alert-crypto {
  font-weight: 500;
  margin-bottom: 5px;
}

.alert-condition {
  font-size: 12px;
  color: #888;
  margin-bottom: 2px;
}

.alert-status {
  font-size: 12px;
  color: #666;
}

.alert-actions {
  display: flex;
  gap: 5px;
}

.action-button {
  width: 32px;
  height: 32px;
  border: none;
  border-radius: 5px;
  background: #333;
  color: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.action-button.delete {
  background: #f44336;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: #1a1a1a;
  border-radius: 10px;
  max-width: 400px;
  width: 90%;
  max-height: 80vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #333;
}

.modal-header h3 {
  margin: 0;
}

.close-button {
  background: none;
  border: none;
  color: #888;
  font-size: 24px;
  cursor: pointer;
}

.modal-content {
  padding: 20px;
}

.form-select {
  width: 100%;
  padding: 12px;
  background: #333;
  border: 1px solid #555;
  border-radius: 5px;
  color: #fff;
}

.create-button {
  width: 100%;
  padding: 15px;
  background: #007aff;
  border: none;
  border-radius: 10px;
  color: #fff;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
}
</style>