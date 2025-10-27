<template>
  <div class="chirper-app">
    <!-- Create Post Section -->
    <div class="create-post-section">
      <textarea 
        v-model="newChirp" 
        placeholder="What's happening?"
        class="chirp-input"
        :maxlength="280"
        :disabled="isPosting"
        @input="updateCharCount"
      ></textarea>
      
      <div class="post-actions">
        <span class="char-count" :class="{ warning: charCount > 260, error: charCount >= 280 }">
          {{ charCount }}/280
        </span>
        <button 
          @click="handlePostChirp" 
          class="post-button"
          :disabled="!canPost || isPosting"
        >
          {{ isPosting ? 'Posting...' : 'Chirp' }}
        </button>
      </div>
      
      <div v-if="postError" class="error-message">
        {{ postError }}
      </div>
    </div>
    
    <!-- Feed Tabs -->
    <div class="feed-tabs">
      <button 
        class="tab-button" 
        :class="{ active: activeTab === 'feed' }"
        @click="activeTab = 'feed'"
      >
        Feed
      </button>
      <button 
        class="tab-button" 
        :class="{ active: activeTab === 'myChirps' }"
        @click="activeTab = 'myChirps'"
      >
        My Chirps
      </button>
    </div>
    
    <!-- Feed Display -->
    <div class="feed-container">
      <div v-if="isLoading" class="loading-state">
        Loading chirps...
      </div>
      
      <div v-else-if="currentFeed.length === 0" class="empty-state">
        {{ activeTab === 'feed' ? 'No chirps yet' : 'You haven\'t posted anything yet' }}
      </div>
      
      <div v-else class="chirp-list">
        <div 
          v-for="chirp in currentFeed" 
          :key="chirp.id"
          class="chirp-item"
        >
          <div class="chirp-header">
            <div class="author-info">
              <div class="author-avatar">
                {{ getInitials(chirp.author_name) }}
              </div>
              <div class="author-details">
                <div class="author-name">{{ chirp.author_name }}</div>
                <div class="author-number">{{ chirp.author_number }}</div>
              </div>
            </div>
            <div class="chirp-time">{{ formatTime(chirp.created_at) }}</div>
          </div>
          
          <div class="chirp-content">
            {{ chirp.content }}
          </div>
          
          <div class="chirp-actions">
            <button 
              class="action-button like-button"
              :class="{ liked: chirp.isLiked }"
              @click="handleLikeChirp(chirp.id)"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
              </svg>
              <span>{{ chirp.likes }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useStore } from 'vuex'

export default {
  name: 'Chirper',
  setup() {
    const store = useStore()
    
    const newChirp = ref('')
    const charCount = ref(0)
    const isPosting = ref(false)
    const isLoading = ref(false)
    const postError = ref('')
    const activeTab = ref('feed')
    
    const feed = computed(() => store.state.apps.chirper.feed)
    const myChirps = computed(() => store.state.apps.chirper.myChirps)
    
    const currentFeed = computed(() => {
      return activeTab.value === 'feed' ? feed.value : myChirps.value
    })
    
    const canPost = computed(() => {
      return newChirp.value.trim().length > 0 && charCount.value <= 280
    })
    
    const updateCharCount = () => {
      charCount.value = newChirp.value.length
    }
    
    const getInitials = (name) => {
      if (!name) return '?'
      const parts = name.split(' ')
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase()
      }
      return name.substring(0, 2).toUpperCase()
    }
    
    const formatTime = (timestamp) => {
      const date = new Date(timestamp)
      const now = new Date()
      const diffMs = now - date
      const diffMins = Math.floor(diffMs / 60000)
      const diffHours = Math.floor(diffMs / 3600000)
      const diffDays = Math.floor(diffMs / 86400000)
      
      if (diffMins < 1) return 'Just now'
      if (diffMins < 60) return `${diffMins}m`
      if (diffHours < 24) return `${diffHours}h`
      if (diffDays < 7) return `${diffDays}d`
      
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
    }
    
    const handlePostChirp = async () => {
      if (!canPost.value || isPosting.value) return
      
      postError.value = ''
      isPosting.value = true
      
      try {
        const result = await store.dispatch('apps/postChirp', {
          content: newChirp.value.trim()
        })
        
        if (result.success) {
          newChirp.value = ''
          charCount.value = 0
          
          // Show notification
          store.dispatch('phone/showNotification', {
            type: 'success',
            title: 'Chirp Posted',
            message: 'Your chirp has been published'
          })
        } else {
          postError.value = result.message || 'Failed to post chirp'
        }
      } catch (error) {
        console.error('Post chirp error:', error)
        postError.value = 'An error occurred while posting'
      } finally {
        isPosting.value = false
      }
    }
    
    const handleLikeChirp = async (chirpId) => {
      try {
        await store.dispatch('apps/likeChirp', { chirpId: chirpId })
      } catch (error) {
        console.error('Like chirp error:', error)
      }
    }
    
    onMounted(async () => {
      isLoading.value = true
      try {
        await store.dispatch('apps/fetchChirperFeed')
      } catch (error) {
        console.error('Error loading chirper feed:', error)
      } finally {
        isLoading.value = false
      }
    })
    
    return {
      newChirp,
      charCount,
      isPosting,
      isLoading,
      postError,
      activeTab,
      currentFeed,
      canPost,
      updateCharCount,
      getInitials,
      formatTime,
      handlePostChirp,
      handleLikeChirp
    }
  }
}
</script>

