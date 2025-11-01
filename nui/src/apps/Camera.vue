<template>
  <div class="camera-app">
    <!-- Status Bar -->
    <div class="status-bar">
      <span class="time">12:44</span>
      <div class="status-icons">
        <span class="signal-icon">📶</span>
        <span class="battery-icon">🔋</span>
      </div>
    </div>

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
          <button 
            class="control-btn flash-btn" 
            @click="toggleFlash" 
            v-if="config.enableFlash"
            :aria-label="flashEnabled ? 'Turn off flash' : 'Turn on flash'"
            :aria-pressed="flashEnabled"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path v-if="flashEnabled" d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" fill="currentColor"/>
              <path v-else d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" stroke="currentColor" stroke-width="2" fill="none"/>
            </svg>
          </button>
          
          <button 
            class="control-btn grid-btn" 
            @click="toggleGrid"
            :aria-label="showGrid ? 'Hide grid lines' : 'Show grid lines'"
            :aria-pressed="showGrid"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <rect x="3" y="3" width="7" height="7" stroke="currentColor" stroke-width="2" fill="none"/>
              <rect x="14" y="3" width="7" height="7" stroke="currentColor" stroke-width="2" fill="none"/>
              <rect x="3" y="14" width="7" height="7" stroke="currentColor" stroke-width="2" fill="none"/>
              <rect x="14" y="14" width="7" height="7" stroke="currentColor" stroke-width="2" fill="none"/>
            </svg>
          </button>
          
          <button 
            class="control-btn flip-btn" 
            @click="flipCamera" 
            v-if="config.enableCameraFlip"
            aria-label="Flip camera"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path d="M16 4h2a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" stroke="currentColor" stroke-width="2"/>
              <circle cx="12" cy="11" r="3" stroke="currentColor" stroke-width="2"/>
              <path d="m8 2 4-2 4 2" stroke="currentColor" stroke-width="2"/>
            </svg>
          </button>
        </div>
        
        <!-- Grid Lines -->
        <div v-if="showGrid" class="grid-lines">
          <div class="grid-line grid-vertical-1"></div>
          <div class="grid-line grid-vertical-2"></div>
          <div class="grid-line grid-horizontal-1"></div>
          <div class="grid-line grid-horizontal-2"></div>
        </div>
      </div>
    </div>
    
    <!-- Bottom Controls -->
    <div class="camera-controls">
      <!-- Mode Selector -->
      <div class="mode-selector" role="tablist" aria-label="Camera modes">
        <div class="mode-options">
          <button 
            class="mode-option" 
            :class="{ active: mode === 'video' }"
            @click="setMode('video')"
            :disabled="isRecording"
            role="tab"
            :aria-selected="mode === 'video'"
            aria-label="Video recording mode"
          >
            VIDEO
          </button>
          <button 
            class="mode-option" 
            :class="{ active: mode === 'photo' }"
            @click="setMode('photo')"
            :disabled="isRecording"
            role="tab"
            :aria-selected="mode === 'photo'"
            aria-label="Photo capture mode"
          >
            PHOTO
          </button>
          <button 
            class="mode-option" 
            :class="{ active: mode === 'landscape' }"
            @click="setMode('landscape')"
            :disabled="isRecording"
            role="tab"
            :aria-selected="mode === 'landscape'"
            aria-label="Landscape photo mode"
          >
            LANDSCAPE
          </button>
        </div>
      </div>
      
      <!-- Main Controls -->
      <div class="main-controls">
        <!-- Gallery Preview -->
        <button 
          class="gallery-preview" 
          @click="openGallery"
          aria-label="Open gallery to view photos and videos"
        >
          <img v-if="lastPhoto" :src="lastPhoto.thumbnail_url || lastPhoto.file_url" alt="Last captured photo" />
          <div v-else class="gallery-placeholder">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <rect x="3" y="3" width="18" height="18" rx="2" ry="2" stroke="currentColor" stroke-width="2"/>
              <circle cx="9" cy="9" r="2" stroke="currentColor" stroke-width="2"/>
              <path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21" stroke="currentColor" stroke-width="2"/>
            </svg>
          </div>
        </button>
        
        <!-- Capture Button -->
        <div class="capture-container">
          <button 
            class="capture-btn" 
            :class="{ 'recording': isRecording, 'video-mode': mode === 'video' }"
            @click="handleCapture"
            :disabled="isCapturing"
            :aria-label="getCaptureButtonLabel()"
            :aria-pressed="isRecording"
          >
            <span class="capture-inner" aria-hidden="true"></span>
          </button>
        </div>
        
        <!-- Flip Camera Button -->
        <div class="flip-camera-container">
          <button 
            class="flip-camera-btn" 
            @click="flipCamera" 
            v-if="config.enableCameraFlip"
            aria-label="Switch between front and back camera"
          >
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path d="M16 4h2a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" stroke="currentColor" stroke-width="2"/>
              <circle cx="12" cy="11" r="3" stroke="currentColor" stroke-width="2"/>
              <path d="m8 2 4-2 4 2" stroke="currentColor" stroke-width="2"/>
            </svg>
          </button>
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
      mode: 'photo', // 'photo', 'video', or 'landscape'
      currentFilter: 'none',
      flashEnabled: false,
      showGrid: false,
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

    toggleGrid() {
      this.showGrid = !this.showGrid;
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
    },
    
    getCaptureButtonLabel() {
      if (this.mode === 'photo') {
        return this.isCapturing ? 'Capturing photo...' : 'Capture photo';
      } else {
        return this.isRecording ? 'Stop recording video' : 'Start recording video';
      }
    }
  }
};
</script>

