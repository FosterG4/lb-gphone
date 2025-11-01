// Business Pages Store Module
import { nuiCallback } from '../../utils/nui'

export default {
  namespaced: true,
  
  state: {
    pages: [],
    myPages: [],
    followingPages: [],
    isLoading: false,
    isLoadingMyPages: false,
    isLoadingFollowing: false,
    currentPage: null,
    searchQuery: '',
    selectedCategory: '',
    pagination: {
      page: 1,
      limit: 20,
      total: 0,
      hasMore: true
    },
    stats: {
      totalPages: 0,
      totalFollowers: 0,
      totalViews: 0,
      categoryBreakdown: []
    }
  },
  
  mutations: {
    // Pages mutations
    setPages(state, pages) {
      state.pages = pages || []
    },
    
    addPages(state, pages) {
      if (pages && pages.length > 0) {
        state.pages.push(...pages)
      }
    },
    
    clearPages(state) {
      state.pages = []
      state.pagination.page = 1
      state.pagination.hasMore = true
    },
    
    setMyPages(state, pages) {
      state.myPages = pages || []
    },
    
    setFollowingPages(state, pages) {
      state.followingPages = pages || []
    },
    
    addPage(state, page) {
      state.pages.unshift(page)
      state.myPages.unshift(page)
    },
    
    updatePage(state, updatedPage) {
      // Update in pages array
      const pageIndex = state.pages.findIndex(p => p.id === updatedPage.id)
      if (pageIndex !== -1) {
        state.pages.splice(pageIndex, 1, updatedPage)
      }
      
      // Update in myPages array
      const myPageIndex = state.myPages.findIndex(p => p.id === updatedPage.id)
      if (myPageIndex !== -1) {
        state.myPages.splice(myPageIndex, 1, updatedPage)
      }
      
      // Update in followingPages array
      const followingIndex = state.followingPages.findIndex(p => p.id === updatedPage.id)
      if (followingIndex !== -1) {
        state.followingPages.splice(followingIndex, 1, updatedPage)
      }
    },
    
    removePage(state, pageId) {
      // Remove from pages array
      state.pages = state.pages.filter(p => p.id !== pageId)
      
      // Remove from myPages array
      state.myPages = state.myPages.filter(p => p.id !== pageId)
      
      // Remove from followingPages array
      state.followingPages = state.followingPages.filter(p => p.id !== pageId)
    },
    
    addToFollowing(state, page) {
      // Add to following if not already there
      const exists = state.followingPages.find(p => p.id === page.id)
      if (!exists) {
        state.followingPages.unshift(page)
      }
      
      // Update followers count in all arrays
      const updateFollowersCount = (pageArray) => {
        const pageIndex = pageArray.findIndex(p => p.id === page.id)
        if (pageIndex !== -1) {
          pageArray[pageIndex].followers_count = (pageArray[pageIndex].followers_count || 0) + 1
        }
      }
      
      updateFollowersCount(state.pages)
      updateFollowersCount(state.myPages)
    },
    
    removeFromFollowing(state, pageId) {
      // Remove from following
      state.followingPages = state.followingPages.filter(p => p.id !== pageId)
      
      // Update followers count in all arrays
      const updateFollowersCount = (pageArray) => {
        const pageIndex = pageArray.findIndex(p => p.id === pageId)
        if (pageIndex !== -1) {
          pageArray[pageIndex].followers_count = Math.max((pageArray[pageIndex].followers_count || 1) - 1, 0)
        }
      }
      
      updateFollowersCount(state.pages)
      updateFollowersCount(state.myPages)
    },
    
    incrementPageViews(state, pageId) {
      // Update views count in all arrays
      const updateViewsCount = (pageArray) => {
        const pageIndex = pageArray.findIndex(p => p.id === pageId)
        if (pageIndex !== -1) {
          pageArray[pageIndex].views_count = (pageArray[pageIndex].views_count || 0) + 1
        }
      }
      
      updateViewsCount(state.pages)
      updateViewsCount(state.myPages)
      updateViewsCount(state.followingPages)
    },
    
    setCurrentPage(state, page) {
      state.currentPage = page
    },
    
    // Loading states
    setLoading(state, isLoading) {
      state.isLoading = isLoading
    },
    
    setLoadingMyPages(state, isLoading) {
      state.isLoadingMyPages = isLoading
    },
    
    setLoadingFollowing(state, isLoading) {
      state.isLoadingFollowing = isLoading
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
    // Fetch all business pages with optional filters
    async fetchPages({ commit, state }, { reset = false, category = null, search = null } = {}) {
      if (reset) {
        commit('clearPages')
        commit('resetPagination')
      }
      
      commit('setLoading', true)
      
      try {
        const response = await nuiCallback('getBusinessPages', {
          category: category || state.selectedCategory,
          search: search || state.searchQuery,
          limit: state.pagination.limit,
          offset: (state.pagination.page - 1) * state.pagination.limit
        })
        
        if (response.success) {
          if (reset || state.pagination.page === 1) {
            commit('setPages', response.pages)
          } else {
            commit('addPages', response.pages)
          }
          
          // Update pagination
          commit('setPagination', {
            total: response.total || response.pages.length,
            hasMore: response.pages.length === state.pagination.limit
          })
          
          if (!reset && response.pages.length > 0) {
            commit('incrementPage')
          }
        }
      } catch (error) {
        console.error('Error fetching business pages:', error)
      } finally {
        commit('setLoading', false)
      }
    },
    
    // Fetch user's own business pages
    async fetchMyPages({ commit }) {
      commit('setLoadingMyPages', true)
      
      try {
        const response = await nuiCallback('getMyBusinessPages')
        
        if (response.success) {
          commit('setMyPages', response.pages)
        }
      } catch (error) {
        console.error('Error fetching my business pages:', error)
      } finally {
        commit('setLoadingMyPages', false)
      }
    },
    
    // Fetch pages user is following
    async fetchFollowingPages({ commit }) {
      commit('setLoadingFollowing', true)
      
      try {
        const response = await nuiCallback('getFollowingPages')
        
        if (response.success) {
          commit('setFollowingPages', response.pages)
        }
      } catch (error) {
        console.error('Error fetching following pages:', error)
      } finally {
        commit('setLoadingFollowing', false)
      }
    },
    
    // Create a new business page
    async createPage({ commit, dispatch }, pageData) {
      try {
        const response = await nuiCallback('createBusinessPage', pageData)
        
        if (response.success) {
          // Refresh pages to include the new one
          await dispatch('fetchPages', { reset: true })
          await dispatch('fetchMyPages')
          return response
        } else {
          throw new Error(response.message || 'Failed to create business page')
        }
      } catch (error) {
        console.error('Error creating business page:', error)
        throw error
      }
    },
    
    // Update an existing business page
    async updatePage({ commit, dispatch }, pageData) {
      try {
        const response = await nuiCallback('updateBusinessPage', pageData)
        
        if (response.success) {
          // Refresh pages to reflect the update
          await dispatch('fetchPages', { reset: true })
          await dispatch('fetchMyPages')
          return response
        } else {
          throw new Error(response.message || 'Failed to update business page')
        }
      } catch (error) {
        console.error('Error updating business page:', error)
        throw error
      }
    },
    
    // Delete a business page
    async deletePage({ commit, dispatch }, pageId) {
      try {
        const response = await nuiCallback('deleteBusinessPage', pageId)
        
        if (response.success) {
          commit('removePage', pageId)
          return response
        } else {
          throw new Error(response.message || 'Failed to delete business page')
        }
      } catch (error) {
        console.error('Error deleting business page:', error)
        throw error
      }
    },
    
    // Follow a business page
    async followPage({ commit, dispatch }, pageId) {
      try {
        const response = await nuiCallback('followBusinessPage', pageId)
        
        if (response.success) {
          // Find the page and add to following
          const page = this.getters['pages/allPages'].find(p => p.id === pageId)
          if (page) {
            commit('addToFollowing', page)
          }
          return response
        } else {
          throw new Error(response.message || 'Failed to follow page')
        }
      } catch (error) {
        console.error('Error following page:', error)
        throw error
      }
    },
    
    // Unfollow a business page
    async unfollowPage({ commit, dispatch }, pageId) {
      try {
        const response = await nuiCallback('unfollowBusinessPage', pageId)
        
        if (response.success) {
          commit('removeFromFollowing', pageId)
          return response
        } else {
          throw new Error(response.message || 'Failed to unfollow page')
        }
      } catch (error) {
        console.error('Error unfollowing page:', error)
        throw error
      }
    },
    
    // Track page view
    async trackPageView({ commit }, pageId) {
      try {
        await nuiCallback('trackPageView', pageId)
        commit('incrementPageViews', pageId)
      } catch (error) {
        console.error('Error tracking page view:', error)
      }
    },
    
    // Search pages
    async searchPages({ commit, dispatch }, searchQuery) {
      commit('setSearchQuery', searchQuery)
      await dispatch('fetchPages', { reset: true, search: searchQuery })
    },
    
    // Filter pages by category
    async filterByCategory({ commit, dispatch }, category) {
      commit('setSelectedCategory', category)
      await dispatch('fetchPages', { reset: true, category })
    },
    
    // Load more pages (pagination)
    async loadMorePages({ dispatch, state }) {
      if (state.pagination.hasMore && !state.isLoading) {
        await dispatch('fetchPages')
      }
    },
    
    // Refresh pages
    async refreshPages({ dispatch }) {
      await dispatch('fetchPages', { reset: true })
    },
    
    // Fetch page statistics
    async fetchPageStats({ commit }, pageId) {
      try {
        const response = await nuiCallback('getPageStatistics', pageId)
        
        if (response.success) {
          return response.statistics
        } else {
          throw new Error(response.message || 'Failed to fetch page statistics')
        }
      } catch (error) {
        console.error('Error fetching page statistics:', error)
        throw error
      }
    },
    
    // Clear filters
    async clearFilters({ commit, dispatch }) {
      commit('setSearchQuery', '')
      commit('setSelectedCategory', '')
      await dispatch('fetchPages', { reset: true })
    },
    
    // Set current page
    setCurrentPage({ commit }, page) {
      commit('setCurrentPage', page)
    },
    
    // Clear current page
    clearCurrentPage({ commit }) {
      commit('setCurrentPage', null)
    },
    
    // Send announcement to followers
    async sendAnnouncement({ commit, dispatch }, { pageId, message }) {
      try {
        const response = await nuiCallback('phone:server:sendPageAnnouncement', {
          pageId,
          message
        })
        
        if (response.success) {
          return response
        } else {
          throw new Error(response.message || 'Failed to send announcement')
        }
      } catch (error) {
        console.error('Error sending announcement:', error)
        throw error
      }
    }
  },
  
  getters: {
    // All pages
    allPages: (state) => {
      return state.pages
    },
    
    // Active pages only
    activePages: (state) => {
      return state.pages.filter(page => page.status === 'active')
    },
    
    // User's active pages
    myActivePages: (state) => {
      return state.myPages.filter(page => page.status === 'active')
    },
    
    // Search results
    searchResults: (state) => {
      if (!state.searchQuery) return state.pages
      
      const query = state.searchQuery.toLowerCase()
      return state.pages.filter(page =>
        page.name.toLowerCase().includes(query) ||
        page.description.toLowerCase().includes(query) ||
        page.category.toLowerCase().includes(query)
      )
    },
    
    // Pages by category
    pagesByCategory: (state) => (category) => {
      return state.pages.filter(page => page.category === category)
    },
    
    // Check if user is following a page
    isFollowing: (state) => (pageId) => {
      return state.followingPages.some(page => page.id === pageId)
    },
    
    // Has more pages to load
    hasMorePages: (state) => {
      return state.pagination.hasMore
    },
    
    // Current page number
    currentPage: (state) => {
      return state.pagination.page
    },
    
    // Total pages count
    totalPages: (state) => {
      return state.pagination.total
    },
    
    // Categories with counts
    categoriesWithCounts: (state) => {
      const categories = {}
      state.pages.forEach(page => {
        categories[page.category] = (categories[page.category] || 0) + 1
      })
      return Object.entries(categories).map(([category, count]) => ({
        category,
        count
      }))
    },
    
    // Loading states
    isLoading: (state) => {
      return state.isLoading
    },
    
    isLoadingMyPages: (state) => {
      return state.isLoadingMyPages
    },
    
    isLoadingFollowing: (state) => {
      return state.isLoadingFollowing
    },
    
    // Statistics
    stats: (state) => {
      return state.stats
    },
    
    // Current selected page
    currentPage: (state) => {
      return state.currentPage
    },
    
    // Search and filter states
    searchQuery: (state) => {
      return state.searchQuery
    },
    
    selectedCategory: (state) => {
      return state.selectedCategory
    }
  }
}