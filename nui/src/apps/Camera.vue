<template>
  <div class="camera-app">
    <!-- Camera Viewfinder -->
    <div class="camera-viewfinder" :class="{ 'recording': isRecording }">
      <div class="viewfinder-overlay">
        <!-- Filter Preview -->
        <div class="filter-preview" :class="`filter-${currentFilter}`"></div>
        
        <!-- Recording Indicator -->
        <div v-if="isRecording" class="recording-indicator">
          <span class="recording-dot"></span>
          <span class="recording-time">{{ formatTime(recordingDuration) }}</span>
        </div>
        
        <!-- Top Controls -->
        <div class="camera-top-controls">
          <button class="control-btn" @click="toggleFlash" v-if="config.enableFlash">
            <i :class="flashEnabled ? 'icon-flash-on' : 'icon-flash-off'"></i>
          </button>
          
          <button class="control-btn" @click="cycleFilter">
            <i class="icon-filter"></i>
            <span class="filter-name">{{ currentFilter }}</span>
          </button>
          
          <button class="control-btn" @click="flipCamera" v-if="config.enableCameraFlip">
            <i class="icon-flip"></i>
          </button>
        </div>
        
        <!-- Center Focus Indicator -->
        <div class="focus-indicator"></div>
      </div>
    </div>
    
    <!-- Bottom Controls -->
    <div class="camera-controls">
      <!-- Mode Toggle -->
      <div class="mode-toggle">
        <button 
          class="mode-btn" 
          :class="{ active: mode === 'photo' }"
          @click="setMode('photo')"
          :disabled="isRecording"
        >
          Photo
        </button>
        <button 
          class="mode-btn" 
          :class="{ active: mode === 'video' }"
          @click="setMode('video')"
          :disabled="isRecording"
        >
          Video
        </button>
      </div>
      
      <!-- Capture Button -->
      <div class="capture-container">
        <button 
          class="capture-btn" 
          :class="{ 'recording': isRecording, 'video-mode': mode === 'video' }"
          @click="handleCapture"
          :disabled="isCapturing"
        >
          <span class="capture-inner"></span>
        </button>
      </div>
      
      <!-- Gallery Preview -->
      <div class="gallery-preview" @click="openGallery">
        <img v-if="lastPhoto" :src="lastPhoto.thumbnail_url || lastPhoto.file_url" alt="Last photo" />
        <div v-else class="gallery-placeholder">
          <i class="icon-gallery"></i>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex';
import { postNUI } from '../utils/nui';

export default {
  name: 'Camera',
  
  data() {
    return {
      mode: 'photo', // 'photo' or 'video'
      currentFilter: 'none',
      flashEnabled: false,
      isCapturing: false,
      isRecording: false,
      recordingDuration: 0,
      recordingInterval: null,
      config: {
        enableFlash: true,
        enableCameraFlip: true,
        availableFilters: ['none', 'bw', 'sepia', 'vintage', 'cool', 'warm']
      }
    };
  },
  
  computed: {
    ...mapState('media', ['photos', 'videos']),
    
    lastPhoto() {
      if (this.photos && this.photos.length > 0) {
        return this.photos[0];
      }
      return null;
    },
    
    availableFilters() {
      return this.config.availableFilters || ['none'];
    }
  },
  
  mounted() {
    // Load config from server
    this.loadCameraConfig();
    
    // Load last photo for preview
    this.loadLastMedia();
  },
  
  beforeUnmount() {
    // Stop recording if active
    if (this.isRecording) {
      this.stopVideoRecording();
    }
  },
  
  methods: {
    ...mapActions('media', ['addPhoto', 'addVideo', 'fetchMedia']),
    
    async loadCameraConfig() {
      // In production, this would fetch from config
      // For now, using default values
      this.config = {
        enableFlash: true,
        enableCameraFlip: true,
        availableFilters: ['none', 'bw', 'sepia', 'vintage', 'cool', 'warm']
      };
    },
    
    async loadLastMedia() {
      // Fetch recent media for gallery preview
      await this.fetchMedia({ limit: 1, offset: 0 });
    },
    
    setMode(newMode) {
      if (this.isRecording) return;
      this.mode = newMode;
    },
    
    toggleFlash() {
      this.flashEnabled = !this.flashEnabled;
    },
    
    cycleFilter() {
      const currentIndex = this.availableFilters.indexOf(this.currentFilter);
      const nextIndex = (currentIndex + 1) % this.availableFilters.length;
      this.currentFilter = this.availableFilters[nextIndex];
      
      // Apply filter effect
      postNUI('setFilter', { filter: this.currentFilter });
    },
    
    flipCamera() {
      // In a real implementation, this would switch between front/back camera
      // For FiveM, this is mostly cosmetic
      console.log('Camera flipped');
    },
    
    async handleCapture() {
      if (this.mode === 'photo') {
        await this.capturePhoto();
      } else {
        if (this.isRecording) {
          await this.stopVideoRecording();
        } else {
          await this.startVideoRecording();
        }
      }
    },
    
    async capturePhoto() {
      if (this.isCapturing) return;
      
      this.isCapturing = true;
      
      try {
        const response = await postNUI('capturePhoto', {
          filter: this.currentFilter,
          flash: this.flashEnabled
        });
        
        if (response.success) {
          // Photo will be added via event listener
          this.showNotification('Photo captured!', 'success');
        } else {
          this.showNotification('Failed to capture photo', 'error');
        }
      } catch (error) {
        console.error('Photo capture error:', error);
        this.showNotification('Error capturing photo', 'error');
      } finally {
        this.isCapturing = false;
      }
    },
    
    async startVideoRecording() {
      if (this.isRecording) return;
      
      try {
        const response = await postNUI('startVideoRecording', {});
        
        if (response.success) {
          this.isRecording = true;
          this.recordingDuration = 0;
          
          // Start recording timer
          this.recordingInterval = setInterval(() => {
            this.recordingDuration++;
          }, 1000);
          
          this.showNotification('Recording started', 'info');
        } else {
          this.showNotification('Failed to start recording', 'error');
        }
      } catch (error) {
        console.error('Video recording error:', error);
        this.showNotification('Error starting recording', 'error');
      }
    },
    
    async stopVideoRecording() {
      if (!this.isRecording) return;
      
      try {
        const response = await postNUI('stopVideoRecording', {});
        
        if (response.success) {
          this.isRecording = false;
          
          // Clear recording timer
          if (this.recordingInterval) {
            clearInterval(this.recordingInterval);
            this.recordingInterval = null;
          }
          
          this.recordingDuration = 0;
          this.showNotification('Video saved!', 'success');
        } else {
          this.showNotification('Failed to stop recording', 'error');
        }
      } catch (error) {
        console.error('Stop recording error:', error);
        this.showNotification('Error stopping recording', 'error');
      }
    },
    
    openGallery() {
      // Navigate to Photos app
      this.$router.push('/photos');
    },
    
    formatTime(seconds) {
      const mins = Math.floor(seconds / 60);
      const secs = seconds % 60;
      return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    },
    
    showNotification(message, type) {
      // Dispatch notification
      this.$store.dispatch('phone/showNotification', {
        message,
        type
      });
    }
  }
};
</script>

