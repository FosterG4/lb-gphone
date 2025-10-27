<template>
  <div class="photos-app">
    <!-- Header -->
    <div class="photos-header">
      <div class="header-left">
        <button v-if="currentView !== 'grid'" @click="goBack" class="back-btn">
          <i class="fas fa-arrow-left"></i>
        </button>
        <h1>{{ headerTitle }}</h1>
      </div>
      <div class="header-right">
        <button v-if="currentView === 'grid'" @click="toggleSelectionMode" class="select-btn">
          {{ selectionMode ? 'Cancel' : 'Select' }}
        </button>
        <button v-if="selectionMode && selectedMedia.length > 0" @click="deleteSelected" class="delete-btn">
          <i class="fas fa-trash"></i>
        </button>
      </div>
    </div>

    <!-- Tab Navigation -->
    <div v-if="currentView === 'grid'" class="tabs">
      <button 
        :class="['tab', { active: activeTab === 'all' }]" 
        @click="activeTab = 'all'"
      >
        All
      </button>
      <button 
        :class="['tab', { active: activeTab === 'photos' }]" 
        @click="activeTab = 'photos'"
      >
        Photos
      </button>
      <button 
        :class="['tab', { active: activeTab === 'videos' }]" 
        @click="activeTab = 'videos'"
      >
        Videos
      </button>
      <button 
        :class="['tab', { active: activeTab === 'albums' }]" 
        @click="activeTab = 'albums'"
      >
        Albums
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Loading media...</p>
    </div>

    <!-- Gallery Grid View -->
    <div v-else-if="currentView === 'grid' && activeTab !== 'albums'" class="gallery-grid" @scroll="handleScroll">
      <div 
        v-for="media in filteredMedia" 
        :key="media.id" 
        :class="['media-item', { selected: isSelected(media.id) }]"
        @click="handleMediaClick(media)"
      >
        <div class="media-thumbnail">
          <img 
            v-if="media.media_type === 'photo'" 
            :src="media.thumbnail_url || media.file_url" 
            :alt="'Photo ' + media.id"
            loading="lazy"
          />
          <video 
            v-else-if="media.media_type === 'video'" 
            :src="media.file_url"
            preload="metadata"
          ></video>
          <div v-if="media.media_type === 'video'" class="video-overlay">
            <i class="fas fa-play"></i>
            <span class="duration">{{ formatDuration(media.duration) }}</span>
          </div>
        </div>
        <div v-if="selectionMode" class="selection-checkbox">
          <i :class="isSelected(media.id) ? 'fas fa-check-circle' : 'far fa-circle'"></i>
        </div>
      </div>
      
      <!-- Empty State -->
      <div v-if="filteredMedia.length === 0" class="empty-state">
        <i class="fas fa-images"></i>
        <p>No {{ activeTab === 'all' ? 'media' : activeTab }} yet</p>
        <p class="hint">Open the Camera app to capture photos and videos</p>
      </div>
    </div>

    <!-- Albums View -->
    <div v-else-if="currentView === 'grid' && activeTab === 'albums'" class="albums-grid">
      <div class="album-item create-album" @click="showCreateAlbumDialog = true">
        <div class="album-cover">
          <i class="fas fa-plus"></i>
        </div>
        <p class="album-name">New Album</p>
      </div>
      
      <div 
        v-for="album in albums" 
        :key="album.id" 
        class="album-item"
        @click="openAlbum(album)"
      >
        <div class="album-cover">
          <img 
            v-if="album.cover_media_id" 
            :src="getAlbumCover(album)" 
            alt="Album cover"
          />
          <i v-else class="fas fa-folder"></i>
        </div>
        <p class="album-name">{{ album.album_name }}</p>
        <p class="album-count">{{ album.media_count || 0 }} items</p>
      </div>
    </div>

    <!-- Full-Screen Media Viewer -->
    <div v-else-if="currentView === 'viewer' && currentMedia" class="media-viewer">
      <div class="viewer-header">
        <button @click="closeViewer" class="close-btn">
          <i class="fas fa-times"></i>
        </button>
        <div class="viewer-actions">
          <button @click="shareMedia(currentMedia)" class="action-btn">
            <i class="fas fa-share"></i>
          </button>
          <button @click="deleteMedia(currentMedia)" class="action-btn">
            <i class="fas fa-trash"></i>
          </button>
        </div>
      </div>
      
      <div class="viewer-content">
        <img 
          v-if="currentMedia.media_type === 'photo'" 
          :src="currentMedia.file_url" 
          :alt="'Photo ' + currentMedia.id"
        />
        <video 
          v-else-if="currentMedia.media_type === 'video'" 
          :src="currentMedia.file_url"
          controls
          autoplay
        ></video>
      </div>
      
      <div class="viewer-info">
        <p class="date">{{ formatDate(currentMedia.created_at) }}</p>
        <p v-if="currentMedia.location_x" class="location">
          <i class="fas fa-map-marker-alt"></i>
          {{ formatLocation(currentMedia.location_x, currentMedia.location_y) }}
        </p>
      </div>
      
      <!-- Navigation -->
      <button 
        v-if="currentMediaIndex > 0" 
        @click="previousMedia" 
        class="nav-btn prev-btn"
      >
        <i class="fas fa-chevron-left"></i>
      </button>
      <button 
        v-if="currentMediaIndex < filteredMedia.length - 1" 
        @click="nextMedia" 
        class="nav-btn next-btn"
      >
        <i class="fas fa-chevron-right"></i>
      </button>
    </div>

    <!-- Album View -->
    <div v-else-if="currentView === 'album' && currentAlbum" class="album-view">
      <div class="album-header">
        <h2>{{ currentAlbum.album_name }}</h2>
        <button @click="showAlbumOptions = true" class="options-btn">
          <i class="fas fa-ellipsis-v"></i>
        </button>
      </div>
      
      <div class="gallery-grid" @scroll="handleScroll">
        <div 
          v-for="media in albumMedia" 
          :key="media.id" 
          class="media-item"
          @click="viewMedia(media)"
        >
          <div class="media-thumbnail">
            <img 
              v-if="media.media_type === 'photo'" 
              :src="media.thumbnail_url || media.file_url" 
              :alt="'Photo ' + media.id"
              loading="lazy"
            />
            <video 
              v-else-if="media.media_type === 'video'" 
              :src="media.file_url"
              preload="metadata"
            ></video>
            <div v-if="media.media_type === 'video'" class="video-overlay">
              <i class="fas fa-play"></i>
            </div>
          </div>
        </div>
        
        <div v-if="albumMedia.length === 0" class="empty-state">
          <i class="fas fa-folder-open"></i>
          <p>This album is empty</p>
        </div>
      </div>
    </div>

    <!-- Create Album Dialog -->
    <div v-if="showCreateAlbumDialog" class="dialog-overlay" @click.self="showCreateAlbumDialog = false">
      <div class="dialog">
        <h3>Create New Album</h3>
        <input 
          v-model="newAlbumName" 
          type="text" 
          placeholder="Album name"
          maxlength="100"
          @keyup.enter="createAlbum"
        />
        <div class="dialog-actions">
          <button @click="showCreateAlbumDialog = false" class="cancel-btn">Cancel</button>
          <button @click="createAlbum" class="confirm-btn" :disabled="!newAlbumName.trim()">Create</button>
        </div>
      </div>
    </div>

    <!-- Share Sheet -->
    <div v-if="showShareSheet" class="dialog-overlay" @click.self="showShareSheet = false">
      <div class="share-sheet">
        <h3>Share to</h3>
        <div class="share-options">
          <button @click="shareToApp('shotz')" class="share-option">
            <i class="fas fa-camera"></i>
            <span>Shotz</span>
          </button>
          <button @click="shareToApp('modish')" class="share-option">
            <i class="fas fa-video"></i>
            <span>Modish</span>
          </button>
          <button @click="shareToApp('messages')" class="share-option">
            <i class="fas fa-comment"></i>
            <span>Messages</span>
          </button>
        </div>
        <button @click="showShareSheet = false" class="cancel-btn">Cancel</button>
      </div>
    </div>

    <!-- Delete Confirmation -->
    <div v-if="showDeleteConfirm" class="dialog-overlay" @click.self="showDeleteConfirm = false">
      <div class="dialog">
        <h3>Delete {{ deleteCount > 1 ? deleteCount + ' items' : 'this item' }}?</h3>
        <p>This action cannot be undone.</p>
        <div class="dialog-actions">
          <button @click="showDeleteConfirm = false" class="cancel-btn">Cancel</button>
          <button @click="confirmDelete" class="delete-btn">Delete</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapGetters, mapActions } from 'vuex';

