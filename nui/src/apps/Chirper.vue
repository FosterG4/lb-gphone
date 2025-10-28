<template>
  <div class="chirper-app">
    <!-- Header -->
    <div class="chirper-header">
      <div class="header-left">
        <button v-if="currentView !== 'feed'" @click="goBack" class="back-btn">
          <i class="fas fa-arrow-left"></i>
        </button>
        <h1>{{ headerTitle }}</h1>
      </div>
      <div class="header-right">
        <button v-if="currentView === 'feed'" @click="showCreatePost = true" class="create-btn">
          <i class="fas fa-feather-alt"></i>
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Loading posts...</p>
    </div>

    <!-- Feed View -->
    <div v-else-if="currentView === 'feed'" class="feed-layout">
      <!-- Main Feed -->
      <div class="feed-container" @scroll="handleScroll">
        <div v-if="currentFeed.length === 0" class="empty-state">
          <i class="fas fa-feather-alt"></i>
          <p>No posts yet</p>
          <p class="hint">Be the first to chirp!</p>
        </div>

        <div 
          v-for="post in currentFeed" 
          :key="post.id" 
          class="post-item"
          @click="viewThread(post)"
        >
          <!-- Post Header -->
          <div class="post-header">
            <div class="author-info">
              <div class="author-avatar">
                {{ getInitials(post.author_name) }}
              </div>
              <div class="author-details">
                <div class="author-name">{{ post.author_name }}</div>
                <div class="post-time">{{ formatTime(post.created_at) }}</div>
              </div>
            </div>
          </div>

          <!-- Post Content -->
          <div class="post-content">
            <p v-html="formatContent(post.content)"></p>
          </div>

          <!-- Post Actions -->
          <div class="post-actions">
            <button 
              class="action-btn reply-btn"
              @click.stop="replyToPost(post)"
            >
              <i class="far fa-comment"></i>
              <span v-if="post.replies > 0">{{ formatCount(post.replies) }}</span>
            </button>
            <button 
              :class="['action-btn', 'repost-btn', { reposted: post.isReposted }]"
              @click.stop="handleRepost(post.id)"
            >
              <i class="fas fa-retweet"></i>
              <span v-if="post.reposts > 0">{{ formatCount(post.reposts) }}</span>
            </button>
            <button 
              :class="['action-btn', 'like-btn', { liked: post.isLiked }]"
              @click.stop="handleLike(post.id)"
            >
              <i :class="post.isLiked ? 'fas fa-heart' : 'far fa-heart'"></i>
              <span v-if="post.likes > 0">{{ formatCount(post.likes) }}</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Trending Sidebar -->
      <div class="trending-sidebar">
        <div class="trending-header">
          <h3>Trending</h3>
          <button @click="refreshTrending" class="refresh-btn">
            <i class="fas fa-sync-alt"></i>
          </button>
        </div>
        
        <div v-if="trending.length === 0" class="no-trending">
          No trending topics yet
        </div>
        
        <div v-else class="trending-list">
          <div 
            v-for="(topic, index) in trending" 
            :key="index" 
            class="trending-item"
            @click="filterByHashtag(topic.hashtag)"
          >
            <div class="trending-rank">{{ index + 1 }}</div>
            <div class="trending-info">
              <div class="trending-hashtag">#{{ topic.hashtag }}</div>
              <div class="trending-count">{{ formatCount(topic.post_count) }} posts</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Thread View -->
    <div v-else-if="currentView === 'thread' && currentThread" class="thread-view">
      <div class="thread-container">
        <!-- Main Post -->
        <div class="main-post">
          <div class="post-header">
            <div class="author-info">
              <div class="author-avatar">
                {{ getInitials(currentThread.post.author_name) }}
              </div>
              <div class="author-details">
                <div class="author-name">{{ currentThread.post.author_name }}</div>
                <div class="post-time">{{ formatTime(currentThread.post.created_at) }}</div>
              </div>
            </div>
          </div>

          <div class="post-content">
            <p v-html="formatContent(currentThread.post.content)"></p>
          </div>

          <div class="post-actions">
            <button 
              class="action-btn reply-btn"
              @click="replyToPost(currentThread.post)"
            >
              <i class="far fa-comment"></i>
              <span v-if="currentThread.post.replies > 0">{{ formatCount(currentThread.post.replies) }}</span>
            </button>
            <button 
              :class="['action-btn', 'repost-btn', { reposted: currentThread.post.isReposted }]"
              @click="handleRepost(currentThread.post.id)"
            >
              <i class="fas fa-retweet"></i>
              <span v-if="currentThread.post.reposts > 0">{{ formatCount(currentThread.post.reposts) }}</span>
            </button>
            <button 
              :class="['action-btn', 'like-btn', { liked: currentThread.post.isLiked }]"
              @click="handleLike(currentThread.post.id)"
            >
              <i :class="currentThread.post.isLiked ? 'fas fa-heart' : 'far fa-heart'"></i>
              <span v-if="currentThread.post.likes > 0">{{ formatCount(currentThread.post.likes) }}</span>
            </button>
          </div>
        </div>

        <!-- Replies -->
        <div class="replies-section">
          <h3 v-if="currentThread.replies.length > 0">
            Replies ({{ currentThread.replies.length }})
          </h3>
          
          <div v-if="currentThread.replies.length === 0" class="no-replies">
            No replies yet. Be the first to reply!
          </div>

          <div 
            v-for="reply in currentThread.replies" 
            :key="reply.id" 
            class="reply-item"
          >
            <div class="reply-header">
              <div class="author-info">
                <div class="author-avatar">
                  {{ getInitials(reply.author_name) }}
                </div>
                <div class="author-details">
                  <div class="author-name">{{ reply.author_name }}</div>
                  <div class="post-time">{{ formatTime(reply.created_at) }}</div>
                </div>
              </div>
            </div>

            <div class="reply-content">
              <p v-html="formatContent(reply.content)"></p>
            </div>

            <div class="reply-actions">
              <button 
                :class="['action-btn', 'like-btn', { liked: reply.isLiked }]"
                @click="handleLike(reply.id)"
              >
                <i :class="reply.isLiked ? 'fas fa-heart' : 'far fa-heart'"></i>
                <span v-if="reply.likes > 0">{{ formatCount(reply.likes) }}</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Create Post Dialog -->
    <div v-if="showCreatePost" class="dialog-overlay" @click.self="closeCreatePost">
      <div class="create-post-dialog">
        <div class="dialog-header">
          <h3>{{ replyingTo ? 'Reply' : 'New Chirp' }}</h3>
          <button @click="closeCreatePost" class="close-btn">
            <i class="fas fa-times"></i>
          </button>
        </div>

        <div class="dialog-content">
          <!-- Replying To Indicator -->
          <div v-if="replyingTo" class="replying-to">
            <i class="fas fa-reply"></i>
            <span>Replying to <strong>{{ replyingTo.author_name }}</strong></span>
          </div>

          <!-- Post Input -->
          <textarea 
            v-model="newPostContent" 
            placeholder="What's happening?"
            maxlength="280"
            class="post-input"
            ref="postInput"
            @input="updateCharCount"
          ></textarea>
          
          <div class="post-meta">
            <div class="char-count" :class="{ warning: charCount > 260, error: charCount >= 280 }">
              {{ charCount }}/280
            </div>
          </div>
        </div>

        <div class="dialog-actions">
          <button @click="closeCreatePost" class="cancel-btn">Cancel</button>
          <button 
            @click="createPost" 
            class="post-btn"
            :disabled="!canPost || isPosting"
          >
            {{ isPosting ? 'Posting...' : (replyingTo ? 'Reply' : 'Chirp') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapGetters, mapActions } from 'vuex';

export default {
  name: 'Chirper',
  
  data() {
    return {
      currentView: 'feed', // 'feed', 'thread'
      currentThread: null,
      showCreatePost: false,
      newPostContent: '',
      charCount: 0,
      isPosting: false,
      replyingTo: null,
      page: 0,
      pageSize: 20,
      hasMore: true,
      isLoadingMore: false,
      hashtagFilter: null
    };
  },
  
  computed: {
    ...mapState('chirper', ['feed', 'myPosts', 'trending', 'loading']),
    
    headerTitle() {
      if (this.currentView === 'thread') return 'Thread';
      return 'Chirper';
    },
    
    currentFeed() {
      if (this.hashtagFilter) {
        return this.feed.filter(post => 
          post.content.toLowerCase().includes(`#${this.hashtagFilter.toLowerCase()}`)
        );
      }
      return this.feed;
    },
    
    canPost() {
      return this.newPostContent.trim().length > 0 && 
             this.newPostContent.length <= 280 && 
             !this.isPosting;
    }
  },
  
  mounted() {
    this.loadFeed();
    this.loadTrending();
  },
  
  methods: {
    ...mapActions('chirper', [
      'fetchFeed',
      'fetchMyPosts',
      'fetchTrending',
      'fetchThread',
      'createChirperPost',
      'likePost',
      'repostPost',
      'replyToPost',
      'deletePost'
    ]),
    
    async loadFeed() {
      await this.fetchFeed({ limit: this.pageSize, offset: this.page * this.pageSize });
    },
    
    async loadTrending() {
      await this.fetchTrending();
    },
    
    async refreshTrending() {
      await this.loadTrending();
    },
    
    async handleScroll(event) {
      const { scrollTop, scrollHeight, clientHeight } = event.target;
      
      if (scrollTop + clientHeight >= scrollHeight - 100 && !this.isLoadingMore && this.hasMore) {
        this.isLoadingMore = true;
        this.page++;
        
        const result = await this.fetchFeed({ 
          limit: this.pageSize, 
          offset: this.page * this.pageSize 
        });
        
        if (!result || result.length < this.pageSize) {
          this.hasMore = false;
        }
        
        this.isLoadingMore = false;
      }
    },
    
    async viewThread(post) {
      this.currentView = 'thread';
      
      // Load thread
      const thread = await this.fetchThread(post.id);
      this.currentThread = thread;
    },
    
    replyToPost(post) {
      this.replyingTo = post;
      this.showCreatePost = true;
      
      // Focus input after dialog opens
      this.$nextTick(() => {
        if (this.$refs.postInput) {
          this.$refs.postInput.focus();
        }
      });
    },
    
    async handleLike(postId) {
      await this.likePost(postId);
    },
    
    async handleRepost(postId) {
      await this.repostPost(postId);
    },
    
    async createPost() {
      if (!this.canPost) return;
      
      this.isPosting = true;
      
      try {
        const postData = {
          content: this.newPostContent.trim()
        };
        
        // If replying, add parent ID
        if (this.replyingTo) {
          postData.parentId = this.replyingTo.id;
        }
        
        const result = await this.createChirperPost(postData);
        
        if (result.success) {
          this.closeCreatePost();
          
          // Reload feed or thread
          if (this.currentView === 'thread' && this.replyingTo) {
            await this.viewThread(this.replyingTo);
          } else {
            await this.loadFeed();
          }
          
          // Show notification
          this.$store.dispatch('phone/showNotification', {
            type: 'success',
            title: 'Posted',
            message: this.replyingTo ? 'Your reply has been posted' : 'Your chirp has been posted'
          });
        }
      } catch (error) {
        console.error('Create post error:', error);
      } finally {
        this.isPosting = false;
      }
    },
    
    closeCreatePost() {
      this.showCreatePost = false;
      this.newPostContent = '';
      this.charCount = 0;
      this.replyingTo = null;
    },
    
    updateCharCount() {
      this.charCount = this.newPostContent.length;
    },
    
    filterByHashtag(hashtag) {
      this.hashtagFilter = hashtag;
      this.page = 0;
      this.hasMore = true;
    },
    
    goBack() {
      if (this.currentView === 'thread') {
        this.currentView = 'feed';
        this.currentThread = null;
      }
    },
    
    getInitials(name) {
      if (!name) return '?';
      const parts = name.split(' ');
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      return name.substring(0, 2).toUpperCase();
    },
    
    formatTime(timestamp) {
      if (!timestamp) return '';
      const date = new Date(timestamp);
      const now = new Date();
      const diffMs = now - date;
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMs / 3600000);
      const diffDays = Math.floor(diffMs / 86400000);
      
      if (diffMins < 1) return 'Just now';
      if (diffMins < 60) return `${diffMins}m`;
      if (diffHours < 24) return `${diffHours}h`;
      if (diffDays < 7) return `${diffDays}d`;
      
      return date.toLocaleDateString();
    },
    
    formatCount(count) {
      if (!count) return '';
      if (count < 1000) return count.toString();
      if (count < 1000000) return (count / 1000).toFixed(1) + 'K';
      return (count / 1000000).toFixed(1) + 'M';
    },
    
    formatContent(content) {
      if (!content) return '';
      
      // Convert hashtags to clickable links
      let formatted = content.replace(/#(\w+)/g, '<span class="hashtag">#$1</span>');
      
      // Convert mentions to clickable links
      formatted = formatted.replace(/@(\w+)/g, '<span class="mention">@$1</span>');
      
      // Convert URLs to clickable links
      formatted = formatted.replace(
        /(https?:\/\/[^\s]+)/g, 
        '<a href="$1" target="_blank" class="link">$1</a>'
      );
      
      return formatted;
    }
  }
};
</script>

<style scoped>
.chirper-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--background-color);
}