<style scoped>
.camera-app {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  background: #000;
  position: relative;
  overflow: hidden;
}

.camera-viewfinder {
  flex: 1;
  position: relative;
  background: #1a1a1a;
  overflow: hidden;
}

.camera-viewfinder.recording {
  border: 2px solid #ff0000;
}

.viewfinder-overlay {
  width: 100%;
  height: 100%;
  position: relative;
}

.filter-preview {
  width: 100%;
  height: 100%;
  position: absolute;
  top: 0;
  left: 0;
  pointer-events: none;
}

.filter-preview.filter-bw {
  filter: grayscale(100%);
}

.filter-preview.filter-sepia {
  filter: sepia(100%);
}

.filter-preview.filter-vintage {
  filter: sepia(50%) contrast(120%) brightness(90%);
}

.filter-preview.filter-cool {
  filter: hue-rotate(180deg) saturate(150%);
}

.filter-preview.filter-warm {
  filter: hue-rotate(20deg) saturate(120%);
}

.recording-indicator {
  position: absolute;
  top: 20px;
  left: 20px;
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(0, 0, 0, 0.6);
  padding: 8px 12px;
  border-radius: 20px;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  z-index: 10;
}

.recording-dot {
  width: 12px;
  height: 12px;
  background: #ff0000;
  border-radius: 50%;
  animation: pulse 1.5s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.3;
  }
}

.recording-time {
  font-family: monospace;
}

.camera-top-controls {
  position: absolute;
  top: 20px;
  right: 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  z-index: 10;
}

.control-btn {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.6);
  border: none;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
}

.control-btn:hover {
  background: rgba(0, 0, 0, 0.8);
  transform: scale(1.05);
}

.control-btn:active {
  transform: scale(0.95);
}

.filter-name {
  position: absolute;
  top: 50%;
  right: calc(100% + 8px);
  transform: translateY(-50%);
  background: rgba(0, 0, 0, 0.8);
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  white-space: nowrap;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.2s;
}

.control-btn:hover .filter-name {
  opacity: 1;
}

.focus-indicator {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 60px;
  height: 60px;
  border: 2px solid rgba(255, 255, 255, 0.6);
  border-radius: 4px;
  pointer-events: none;
}

.camera-controls {
  height: 140px;
  background: rgba(0, 0, 0, 0.9);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  position: relative;
}

.mode-toggle {
  display: flex;
  gap: 8px;
  flex-direction: column;
}

.mode-btn {
  padding: 8px 16px;
  background: transparent;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 20px;
  color: rgba(255, 255, 255, 0.6);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  text-transform: uppercase;
}

.mode-btn.active {
  background: rgba(255, 255, 255, 0.2);
  border-color: #fff;
  color: #fff;
}

.mode-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.capture-container {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
}

.capture-btn {
  width: 70px;
  height: 70px;
  border-radius: 50%;
  background: transparent;
  border: 4px solid #fff;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
}

.capture-btn:hover {
  transform: scale(1.05);
}

.capture-btn:active {
  transform: scale(0.95);
}

.capture-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.capture-inner {
  width: 58px;
  height: 58px;
  background: #fff;
  border-radius: 50%;
  transition: all 0.2s;
}

.capture-btn.video-mode .capture-inner {
  background: #ff0000;
}

.capture-btn.recording .capture-inner {
  width: 24px;
  height: 24px;
  border-radius: 4px;
}

.gallery-preview {
  width: 50px;
  height: 50px;
  border-radius: 8px;
  overflow: hidden;
  cursor: pointer;
  border: 2px solid rgba(255, 255, 255, 0.3);
  transition: all 0.2s;
}

.gallery-preview:hover {
  border-color: #fff;
  transform: scale(1.05);
}

.gallery-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.gallery-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.5);
  font-size: 20px;
}

/* Icon placeholders - replace with actual icon library */
.icon-flash-on::before { content: '⚡'; }
.icon-flash-off::before { content: '⚡'; opacity: 0.5; }
.icon-filter::before { content: '🎨'; }
.icon-flip::before { content: '🔄'; }
.icon-gallery::before { content: '🖼️'; }
</style>