export default {
  name: 'Photos',
  
  data() {
    return {
      currentView: 'grid', // 'grid', 'viewer', 'album'
      activeTab: 'all', // 'all', 'photos', 'videos', 'albums'
      selectionMode: false,
      selectedMedia: [],
      currentMedia: null,
      currentMediaIndex: 0,
      currentAlbum: null,
      albumMedia: [],
      showCreateAlbumDialog: false,
      showShareSheet: false,
      showDeleteConfirm: false,
      showAlbumOptions: false,
      newAlbumName: '',
      mediaToShare: null,
      mediaToDelete: [],
      deleteCount: 0,
      page: 0,
      pageSize: 20,
      hasMore: true,
      isLoadingMore: false
    };
  },
  
  computed: {
    ...mapState('media', ['photos', 'videos', 'albums', 'loading']),
    ...mapGetters('media', ['allPhotos', 'allVideos', 'allAlbums']),
    
    headerTitle() {
      if (this.currentView === 'album' && this.currentAlbum) {
        return this.currentAlbum.album_name;
      }
      if (this.currentView === 'viewer') {
        return '';
      }
      return 'Photos';
    },
    
    filteredMedia() {
      if (this.activeTab === 'photos') {
        return this.photos;
      } else if (this.activeTab === 'videos') {
        return this.videos;
      } else {
        return [...this.photos, ...this.videos].sort((a, b) => {
          return new Date(b.created_at) - new Date(a.created_at);
        });
      }
    }
  },
  
  mounted() {
    this.loadMedia();
    this.loadAlbums();
  },
  
  methods: {
    ...mapActions('media', [
      'fetchMedia',
      'fetchAlbums',
      'createAlbum',
      'deletePhoto',
      'deleteVideo',
      'fetchAlbumMedia',
      'bulkDeleteMedia'
    ]),
    
    async loadMedia() {
      await this.fetchMedia({ limit: this.pageSize, offset: this.page * this.pageSize });
    },
    
    async loadAlbums() {
      await this.fetchAlbums();
    },
    
    async handleScroll(event) {
      const { scrollTop, scrollHeight, clientHeight } = event.target;
      
      if (scrollTop + clientHeight >= scrollHeight - 100 && !this.isLoadingMore && this.hasMore) {
        this.isLoadingMore = true;
        this.page++;
        
        const result = await this.fetchMedia({ 
          limit: this.pageSize, 
          offset: this.page * this.pageSize 
        });
        
        if (!result || result.length < this.pageSize) {
          this.hasMore = false;
        }
        
        this.isLoadingMore = false;
      }
    },
    
    handleMediaClick(media) {
      if (this.selectionMode) {
        this.toggleSelection(media.id);
      } else {
        this.viewMedia(media);
      }
    },
    
    viewMedia(media) {
      this.currentMedia = media;
      this.currentMediaIndex = this.filteredMedia.findIndex(m => m.id === media.id);
      this.currentView = 'viewer';
    },
    
    closeViewer() {
      this.currentView = 'grid';
      this.currentMedia = null;
    },
    
    previousMedia() {
      if (this.currentMediaIndex > 0) {
        this.currentMediaIndex--;
        this.currentMedia = this.filteredMedia[this.currentMediaIndex];
      }
    },
    
    nextMedia() {
      if (this.currentMediaIndex < this.filteredMedia.length - 1) {
        this.currentMediaIndex++;
        this.currentMedia = this.filteredMedia[this.currentMediaIndex];
      }
    },
    
    toggleSelectionMode() {
      this.selectionMode = !this.selectionMode;
      if (!this.selectionMode) {
        this.selectedMedia = [];
      }
    },
    
    toggleSelection(mediaId) {
      const index = this.selectedMedia.indexOf(mediaId);
      if (index > -1) {
        this.selectedMedia.splice(index, 1);
      } else {
        this.selectedMedia.push(mediaId);
      }
    },
    
    isSelected(mediaId) {
      return this.selectedMedia.includes(mediaId);
    },
    
    deleteSelected() {
      this.mediaToDelete = this.selectedMedia;
      this.deleteCount = this.selectedMedia.length;
      this.showDeleteConfirm = true;
    },
    
    deleteMedia(media) {
      this.mediaToDelete = [media.id];
      this.deleteCount = 1;
      this.showDeleteConfirm = true;
    },
    
    async confirmDelete() {
      // Use bulk delete if multiple items
      if (this.mediaToDelete.length > 1) {
        const result = await this.bulkDeleteMedia(this.mediaToDelete);
        
        if (result.success) {
          console.log(`Deleted ${result.data.deleted_count} of ${result.data.total_count} items`);
        }
      } else {
        // Single delete
        for (const mediaId of this.mediaToDelete) {
          const media = this.filteredMedia.find(m => m.id === mediaId);
          if (media) {
            if (media.media_type === 'photo') {
              await this.deletePhoto(mediaId);
            } else if (media.media_type === 'video') {
              await this.deleteVideo(mediaId);
            }
          }
        }
      }
      
      this.showDeleteConfirm = false;
      this.mediaToDelete = [];
      this.selectedMedia = [];
      this.selectionMode = false;
      
      if (this.currentView === 'viewer') {
        this.closeViewer();
      }
    },
    
    shareMedia(media) {
      this.mediaToShare = media;
      this.showShareSheet = true;
    },
    
    async shareToApp(appName) {
      if (!this.mediaToShare) return;
      
      const media = this.mediaToShare;
      
      // Share to different apps based on appName
      if (appName === 'shotz') {
        // Navigate to Shotz app with media pre-selected
        this.$router.push({
          name: 'Shotz',
          params: {
            shareMedia: {
              id: media.id,
              url: media.file_url,
              type: media.media_type
            }
          }
        });
      } else if (appName === 'modish') {
        // Navigate to Modish app with video pre-selected
        if (media.media_type === 'video') {
          this.$router.push({
            name: 'Modish',
            params: {
              shareMedia: {
                id: media.id,
                url: media.file_url
              }
            }
          });
        } else {
          // Show error - Modish only accepts videos
          alert('Modish only accepts video content');
        }
      } else if (appName === 'messages') {
        // Navigate to Messages app with media attachment
        this.$router.push({
          name: 'Messages',
          params: {
            attachment: {
              id: media.id,
              url: media.file_url,
              type: media.media_type,
              thumbnail: media.thumbnail_url
            }
          }
        });
      }
      
      this.showShareSheet = false;
      this.mediaToShare = null;
    },
    
    async createAlbum() {
      if (!this.newAlbumName.trim()) return;
      
      await this.createAlbum({ name: this.newAlbumName });
      this.newAlbumName = '';
      this.showCreateAlbumDialog = false;
      await this.loadAlbums();
    },
    
    async openAlbum(album) {
      this.currentAlbum = album;
      this.currentView = 'album';
      // Load album media
      await this.loadAlbumMedia(album.id);
    },
    
    async loadAlbumMedia(albumId) {
      const result = await this.fetchAlbumMedia(albumId);
      this.albumMedia = result || [];
    },
    
    getAlbumCover(album) {
      if (album.cover_media_id) {
        const media = this.filteredMedia.find(m => m.id === album.cover_media_id);
        return media ? (media.thumbnail_url || media.file_url) : '';
      }
      return '';
    },
    
    goBack() {
      if (this.currentView === 'album') {
        this.currentView = 'grid';
        this.currentAlbum = null;
        this.activeTab = 'albums';
      } else if (this.currentView === 'viewer') {
        this.closeViewer();
      }
    },
    
    formatDuration(seconds) {
      if (!seconds) return '0:00';
      const mins = Math.floor(seconds / 60);
      const secs = seconds % 60;
      return `${mins}:${secs.toString().padStart(2, '0')}`;
    },
    
    formatDate(dateString) {
      if (!dateString) return '';
      const date = new Date(dateString);
      return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
    },
    
    formatLocation(x, y) {
      if (!x || !y) return '';
      return `${x.toFixed(2)}, ${y.toFixed(2)}`;
    }
  }
};
</script>