.chirper-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: var(--card-background);
  border-bottom: 1px solid var(--border-color);
}

.header-left {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.header-left h1 {
  font-size: 1.5rem;
  font-weight: 600;
  margin: 0;
  color: #1DA1F2;
}

.header-right {
  display: flex;
  gap: 0.5rem;
}

.back-btn, .create-btn, .close-btn, .refresh-btn {
  background: none;
  border: none;
  color: var(--primary-color);
  font-size: 1.25rem;
  cursor: pointer;
  padding: 0.5rem;
}

.create-btn {
  color: #1DA1F2;
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: var(--text-color);
  opacity: 0.6;
}

.loading i {
  font-size: 2rem;
  margin-bottom: 1rem;
}

.feed-layout {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.feed-container {
  flex: 1;
  overflow-y: auto;
  border-right: 1px solid var(--border-color);
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem 1rem;
  color: var(--text-color);
  opacity: 0.6;
}

.empty-state i {
  font-size: 3rem;
  margin-bottom: 1rem;
  color: #1DA1F2;
}

.empty-state .hint {
  font-size: 0.9rem;
  margin-top: 0.5rem;
}

.post-item {
  background: var(--card-background);
  border-bottom: 1px solid var(--border-color);
  padding: 1rem;
  cursor: pointer;
  transition: background 0.2s;
}

.post-item:hover {
  background: var(--background-color);
}

.post-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.author-info {
  display: flex;
  gap: 0.75rem;
  align-items: center;
}

.author-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #1DA1F2 0%, #0d8bd9 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 600;
  color: white;
  flex-shrink: 0;
}

.author-details {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.author-name {
  font-weight: 600;
  color: var(--text-color);
}

.post-time {
  font-size: 0.85rem;
  color: var(--text-color);
  opacity: 0.6;
}

.post-content {
  color: var(--text-color);
  line-height: 1.5;
  margin-bottom: 0.75rem;
}

.post-content p {
  margin: 0;
  word-wrap: break-word;
}

.post-content :deep(.hashtag) {
  color: #1DA1F2;
  font-weight: 500;
  cursor: pointer;
}

.post-content :deep(.mention) {
  color: #1DA1F2;
  font-weight: 500;
  cursor: pointer;
}

.post-content :deep(.link) {
  color: #1DA1F2;
  text-decoration: none;
}

.post-content :deep(.link):hover {
  text-decoration: underline;
}

.post-actions {
  display: flex;
  gap: 2rem;
  padding-top: 0.5rem;
}

.action-btn {
  background: none;
  border: none;
  color: var(--text-color);
  opacity: 0.6;
  font-size: 1rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  transition: all 0.2s;
}

.action-btn:hover {
  opacity: 1;
}

.action-btn span {
  font-size: 0.9rem;
}

.reply-btn:hover {
  color: #1DA1F2;
}

.repost-btn:hover {
  color: #17BF63;
}

.repost-btn.reposted {
  color: #17BF63;
  opacity: 1;
}

.like-btn:hover {
  color: #E0245E;
}

.like-btn.liked {
  color: #E0245E;
  opacity: 1;
}

/* Trending Sidebar */
.trending-sidebar {
  width: 300px;
  background: var(--card-background);
  overflow-y: auto;
  flex-shrink: 0;
}

.trending-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid var(--border-color);
}

.trending-header h3 {
  margin: 0;
  font-size: 1.25rem;
  color: var(--text-color);
}

.no-trending {
  padding: 2rem 1rem;
  text-align: center;
  color: var(--text-color);
  opacity: 0.6;
}

.trending-list {
  padding: 0.5rem 0;
}

.trending-item {
  display: flex;
  gap: 1rem;
  padding: 1rem;
  cursor: pointer;
  transition: background 0.2s;
}

.trending-item:hover {
  background: var(--background-color);
}

.trending-rank {
  font-size: 1.25rem;
  font-weight: 600;
  color: #1DA1F2;
  width: 30px;
  text-align: center;
}

.trending-info {
  flex: 1;
}

.trending-hashtag {
  font-weight: 600;
  color: var(--text-color);
  margin-bottom: 0.25rem;
}

.trending-count {
  font-size: 0.85rem;
  color: var(--text-color);
  opacity: 0.6;
}

/* Thread View */
.thread-view {
  flex: 1;
  overflow-y: auto;
}

.thread-container {
  max-width: 600px;
  margin: 0 auto;
}

.main-post {
  background: var(--card-background);
  border-bottom: 2px solid var(--border-color);
  padding: 1.5rem;
}

.replies-section {
  padding: 1rem;
}

.replies-section h3 {
  margin: 0 0 1rem;
  padding: 0 0.5rem;
  color: var(--text-color);
  font-size: 1rem;
}

.no-replies {
  text-align: center;
  padding: 2rem 1rem;
  color: var(--text-color);
  opacity: 0.6;
}

.reply-item {
  background: var(--card-background);
  border-bottom: 1px solid var(--border-color);
  padding: 1rem;
}

.reply-header {
  margin-bottom: 0.75rem;
}

.reply-content {
  color: var(--text-color);
  line-height: 1.5;
  margin-bottom: 0.75rem;
  padding-left: 3rem;
}

.reply-content p {
  margin: 0;
  word-wrap: break-word;
}

.reply-actions {
  display: flex;
  gap: 2rem;
  padding-left: 3rem;
}

/* Dialogs */
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}

