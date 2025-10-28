<template>
  <div class="shotz-app">
    <!-- Header -->
    <div class="shotz-header">
      <div class="header-left">
        <button v-if="currentView !== 'feed'" @click="goBack" class="back-btn">
          <i class="fas fa-arrow-left"></i>
        </button>
        <h1>{{ headerTitle }}</h1>
      </div>
      <div class="header-right">
        <button v-if="currentView === 'feed'" @click="showCreatePost = true" class="create-btn">
          <i class="fas fa-plus"></i>
        </button>
        <button v-if="currentView === 'feed'" @click="currentView = 'profile'" class="profile-btn">
          <i class="fas fa-user"></i>
        </button>
      </div>
    </div>

    <!-- Tab Navigation -->
    <div v-if="currentView === 'feed'" class="tabs">
      <button 
        :class="['tab', { active: activeTab === 'following' }]" 
        @click="activeTab = 'following'"
      >
        Following
      </button>
      <button 
        :class="['tab', { active: activeTab === 'trending' }]" 
        @click="activeTab = 'trending'"
      >
        Trending
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Loading posts...</p>
    </div>

    <!-- Feed View -->
    <div v-else-if="currentView === 'feed'" class="feed-container" @scroll="handleScroll">
      <div v-if="currentFeed.length === 0" class="empty-state">
        <i class="fas fa-camera"></i>
        <p>No posts yet</p>
        <p class="hint">Be the first to share something!</p>
      </div>

      <div 
        v-for="post in currentFeed" 
        :key="post.id" 
        class="post-item"
        @click="viewPost(post)"
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
          <div v-if="post.is_live" class="live-badge">
            <i class="fas fa-circle"></i> LIVE
          </div>
        </div>

        <!-- Post Media -->
        <div class="post-media">
          <img 
            v-if="post.media_type === 'photo'" 
            :src="post.media_url" 
            :alt="'Post ' + post.id"
            loading="lazy"
          />
          <video 
            v-else-if="post.media_type === 'video'" 
            :src="post.media_url"
            :poster="post.thumbnail_url"
            loop
            muted
            playsinline
          ></video>
        </div>

        <!-- Post Caption -->
        <div v-if="post.caption" class="post-caption">
          <span class="author-name">{{ post.author_name }}</span>
          {{ post.caption }}
        </div>

        <!-- Post Actions -->
        <div class="post-actions">
          <button 
            :class="['action-btn', 'like-btn', { liked: post.isLiked }]"
            @click.stop="handleLike(post.id)"
          >
            <i :class="post.isLiked ? 'fas fa-heart' : 'far fa-heart'"></i>
          </button>
          <button class="action-btn comment-btn" @click.stop="viewPost(post)">
            <i class="far fa-comment"></i>
          </button>
          <button class="action-btn share-btn" @click.stop="sharePost(post)">
            <i class="far fa-paper-plane"></i>
          </button>
        </div>

        <!-- Post Stats -->
        <div class="post-stats">
          <span class="likes-count">{{ formatCount(post.likes) }} likes</span>
          <span v-if="post.comments > 0" class="comments-count">
            {{ formatCount(post.comments) }} comments
          </span>
        </div>
      </div>
    </div>

    <!-- Profile View -->
    <div v-else-if="currentView === 'profile'" class="profile-view">
      <div class="profile-header">
        <div class="profile-avatar">
          {{ getInitials(profile.name) }}
        </div>
        <div class="profile-stats">
          <div class="stat">
            <div class="stat-value">{{ formatCount(myPosts.length) }}</div>
            <div class="stat-label">Posts</div>
          </div>
          <div class="stat">
            <div class="stat-value">{{ formatCount(profile.followers) }}</div>
            <div class="stat-label">Followers</div>
          </div>
          <div class="stat">
            <div class="stat-value">{{ formatCount(profile.following) }}</div>
            <div class="stat-label">Following</div>
          </div>
        </div>
      </div>

      <div class="profile-info">
        <h2>{{ profile.name }}</h2>
        <p v-if="profile.bio" class="profile-bio">{{ profile.bio }}</p>
      </div>

      <!-- My Posts Grid -->
      <div class="posts-grid">
        <div 
          v-for="post in myPosts" 
          :key="post.id" 
          class="grid-post"
          @click="viewPost(post)"
        >
          <img 
            v-if="post.media_type === 'photo'" 
            :src="post.thumbnail_url || post.media_url" 
            :alt="'Post ' + post.id"
          />
          <video 
            v-else-if="post.media_type === 'video'" 
            :src="post.media_url"
            :poster="post.thumbnail_url"
          ></video>
          <div v-if="post.is_live" class="live-overlay">
            <i class="fas fa-circle"></i> LIVE
          </div>
        </div>

        <div v-if="myPosts.length === 0" class="empty-state">
          <i class="fas fa-camera"></i>
          <p>No posts yet</p>
        </div>
      </div>
    </div>

    <!-- Post Detail View -->
    <div v-else-if="currentView === 'detail' && currentPost" class="post-detail">
      <div class="detail-media">
        <img 
          v-if="currentPost.media_type === 'photo'" 
          :src="currentPost.media_url" 
          :alt="'Post ' + currentPost.id"
        />
        <video 
          v-else-if="currentPost.media_type === 'video'" 
          :src="currentPost.media_url"
          controls
          autoplay
          loop
        ></video>
      </div>

      <div class="detail-content">
        <!-- Post Header -->
        <div class="post-header">
          <div class="author-info">
            <div class="author-avatar">
              {{ getInitials(currentPost.author_name) }}
            </div>
            <div class="author-details">
              <div class="author-name">{{ currentPost.author_name }}</div>
              <div class="post-time">{{ formatTime(currentPost.created_at) }}</div>
            </div>
          </div>
        </div>

        <!-- Caption -->
        <div v-if="currentPost.caption" class="detail-caption">
          <span class="author-name">{{ currentPost.author_name }}</span>
          {{ currentPost.caption }}
        </div>

        <!-- Comments Section -->
        <div class="comments-section">
          <h3>Comments</h3>
          <div v-if="currentComments.length === 0" class="no-comments">
            No comments yet. Be the first to comment!
          </div>
          <div v-else class="comments-list">
            <div v-for="comment in currentComments" :key="comment.id" class="comment-item">
              <div class="comment-avatar">
                {{ getInitials(comment.author_name) }}
              </div>
              <div class="comment-content">
                <span class="comment-author">{{ comment.author_name }}</span>
                <p>{{ comment.content }}</p>
                <span class="comment-time">{{ formatTime(comment.created_at) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Comment Input -->
        <div class="comment-input-container">
          <input 
            v-model="newComment" 
            type="text" 
            placeholder="Add a comment..."
            @keyup.enter="postComment"
            :disabled="isPostingComment"
          />
          <button 
            @click="postComment" 
            :disabled="!newComment.trim() || isPostingComment"
            class="post-comment-btn"
          >
            Post
          </button>
        </div>
      </div>
    </div>

    <!-- Create Post Dialog -->
    <div v-if="showCreatePost" class="dialog-overlay" @click.self="showCreatePost = false">
      <div class="create-post-dialog">
        <div class="dialog-header">
          <h3>Create Post</h3>
          <button @click="showCreatePost = false" class="close-btn">
            <i class="fas fa-times"></i>
          </button>
        </div>

        <div class="dialog-content">
          <!-- Media Selection -->
          <div v-if="!selectedMedia" class="media-selector">
            <button @click="selectFromGallery" class="select-media-btn">
              <i class="fas fa-images"></i>
              <span>Select from Gallery</span>
            </button>
            <button @click="openCamera" class="select-media-btn">
              <i class="fas fa-camera"></i>
              <span>Take Photo/Video</span>
            </button>
          </div>

          <!-- Selected Media Preview -->
          <div v-else class="media-preview">
            <img 
              v-if="selectedMedia.type === 'photo'" 
              :src="selectedMedia.url" 
              alt="Selected media"
            />
            <video 
              v-else-if="selectedMedia.type === 'video'" 
              :src="selectedMedia.url"
              controls
            ></video>
            <button @click="selectedMedia = null" class="change-media-btn">
              Change Media
            </button>
          </div>

          <!-- Caption Input -->
          <textarea 
            v-model="newPostCaption" 
            placeholder="Write a caption..."
            maxlength="500"
            class="caption-input"
          ></textarea>
          <div class="char-count">{{ newPostCaption.length }}/500</div>

          <!-- Live Stream Option -->
          <div class="live-stream-option">
            <label>
              <input type="checkbox" v-model="isLiveStream" />
              <span>Start Live Stream</span>
            </label>
          </div>
        </div>

        <div class="dialog-actions">
          <button @click="showCreatePost = false" class="cancel-btn">Cancel</button>
          <button 
            @click="createPost" 
            class="post-btn"
            :disabled="!canPost || isPosting"
          >
            {{ isPosting ? 'Posting...' : (isLiveStream ? 'Go Live' : 'Post') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Share Sheet -->
    <div v-if="showShareSheet" class="dialog-overlay" @click.self="showShareSheet = false">
      <div class="share-sheet">
        <h3>Share Post</h3>
        <div class="share-options">
          <button @click="shareToApp('messages')" class="share-option">
            <i class="fas fa-comment"></i>
            <span>Messages</span>
          </button>
          <button @click="shareToApp('chirper')" class="share-option">
            <i class="fas fa-bird"></i>
            <span>Chirper</span>
          </button>
          <button @click="copyLink" class="share-option">
            <i class="fas fa-link"></i>
            <span>Copy Link</span>
          </button>
        </div>
        <button @click="showShareSheet = false" class="cancel-btn">Cancel</button>
      </div>
    </div>

    <!-- Gallery Selector -->
    <div v-if="showGallerySelector" class="dialog-overlay" @click.self="showGallerySelector = false">
      <div class="gallery-selector">
        <div class="dialog-header">
          <h3>Select Media</h3>
          <button @click="showGallerySelector = false" class="close-btn">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="gallery-grid">
          <div 
            v-for="media in galleryMedia" 
            :key="media.id" 
            class="gallery-item"
            @click="selectMedia(media)"
          >
            <img 
              v-if="media.media_type === 'photo'" 
              :src="media.thumbnail_url || media.file_url" 
              alt="Gallery item"
            />
            <video 
              v-else-if="media.media_type === 'video'" 
              :src="media.file_url"
              :poster="media.thumbnail_url"
            ></video>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapGetters, mapActions } from 'vuex';

export default {
  name: 'Shotz',
  
  data() {
    return {
      currentView: 'feed', // 'feed', 'profile', 'detail'
      activeTab: 'following', // 'following', 'trending'
      currentPost: null,
      currentComments: [],
      newComment: '',
      isPostingComment: false,
      showCreatePost: false,
      showShareSheet: false,
      showGallerySelector: false,
      selectedMedia: null,
      newPostCaption: '',
      isLiveStream: false,
      isPosting: false,
      postToShare: null,
      page: 0,
      pageSize: 20,
      hasMore: true,
      isLoadingMore: false
    };
  },
  
  computed: {
    ...mapState('shotz', ['feed', 'myPosts', 'profile', 'loading']),
    ...mapState('media', { galleryMedia: 'photos' }),
    
    headerTitle() {
      if (this.currentView === 'profile') return 'Profile';
      if (this.currentView === 'detail') return 'Post';
      return 'Shotz';
    },
    
    currentFeed() {
      if (this.activeTab === 'following') {
        return this.feed.filter(post => post.isFollowing);
      } else {
        return this.feed;
      }
    },
    
    canPost() {
      return this.selectedMedia !== null && !this.isPosting;
    }
  },
  
  mounted() {
    this.loadFeed();
    this.loadProfile();
    this.loadGalleryMedia();
  },
  
  methods: {
    ...mapActions('shotz', [
      'fetchFeed',
      'fetchMyPosts',
      'fetchProfile',
      'createShotzPost',
      'likePost',
      'commentOnPost',
      'fetchComments',
      'sharePost',
      'startLiveStream',
      'endLiveStream'
    ]),
    ...mapActions('media', ['fetchMedia']),
    
    async loadFeed() {
      await this.fetchFeed({ limit: this.pageSize, offset: this.page * this.pageSize });
    },
    
    async loadProfile() {
      await this.fetchProfile();
      await this.fetchMyPosts();
    },
    
    async loadGalleryMedia() {
      await this.fetchMedia({ mediaType: null, limit: 100, offset: 0 });
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
    
    async viewPost(post) {
      this.currentPost = post;
      this.currentView = 'detail';
      
      // Load comments
      const comments = await this.fetchComments(post.id);
      this.currentComments = comments || [];
    },
    
    async handleLike(postId) {
      await this.likePost(postId);
    },
    
    async postComment() {
      if (!this.newComment.trim() || this.isPostingComment) return;
      
      this.isPostingComment = true;
      
      try {
        const result = await this.commentOnPost({
          postId: this.currentPost.id,
          content: this.newComment.trim()
        });
        
        if (result.success) {
          this.currentComments.push(result.data);
          this.newComment = '';
        }
      } catch (error) {
        console.error('Post comment error:', error);
      } finally {
        this.isPostingComment = false;
      }
    },
    
    selectFromGallery() {
      this.showGallerySelector = true;
    },
    
    selectMedia(media) {
      this.selectedMedia = {
        id: media.id,
        url: media.file_url,
        type: media.media_type,
        thumbnail: media.thumbnail_url
      };
      this.showGallerySelector = false;
    },
    
    openCamera() {
      // Navigate to camera app
      this.$router.push({ name: 'Camera' });
      this.showCreatePost = false;
    },
    
    async createPost() {
      if (!this.canPost) return;
      
      this.isPosting = true;
      
      try {
        const postData = {
          mediaId: this.selectedMedia.id,
          caption: this.newPostCaption.trim(),
          isLive: this.isLiveStream
        };
        
        const result = await this.createShotzPost(postData);
        
        if (result.success) {
          this.showCreatePost = false;
          this.selectedMedia = null;
          this.newPostCaption = '';
          this.isLiveStream = false;
          
          // Reload feed
          await this.loadFeed();
          
          // Show notification
          this.$store.dispatch('phone/showNotification', {
            type: 'success',
            title: 'Post Created',
            message: this.isLiveStream ? 'You are now live!' : 'Your post has been published'
          });
        }
      } catch (error) {
        console.error('Create post error:', error);
      } finally {
        this.isPosting = false;
      }
    },
    
    sharePost(post) {
      this.postToShare = post;
      this.showShareSheet = true;
    },
    
    async shareToApp(appName) {
      if (!this.postToShare) return;
      
      if (appName === 'messages') {
        this.$router.push({
          name: 'Messages',
          params: {
            shareContent: {
              type: 'shotz_post',
              postId: this.postToShare.id,
              preview: this.postToShare.media_url
            }
          }
        });
      } else if (appName === 'chirper') {
        this.$router.push({
          name: 'Chirper',
          params: {
            shareContent: {
              type: 'shotz_post',
              postId: this.postToShare.id,
              text: `Check out this post on Shotz!`
            }
          }
        });
      }
      
      this.showShareSheet = false;
      this.postToShare = null;
    },
    
    copyLink() {
      if (!this.postToShare) return;
      
      // Copy post link to clipboard
      const link = `shotz://post/${this.postToShare.id}`;
      navigator.clipboard.writeText(link);
      
      this.$store.dispatch('phone/showNotification', {
        type: 'success',
        title: 'Link Copied',
        message: 'Post link copied to clipboard'
      });
      
      this.showShareSheet = false;
      this.postToShare = null;
    },
    
    goBack() {
      if (this.currentView === 'detail') {
        this.currentView = 'feed';
        this.currentPost = null;
        this.currentComments = [];
      } else if (this.currentView === 'profile') {
        this.currentView = 'feed';
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
      if (diffMins < 60) return `${diffMins}m ago`;
      if (diffHours < 24) return `${diffHours}h ago`;
      if (diffDays < 7) return `${diffDays}d ago`;
      
      return date.toLocaleDateString();
    },
    
    formatCount(count) {
      if (!count) return '0';
      if (count < 1000) return count.toString();
      if (count < 1000000) return (count / 1000).toFixed(1) + 'K';
      return (count / 1000000).toFixed(1) + 'M';
    }
  }
};
</script>

<style scoped>
.shotz-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--background-color);
}

.shotz-header {
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
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.header-right {
  display: flex;
  gap: 0.5rem;
}

.back-btn, .create-btn, .profile-btn, .close-btn {
  background: none;
  border: none;
  color: var(--primary-color);
  font-size: 1.25rem;
  cursor: pointer;
  padding: 0.5rem;
}

.tabs {
  display: flex;
  background: var(--card-background);
  border-bottom: 1px solid var(--border-color);
}

.tab {
  flex: 1;
  padding: 0.75rem;
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  color: var(--text-color);
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s;
}

.tab.active {
  border-bottom-color: var(--primary-color);
  color: var(--primary-color);
  font-weight: 600;
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

.feed-container {
  flex: 1;
  overflow-y: auto;
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
}

.empty-state .hint {
  font-size: 0.9rem;
  margin-top: 0.5rem;
}

.post-item {
  background: var(--card-background);
  margin-bottom: 1rem;
  cursor: pointer;
}

.post-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
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
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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

.live-badge {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.25rem 0.75rem;
  background: #ff3b30;
  color: white;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 600;
}

.live-badge i {
  animation: pulse 1.5s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.post-media {
  width: 100%;
  aspect-ratio: 1;
  background: black;
  overflow: hidden;
}

.post-media img,
.post-media video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.post-caption {
  padding: 0.75rem 1rem;
  color: var(--text-color);
  line-height: 1.5;
}

.post-caption .author-name {
  font-weight: 600;
  margin-right: 0.5rem;
}

.post-actions {
  display: flex;
  gap: 1rem;
  padding: 0.5rem 1rem;
}

.action-btn {
  background: none;
  border: none;
  color: var(--text-color);
  font-size: 1.5rem;
  cursor: pointer;
  transition: transform 0.2s;
}

.action-btn:active {
  transform: scale(0.9);
}

.like-btn.liked {
  color: #ff3b30;
}

.post-stats {
  padding: 0 1rem 1rem;
  display: flex;
  gap: 1rem;
  font-size: 0.9rem;
  color: var(--text-color);
  opacity: 0.8;
}

/* Profile View */
.profile-view {
  flex: 1;
  overflow-y: auto;
}

.profile-header {
  padding: 2rem 1rem;
  background: var(--card-background);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
}

.profile-avatar {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  font-weight: 600;
  color: white;
}

.profile-stats {
  display: flex;
  gap: 2rem;
}

.stat {
  text-align: center;
}

.stat-value {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--text-color);
}

.stat-label {
  font-size: 0.85rem;
  color: var(--text-color);
  opacity: 0.6;
  margin-top: 0.25rem;
}

.profile-info {
  padding: 1rem;
  text-align: center;
}

.profile-info h2 {
  margin: 0 0 0.5rem;
  color: var(--text-color);
}

.profile-bio {
  color: var(--text-color);
  opacity: 0.8;
  margin: 0;
}

.posts-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 2px;
  padding: 2px;
}

.grid-post {
  position: relative;
  aspect-ratio: 1;
  cursor: pointer;
  overflow: hidden;
}

.grid-post img,
.grid-post video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.live-overlay {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.25rem 0.5rem;
  background: #ff3b30;
  color: white;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 600;
}

/* Post Detail View */
.post-detail {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.detail-media {
  width: 100%;
  aspect-ratio: 1;
  background: black;
  overflow: hidden;
}

.detail-media img,
.detail-media video {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.detail-content {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
}

.detail-caption {
  padding: 1rem;
  color: var(--text-color);
  line-height: 1.5;
  border-bottom: 1px solid var(--border-color);
}

.detail-caption .author-name {
  font-weight: 600;
  margin-right: 0.5rem;
}

.comments-section {
  flex: 1;
  padding: 1rem;
  overflow-y: auto;
}

.comments-section h3 {
  margin: 0 0 1rem;
  color: var(--text-color);
  font-size: 1rem;
}

.no-comments {
  text-align: center;
  padding: 2rem 1rem;
  color: var(--text-color);
  opacity: 0.6;
}

.comments-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.comment-item {
  display: flex;
  gap: 0.75rem;
}

.comment-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  color: white;
  flex-shrink: 0;
}

.comment-content {
  flex: 1;
}

.comment-author {
  font-weight: 600;
  color: var(--text-color);
  margin-right: 0.5rem;
}

.comment-content p {
  margin: 0.25rem 0;
  color: var(--text-color);
}

.comment-time {
  font-size: 0.75rem;
  color: var(--text-color);
  opacity: 0.6;
}

.comment-input-container {
  display: flex;
  gap: 0.5rem;
  padding: 1rem;
  border-top: 1px solid var(--border-color);
  background: var(--card-background);
}

.comment-input-container input {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid var(--border-color);
  border-radius: 20px;
  background: var(--background-color);
  color: var(--text-color);
  font-size: 0.9rem;
}

.post-comment-btn {
  padding: 0.75rem 1.5rem;
  background: var(--primary-color);
  color: white;
  border: none;
  border-radius: 20px;
  font-weight: 600;
  cursor: pointer;
}

.post-comment-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
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

.create-post-dialog, .share-sheet, .gallery-selector {
  background: var(--card-background);
  border-radius: 12px;
  padding: 1.5rem;
  min-width: 300px;
  max-width: 90%;
  max-height: 80%;
  overflow-y: auto;
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

.media-selector {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.select-media-btn {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: var(--background-color);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  color: var(--text-color);
  cursor: pointer;
  transition: background 0.2s;
}

.select-media-btn:hover {
  background: var(--border-color);
}

.select-media-btn i {
  font-size: 1.5rem;
  color: var(--primary-color);
}

.media-preview {
  position: relative;
  margin-bottom: 1rem;
}

.media-preview img,
.media-preview video {
  width: 100%;
  border-radius: 8px;
}

.change-media-btn {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  padding: 0.5rem 1rem;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.caption-input {
  width: 100%;
  min-height: 100px;
  padding: 0.75rem;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  background: var(--background-color);
  color: var(--text-color);
  font-family: inherit;
  font-size: 0.9rem;
  resize: vertical;
}

.char-count {
  text-align: right;
  font-size: 0.85rem;
  color: var(--text-color);
  opacity: 0.6;
  margin-top: 0.5rem;
}

.live-stream-option {
  margin-top: 1rem;
}

.live-stream-option label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--text-color);
  cursor: pointer;
}

.dialog-actions {
  display: flex;
  gap: 0.5rem;
  justify-content: flex-end;
}

.cancel-btn, .post-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: opacity 0.2s;
}

.cancel-btn {
  background: var(--border-color);
  color: var(--text-color);
}

.post-btn {
  background: var(--primary-color);
  color: white;
}

.post-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.share-options {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
}

.share-option {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem;
  background: var(--background-color);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.2s;
}

.share-option:hover {
  background: var(--border-color);
}

.share-option i {
  font-size: 1.5rem;
  color: var(--primary-color);
}

.share-option span {
  font-size: 0.9rem;
  color: var(--text-color);
}

.gallery-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 4px;
  max-height: 400px;
  overflow-y: auto;
}

.gallery-item {
  aspect-ratio: 1;
  cursor: pointer;
  overflow: hidden;
  border-radius: 4px;
}

.gallery-item img,
.gallery-item video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
</style>