<style scoped>
.camera-app {
  width: 100%;
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: #000;
  position: relative;
  overflow: hidden;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* Status Bar */
.status-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 20px;
  background: #000;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  z-index: 20;
}

.status-icons {
  display: flex;
  gap: 4px;
  align-items: center;
}

.signal-icon,
.battery-icon {
  font-size: 12px;
}

/* Camera Viewfinder */
.camera-viewfinder {
  flex: 1;
  position: relative;
  background: #ff0000; /* Red background like iOS camera */
  overflow: hidden;
}

.camera-viewfinder.recording {
  animation: recordingPulse 2s ease-in-out infinite;
}

@keyframes recordingPulse {
  0%, 100% { background: #ff0000; }
  50% { background: #cc0000; }
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

/* Recording Indicator */
.recording-indicator {
  position: absolute;
  top: 20px;
  left: 20px;
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(0, 0, 0, 0.7);
  padding: 8px 12px;
  border-radius: 20px;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  z-index: 15;
}

.recording-dot {
  width: 8px;
  height: 8px;
  background: #ff0000;
  border-radius: 50%;
  animation: pulse 1.5s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}

.recording-time {
  font-family: -apple-system-monospaced, monospace;
  font-size: 13px;
}

/* Top Controls */
.camera-top-controls {
  position: absolute;
  top: 20px;
  right: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  z-index: 15;
}

.control-btn {
  width: 40px;
  height: 40px;
  border-radius: 20px;
  background: rgba(0, 0, 0, 0.5);
  border: none;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
  backdrop-filter: blur(10px);
}

.control-btn:hover {
  background: rgba(0, 0, 0, 0.7);
  transform: scale(1.05);
}

.control-btn:active {
  transform: scale(0.95);
}

.flash-btn.active,
.grid-btn.active {
  background: rgba(255, 255, 255, 0.9);
  color: #000;
}

/* Grid Lines */
.grid-lines {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  z-index: 5;
}

.grid-line {
  position: absolute;
  background: rgba(255, 255, 255, 0.3);
}

.grid-vertical-1,
.grid-vertical-2 {
  width: 1px;
  height: 100%;
  top: 0;
}

.grid-vertical-1 { left: 33.33%; }
.grid-vertical-2 { left: 66.66%; }

.grid-horizontal-1,
.grid-horizontal-2 {
  height: 1px;
  width: 100%;
  left: 0;
}

.grid-horizontal-1 { top: 33.33%; }
.grid-horizontal-2 { top: 66.66%; }

/* Bottom Controls */
.camera-controls {
  background: #000;
  padding: 20px 0 40px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Mode Selector */
.mode-selector {
  display: flex;
  justify-content: center;
}

.mode-options {
  display: flex;
  gap: 40px;
  align-items: center;
}

.mode-option {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.6);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  padding: 8px 0;
  letter-spacing: 0.5px;
  text-transform: uppercase;
  position: relative;
}

.mode-option.active {
  color: #fff;
  font-weight: 600;
}

.mode-option.active::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 100%;
  height: 2px;
  background: #ffcc00;
  border-radius: 1px;
}

.mode-option:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

/* Main Controls */
.main-controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 30px;
}

/* Gallery Preview */
.gallery-preview {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  overflow: hidden;
  cursor: pointer;
  border: 2px solid rgba(255, 255, 255, 0.3);
  transition: all 0.2s ease;
  background: rgba(255, 255, 255, 0.1);
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
  color: rgba(255, 255, 255, 0.6);
}

/* Capture Button */
.capture-container {
  display: flex;
  align-items: center;
  justify-content: center;
}

.capture-btn {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: transparent;
  border: 6px solid #fff;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  position: relative;
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
  width: 64px;
  height: 64px;
  background: #fff;
  border-radius: 50%;
  transition: all 0.3s ease;
}

.capture-btn.video-mode .capture-inner {
  background: #ff0000;
  border-radius: 50%;
}

.capture-btn.recording .capture-inner {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background: #fff;
}

/* Flip Camera Button */
.flip-camera-container {
  display: flex;
  align-items: center;
  justify-content: center;
}

.flip-camera-btn {
  width: 40px;
  height: 40px;
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: #fff;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  backdrop-filter: blur(10px);
}

.flip-camera-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.5);
  transform: scale(1.05);
}

.flip-camera-btn:active {
  transform: scale(0.95);
}