<style scoped>
.photos-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--background-color);
}

.photos-header {
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
}

.header-right {
  display: flex;
  gap: 0.5rem;
}

.back-btn, .select-btn, .delete-btn, .close-btn, .action-btn, .options-btn {
  background: none;
  border: none;
  color: var(--primary-color);
  font-size: 1rem;
  cursor: pointer;
  padding: 0.5rem;
}

.delete-btn {
  color: var(--accent-color);
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

.gallery-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 2px;
  overflow-y: auto;
  flex: 1;
  padding: 2px;
}

.media-item {
  position: relative;
  aspect-ratio: 1;
  cursor: pointer;
  overflow: hidden;
}

.media-item.selected {
  outline: 3px solid var(--primary-color);
}

.media-thumbnail {
  width: 100%;
  height: 100%;
  position: relative;
}

.media-thumbnail img,
.media-thumbnail video {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.video-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.3);
  color: white;
}

.video-overlay i {
  font-size: 2rem;
}

.video-overlay .duration {
  position: absolute;
  bottom: 0.5rem;
  right: 0.5rem;
  background: rgba(0, 0, 0, 0.7);
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
}

.selection-checkbox {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  color: white;
  font-size: 1.5rem;
  text-shadow: 0 0 4px rgba(0, 0, 0, 0.5);
}

