// Marketplace Store Module
import { nuiCallback } from '../../utils/nui'

export default {
  namespaced: true,
  
  state: {
    listings: [],
    myListings: [],
    isLoading: false,
    isLoadingMyListings: false,
    currentListing: null,
    searchQuery: '',
    selectedCategory: '',
    pagination: {
      page: 1,
      limit: 20,
      total: 0,
      hasMore: true
    },
    stats: {
      totalListings: 0,
      activeListings: 0,
      soldListings: 0,
      avgSoldPrice: 0,
      categoryBreakdown: []
    }
  },
  
  mutations: {
    // Listings mutations
    setListings(state, listings) {
      state.listings = listings || []
    },
    
    addListings(state, listings) {
      if (listings && listings.length > 0) {
        state.listings.push(...listings)
      }
    },
    
    clearListings(state) {
      state.listings = []
      state.pagination.page = 1
      state.pagination.hasMore = true
    },
    
    setMyListings(state, listings) {
      state.myListings = listings || []
    },
    
    addListing(state, listing) {
      state.listings.unshift(listing)
      state.myListings.unshift(listing)
    },
    
    updateListing(state, updatedListing) {
      // Update in listings array
      const listingIndex = state.listings.findIndex(l => l.id === updatedListing.id)
      if (listingIndex !== -1) {
        state.listings.splice(listingIndex, 1, updatedListing)
      }
      
      // Update in myListings array
      const myListingIndex = state.myListings.findIndex(l => l.id === updatedListing.id)
      if (myListingIndex !== -1) {
        state.myListings.splice(myListingIndex, 1, updatedListing)
      }
    },
    
    removeListing(state, listingId) {
      // Remove from listings array
      state.listings = state.listings.filter(l => l.id !== listingId)
      
      // Remove from myListings array
      state.myListings = state.myListings.filter(l => l.id !== listingId)
    },
    
    setCurrentListing(state, listing) {
      state.currentListing = listing
    },
    
    // Loading states
    setLoading(state, isLoading) {
      state.isLoading = isLoading
    },
    
    setLoadingMyListings(state, isLoading) {
      state.isLoadingMyListings = isLoading
    },
    
    // Search and filters
    setSearchQuery(state, query) {
      state.searchQuery = query
    },
    
    setSelectedCategory(state, category) {
      state.selectedCategory = category
    },
    
    // Pagination
    setPagination(state, pagination) {
      state.pagination = { ...state.pagination, ...pagination }
    },
    
    incrementPage(state) {
      state.pagination.page += 1
    },
    
    resetPagination(state) {
      state.pagination = {
        page: 1,
        limit: 20,
        total: 0,
        hasMore: true
      }
    },
    
    // Statistics
    setStats(state, stats) {
      state.stats = { ...state.stats, ...stats }
    }
  },
  
  actions: {
    // Fetch marketplace listings with optional filters
    async fetchListings({ commit, state }, { reset = false, category = null, search = null } = {}) {
      if (reset) {
        commit('clearListings')
        commit('resetPagination')
      }
      
      if (!state.pagination.hasMore && !reset) {
        return
      }
      
      commit('setLoading', true)
      
      try {
        const response = await nuiCallback('getMarketplaceListings', {
          category: category !== null ? category : state.selectedCategory,
          search: search !== null ? search : state.searchQuery,
          limit: state.pagination.limit,
          offset: (state.pagination.page - 1) * state.pagination.limit
        })
        
        if (response.success) {
          const listings = response.listings || []
          
          if (reset || state.pagination.page === 1) {
            commit('setListings', listings)
          } else {
            commit('addListings', listings)
          }
          
          // Update pagination
          commit('setPagination', {
            total: response.total || listings.length,
            hasMore: listings.length === state.pagination.limit
          })
          
          if (listings.length === state.pagination.limit) {
            commit('incrementPage')
          }
        } else {
          throw new Error(response.message || 'Failed to fetch listings')
        }
      } catch (error) {
        console.error('Error fetching marketplace listings:', error)
        throw error
      } finally {
        commit('setLoading', false)
      }
    },
    
    // Fetch user's own listings
    async fetchMyListings({ commit }) {
      commit('setLoadingMyListings', true)
      
      try {
        const response = await nuiCallback('getMyMarketplaceListings')
        
        if (response.success) {
          commit('setMyListings', response.listings || [])
        } else {
          throw new Error(response.message || 'Failed to fetch your listings')
        }
      } catch (error) {
        console.error('Error fetching my listings:', error)
        throw error
      } finally {
        commit('setLoadingMyListings', false)
      }
    },
    
    // Create new listing
    async createListing({ commit, dispatch }, listingData) {
      try {
        const response = await nuiCallback('createMarketplaceListing', listingData)
        
        if (response.success) {
          // Refresh listings to show the new one
          await dispatch('fetchMyListings')
          return response
        } else {
          throw new Error(response.message || 'Failed to create listing')
        }
      } catch (error) {
        console.error('Error creating listing:', error)
        throw error
      }
    },
    
    // Update existing listing
    async updateListing({ commit, dispatch }, listingData) {
      try {
        const response = await nuiCallback('updateMarketplaceListing', listingData)
        
        if (response.success) {
          // Refresh listings to show the updated one
          await dispatch('fetchMyListings')
          return response
        } else {
          throw new Error(response.message || 'Failed to update listing')
        }
      } catch (error) {
        console.error('Error updating listing:', error)
        throw error
      }
    },
    
    // Delete listing
    async deleteListing({ commit, dispatch }, listingId) {
      try {
        const response = await nuiCallback('deleteMarketplaceListing', listingId)
        
        if (response.success) {
          // Remove from local state
          commit('removeListing', listingId)
          return response
        } else {
          throw new Error(response.message || 'Failed to delete listing')
        }
      } catch (error) {
        console.error('Error deleting listing:', error)
        throw error
      }
    },
    
    // Mark listing as sold
    async markListingSold({ commit, dispatch }, listingId) {
      try {
        const response = await nuiCallback('markListingSold', listingId)
        
        if (response.success) {
          // Refresh listings to show the updated status
          await dispatch('fetchMyListings')
          return response
        } else {
          throw new Error(response.message || 'Failed to mark listing as sold')
        }
      } catch (error) {
        console.error('Error marking listing as sold:', error)
        throw error
      }
    },
    
    // Search listings
    async searchListings({ commit, dispatch }, searchQuery) {
      commit('setSearchQuery', searchQuery)
      await dispatch('fetchListings', { reset: true, search: searchQuery })
    },
    
    // Filter by category
    async filterByCategory({ commit, dispatch }, category) {
      commit('setSelectedCategory', category)
      await dispatch('fetchListings', { reset: true, category: category })
    },
    
    // Load more listings (pagination)
    async loadMoreListings({ dispatch, state }) {
      if (state.pagination.hasMore && !state.isLoading) {
        await dispatch('fetchListings')
      }
    },
    
    // Refresh all listings
    async refreshListings({ dispatch }) {
      await dispatch('fetchListings', { reset: true })
    },
    
    // Get marketplace statistics
    async fetchStats({ commit }) {
      try {
        const response = await nuiCallback('getMarketplaceStats')
        
        if (response.success) {
          commit('setStats', response.stats || {})
        } else {
          throw new Error(response.message || 'Failed to fetch statistics')
        }
      } catch (error) {
        console.error('Error fetching marketplace stats:', error)
        throw error
      }
    },
    
    // Clear search and filters
    async clearFilters({ commit, dispatch }) {
      commit('setSearchQuery', '')
      commit('setSelectedCategory', '')
      await dispatch('fetchListings', { reset: true })
    },
    
    // Set current listing for viewing
    setCurrentListing({ commit }, listing) {
      commit('setCurrentListing', listing)
    },
    
    // Clear current listing
    clearCurrentListing({ commit }) {
      commit('setCurrentListing', null)
    }
  },
  
  getters: {
    // Get listings by category
    listingsByCategory: (state) => (category) => {
      if (!category) return state.listings
      return state.listings.filter(listing => listing.category === category)
    },
    
    // Get active listings only
    activeListings: (state) => {
      return state.listings.filter(listing => listing.status === 'active')
    },
    
    // Get my active listings
    myActiveListings: (state) => {
      return state.myListings.filter(listing => listing.status === 'active')
    },
    
    // Get my sold listings
    mySoldListings: (state) => {
      return state.myListings.filter(listing => listing.status === 'sold')
    },
    
    // Search results
    searchResults: (state) => {
      if (!state.searchQuery) return state.listings
      
      const query = state.searchQuery.toLowerCase()
      return state.listings.filter(listing => 
        listing.title.toLowerCase().includes(query) ||
        listing.description.toLowerCase().includes(query)
      )
    },
    
    // Get listing by ID
    getListingById: (state) => (id) => {
      return state.listings.find(listing => listing.id === id) ||
             state.myListings.find(listing => listing.id === id)
    },
    
    // Check if has more listings to load
    hasMoreListings: (state) => {
      return state.pagination.hasMore
    },
    
    // Get current page
    currentPage: (state) => {
      return state.pagination.page
    },
    
    // Get total listings count
    totalListings: (state) => {
      return state.pagination.total
    },
    
    // Get categories with counts
    categoriesWithCounts: (state) => {
      const categories = {}
      state.listings.forEach(listing => {
        if (listing.category) {
          categories[listing.category] = (categories[listing.category] || 0) + 1
        }
      })
      return categories
    },
    
    // Check if currently loading
    isLoading: (state) => {
      return state.isLoading
    },
    
    // Check if loading my listings
    isLoadingMyListings: (state) => {
      return state.isLoadingMyListings
    }
  }
}