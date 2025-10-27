// Apps Store Module
import { nuiCallback } from '../../utils/nui'

export default {
  namespaced: true,
  
  state: {
    bank: {
      balance: 0,
      transactions: []
    },
    chirper: {
      feed: [],
      myChirps: []
    },
    crypto: {
      portfolio: [],
      prices: {}
    },
    appstore: {
      availableApps: [],
      installedApps: [],
      isLoading: false
    }
  },
  
  mutations: {
    // Bank mutations
    setBalance(state, balance) {
      state.bank.balance = balance
    },
    
    setTransactions(state, transactions) {
      state.bank.transactions = transactions || []
    },
    
    addTransaction(state, transaction) {
      state.bank.transactions.unshift(transaction)
      
      // Keep only the last 50 transactions
      if (state.bank.transactions.length > 50) {
        state.bank.transactions = state.bank.transactions.slice(0, 50)
      }
    },
    
    updateBalance(state, amount) {
      state.bank.balance = amount
    },
    
    // Chirper mutations
    setChirperFeed(state, feed) {
      state.chirper.feed = feed || []
    },
    
    setMyChirps(state, chirps) {
      state.chirper.myChirps = chirps || []
    },
    
    addChirpToFeed(state, chirp) {
      state.chirper.feed.unshift(chirp)
      
      // Keep only the last 100 chirps
      if (state.chirper.feed.length > 100) {
        state.chirper.feed = state.chirper.feed.slice(0, 100)
      }
    },
    
    addMyChirp(state, chirp) {
      state.chirper.myChirps.unshift(chirp)
    },
    
    updateChirpLikes(state, { chirpId, likes, isLiked }) {
      // Update in feed
      const feedChirp = state.chirper.feed.find(c => c.id === chirpId)
      if (feedChirp) {
        feedChirp.likes = likes
        feedChirp.isLiked = isLiked
      }
      
      // Update in myChirps
      const myChirp = state.chirper.myChirps.find(c => c.id === chirpId)
      if (myChirp) {
        myChirp.likes = likes
        myChirp.isLiked = isLiked
      }
    },
    
    // Crypto mutations
    setCryptoPortfolio(state, portfolio) {
      state.crypto.portfolio = portfolio || []
    },
    
    setCryptoPrices(state, prices) {
      state.crypto.prices = prices || {}
    },
    
    updateCryptoPrices(state, prices) {
      // Store previous prices for change calculation
      Object.keys(prices).forEach(symbol => {
        if (state.crypto.prices[symbol]) {
          prices[symbol].previousPrice = state.crypto.prices[symbol].currentPrice
        }
      })
      state.crypto.prices = prices
    },
    
    updateCryptoHolding(state, { cryptoType, amount }) {
      const holding = state.crypto.portfolio.find(h => h.crypto_type === cryptoType)
      if (holding) {
        holding.amount = amount
      } else if (amount > 0) {
        state.crypto.portfolio.push({
          crypto_type: cryptoType,
          amount: amount
        })
      }
    },
    
    // AppStore mutations
    setAvailableApps(state, apps) {
      state.appstore.availableApps = apps || []
    },
    
    setInstalledApps(state, apps) {
      state.appstore.installedApps = apps || []
    },
    
    setAppStoreLoading(state, isLoading) {
      state.appstore.isLoading = isLoading
    },
    
    installApp(state, appId) {
      if (!state.appstore.installedApps.includes(appId)) {
        state.appstore.installedApps.push(appId)
      }
    },
    
    uninstallApp(state, appId) {
      const index = state.appstore.installedApps.indexOf(appId)
      if (index > -1) {
        state.appstore.installedApps.splice(index, 1)
      }
    }
  },
  
  actions: {
    // Fetch bank balance and transaction history
    async fetchBankData({ commit }) {
      try {
        const response = await nuiCallback('getBankData', {})
        if (response.success) {
          commit('setBalance', response.balance || 0)
          commit('setTransactions', response.transactions || [])
        }
        return response
      } catch (error) {
        console.error('Error fetching bank data:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    // Transfer money to another player
    async transferMoney({ commit }, { targetNumber, amount }) {
      try {
        const response = await nuiCallback('transferMoney', {
          targetNumber,
          amount
        })
        
        if (response.success) {
          // Update balance
          commit('updateBalance', response.newBalance)
          
          // Add transaction to history
          commit('addTransaction', {
            id: Date.now(),
            type: 'sent',
            phoneNumber: targetNumber,
            amount: amount,
            timestamp: Date.now()
          })
        }
        
        return response
      } catch (error) {
        console.error('Error transferring money:', error)
        return { success: false, error: 'TRANSFER_FAILED' }
      }
    },
    
    // Fetch chirper feed and user's chirps
    async fetchChirperFeed({ commit }) {
      try {
        const response = await nuiCallback('getChirperFeed', {})
        if (response.success) {
          commit('setChirperFeed', response.feed || [])
          commit('setMyChirps', response.myChirps || [])
        }
        return response
      } catch (error) {
        console.error('Error fetching chirper feed:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    // Post a new chirp
    async postChirp({ commit }, { content }) {
      try {
        const response = await nuiCallback('postChirp', { content })
        
        if (response.success && response.chirp) {
          // Add to both feed and myChirps
          commit('addChirpToFeed', response.chirp)
          commit('addMyChirp', response.chirp)
        }
        
        return response
      } catch (error) {
        console.error('Error posting chirp:', error)
        return { success: false, error: 'POST_FAILED' }
      }
    },
    
    // Like a chirp
    async likeChirp({ commit }, { chirpId }) {
      try {
        const response = await nuiCallback('likeChirp', { chirpId })
        
        if (response.success) {
          commit('updateChirpLikes', {
            chirpId,
            likes: response.likes,
            isLiked: response.isLiked
          })
        }
        
        return response
      } catch (error) {
        console.error('Error liking chirp:', error)
        return { success: false, error: 'LIKE_FAILED' }
      }
    },
    
    // Fetch crypto portfolio and prices
    async fetchCryptoData({ commit }) {
      try {
        const response = await nuiCallback('getCryptoData', {})
        if (response.success) {
          commit('setCryptoPortfolio', response.portfolio || [])
          commit('setCryptoPrices', response.prices || {})
        }
        return response
      } catch (error) {
        console.error('Error fetching crypto data:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    // Buy or sell cryptocurrency
    async tradeCrypto({ commit }, { cryptoType, amount, action }) {
      try {
        const response = await nuiCallback('tradeCrypto', {
          cryptoType,
          amount,
          action
        })
        
        if (response.success) {
          // Update portfolio holding
          commit('updateCryptoHolding', {
            cryptoType,
            amount: response.newAmount
          })
          
          // Update balance
          commit('updateBalance', response.newBalance)
        }
        
        return response
      } catch (error) {
        console.error('Error trading crypto:', error)
        return { success: false, error: 'TRADE_FAILED' }
      }
    },
    
    // Fetch available apps and installed apps
    async fetchAppStoreData({ commit }) {
      commit('setAppStoreLoading', true)
      try {
        const response = await nuiCallback('getAvailableApps', {})
        if (response.success) {
          commit('setAvailableApps', response.apps || [])
          commit('setInstalledApps', response.installedApps || [])
        }
        return response
      } catch (error) {
        console.error('Error fetching app store data:', error)
        return { success: false, error: 'FETCH_FAILED' }
      } finally {
        commit('setAppStoreLoading', false)
      }
    },
    
    // Install an app
    async installApp({ commit }, { appId }) {
      try {
        const response = await nuiCallback('installApp', { appId })
        
        if (response.success) {
          commit('installApp', appId)
        }
        
        return response
      } catch (error) {
        console.error('Error installing app:', error)
        return { success: false, error: 'INSTALL_FAILED' }
      }
    },
    
    // Uninstall an app
    async uninstallApp({ commit }, { appId }) {
      try {
        const response = await nuiCallback('uninstallApp', { appId })
        
        if (response.success) {
          commit('uninstallApp', appId)
        }
        
        return response
      } catch (error) {
        console.error('Error uninstalling app:', error)
        return { success: false, error: 'UNINSTALL_FAILED' }
      }
    }
  }
}
