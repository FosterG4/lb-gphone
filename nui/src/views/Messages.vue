<template>
  <div class="messages-app">
    <!-- Conversation List View -->
    <div v-if="!activeConversation" class="conversation-list">
      <div class="app-header">
        <h2>Messages</h2>
        <button class="new-message-btn" @click="showNewMessage = true">+</button>
      </div>
      
      <div class="search-bar">
        <input 
          type="text" 
          v-model="searchQuery" 
          placeholder="Search conversations..."
          class="search-input"
        />
      </div>
      
      <div class="conversations">
        <div 
          v-for="conversation in filteredConversations" 
          :key="conversation.phoneNumber"
          class="conversation-item"
          @click="openConversation(conversation.phoneNumber)"
        >
          <div class="conversation-avatar">
            <span>{{ getContactName(conversation.phoneNumber).charAt(0) }}</span>
          </div>
          <div class="conversation-info">
            <div class="conversation-header">
              <span class="conversation-name">{{ getContactName(conversation.phoneNumber) }}</span>
              <span class="conversation-time">{{ formatTime(conversation.lastMessage.created_at) }}</span>
            </div>
            <div class="conversation-preview">
              <span class="preview-text">{{ conversation.lastMessage.message }}</span>
              <span v-if="conversation.unreadCount > 0" class="unread-badge">
                {{ conversation.unreadCount }}
              </span>
            </div>
          </div>
        </div>
        
        <div v-if="filteredConversations.length === 0" class="empty-state">
          <p>No messages yet</p>
          <p class="empty-subtitle">Start a conversation</p>
        </div>
      </div>
    </div>
    
    <!-- Thread View -->
    <div v-else class="thread-view">
      <div class="thread-header">
        <button class="back-btn" @click="closeConversation">←</button>
        <h3>{{ getContactName(activeConversation) }}</h3>
      </div>
      
      <div class="messages-container" ref="messagesContainer">
        <div 
          v-for="message in activeMessages" 
          :key="message.id"
          :class="['message-bubble', message.sender_number === myPhoneNumber ? 'sent' : 'received']"
        >
          <div class="message-content">{{ message.message }}</div>
          <div class="message-time">{{ formatTime(message.created_at) }}</div>
        </div>
      </div>
      
      <div class="message-input-container">
        <textarea
          v-model="newMessage"
          @keydown.enter.prevent="sendMessage"
          placeholder="Type a message..."
          class="message-input"
          :maxlength="maxMessageLength"
          rows="1"
        ></textarea>
        <button 
          @click="sendMessage" 
          class="send-btn"
          :disabled="!newMessage.trim()"
        >
          Send
        </button>
      </div>
    </div>
    
    <!-- New Message Modal -->
    <div v-if="showNewMessage" class="modal-overlay" @click="showNewMessage = false">
      <div class="modal-content" @click.stop>
        <h3>New Message</h3>
        <input 
          type="text" 
          v-model="newMessageNumber" 
          placeholder="Phone number"
          class="modal-input"
        />
        <textarea
          v-model="newMessageText"
          placeholder="Type your message..."
          class="modal-textarea"
          :maxlength="maxMessageLength"
        ></textarea>
        <div class="modal-actions">
          <button @click="showNewMessage = false" class="cancel-btn">Cancel</button>
          <button @click="sendNewMessage" class="confirm-btn">Send</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { computed, ref, watch, nextTick } from 'vue'
import { useStore } from 'vuex'