.empty-state {
  grid-column: 1 / -1;
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

.albums-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
  padding: 1rem;
  overflow-y: auto;
  flex: 1;
}

.album-item {
  cursor: pointer;
  text-align: center;
}

.album-item.create-album .album-cover {
  background: var(--card-background);
  border: 2px dashed var(--border-color);
}

.album-cover {
  aspect-ratio: 1;
  border-radius: 8px;
  overflow: hidden;
  margin-bottom: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--card-background);
}

.album-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.album-cover i {
  font-size: 2rem;
  color: var(--text-color);
  opacity: 0.5;
}

.album-name {
  font-weight: 600;
  margin: 0;
  color: var(--text-color);
}

.album-count {
  font-size: 0.85rem;
  color: var(--text-color);
  opacity: 0.6;
  margin: 0.25rem 0 0;
}

.media-viewer {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: black;
  z-index: 1000;
  display: flex;
  flex-direction: column;
}

.viewer-header {
  display: flex;
  justify-content: space-between;
  padding: 1rem;
  background: rgba(0, 0, 0, 0.8);
}

.viewer-actions {
  display: flex;
  gap: 1rem;
}

.action-btn, .close-btn {
  color: white;
  font-size: 1.25rem;
}

.viewer-content {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.viewer-content img,
.viewer-content video {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}

.viewer-info {
  padding: 1rem;
  background: rgba(0, 0, 0, 0.8);
  color: white;
  text-align: center;
}

.viewer-info p {
  margin: 0.25rem 0;
}

.nav-btn {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  background: rgba(0, 0, 0, 0.5);
  border: none;
  color: white;
  font-size: 2rem;
  padding: 1rem;
  cursor: pointer;
  transition: background 0.2s;
}

.nav-btn:hover {
  background: rgba(0, 0, 0, 0.7);
}

.prev-btn {
  left: 0;
}

.next-btn {
  right: 0;
}

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

.dialog, .share-sheet {
  background: var(--card-background);
  border-radius: 12px;
  padding: 1.5rem;
  min-width: 300px;
  max-width: 90%;
}

.dialog h3, .share-sheet h3 {
  margin: 0 0 1rem;
  color: var(--text-color);
}

.dialog input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  font-size: 1rem;
  margin-bottom: 1rem;
  background: var(--background-color);
  color: var(--text-color);
}

.dialog-actions {
  display: flex;
  gap: 0.5rem;
  justify-content: flex-end;
}

.cancel-btn, .confirm-btn, .delete-btn {
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

.confirm-btn {
  background: var(--primary-color);
  color: white;
}

.confirm-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.delete-btn {
  background: var(--accent-color);
  color: white;
}

.share-sheet {
  padding-bottom: 1rem;
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

.album-view {
  display: flex;
  flex-direction: column;
  height: 100%;
}

.album-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: var(--card-background);
  border-bottom: 1px solid var(--border-color);
}

.album-header h2 {
  margin: 0;
  font-size: 1.25rem;
  color: var(--text-color);
}
</style>