<style scoped>
.chirper-app {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: #000;
  color: #fff;
  overflow: hidden;
}

.create-post-section {
  padding: 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(255, 255, 255, 0.02);
}

.chirp-input {
  width: 100%;
  min-height: 80px;
  padding: 12px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  color: #fff;
  font-size: 15px;
  font-family: inherit;
  resize: none;
  transition: all 0.2s;
}

.chirp-input:focus {
  outline: none;
  background: rgba(255, 255, 255, 0.08);
  border-color: #1da1f2;
}

.chirp-input:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.chirp-input::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.post-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 12px;
}

.char-count {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.5);
  transition: color 0.2s;
}

.char-count.warning {
  color: #ff9500;
}

.char-count.error {
  color: #ff3b30;
  font-weight: 600;
}

.post-button {
  padding: 8px 24px;
  background: #1da1f2;
  border: none;
  border-radius: 20px;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.post-button:hover:not(:disabled) {
  background: #1a8cd8;
}

.post-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.error-message {
  margin-top: 12px;
  padding: 10px;
  background: rgba(255, 59, 48, 0.2);
  border: 1px solid rgba(255, 59, 48, 0.4);
  border-radius: 6px;
  color: #ff3b30;
  font-size: 13px;
}

.feed-tabs {
  display: flex;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(255, 255, 255, 0.02);
}

.tab-button {
  flex: 1;
  padding: 14px;
  background: transparent;
  border: none;
  color: rgba(255, 255, 255, 0.6);
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}

.tab-button:hover {
  background: rgba(255, 255, 255, 0.05);
}

.tab-button.active {
  color: #1da1f2;
}

.tab-button.active::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: #1da1f2;
  border-radius: 3px 3px 0 0;
}

.feed-container {
  flex: 1;
  overflow-y: auto;
}

.loading-state,
.empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  color: rgba(255, 255, 255, 0.5);
  font-size: 14px;
}

.chirp-list {
  display: flex;
  flex-direction: column;
}

.chirp-item {
  padding: 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  transition: background 0.2s;
}

.chirp-item:hover {
  background: rgba(255, 255, 255, 0.02);
}

.chirp-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
}

.author-info {
  display: flex;
  gap: 12px;
  align-items: center;
}

.author-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 600;
  color: #fff;
  flex-shrink: 0;
}

.author-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.author-name {
  font-size: 15px;
  font-weight: 600;
  color: #fff;
}

.author-number {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.5);
}

.chirp-time {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.5);
}

.chirp-content {
  font-size: 15px;
  line-height: 1.5;
  color: #fff;
  margin-bottom: 12px;
  word-wrap: break-word;
}

.chirp-actions {
  display: flex;
  gap: 16px;
}

.action-button {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: transparent;
  border: none;
  border-radius: 16px;
  color: rgba(255, 255, 255, 0.6);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
}

.action-button:hover {
  background: rgba(255, 255, 255, 0.1);
}

.like-button.liked {
  color: #ff3b30;
}

.like-button.liked svg {
  fill: #ff3b30;
}

/* Responsive adjustments */
@media (max-width: 1600px) and (max-height: 900px) {
  .create-post-section {
    padding: 14px;
  }
  
  .chirp-input {
    min-height: 70px;
    font-size: 14px;
  }
  
  .chirp-item {
    padding: 14px;
  }
  
  .author-avatar {
    width: 36px;
    height: 36px;
    font-size: 13px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .create-post-section {
    padding: 12px;
  }
  
  .chirp-input {
    min-height: 60px;
    font-size: 13px;
    padding: 10px;
  }
  
  .post-actions {
    margin-top: 10px;
  }
  
  .char-count {
    font-size: 12px;
  }
  
  .post-button {
    padding: 6px 20px;
    font-size: 13px;
  }
  
  .tab-button {
    padding: 12px;
    font-size: 13px;
  }
  
  .chirp-item {
    padding: 12px;
  }
  
  .author-avatar {
    width: 32px;
    height: 32px;
    font-size: 12px;
  }
  
  .author-name {
    font-size: 14px;
  }
  
  .author-number,
  .chirp-time {
    font-size: 12px;
  }
  
  .chirp-content {
    font-size: 14px;
  }
}
</style>