export default {
  name: 'Messages',
  
  setup() {
    const store = useStore()
    const searchQuery = ref('')
    const newMessage = ref('')
    const showNewMessage = ref(false)
    const newMessageNumber = ref('')
    const newMessageText = ref('')
    const messagesContainer = ref(null)
    
    const myPhoneNumber = computed(() => store.state.phone.phoneNumber)
    const conversations = computed(() => store.getters['messages/conversationList'])
    const activeConversation = computed(() => store.state.messages.activeConversation)
    const activeMessages = computed(() => store.getters['messages/activeMessages'])
    const contacts = computed(() => store.state.contacts.list)
    const maxMessageLength = ref(500)
    
    // Filter conversations by search query
    const filteredConversations = computed(() => {
      if (!searchQuery.value) return conversations.value
      
      const query = searchQuery.value.toLowerCase()
      return conversations.value.filter(conv => {
        const name = getContactName(conv.phoneNumber).toLowerCase()
        const number = conv.phoneNumber.toLowerCase()
        const lastMsg = conv.lastMessage.message.toLowerCase()
        
        return name.includes(query) || number.includes(query) || lastMsg.includes(query)
      })
    })
    
    // Get contact name or return phone number
    const getContactName = (phoneNumber) => {
      const contact = contacts.value.find(c => c.contact_number === phoneNumber)
      return contact ? contact.contact_name : phoneNumber
    }
    
    // Format timestamp
    const formatTime = (timestamp) => {
      const date = new Date(timestamp)
      const now = new Date()
      const diff = now - date
      
      // Less than 1 minute
      if (diff < 60000) {
        return 'Just now'
      }
      
      // Less than 1 hour
      if (diff < 3600000) {
        const minutes = Math.floor(diff / 60000)
        return `${minutes}m ago`
      }
      
      // Today
      if (date.toDateString() === now.toDateString()) {
        return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
      }
      
      // This week
      if (diff < 604800000) {
        return date.toLocaleDateString('en-US', { weekday: 'short' })
      }
      
      // Older
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    }
    
    // Open conversation
    const openConversation = async (phoneNumber) => {
      store.commit('messages/setActiveConversation', phoneNumber)
      
      // Mark messages as read
      await store.dispatch('messages/markAsRead', phoneNumber)
      
      // Scroll to bottom
      await nextTick()
      scrollToBottom()
    }
    
    // Close conversation
    const closeConversation = () => {
      store.commit('messages/setActiveConversation', null)
      newMessage.value = ''
    }
    
    // Send message in active conversation
    const sendMessage = async () => {
      if (!newMessage.value.trim() || !activeConversation.value) return
      
      const result = await store.dispatch('messages/sendMessage', {
        targetNumber: activeConversation.value,
        message: newMessage.value.trim()
      })
      
      if (result.success) {
        newMessage.value = ''
        await nextTick()
        scrollToBottom()
      } else {
        alert(result.message || 'Failed to send message')
      }
    }
    
    // Send new message from modal
    const sendNewMessage = async () => {
      if (!newMessageNumber.value.trim() || !newMessageText.value.trim()) {
        alert('Please enter both phone number and message')
        return
      }
      
      const result = await store.dispatch('messages/sendMessage', {
        targetNumber: newMessageNumber.value.trim(),
        message: newMessageText.value.trim()
      })
      
      if (result.success) {
        showNewMessage.value = false
        newMessageNumber.value = ''
        newMessageText.value = ''
        
        // Open the new conversation
        openConversation(result.message.receiver_number)
      } else {
        alert(result.message || 'Failed to send message')
      }
    }
    
    // Scroll to bottom of messages
    const scrollToBottom = () => {
      if (messagesContainer.value) {
        messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
      }
    }
    
    // Watch for new messages in active conversation
    watch(() => activeMessages.value.length, () => {
      nextTick(() => scrollToBottom())
    })
    
    // Load messages on mount
    store.dispatch('messages/fetchMessages')
    
    return {
      searchQuery,
      newMessage,
      showNewMessage,
      newMessageNumber,
      newMessageText,
      messagesContainer,
      myPhoneNumber,
      conversations,
      activeConversation,
      activeMessages,
      filteredConversations,
      maxMessageLength,
      getContactName,
      formatTime,
      openConversation,
      closeConversation,
      sendMessage,
      sendNewMessage
    }
  }
}
</script>

<style scoped>
.messages-app {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  background: #000;
  color: #fff;
}

.conversation-list,
.thread-view {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #333;
}

