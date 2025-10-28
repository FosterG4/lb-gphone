<template>
  <div class="modish-app">
    <!-- Header (only visible when not viewing video) -->
    <div v-if="!isViewingVideo" class="modish-header">
      <div class="header-left">
        <h1>Modish</h1>
      </div>
      <div class="header-right">
        <button @click="showCreateVideo = true" class="create-btn">
          <i class="fas fa-plus"></i>
        </button>
        <button @click="currentView = 'profile'" class="profile-btn">
          <i class="fas fa-user"></i>
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Loading videos...</p>
    </div>

    <!-- Video Feed (Vertical Scroll) -->
    <div v-else-if="currentView === 'feed'" class="video-feed" @scroll="handleScroll">
      <div v-if="feed.length === 0" class="empty-state">
        <i class="fas fa-video"></i>
        <p>No videos yet</p>
        <p class="hint">Be the first to create a video!</p>
      </div>

      <div 
        v-for="(video, index) in feed" 
        :key="video.id" 
        class="video-item"
        :class="{ active: currentVideoIndex === index }"
        @click="playVideo(index)"
      >
        <video 
          :ref="`video-${index}`"
          :src="video.media_url"
          :poster="video.thumbnail_url"
          loop
          playsinline
          @ended="nextVideo"
        ></video>

        <!-- Video Overlay Info -->
        <div class="video-overlay">
          <!-- Author Info -->
          <div class="author-section">
            <div class="author-avatar">
              {{ getInitials(video.author_name) }}
            </div>
            <div class="author-name">{{ video.author_name }}</div>
          </div>

          <!-- Caption -->
          <div v-if="video.caption" class="video-caption">
            {{ video.caption }}
          </div>

          <!-- Music Track -->
          <div v-if="video.music_track" class="music-info">
            <i class="fas fa-music"></i>
            <span>{{ video.music_track }}</span>
          </div>
        </div>

        <!-- Action Buttons (Right Side) -->
        <div class="action-buttons">
          <button 
            :class="['action-btn', 'like-btn', { liked: video.isLiked }]"
            @click.stop="handleLike(video.id)"
          >
            <i :class="video.isLiked ? 'fas fa-heart' : 'far fa-heart'"></i>
            <span>{{ formatCount(video.likes) }}</span>
          </button>

          <button class="action-btn comment-btn" @click.stop="showComments(video)">
            <i class="far fa-comment"></i>
            <span>{{ formatCount(video.comments) }}</span>
          </button>

          <button class="action-btn share-btn" @click.stop="shareVideo(video)">
            <i class="far fa-paper-plane"></i>
            <span>Share</span>
          </button>

          <button class="action-btn views-btn">
            <i class="far fa-eye"></i>
            <span>{{ formatCount(video.views) }}</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Profile View -->
    <div v-else-if="currentView === 'profile'" class="profile-view">
      <div class="profile-header">
        <button @click="currentView = 'feed'" class="back-btn">
          <i class="fas fa-arrow-left"></i>
        </button>
        <h2>My Videos</h2>
      </div>

      <div class="profile-stats">
        <div class="stat">
          <div class="stat-value">{{ formatCount(myVideos.length) }}</div>
          <div class="stat-label">Videos</div>
        </div>
        <div class="stat">
          <div class="stat-value">{{ formatCount(totalLikes) }}</div>
          <div class="stat-label">Likes</div>
        </div>
        <div class="stat">
          <div class="stat-value">{{ formatCount(totalViews) }}</div>
          <div class="stat-label">Views</div>
        </div>
      </div>

      <!-- My Videos Grid -->
      <div class="videos-grid">
        <div 
          v-for="video in myVideos" 
          :key="video.id" 
          class="grid-video"
          @click="viewMyVideo(video)"
        >
          <video 
            :src="video.media_url"
            :poster="video.thumbnail_url"
          ></video>
          <div class="video-stats">
            <span><i class="fas fa-heart"></i> {{ formatCount(video.likes) }}</span>
            <span><i class="fas fa-eye"></i> {{ formatCount(video.views) }}</span>
          </div>
        </div>

        <div v-if="myVideos.length === 0" class="empty-state">
          <i class="fas fa-video"></i>
          <p>No videos yet</p>
        </div>
      </div>
    </div>

    <!-- Create Video Dialog -->
    <div v-if="showCreateVideo" class="dialog-overlay" @click.self="showCreateVideo = false">
      <div class="create-video-dialog">
        <div class="dialog-header">
          <h3>Create Video</h3>
          <button @click="showCreateVideo = false" class="close-btn">
            <i class="fas fa-times"></i>
          </button>
        </div>

        <div class="dialog-content">
          <!-- Video Selection -->
          <div v-if="!selectedVideo" class="video-selector">
            <button @click="selectFromGallery" class="select-video-btn">
              <i class="fas fa-video"></i>
              <span>Select from Gallery</span>
            </button>
            <button @click="recordVideo" class="select-video-btn">
              <i class="fas fa-camera"></i>
              <span>Record Video</span>
            </button>
          </div>

          <!-- Selected Video Preview -->
          <div v-else class="video-preview">
            <video 
              :src="selectedVideo.url"
              controls
            ></video>
            <button @click="selectedVideo = null" class="change-video-btn">
              Change Video
            </button>
          </div>

          <!-- Caption Input -->
          <textarea 
            v-model="newVideoCaption" 
            placeholder="Write a caption..."
            maxlength="500"
            class="caption-input"
          ></textarea>
          <div class="char-count">{{ newVideoCaption.length }}/500</div>

          <!-- Filter Selection -->
          <div class="filter-section">
            <label>Filter:</label>
            <select v-model="selectedFilter" class="filter-select">
              <option value="none">None</option>
              <option value="bw">Black & White</option>
              <option value="sepia">Sepia</option>
              <option value="vintage">Vintage</option>
              <option value="cool">Cool</option>
              <option value="warm">Warm</option>
              <option value="vibrant">Vibrant</option>
            </select>
          </div>

          <!-- TTS Voiceover -->
          <div class="tts-section">
            <label>
              <input type="checkbox" v-model="enableTTS" />
              <span>Add Text-to-Speech Voiceover</span>
            </label>
            <textarea 
              v-if="enableTTS"
              v-model="ttsText" 
              placeholder="Enter text for voiceover..."
              maxlength="200"
              class="tts-input"
            ></textarea>
          </div>

          <!-- Music Track Selection -->
          <div class="music-section">
            <label>Music Track:</label>
            <select v-model="selectedMusic" class="music-select">
              <option value="">None</option>
              <option value="track1">Upbeat Pop</option>
              <option value="track2">Chill Vibes</option>
              <option value="track3">Hip Hop Beat</option>
              <option value="track4">Electronic Dance</option>
              <option value="track5">Acoustic Guitar</option>
            </select>
          </div>
        </div>

        <div class="dialog-actions">
          <button @click="showCreateVideo = false" class="cancel-btn">Cancel</button>
          <button 
            @click="createVideo" 
            class="post-btn"
            :disabled="!canPost || isPosting"
          >
            {{ isPosting ? 'Posting...' : 'Post' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Comments Sheet -->
    <div v-if="showCommentsSheet" class="dialog-overlay" @click.self="showCommentsSheet = false">
      <div class="comments-sheet">
        <div class="sheet-header">
          <h3>Comments</h3>
          <button @click="showCommentsSheet = false" class="close-btn">
            <i class="fas fa-times"></i>
          </button>
        </div>

        <div class="comments-list">
          <div v-if="currentComments.length === 0" class="no-comments">
            No comments yet. Be the first to comment!
          </div>
          <div v-else>
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

    <!-- Share Sheet -->
    <div v-if="showShareSheet" class="dialog-overlay" @click.self="showShareSheet = false">
      <div class="share-sheet">
        <h3>Share Video</h3>
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
          <h3>Select Video</h3>
          <button @click="showGallerySelector = false" class="close-btn">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="gallery-grid">
          <div 
            v-for="video in galleryVideos" 
            :key="video.id" 
            class="gallery-item"
            @click="selectVideo(video)"
          >
            <video 
              :src="video.file_url"
              :poster="video.thumbnail_url"
            ></video>
            <div class="video-duration">{{ formatDuration(video.duration) }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex';

export default {
  name: 'Modish',
  
  data() {
    return {
      currentView: 'feed', // 'feed', 'profile'
      currentVideoIndex: 0,
      isViewingVideo: false,
      currentComments: [],
      newComment: '',
      isPostingComment: false,
      showCreateVideo: false,
      showCommentsSheet: false,
      showShareSheet: false,
      showGallerySelector: false,
      selectedVideo: null,
      newVideoCaption: '',
      selectedFilter: 'none',
      enableTTS: false,
      ttsText: '',
      selectedMusic: '',
      isPosting: false,
      videoToShare: null,
      page: 0,
      pageSize: 20,
      hasMore: true,
      isLoadingMore: false
    };
  },
  
  computed: {
    ...mapState('modish', ['feed', 'myVideos', 'loading']),
    ...mapState('media', { galleryVideos: state => state.videos || [] }),
    
    canPost() {
      return this.selectedVideo !== null && !this.isPosting;
    },

    totalLikes() {
      return this.myVideos.reduce((sum, video) => sum + (video.likes || 0), 0);
    },

    totalViews() {
      return this.myVideos.reduce((sum, video) => sum + (video.views || 0), 0);
    }
  },
  
  mounted() {
    this.loadFeed();
    this.loadGalleryVideos();
    
    // Auto-play first video
    if (this.feed.length > 0) {
      this.$nextTick(() => {
        this.playVideo(0);
      });
    }
  },
  
  beforeUnmount() {
    // Pause all videos
    this.pauseAllVideos();
  },
  
  methods: {
    ...mapActions('modish', [
      'fetchFeed',
      'fetchMyVideos',
      'createModishVideo',
      'likeVideo',
      'commentOnVideo',
      'fetchComments',
      'incrementViews'
    ]),
    ...mapActions('media', ['fetchMedia']),
    
    async loadFeed() {
      await this.fetchFeed({ limit: this.pageSize, offset: this.page * this.pageSize });
    },
    
    async loadGalleryVideos() {
      await this.fetchMedia({ mediaType: 'video', limit: 100, offset: 0 });
    },
    
    async handleScroll(event) {
      const { scrollTop, scrollHeight, clientHeight } = event.target;
      
      // Check if scrolled near bottom
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

      // Auto-play video when scrolled into view
      const videoItems = event.target.querySelectorAll('.video-item');
      videoItems.forEach((item, index) => {
        const rect = item.getBoundingClientRect();
        const isInView = rect.top >= 0 && rect.bottom <= window.innerHeight;
        
        if (isInView && this.currentVideoIndex !== index) {
          this.playVideo(index);
        }
      });
    },
    
    playVideo(index) {
      // Pause all videos first
      this.pauseAllVideos();
      
      this.currentVideoIndex = index;
      this.isViewingVideo = true;
      
      const videoRef = this.$refs[`video-${index}`];
      if (videoRef && videoRef[0]) {
        videoRef[0].play();
        
        // Increment view count
        const video = this.feed[index];
        if (video) {
          this.incrementViews(video.id);
        }
      }
    },
    
    pauseAllVideos() {
      Object.keys(this.$refs).forEach(key => {
        if (key.startsWith('video-')) {
          const videoRef = this.$refs[key];
          if (videoRef && videoRef[0]) {
            videoRef[0].pause();
          }
        }
      });
    },
    
    nextVideo() {
      if (this.currentVideoIndex < this.feed.length - 1) {
        this.playVideo(this.currentVideoIndex + 1);
        
        // Scroll to next video
        const nextItem = document.querySelectorAll('.video-item')[this.currentVideoIndex];
        if (nextItem) {
          nextItem.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      }
    },

    async handleLike(videoId) {
      await this.likeVideo(videoId);
    },
    
    async showComments(video) {
      this.showCommentsSheet = true;
      this.currentComments = await this.fetchComments(video.id) || [];
    },
    
    async postComment() {
      if (!this.newComment.trim() || this.isPostingComment) return;
      
      this.isPostingComment = true;
      
      try {
        const video = this.feed[this.currentVideoIndex];
        const result = await this.commentOnVideo({
          videoId: video.id,
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
    
    selectVideo(video) {
      this.selectedVideo = {
        id: video.id,
        url: video.file_url,
        thumbnail: video.thumbnail_url,
        duration: video.duration
      };
      this.showGallerySelector = false;
    },
    
    recordVideo() {
      // Navigate to camera app in video mode
      this.$router.push({ name: 'Camera', params: { mode: 'video' } });
      this.showCreateVideo = false;
    },
    
    async createVideo() {
      if (!this.canPost) return;
      
      this.isPosting = true;
      
      try {
        const videoData = {
          mediaId: this.selectedVideo.id,
          caption: this.newVideoCaption.trim(),
          filters: this.selectedFilter !== 'none' ? { filter: this.selectedFilter } : null,
          tts: this.enableTTS ? { text: this.ttsText.trim() } : null,
          music: this.selectedMusic || null
        };
        
        const result = await this.createModishVideo(videoData);
        
        if (result.success) {
          this.showCreateVideo = false;
          this.resetCreateForm();
          
          // Reload feed
          await this.loadFeed();
          
          // Show notification
          this.$store.dispatch('phone/showNotification', {
            type: 'success',
            title: 'Video Posted',
            message: 'Your video has been published'
          });
        }
      } catch (error) {
        console.error('Create video error:', error);
      } finally {
        this.isPosting = false;
      }
    },
    
    resetCreateForm() {
      this.selectedVideo = null;
      this.newVideoCaption = '';
      this.selectedFilter = 'none';
      this.enableTTS = false;
      this.ttsText = '';
      this.selectedMusic = '';
    },
    
    shareVideo(video) {
      this.videoToShare = video;
      this.showShareSheet = true;
    },
    
    async shareToApp(appName) {
      if (!this.videoToShare) return;
      
      if (appName === 'messages') {
        this.$router.push({
          name: 'Messages',
          params: {
            shareContent: {
              type: 'modish_video',
              videoId: this.videoToShare.id,
              preview: this.videoToShare.thumbnail_url
            }
          }
        });
      } else if (appName === 'chirper') {
        this.$router.push({
          name: 'Chirper',
          params: {
            shareContent: {
              type: 'modish_video',
              videoId: this.videoToShare.id,
              text: `Check out this video on Modish!`
            }
          }
        });
      }
      
      this.showShareSheet = false;
      this.videoToShare = null;
    },
    
    copyLink() {
      if (!this.videoToShare) return;
      
      const link = `modish://video/${this.videoToShare.id}`;
      navigator.clipboard.writeText(link);
      
      this.$store.dispatch('phone/showNotification', {
        type: 'success',
        title: 'Link Copied',
        message: 'Video link copied to clipboard'
      });
      
      this.showShareSheet = false;
      this.videoToShare = null;
    },
    
    viewMyVideo(video) {
      // Find video in feed or add it temporarily
      const index = this.feed.findIndex(v => v.id === video.id);
      if (index !== -1) {
        this.currentView = 'feed';
        this.$nextTick(() => {
          this.playVideo(index);
        });
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
    },
    
    formatDuration(seconds) {
      if (!seconds) return '0:00';
      const mins = Math.floor(seconds / 60);
      const secs = seconds % 60;
      return `${mins}:${secs.toString().padStart(2, '0')}`;
    }
  }
};
</script>

<style scoped>
.modish-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #000;
  color: white;
}

.modish-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: rgba(0, 0, 0, 0.8);
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
}

.header-left h1 {
  font-size: 1.5rem;
  font-weight: 700;
  margin: 0;
  background: linear-gradient(135deg, #ff0080 0%, #ff8c00 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.header-right {
  display: flex;
  gap: 0.5rem;
}

.create-btn, .profile-btn, .back-btn, .close-btn {
  background: none;
  border: none;
  color: white;
  font-size: 1.25rem;
  cursor: pointer;
  padding: 0.5rem;
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: white;
}

.loading i {
  font-size: 2rem;
  margin-bottom: 1rem;
}

.video-feed {
  flex: 1;
  overflow-y: scroll;
  scroll-snap-type: y mandatory;
  -webkit-overflow-scrolling: touch;
}

.video-feed::-webkit-scrollbar {
  display: none;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  padding: 3rem 1rem;
  color: white;
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

.video-item {
  position: relative;
  width: 100%;
  height: 100vh;
  scroll-snap-align: start;
  display: flex;
  align-items: center;
  justify-content: center;
}

.video-item video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.video-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 2rem 1rem 1rem;
  background: linear-gradient(to top, rgba(0,0,0,0.8) 0%, transparent 100%);
  pointer-events: none;
}

.author-section {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.author-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #ff0080 0%, #ff8c00 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 600;
  color: white;
  flex-shrink: 0;
}

.author-name {
  font-weight: 600;
  font-size: 1rem;
}

.video-caption {
  margin-bottom: 0.5rem;
  line-height: 1.4;
  max-width: 70%;
}

.music-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9rem;
  opacity: 0.9;
}

.music-info i {
  animation: spin 3s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.action-buttons {
  position: absolute;
  right: 1rem;
  bottom: 8rem;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  pointer-events: all;
}

.action-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
  background: none;
  border: none;
  color: white;
  font-size: 1.75rem;
  cursor: pointer;
  transition: transform 0.2s;
}

.action-btn:active {
  transform: scale(0.9);
}

.action-btn span {
  font-size: 0.75rem;
  font-weight: 500;
}

.like-btn.liked {
  color: #ff0080;
}

.views-btn {
  opacity: 0.8;
}

/* Profile View */
.profile-view {
  flex: 1;
  overflow-y: auto;
  background: var(--background-color);
  color: var(--text-color);
}

.profile-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: var(--card-background);
  border-bottom: 1px solid var(--border-color);
}

.profile-header h2 {
  margin: 0;
  font-size: 1.25rem;
}

.profile-stats {
  display: flex;
  justify-content: space-around;
  padding: 2rem 1rem;
  background: var(--card-background);
  border-bottom: 1px solid var(--border-color);
}

.stat {
  text-align: center;
}

.stat-value {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--text-color);
}

.stat-label {
  font-size: 0.85rem;
  color: var(--text-color);
  opacity: 0.6;
  margin-top: 0.25rem;
}

.videos-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 2px;
  padding: 2px;
}

.grid-video {
  position: relative;
  aspect-ratio: 9/16;
  cursor: pointer;
  overflow: hidden;
  background: #000;
}

.grid-video video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.video-stats {
  position: absolute;
  bottom: 0.5rem;
  left: 0.5rem;
  right: 0.5rem;
  display: flex;
  justify-content: space-between;
  font-size: 0.75rem;
  color: white;
  text-shadow: 0 1px 2px rgba(0,0,0,0.8);
}

/* Dialogs */
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}

.create-video-dialog, .comments-sheet, .share-sheet, .gallery-selector {
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

.video-selector {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.select-video-btn {
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

.select-video-btn:hover {
  background: var(--border-color);
}

.select-video-btn i {
  font-size: 1.5rem;
  color: var(--primary-color);
}

.video-preview {
  position: relative;
  margin-bottom: 1rem;
}

.video-preview video {
  width: 100%;
  border-radius: 8px;
}

.change-video-btn {
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

.caption-input, .tts-input {
  width: 100%;
  min-height: 80px;
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

.filter-section, .tts-section, .music-section {
  margin-top: 1rem;
}

.filter-section label, .tts-section label, .music-section label {
  display: block;
  margin-bottom: 0.5rem;
  color: var(--text-color);
  font-weight: 500;
}

.tts-section label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
}

.filter-select, .music-select {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  background: var(--background-color);
  color: var(--text-color);
  font-size: 0.9rem;
}

.tts-input {
  margin-top: 0.5rem;
  min-height: 60px;
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
  background: linear-gradient(135deg, #ff0080 0%, #ff8c00 100%);
  color: white;
}

.post-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Comments Sheet */
.comments-sheet {
  max-height: 70vh;
  display: flex;
  flex-direction: column;
}

.sheet-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--border-color);
}

.sheet-header h3 {
  margin: 0;
  color: var(--text-color);
}

.comments-list {
  flex: 1;
  overflow-y: auto;
  margin-bottom: 1rem;
}

.no-comments {
  text-align: center;
  padding: 2rem 1rem;
  color: var(--text-color);
  opacity: 0.6;
}

.comment-item {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.comment-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: linear-gradient(135deg, #ff0080 0%, #ff8c00 100%);
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
  padding-top: 1rem;
  border-top: 1px solid var(--border-color);
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
  background: linear-gradient(135deg, #ff0080 0%, #ff8c00 100%);
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

/* Share Sheet */
.share-sheet h3 {
  margin: 0 0 1rem;
  color: var(--text-color);
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

/* Gallery Selector */
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 4px;
  max-height: 400px;
  overflow-y: auto;
}

.gallery-item {
  position: relative;
  aspect-ratio: 9/16;
  cursor: pointer;
  overflow: hidden;
  border-radius: 4px;
  background: #000;
}

.gallery-item video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.video-duration {
  position: absolute;
  bottom: 0.25rem;
  right: 0.25rem;
  padding: 0.25rem 0.5rem;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  font-size: 0.75rem;
  border-radius: 4px;
}
</style>

</content>
</invoke>