/* Responsive Design */
/* Large phones and small tablets */
@media (max-width: 480px) {
  .status-bar {
    padding: 6px 18px;
    font-size: 13px;
  }
  
  .top-controls {
    padding: 16px 24px;
    gap: 20px;
  }
  
  .control-btn {
    width: 38px;
    height: 38px;
  }
  
  .control-btn svg {
    width: 20px;
    height: 20px;
  }
  
  .camera-controls {
    padding: 18px 0 36px;
    gap: 18px;
  }
  
  .mode-options {
    gap: 36px;
  }
  
  .mode-option {
    font-size: 12px;
    padding: 6px 0;
  }
  
  .main-controls {
    padding: 0 24px;
  }
  
  .gallery-preview {
    width: 38px;
    height: 38px;
  }
  
  .capture-btn {
    width: 76px;
    height: 76px;
    border-width: 5px;
  }
  
  .capture-inner {
    width: 60px;
    height: 60px;
  }
  
  .capture-btn.recording .capture-inner {
    width: 26px;
    height: 26px;
  }
  
  .flip-camera-btn {
    width: 38px;
    height: 38px;
  }
  
  .flip-camera-btn svg {
    width: 24px;
    height: 24px;
  }
}

/* Small phones */
@media (max-width: 375px) {
  .main-controls {
    padding: 0 20px;
  }
  
  .mode-options {
    gap: 30px;
  }
  
  .capture-btn {
    width: 70px;
    height: 70px;
    border-width: 5px;
  }
  
  .capture-inner {
    width: 56px;
    height: 56px;
  }
  
  .capture-btn.recording .capture-inner {
    width: 24px;
    height: 24px;
  }
  
  .gallery-preview {
    width: 36px;
    height: 36px;
  }
  
  .flip-camera-btn {
    width: 36px;
    height: 36px;
  }
  
  .flip-camera-btn svg {
    width: 22px;
    height: 22px;
  }
  
  .recording-indicator {
    top: 16px;
    left: 16px;
    padding: 6px 10px;
    font-size: 13px;
  }
  
  .recording-dot {
    width: 6px;
    height: 6px;
  }
}

/* Very small phones */
@media (max-width: 320px) {
  .status-bar {
    padding: 4px 16px;
    font-size: 12px;
  }
  
  .top-controls {
    padding: 12px 20px;
    gap: 16px;
  }
  
  .control-btn {
    width: 32px;
    height: 32px;
  }
  
  .control-btn svg {
    width: 18px;
    height: 18px;
  }
  
  .camera-controls {
    padding: 16px 0 32px;
    gap: 16px;
  }
  
  .mode-options {
    gap: 24px;
  }
  
  .mode-option {
    font-size: 11px;
    padding: 4px 0;
  }
  
  .main-controls {
    padding: 0 16px;
  }
  
  .gallery-preview {
    width: 32px;
    height: 32px;
  }
  
  .capture-btn {
    width: 64px;
    height: 64px;
    border-width: 4px;
  }
  
  .capture-inner {
    width: 52px;
    height: 52px;
  }
  
  .capture-btn.recording .capture-inner {
    width: 20px;
    height: 20px;
  }
  
  .flip-camera-btn {
    width: 32px;
    height: 32px;
  }
  
  .flip-camera-btn svg {
    width: 20px;
    height: 20px;
  }
  
  .recording-indicator {
    top: 12px;
    left: 12px;
    padding: 4px 8px;
    font-size: 12px;
  }
  
  .recording-dot {
    width: 5px;
    height: 5px;
  }
}

/* Accessibility - Focus States */
.control-btn:focus,
.mode-option:focus,
.capture-btn:focus,
.flip-camera-btn:focus,
.gallery-preview:focus {
  outline: 2px solid #ffcc00;
  outline-offset: 2px;
}

.control-btn:focus-visible,
.mode-option:focus-visible,
.capture-btn:focus-visible,
.flip-camera-btn:focus-visible,
.gallery-preview:focus-visible {
  outline: 2px solid #ffcc00;
  outline-offset: 2px;
}

/* High Contrast Mode Support */
@media (prefers-contrast: high) {
  .control-btn {
    border-color: #fff;
    background: rgba(0, 0, 0, 0.8);
  }
  
  .control-btn.active {
    background: #fff;
    color: #000;
  }
  
  .mode-option {
    color: #fff;
  }
  
  .mode-option.active {
    background: #fff;
    color: #000;
    padding: 8px 12px;
    border-radius: 4px;
  }
  
  .capture-btn {
    border-color: #fff;
  }
  
  .flip-camera-btn {
    border-color: #fff;
    background: rgba(0, 0, 0, 0.8);
  }
  
  .gallery-preview {
    border-color: #fff;
  }
}

/* Accessibility */
@media (prefers-reduced-motion: reduce) {
  * {
    transition: none !important;
    animation: none !important;
  }
}

/* Touch feedback for mobile */
@media (hover: none) and (pointer: coarse) {
  .control-btn:hover,
  .capture-btn:hover,
  .flip-camera-btn:hover,
  .gallery-preview:hover {
    transform: none;
  }
  
  .control-btn:active,
  .capture-btn:active,
  .flip-camera-btn:active {
    transform: scale(0.95);
  }
}
</style>
