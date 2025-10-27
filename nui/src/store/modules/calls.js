// Calls Store Module
import { nuiCallback } from '../../utils/nui'

export default {
  namespaced: true,
  
  state: {
    state: 'idle', // 'idle', 'ringing', 'active'
    currentCall: null,
    history: [],
    incomingCall: null
  },
  
  mutations: {
    setState(state, callState) {
      state.state = callState
    },
    
    setCurrentCall(state, call) {
      state.currentCall = call
    },
    
    setHistory(state, history) {
      state.history = history
    },
    
    setIncomingCall(state, call) {
      state.incomingCall = call
    },
    
    addToHistory(state, call) {
      state.history.unshift(call)
      // Keep only last 50 calls
      if (state.history.length > 50) {
        state.history = state.history.slice(0, 50)
      }
    },
    
    clearCurrentCall(state) {
      state.currentCall = null
      state.incomingCall = null
    }
  },
  
  actions: {
    async initiateCall({ commit }, phoneNumber) {
      try {
        const response = await nuiCallback('initiateCall', { phoneNumber })
        
        if (response.success) {
          commit('setState', 'ringing')
          commit('setCurrentCall', {
            number: phoneNumber,
            direction: 'outgoing',
            startTime: Date.now()
          })
        }
        
        return response
      } catch (error) {
        console.error('Failed to initiate call:', error)
        return { success: false, message: 'Failed to initiate call' }
      }
    },
    
    async acceptCall({ commit, state }) {
      try {
        const response = await nuiCallback('acceptCall', {})
        
        if (response.success) {
          commit('setState', 'active')
          if (state.incomingCall) {
            commit('setCurrentCall', {
              ...state.incomingCall,
              acceptedTime: Date.now()
            })
          }
        }
        
        return response
      } catch (error) {
        console.error('Failed to accept call:', error)
        return { success: false, message: 'Failed to accept call' }
      }
    },
    
    async endCall({ commit, state }) {
      try {
        const response = await nuiCallback('endCall', {})
        
        if (response.success) {
          // Add to history if call was active
          if (state.currentCall && state.state === 'active') {
            const duration = Math.floor((Date.now() - state.currentCall.acceptedTime) / 1000)
            commit('addToHistory', {
              ...state.currentCall,
              duration,
              endTime: Date.now()
            })
          }
          
          commit('setState', 'idle')
          commit('clearCurrentCall')
        }
        
        return response
      } catch (error) {
        console.error('Failed to end call:', error)
        return { success: false, message: 'Failed to end call' }
      }
    },
    
    receiveIncomingCall({ commit }, callData) {
      commit('setState', 'ringing')
      commit('setIncomingCall', {
        number: callData.callerNumber,
        callerName: callData.callerName,
        direction: 'incoming',
        startTime: Date.now()
      })
      commit('setCurrentCall', {
        number: callData.callerNumber,
        callerName: callData.callerName,
        direction: 'incoming',
        startTime: Date.now()
      })
    },
    
    callAccepted({ commit }) {
      commit('setState', 'active')
    },
    
    callEnded({ commit, state }) {
      // Add to history if call was active
      if (state.currentCall && state.state === 'active') {
        const duration = Math.floor((Date.now() - (state.currentCall.acceptedTime || state.currentCall.startTime)) / 1000)
        commit('addToHistory', {
          ...state.currentCall,
          duration,
          endTime: Date.now()
        })
      }
      
      commit('setState', 'idle')
      commit('clearCurrentCall')
    },
    
    async getCallHistory({ commit }) {
      try {
        const response = await nuiCallback('getCallHistory', {})
        
        if (response.success && response.history) {
          commit('setHistory', response.history)
        }
        
        return response
      } catch (error) {
        console.error('Failed to get call history:', error)
        return { success: false, message: 'Failed to get call history' }
      }
    }
  },
  
  getters: {
    isInCall: (state) => state.state !== 'idle',
    isRinging: (state) => state.state === 'ringing',
    isActive: (state) => state.state === 'active'
  }
}
