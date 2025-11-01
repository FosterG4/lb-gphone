// Unified Wallet Store Module
import { nuiCallback } from '../../utils/nui'

export default {
  namespaced: true,
  
  state: {
    // Account data
    accounts: [
      {
        id: 'checking',
        name: 'Checking Account',
        type: 'checking',
        balance: 0,
        isActive: true,
        cardNumber: '•••• •••• •••• 7890',
        cardHolder: 'LB PHONE',
        expiry: '12/25',
        cvv: '123'
      }
    ],
    selectedAccount: null,
    totalBalance: 0,
    
    // Transaction data
    transactions: [],
    transactionFilters: {
      type: 'all', // all, credit, debit
      category: 'all',
      dateRange: 'all', // all, week, month, quarter, year
      searchQuery: ''
    },
    
    // Analytics data
    analytics: {
      spending: {
        thisWeek: 0,
        thisMonth: 0,
        thisQuarter: 0,
        thisYear: 0
      },
      categories: [],
      trends: {}
    },
    budgets: [],
    
    // Recurring payments
    recurringPayments: [],
    
    // UI state
    activeTab: 'dashboard',
    isLoading: false,
    isTransferring: false,
    
    // Settings
    userSettings: {
      theme: {
        mode: 'auto', // light, dark, auto
        accentColor: '#007AFF'
      },
      notifications: {
        transfers: true,
        budgets: true,
        security: true,
        marketing: false
      },
      security: {
        pinEnabled: false,
        biometricEnabled: false,
        sessionTimeout: 15 // minutes
      }
    },
    
    // Customization
    customization: {
      wallpaper: 'default',
      ringtone: 'default',
      hapticFeedback: true,
      animations: true
    },
    
    // Cards
    cards: [
      {
        id: 'main-card',
        type: 'debit',
        number: '•••• •••• •••• 7890',
        holder: 'LB PHONE',
        expiry: '12/25',
        cvv: '123',
        isActive: true,
        dailyLimit: 5000,
        monthlyLimit: 50000,
        spentToday: 0,
        spentThisMonth: 0
      }
    ]
  },
  
  getters: {
    // Account getters
    primaryAccount: (state) => {
      return state.selectedAccount || state.accounts[0] || null
    },
    
    accountById: (state) => (id) => {
      return state.accounts.find(account => account.id === id)
    },
    
    // Transaction getters
    filteredTransactions: (state) => {
      let filtered = [...state.transactions]
      
      // Filter by type
      if (state.transactionFilters.type !== 'all') {
        filtered = filtered.filter(t => t.type === state.transactionFilters.type)
      }
      
      // Filter by category
      if (state.transactionFilters.category !== 'all') {
        filtered = filtered.filter(t => t.category === state.transactionFilters.category)
      }
      
      // Filter by search query
      if (state.transactionFilters.searchQuery) {
        const query = state.transactionFilters.searchQuery.toLowerCase()
        filtered = filtered.filter(t => 
          t.description.toLowerCase().includes(query) ||
          (t.targetNumber && t.targetNumber.includes(query))
        )
      }
      
      // Filter by date range
      if (state.transactionFilters.dateRange !== 'all') {
        const now = new Date()
        let startDate = new Date()
        
        switch (state.transactionFilters.dateRange) {
          case 'week':
            startDate.setDate(now.getDate() - 7)
            break
          case 'month':
            startDate.setMonth(now.getMonth() - 1)
            break
          case 'quarter':
            startDate.setMonth(now.getMonth() - 3)
            break
          case 'year':
            startDate.setFullYear(now.getFullYear() - 1)
            break
        }
        
        filtered = filtered.filter(t => new Date(t.timestamp) >= startDate)
      }
      
      return filtered.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
    },
    
    recentTransactions: (state, getters) => {
      return getters.filteredTransactions.slice(0, 5)
    },
    
    // Analytics getters
    spendingByCategory: (state) => {
      const categories = {}
      state.transactions
        .filter(t => t.type === 'debit' || t.type === 'transfer_out')
        .forEach(transaction => {
          const category = transaction.category || 'general'
          categories[category] = (categories[category] || 0) + Math.abs(transaction.amount)
        })
      
      return Object.entries(categories).map(([name, amount]) => ({
        name,
        amount,
        percentage: (amount / state.totalBalance) * 100
      }))
    },
    
    monthlySpending: (state) => {
      const now = new Date()
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1)
      
      return state.transactions
        .filter(t => 
          (t.type === 'debit' || t.type === 'transfer_out') &&
          new Date(t.timestamp) >= startOfMonth
        )
        .reduce((total, t) => total + Math.abs(t.amount), 0)
    },
    
    // Budget getters
    activeBudgets: (state) => {
      return state.budgets.filter(budget => budget.isActive)
    },
    
    budgetProgress: (state, getters) => {
      return state.budgets.map(budget => {
        const spent = state.transactions
          .filter(t => 
            t.category === budget.category &&
            (t.type === 'debit' || t.type === 'transfer_out') &&
            new Date(t.timestamp) >= new Date(budget.periodStart) &&
            new Date(t.timestamp) <= new Date(budget.periodEnd)
          )
          .reduce((total, t) => total + Math.abs(t.amount), 0)
        
        return {
          ...budget,
          spent,
          remaining: Math.max(0, budget.limitAmount - spent),
          percentage: Math.min(100, (spent / budget.limitAmount) * 100),
          isOverBudget: spent > budget.limitAmount
        }
      })
    }
  },
  
  mutations: {
    // Account mutations
    SET_ACCOUNTS(state, accounts) {
      state.accounts = accounts || []
      if (accounts && accounts.length > 0) {
        state.totalBalance = accounts.reduce((sum, acc) => sum + acc.balance, 0)
      }
    },
    
    SET_SELECTED_ACCOUNT(state, account) {
      state.selectedAccount = account
    },
    
    UPDATE_ACCOUNT_BALANCE(state, { accountId, newBalance }) {
      const account = state.accounts.find(acc => acc.id === accountId)
      if (account) {
        const oldBalance = account.balance
        account.balance = newBalance
        state.totalBalance = state.totalBalance - oldBalance + newBalance
      }
    },
    
    // Transaction mutations
    SET_TRANSACTIONS(state, transactions) {
      state.transactions = transactions || []
    },
    
    ADD_TRANSACTION(state, transaction) {
      state.transactions.unshift({
        id: transaction.id || Date.now(),
        ...transaction,
        timestamp: transaction.timestamp || Date.now()
      })
      
      // Keep only the last 200 transactions
      if (state.transactions.length > 200) {
        state.transactions = state.transactions.slice(0, 200)
      }
    },
    
    SET_TRANSACTION_FILTERS(state, filters) {
      state.transactionFilters = { ...state.transactionFilters, ...filters }
    },
    
    // Analytics mutations
    SET_ANALYTICS(state, analytics) {
      state.analytics = { ...state.analytics, ...analytics }
    },
    
    SET_BUDGETS(state, budgets) {
      state.budgets = budgets || []
    },
    
    ADD_BUDGET(state, budget) {
      state.budgets.push({
        id: budget.id || Date.now(),
        ...budget,
        isActive: true,
        createdAt: Date.now()
      })
    },
    
    UPDATE_BUDGET(state, { budgetId, updates }) {
      const budget = state.budgets.find(b => b.id === budgetId)
      if (budget) {
        Object.assign(budget, updates)
      }
    },
    
    REMOVE_BUDGET(state, budgetId) {
      const index = state.budgets.findIndex(b => b.id === budgetId)
      if (index > -1) {
        state.budgets.splice(index, 1)
      }
    },
    
    // Recurring payments mutations
    SET_RECURRING_PAYMENTS(state, payments) {
      state.recurringPayments = payments || []
    },
    
    ADD_RECURRING_PAYMENT(state, payment) {
      state.recurringPayments.push({
        id: payment.id || Date.now(),
        ...payment,
        isActive: true,
        createdAt: Date.now()
      })
    },
    
    REMOVE_RECURRING_PAYMENT(state, paymentId) {
      const index = state.recurringPayments.findIndex(p => p.id === paymentId)
      if (index > -1) {
        state.recurringPayments.splice(index, 1)
      }
    },
    
    // UI mutations
    SET_ACTIVE_TAB(state, tab) {
      state.activeTab = tab
    },
    
    SET_LOADING(state, isLoading) {
      state.isLoading = isLoading
    },
    
    SET_TRANSFERRING(state, isTransferring) {
      state.isTransferring = isTransferring
    },
    
    // Settings mutations
    UPDATE_USER_SETTINGS(state, settings) {
      state.userSettings = { ...state.userSettings, ...settings }
    },
    
    UPDATE_THEME_SETTINGS(state, themeSettings) {
      state.userSettings.theme = { ...state.userSettings.theme, ...themeSettings }
    },
    
    UPDATE_NOTIFICATION_SETTINGS(state, notificationSettings) {
      state.userSettings.notifications = { ...state.userSettings.notifications, ...notificationSettings }
    },
    
    UPDATE_SECURITY_SETTINGS(state, securitySettings) {
      state.userSettings.security = { ...state.userSettings.security, ...securitySettings }
    },
    
    // Customization mutations
    UPDATE_CUSTOMIZATION(state, customization) {
      state.customization = { ...state.customization, ...customization }
    },
    
    SET_WALLPAPER(state, wallpaper) {
      state.customization.wallpaper = wallpaper
    },
    
    SET_RINGTONE(state, ringtone) {
      state.customization.ringtone = ringtone
    },
    
    // Cards mutations
    SET_CARDS(state, cards) {
      state.cards = cards || []
    },
    
    ADD_CARD(state, card) {
      state.cards.push({
        id: card.id || Date.now(),
        ...card,
        isActive: true,
        createdAt: Date.now()
      })
    },
    
    UPDATE_CARD(state, { cardId, updates }) {
      const card = state.cards.find(c => c.id === cardId)
      if (card) {
        Object.assign(card, updates)
      }
    },
    
    REMOVE_CARD(state, cardId) {
      const index = state.cards.findIndex(c => c.id === cardId)
      if (index > -1) {
        state.cards.splice(index, 1)
      }
    }
  },
  
  actions: {
    // Initialize wallet data
    async initializeWallet({ commit, dispatch }) {
      commit('SET_LOADING', true)
      try {
        // Fetch all wallet data
        await Promise.all([
          dispatch('fetchAccounts'),
          dispatch('fetchTransactions'),
          dispatch('fetchAnalytics'),
          dispatch('fetchBudgets'),
          dispatch('fetchRecurringPayments'),
          dispatch('fetchUserSettings'),
          dispatch('fetchCards')
        ])
      } catch (error) {
        console.error('Error initializing wallet:', error)
      } finally {
        commit('SET_LOADING', false)
      }
    },
    
    // Account actions
    async fetchAccounts({ commit }) {
      try {
        const response = await nuiCallback('getWalletAccounts', {})
        if (response.success) {
          commit('SET_ACCOUNTS', response.accounts)
          if (response.accounts && response.accounts.length > 0) {
            commit('SET_SELECTED_ACCOUNT', response.accounts[0])
          }
        }
        return response
      } catch (error) {
        console.error('Error fetching accounts:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    async selectAccount({ commit }, account) {
      commit('SET_SELECTED_ACCOUNT', account)
    },
    
    // Transaction actions
    async fetchTransactions({ commit }, filters = {}) {
      try {
        const response = await nuiCallback('getWalletTransactions', filters)
        if (response.success) {
          commit('SET_TRANSACTIONS', response.transactions)
        }
        return response
      } catch (error) {
        console.error('Error fetching transactions:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    async createTransfer({ commit, getters }, transferData) {
      commit('SET_TRANSFERRING', true)
      try {
        const response = await nuiCallback('createWalletTransfer', {
          fromAccount: transferData.fromAccount || getters.primaryAccount?.id,
          toNumber: transferData.toNumber,
          amount: transferData.amount,
          description: transferData.description || '',
          category: transferData.category || 'transfer'
        })
        
        if (response.success) {
          // Update account balance
          commit('UPDATE_ACCOUNT_BALANCE', {
            accountId: transferData.fromAccount || getters.primaryAccount?.id,
            newBalance: response.newBalance
          })
          
          // Add transaction
          commit('ADD_TRANSACTION', {
            id: response.transactionId,
            accountId: transferData.fromAccount || getters.primaryAccount?.id,
            type: 'transfer_out',
            amount: -Math.abs(transferData.amount),
            description: transferData.description || `Transfer to ${transferData.toNumber}`,
            targetNumber: transferData.toNumber,
            category: transferData.category || 'transfer',
            timestamp: Date.now()
          })
        }
        
        return response
      } catch (error) {
        console.error('Error creating transfer:', error)
        return { success: false, error: 'TRANSFER_FAILED' }
      } finally {
        commit('SET_TRANSFERRING', false)
      }
    },
    
    async updateTransactionFilters({ commit }, filters) {
      commit('SET_TRANSACTION_FILTERS', filters)
    },
    
    // Analytics actions
    async fetchAnalytics({ commit }) {
      try {
        const response = await nuiCallback('getWalletAnalytics', {})
        if (response.success) {
          commit('SET_ANALYTICS', response.analytics)
        }
        return response
      } catch (error) {
        console.error('Error fetching analytics:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    // Budget actions
    async fetchBudgets({ commit }) {
      try {
        const response = await nuiCallback('getWalletBudgets', {})
        if (response.success) {
          commit('SET_BUDGETS', response.budgets)
        }
        return response
      } catch (error) {
        console.error('Error fetching budgets:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    async createBudget({ commit }, budgetData) {
      try {
        const response = await nuiCallback('createWalletBudget', budgetData)
        if (response.success) {
          commit('ADD_BUDGET', {
            ...budgetData,
            id: response.budgetId
          })
        }
        return response
      } catch (error) {
        console.error('Error creating budget:', error)
        return { success: false, error: 'BUDGET_FAILED' }
      }
    },
    
    async updateBudget({ commit }, { budgetId, updates }) {
      try {
        const response = await nuiCallback('updateWalletBudget', { budgetId, ...updates })
        if (response.success) {
          commit('UPDATE_BUDGET', { budgetId, updates })
        }
        return response
      } catch (error) {
        console.error('Error updating budget:', error)
        return { success: false, error: 'UPDATE_FAILED' }
      }
    },
    
    async deleteBudget({ commit }, budgetId) {
      try {
        const response = await nuiCallback('deleteWalletBudget', { budgetId })
        if (response.success) {
          commit('REMOVE_BUDGET', budgetId)
        }
        return response
      } catch (error) {
        console.error('Error deleting budget:', error)
        return { success: false, error: 'DELETE_FAILED' }
      }
    },
    
    // Recurring payments actions
    async fetchRecurringPayments({ commit }) {
      try {
        const response = await nuiCallback('getWalletRecurringPayments', {})
        if (response.success) {
          commit('SET_RECURRING_PAYMENTS', response.payments)
        }
        return response
      } catch (error) {
        console.error('Error fetching recurring payments:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    async createRecurringPayment({ commit }, paymentData) {
      try {
        const response = await nuiCallback('createWalletRecurringPayment', paymentData)
        if (response.success) {
          commit('ADD_RECURRING_PAYMENT', {
            ...paymentData,
            id: response.paymentId
          })
        }
        return response
      } catch (error) {
        console.error('Error creating recurring payment:', error)
        return { success: false, error: 'RECURRING_FAILED' }
      }
    },
    
    async deleteRecurringPayment({ commit }, paymentId) {
      try {
        const response = await nuiCallback('deleteWalletRecurringPayment', { paymentId })
        if (response.success) {
          commit('REMOVE_RECURRING_PAYMENT', paymentId)
        }
        return response
      } catch (error) {
        console.error('Error deleting recurring payment:', error)
        return { success: false, error: 'DELETE_FAILED' }
      }
    },
    
    // Settings actions
    async fetchUserSettings({ commit }) {
      try {
        const response = await nuiCallback('getWalletUserSettings', {})
        if (response.success) {
          commit('UPDATE_USER_SETTINGS', response.settings)
          commit('UPDATE_CUSTOMIZATION', response.customization)
        }
        return response
      } catch (error) {
        console.error('Error fetching user settings:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    async updateUserSettings({ commit }, settings) {
      try {
        const response = await nuiCallback('updateWalletUserSettings', settings)
        if (response.success) {
          commit('UPDATE_USER_SETTINGS', settings)
        }
        return response
      } catch (error) {
        console.error('Error updating user settings:', error)
        return { success: false, error: 'UPDATE_FAILED' }
      }
    },
    
    async updateTheme({ commit }, themeSettings) {
      try {
        const response = await nuiCallback('updateWalletTheme', themeSettings)
        if (response.success) {
          commit('UPDATE_THEME_SETTINGS', themeSettings)
        }
        return response
      } catch (error) {
        console.error('Error updating theme:', error)
        return { success: false, error: 'THEME_FAILED' }
      }
    },
    
    // Customization actions
    async updateCustomization({ commit }, customization) {
      try {
        const response = await nuiCallback('updateWalletCustomization', customization)
        if (response.success) {
          commit('UPDATE_CUSTOMIZATION', customization)
        }
        return response
      } catch (error) {
        console.error('Error updating customization:', error)
        return { success: false, error: 'CUSTOMIZATION_FAILED' }
      }
    },
    
    // Cards actions
    async fetchCards({ commit }) {
      try {
        const response = await nuiCallback('getWalletCards', {})
        if (response.success) {
          commit('SET_CARDS', response.cards)
        }
        return response
      } catch (error) {
        console.error('Error fetching cards:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    async addCard({ commit }, cardData) {
      try {
        const response = await nuiCallback('addWalletCard', cardData)
        if (response.success) {
          commit('ADD_CARD', {
            ...cardData,
            id: response.cardId
          })
        }
        return response
      } catch (error) {
        console.error('Error adding card:', error)
        return { success: false, error: 'ADD_CARD_FAILED' }
      }
    },
    
    async updateCard({ commit }, { cardId, updates }) {
      try {
        const response = await nuiCallback('updateWalletCard', { cardId, ...updates })
        if (response.success) {
          commit('UPDATE_CARD', { cardId, updates })
        }
        return response
      } catch (error) {
        console.error('Error updating card:', error)
        return { success: false, error: 'UPDATE_CARD_FAILED' }
      }
    },
    
    async removeCard({ commit }, cardId) {
      try {
        const response = await nuiCallback('removeWalletCard', { cardId })
        if (response.success) {
          commit('REMOVE_CARD', cardId)
        }
        return response
      } catch (error) {
        console.error('Error removing card:', error)
        return { success: false, error: 'REMOVE_CARD_FAILED' }
      }
    },
    
    // UI actions
    setActiveTab({ commit }, tab) {
      commit('SET_ACTIVE_TAB', tab)
    }
  }
}