.app-header h2 {
  margin: 0;
  font-size: 24px;
}

.new-message-btn {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #007aff;
  color: white;
  border: none;
  font-size: 24px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.search-bar {
  padding: 10px 20px;
  border-bottom: 1px solid #333;
}

.search-input {
  width: 100%;
  padding: 10px 15px;
  background: #1c1c1e;
  border: none;
  border-radius: 10px;
  color: #fff;
  font-size: 16px;
}

.conversations {
  flex: 1;
  overflow-y: auto;
}

.conversation-item {
  display: flex;
  padding: 15px 20px;
  border-bottom: 1px solid #333;
  cursor: pointer;
  transition: background 0.2s;
}

.conversation-item:hover {
  background: #1c1c1e;
}

.conversation-avatar {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background: #007aff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  font-weight: bold;
  margin-right: 15px;
  flex-shrink: 0;
}

.conversation-info {
  flex: 1;
  min-width: 0;
}

.conversation-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 5px;
}

.conversation-name {
  font-weight: 600;
  font-size: 16px;
}

.conversation-time {
  font-size: 12px;
  color: #8e8e93;
}

.conversation-preview {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.preview-text {
  flex: 1;
  font-size: 14px;
  color: #8e8e93;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.unread-badge {
  background: #007aff;
  color: white;
  border-radius: 10px;
  padding: 2px 8px;
  font-size: 12px;
  font-weight: bold;
  margin-left: 10px;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: #8e8e93;
}

.empty-subtitle {
  font-size: 14px;
  margin-top: 5px;
}

.thread-header {
  display: flex;
  align-items: center;
  padding: 15px 20px;
  border-bottom: 1px solid #333;
}

.back-btn {
  background: none;
  border: none;
  color: #007aff;
  font-size: 24px;
  cursor: pointer;
  margin-right: 15px;
  padding: 0;
}

.thread-header h3 {
  margin: 0;
  font-size: 18px;
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.message-bubble {
  max-width: 70%;
  padding: 10px 15px;
  border-radius: 18px;
  word-wrap: break-word;
}

.message-bubble.sent {
  align-self: flex-end;
  background: #007aff;
  color: white;
}

.message-bubble.received {
  align-self: flex-start;
  background: #3a3a3c;
  color: white;
}

.message-content {
  font-size: 16px;
  line-height: 1.4;
}

.message-time {
  font-size: 11px;
  margin-top: 5px;
  opacity: 0.7;
}

.message-input-container {
  display: flex;
  padding: 10px 20px;
  border-top: 1px solid #333;
  gap: 10px;
}

.message-input {
  flex: 1;
  padding: 10px 15px;
  background: #1c1c1e;
  border: none;
  border-radius: 20px;
  color: #fff;
  font-size: 16px;
  resize: none;
  font-family: inherit;
}

.send-btn {
  padding: 10px 20px;
  background: #007aff;
  color: white;
  border: none;
  border-radius: 20px;
  cursor: pointer;
  font-size: 16px;
  font-weight: 600;
}

.send-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
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

.modal-content {
  background: #1c1c1e;
  border-radius: 20px;
  padding: 30px;
  width: 90%;
  max-width: 400px;
}

.modal-content h3 {
  margin: 0 0 20px 0;
  font-size: 20px;
}

.modal-input,
.modal-textarea {
  width: 100%;
  padding: 12px 15px;
  background: #2c2c2e;
  border: 1px solid #3a3a3c;
  border-radius: 10px;
  color: #fff;
  font-size: 16px;
  margin-bottom: 15px;
  font-family: inherit;
}

.modal-textarea {
  resize: vertical;
  min-height: 100px;
}

.modal-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
}

.cancel-btn,
.confirm-btn {
  padding: 10px 20px;
  border: none;
  border-radius: 10px;
  font-size: 16px;
  cursor: pointer;
  font-weight: 600;
}

.cancel-btn {
  background: #3a3a3c;
  color: white;
}

.confirm-btn {
  background: #007aff;
  color: white;
}
</style>
