// Messages Store Module
import { nuiCallback } from '../../utils/nui'

export default {
  namespaced: true,
  
  state: {
    conversations: {},
    unreadCount: 0,
    activeConversation: null
  },
  
  getters: {
    // Get all conversations as array sorted by most recent message
    conversationList(state) {
      return Object.entries(state.conversations)
        .map(([phoneNumber, messages]) => {
          const lastMessage = messages[messages.length - 1]
          const unread = messages.filter(m => !m.is_read && m.receiver_number === state.activeConversation).length
          
          return {
            phoneNumber,
            messages,
            lastMessage,
            unreadCount: unread,
            timestamp: lastMessage ? new Date(lastMessage.created_at).getTime() : 0
          }
        })
        .sort((a, b) => b.timestamp - a.timestamp)
    },
    
    // Get messages for active conversation
    activeMessages(state) {
      if (!state.activeConversation) return []
      return state.conversations[state.activeConversation] || []
    },
    
    // Get total unread count
    totalUnread(state) {
      return state.unreadCount
    }
  },
  
  mutations: {
    setConversations(state, messagesData) {
      // Group messages by conversation (other party's phone number)
      const conversations = {}
      const myNumber = this.state.phone.phoneNumber
      
      if (Array.isArray(messagesData)) {
        messagesData.forEach(message => {
          // Determine the other party's number
          const otherNumber = message.sender_number === myNumber 
            ? message.receiver_number 
            : message.sender_number
          
          if (!conversations[otherNumber]) {
            conversations[otherNumber] = []
          }
          
          conversations[otherNumber].push(message)
        })
        
        // Sort messages in each conversation chronologically
        Object.keys(conversations).forEach(number => {
          conversations[number].sort((a, b) => 
            new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
          )
        })
      }
      
      state.conversations = conversations
      state.unreadCount = messagesData.filter(m => !m.is_read && m.receiver_number === myNumber).length
    },
    
    setUnreadCount(state, count) {
      state.unreadCount = count
    },
    
    setActiveConversation(state, phoneNumber) {
      state.activeConversation = phoneNumber
    },
    
    addMessage(state, message) {
      const myNumber = this.state.phone.phoneNumber
      const otherNumber = message.sender_number === myNumber 
        ? message.receiver_number 
        : message.sender_number
      
      if (!state.conversations[otherNumber]) {
        state.conversations[otherNumber] = []
      }
      
      state.conversations[otherNumber].push(message)
      
      // Update unread count if it's an incoming message
      if (message.receiver_number === myNumber && !message.is_read) {
        state.unreadCount++
      }
    },
    
    markConversationRead(state, phoneNumber) {
      const myNumber = this.state.phone.phoneNumber
      
      if (state.conversations[phoneNumber]) {
        state.conversations[phoneNumber].forEach(message => {
          if (message.receiver_number === myNumber && !message.is_read) {
            message.is_read = true
            state.unreadCount--
          }
        })
      }
    }
  },
  
  actions: {
    // Fetch all messages from server
    async fetchMessages({ commit }) {
      try {
        const response = await nuiCallback('getMessages', {})
        if (response.success) {
          commit('setConversations', response.messages)
        }
        return response
      } catch (error) {
        console.error('Error fetching messages:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    // Send a new message
    async sendMessage({ commit }, { targetNumber, message }) {
      try {
        const response = await nuiCallback('sendMessage', {
          targetNumber,
          message
        })
        
        if (response.success) {
          commit('addMessage', response.message)
        }
        
        return response
      } catch (error) {
        console.error('Error sending message:', error)
        return { success: false, error: 'SEND_FAILED' }
      }
    },
    
    // Mark conversation as read
    async markAsRead({ commit }, phoneNumber) {
      try {
        const response = await nuiCallback('markMessagesRead', { phoneNumber })
        
        if (response.success) {
          commit('markConversationRead', phoneNumber)
        }
        
        return response
      } catch (error) {
        console.error('Error marking messages as read:', error)
        return { success: false, error: 'MARK_READ_FAILED' }
      }
    },
    
    // Receive incoming message (called from NUI message listener)
    receiveMessage({ commit, dispatch }, message) {
      commit('addMessage', message)
      
      // Show notification
      dispatch('phone/showNotification', {
        type: 'message',
        title: 'New Message',
        message: `From: ${message.sender_number}`,
        data: message
      }, { root: true })
    }
  }
}
