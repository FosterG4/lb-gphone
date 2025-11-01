// Nearby Players Store Module
export default {
  namespaced: true,
  
  state: {
    list: [],
    lastUpdate: null
  },
  
  getters: {
    // Get sorted nearby players (closest first)
    sortedPlayers(state) {
      return [...state.list].sort((a, b) => a.distance - b.distance)
    },
    
    // Get count of nearby players
    count(state) {
      return state.list.length
    },
    
    // Check if a specific player is nearby
    isPlayerNearby: (state) => (source) => {
      return state.list.some(player => player.source === source)
    },
    
    // Get nearby players who are broadcasting
    broadcastingPlayers(state) {
      return state.list.filter(player => player.isBroadcasting)
    },
    
    // Get nearby players filtered by whether they're already in contacts
    // Requires contacts list to be passed as parameter
    filteredByContactStatus: (state) => (contactsList, showOnlyNew = false) => {
      const sorted = [...state.list].sort((a, b) => a.distance - b.distance)
      
      if (!showOnlyNew) {
        return sorted
      }
      
      // Filter out players who are already in contacts
      return sorted.filter(player => {
        return !contactsList.some(contact => 
          contact.contact_number === player.phoneNumber
        )
      })
    }
  },
  
  mutations: {
    // Update the entire nearby players list
    setNearbyPlayers(state, players) {
      state.list = players || []
      state.lastUpdate = Date.now()
    },
    
    // Add a single nearby player
    addNearbyPlayer(state, player) {
      const existingIndex = state.list.findIndex(p => p.source === player.source)
      if (existingIndex === -1) {
        state.list.push(player)
      } else {
        // Update existing player
        state.list.splice(existingIndex, 1, player)
      }
      state.lastUpdate = Date.now()
    },
    
    // Remove a nearby player
    removeNearbyPlayer(state, source) {
      const index = state.list.findIndex(p => p.source === source)
      if (index !== -1) {
        state.list.splice(index, 1)
        state.lastUpdate = Date.now()
      }
    },
    
    // Update a player's broadcast status
    updateBroadcastStatus(state, { source, isBroadcasting }) {
      const player = state.list.find(p => p.source === source)
      if (player) {
        player.isBroadcasting = isBroadcasting
        state.lastUpdate = Date.now()
      }
    },
    
    // Clear all nearby players
    clearNearbyPlayers(state) {
      state.list = []
      state.lastUpdate = Date.now()
    }
  },
  
  actions: {
    // Handle nearby players update from client
    updateNearbyPlayers({ commit }, players) {
      commit('setNearbyPlayers', players)
    },
    
    // Handle broadcast started event
    handleBroadcastStarted({ commit }, { source }) {
      commit('updateBroadcastStatus', { source, isBroadcasting: true })
    },
    
    // Handle broadcast stopped event
    handleBroadcastStopped({ commit }, { source }) {
      commit('updateBroadcastStatus', { source, isBroadcasting: false })
    }
  }
}