.create-post-dialog {
  background: var(--card-background);
  border-radius: 12px;
  padding: 1.5rem;
  min-width: 500px;
  max-width: 90%;
}

.dialog-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.dialog-header h3 {
  margin: 0;
  color: var(--text-color);
}

.dialog-content {
  margin-bottom: 1rem;
}

.replying-to {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem;
  background: var(--background-color);
  border-radius: 8px;
  margin-bottom: 1rem;
  color: var(--text-color);
  opacity: 0.8;
}

.replying-to i {
  color: #1DA1F2;
}

.post-input {
  width: 100%;
  min-height: 120px;
  padding: 0.75rem;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  background: var(--background-color);
  color: var(--text-color);
  font-family: inherit;
  font-size: 1rem;
  resize: vertical;
}

.post-meta {
  display: flex;
  justify-content: flex-end;
  margin-top: 0.5rem;
}

.char-count {
  font-size: 0.85rem;
  color: var(--text-color);
  opacity: 0.6;
}

.char-count.warning {
  color: #FFAD1F;
  opacity: 1;
}

.char-count.error {
  color: #E0245E;
  opacity: 1;
  font-weight: 600;
}

.dialog-actions {
  display: flex;
  gap: 0.5rem;
  justify-content: flex-end;
}

.cancel-btn, .post-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 20px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s;
}

.cancel-btn {
  background: var(--border-color);
  color: var(--text-color);
}

.post-btn {
  background: #1DA1F2;
  color: white;
}

.post-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Mobile Responsive */
@media (max-width: 768px) {
  .feed-layout {
    flex-direction: column;
  }
  
  .trending-sidebar {
    width: 100%;
    max-height: 200px;
    border-right: none;
    border-top: 1px solid var(--border-color);
  }
  
  .create-post-dialog {
    min-width: 90%;
  }
}
</style>
