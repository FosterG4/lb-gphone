<template>
  <div class="voice-recorder-app">
    <!-- Header -->
    <div class="app-header">
      <div class="header-content">
        <h1 class="app-title">Voice Recorder</h1>
        <p class="app-subtitle">Record &amp; Share Audio</p>
      </div>
      <div class="storage-info">
        <i class="fas fa-hdd"></i>
        <span>{{ formatFileSize(totalStorageUsed) }} / {{ formatFileSize(maxStorage) }}</span>
      </div>
    </div>

    <!-- Recording Controls -->
    <div class="recording-section">
      <div class="recording-visualizer" :class="{ 'active': isRecording }">
        <div class="wave-container">
          <div 
            v-for="i in 20" 
            :key="i"
            class="wave-bar"
            :style="{ height: isRecording ? Math.random() * 100 + '%' : '20%' }"
          ></div>
        </div>
      </div>
      
      <div class="recording-info">
        <div class="recording-status">
          <span v-if="isRecording" class="status-recording">
            <i class="fas fa-circle"></i>
            Recording...
          </span>
          <span v-else-if="isPaused" class="status-paused">
            <i class="fas fa-pause"></i>
            Paused
          </span>
          <span v-else class="status-ready">
            <i class="fas fa-microphone"></i>
            Ready to Record
          </span>
        </div>
        
        <div class="recording-timer">
          {{ formatTime(recordingTime) }}
        </div>
        
        <div class="recording-quality">
          Quality: {{ recordingQuality.toUpperCase() }}
        </div>
      </div>
      
      <div class="recording-controls">
        <button 
          v-if="!isRecording && !isPaused"
          class="control-btn record-btn"
          @click="startRecording"
          :disabled="recordings.length >= maxRecordings"
        >
          <i class="fas fa-microphone"></i>
          <span>Record</span>
        </button>
        
        <button 
          v-if="isRecording"
          class="control-btn pause-btn"
          @click="pauseRecording"
        >
          <i class="fas fa-pause"></i>
          <span>Pause</span>
        </button>
        
        <button 
          v-if="isPaused"
          class="control-btn resume-btn"
          @click="resumeRecording"
        >
          <i class="fas fa-play"></i>
          <span>Resume</span>
        </button>
        
        <button 
          v-if="isRecording || isPaused"
          class="control-btn stop-btn"
          @click="stopRecording"
        >
          <i class="fas fa-stop"></i>
          <span>Stop</span>
        </button>
        
        <button 
          v-if="isRecording || isPaused"
          class="control-btn cancel-btn"
          @click="cancelRecording"
        >
          <i class="fas fa-times"></i>
          <span>Cancel</span>
        </button>
      </div>
    </div>

    <!-- Navigation Tabs -->
    <div class="nav-tabs">
      <button 
        v-for="tab in tabs" 
        :key="tab.id"
        class="nav-tab"
        :class="{ 'active': activeTab === tab.id }"
        @click="activeTab = tab.id"
      >
        <i :class="tab.icon"></i>
        <span>{{ tab.label }}</span>
        <span v-if="tab.id === 'recordings'" class="tab-count">{{ recordings.length }}</span>
      </button>
    </div>

    <!-- Tab Content -->
    <div class="tab-content">
      <!-- Recordings Tab -->
      <div v-if="activeTab === 'recordings'" class="recordings-tab">
        <div class="section-header">
          <h3>My Recordings</h3>
          <div class="header-actions">
            <button class="sort-btn" @click="toggleSortOrder">
              <i :class="sortOrder === 'desc' ? 'fas fa-sort-amount-down' : 'fas fa-sort-amount-up'"></i>
            </button>
            <button class="select-all-btn" @click="toggleSelectAll" v-if="recordings.length > 0">
              <i class="fas fa-check-square"></i>
            </button>
          </div>
        </div>
        
        <div class="recordings-list">
          <div 
            v-for="recording in sortedRecordings" 
            :key="recording.id"
            class="recording-item"
            :class="{ 
              'playing': currentlyPlaying === recording.id,
              'selected': selectedRecordings.includes(recording.id)
            }"
          >
            <div class="recording-checkbox" @click="toggleRecordingSelection(recording.id)">
              <i :class="selectedRecordings.includes(recording.id) ? 'fas fa-check-square' : 'far fa-square'"></i>
            </div>
            
            <div class="recording-info">
              <div class="recording-name">{{ recording.name }}</div>
              <div class="recording-meta">
                <span class="recording-duration">{{ formatTime(recording.duration) }}</span>
                <span class="recording-size">{{ formatFileSize(recording.size) }}</span>
                <span class="recording-date">{{ formatDate(recording.createdAt) }}</span>
              </div>
              <div class="recording-quality-badge">{{ recording.quality.toUpperCase() }}</div>
            </div>
            
            <div class="recording-actions">
              <button 
                class="action-btn play-btn"
                @click="togglePlayback(recording)"
                :class="{ 'playing': currentlyPlaying === recording.id }"
              >
                <i :class="currentlyPlaying === recording.id ? 'fas fa-pause' : 'fas fa-play'"></i>
              </button>
              <button class="action-btn share-btn" @click="shareRecording(recording)">
                <i class="fas fa-share"></i>
              </button>
              <button class="action-btn rename-btn" @click="renameRecording(recording)">
                <i class="fas fa-edit"></i>
              </button>
              <button class="action-btn delete-btn" @click="deleteRecording(recording.id)">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          </div>
        </div>

        <div v-if="recordings.length === 0" class="empty-state">
          <i class="fas fa-microphone-alt"></i>
          <p>No recordings yet</p>
          <button class="start-recording-btn" @click="startRecording">
            Start Your First Recording
          </button>
        </div>

        <!-- Bulk Actions -->
        <div v-if="selectedRecordings.length > 0" class="bulk-actions">
          <div class="bulk-info">
            {{ selectedRecordings.length }} recording{{ selectedRecordings.length > 1 ? 's' : '' }} selected
          </div>
          <div class="bulk-buttons">
            <button class="bulk-btn share-btn" @click="shareSelectedRecordings">
              <i class="fas fa-share"></i>
              Share
            </button>
            <button class="bulk-btn delete-btn" @click="deleteSelectedRecordings">
              <i class="fas fa-trash"></i>
              Delete
            </button>
          </div>
        </div>
      </div>

      <!-- Settings Tab -->
      <div v-if="activeTab === 'settings'" class="settings-tab">
        <div class="section-header">
          <h3>Recording Settings</h3>
        </div>
        
        <div class="settings-list">
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-name">Recording Quality</div>
              <div class="setting-desc">Higher quality uses more storage</div>
            </div>
            <div class="setting-control">
              <select v-model="recordingQuality" @change="saveSettings">
                <option value="low">Low (32 kbps)</option>
                <option value="medium">Medium (64 kbps)</option>
                <option value="high">High (128 kbps)</option>
                <option value="ultra">Ultra (256 kbps)</option>
              </select>
            </div>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-name">Auto-Save</div>
              <div class="setting-desc">Automatically save recordings when stopped</div>
            </div>
            <div class="setting-control">
              <label class="toggle">
                <input type="checkbox" v-model="settings.autoSave" @change="saveSettings">
                <span class="slider"></span>
              </label>
            </div>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-name">Background Recording</div>
              <div class="setting-desc">Continue recording when phone is closed</div>
            </div>
            <div class="setting-control">
              <label class="toggle">
                <input type="checkbox" v-model="settings.backgroundRecording" @change="saveSettings">
                <span class="slider"></span>
              </label>
            </div>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-name">Max Recording Length</div>
              <div class="setting-desc">Maximum duration for a single recording</div>
            </div>
            <div class="setting-control">
              <select v-model="settings.maxRecordingLength" @change="saveSettings">
                <option :value="60">1 minute</option>
                <option :value="300">5 minutes</option>
                <option :value="600">10 minutes</option>
                <option :value="1800">30 minutes</option>
                <option :value="3600">1 hour</option>
              </select>
            </div>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <div class="setting-name">Storage Management</div>
              <div class="setting-desc">Automatically delete old recordings when storage is full</div>
            </div>
            <div class="setting-control">
              <label class="toggle">
                <input type="checkbox" v-model="settings.autoCleanup" @change="saveSettings">
                <span class="slider"></span>
              </label>
            </div>
          </div>
        </div>
        
        <div class="storage-management">
          <h4>Storage Management</h4>
          <div class="storage-bar">
            <div class="storage-used" :style="{ width: storagePercentage + '%' }"></div>
          </div>
          <div class="storage-details">
            <span>{{ formatFileSize(totalStorageUsed) }} used of {{ formatFileSize(maxStorage) }}</span>
            <span>{{ recordings.length }} recordings</span>
          </div>
          <button class="cleanup-btn" @click="cleanupOldRecordings" v-if="storagePercentage > 80">
            <i class="fas fa-broom"></i>
            Clean Up Old Recordings
          </button>
        </div>
      </div>
    </div>

    <!-- Rename Modal -->
    <div v-if="showRenameModal" class="modal-overlay" @click="closeRenameModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>Rename Recording</h3>
          <button class="close-btn" @click="closeRenameModal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>Recording Name</label>
            <input 
              type="text" 
              v-model="renameForm.name" 
              placeholder="Enter new name"
              maxlength="50"
              @keyup.enter="saveRename"
            >
          </div>
        </div>
        <div class="modal-footer">
          <button class="cancel-btn" @click="closeRenameModal">Cancel</button>
          <button class="save-btn" @click="saveRename" :disabled="!renameForm.name.trim()">
            Rename
          </button>
        </div>
      </div>
    </div>

    <!-- Share Modal -->
    <div v-if="showShareModal" class="modal-overlay" @click="closeShareModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>Share Recording{{ shareRecordings.length > 1 ? 's' : '' }}</h3>
          <button class="close-btn" @click="closeShareModal">
            <i class="fas fa-times"></i>
          </button>
        </div>
        <div class="modal-body">
          <div class="share-options">
            <button class="share-option" @click="shareToMessages">
              <i class="fas fa-comment"></i>
              <span>Send as Message</span>
            </button>
            <button class="share-option" @click="shareToEmail">
              <i class="fas fa-envelope"></i>
              <span>Send via Email</span>
            </button>
            <button class="share-option" @click="shareToCloud">
              <i class="fas fa-cloud-upload-alt"></i>
              <span>Upload to Cloud</span>
            </button>
            <button class="share-option" @click="exportToDevice">
              <i class="fas fa-download"></i>
              <span>Export to Device</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useStore } from 'vuex'

export default {
  name: 'VoiceRecorder',
  setup() {
    const store = useStore()
    
    // Reactive data
    const activeTab = ref('recordings')
    const isRecording = ref(false)
    const isPaused = ref(false)
    const recordingTime = ref(0)
    const currentlyPlaying = ref(null)
    const selectedRecordings = ref([])
    const sortOrder = ref('desc')
    const showRenameModal = ref(false)
    const showShareModal = ref(false)
    const shareRecordings = ref([])
    const recordingTimer = ref(null)
    const playbackTimer = ref(null)
    
    // Recording settings
    const recordingQuality = ref('medium')
    const maxRecordings = ref(50)
    const maxStorage = ref(100 * 1024 * 1024) // 100MB
    
    // Settings
    const settings = ref({
      autoSave: true,
      backgroundRecording: false,
      maxRecordingLength: 600, // 10 minutes
      autoCleanup: true
    })
    
    // Recordings data
    const recordings = ref([
      {
        id: 1,
        name: 'Meeting Notes',
        duration: 180,
        size: 2.5 * 1024 * 1024,
        quality: 'medium',
        createdAt: Date.now() - 86400000,
        filePath: '/recordings/meeting_notes.mp3'
      },
      {
        id: 2,
        name: 'Voice Memo',
        duration: 45,
        size: 0.8 * 1024 * 1024,
        quality: 'high',
        createdAt: Date.now() - 3600000,
        filePath: '/recordings/voice_memo.mp3'
      }
    ])
    
    // Rename form
    const renameForm = ref({
      id: null,
      name: ''
    })
    
    // Navigation tabs
    const tabs = [
      { id: 'recordings', label: 'Recordings', icon: 'fas fa-list' },
      { id: 'settings', label: 'Settings', icon: 'fas fa-cog' }
    ]
    
    // Computed properties
    const sortedRecordings = computed(() => {
      return [...recordings.value].sort((a, b) => {
        if (sortOrder.value === 'desc') {
          return b.createdAt - a.createdAt
        } else {
          return a.createdAt - b.createdAt
        }
      })
    })
    
    const totalStorageUsed = computed(() => {
      return recordings.value.reduce((total, recording) => total + recording.size, 0)
    })
    
    const storagePercentage = computed(() => {
      return Math.min((totalStorageUsed.value / maxStorage.value) * 100, 100)
    })
    
    // Methods
    const startRecording = () => {
      if (recordings.value.length >= maxRecordings.value) {
        store.dispatch('phone/addNotification', {
          app: 'VoiceRecorder',
          title: 'Storage Full',
          message: 'Maximum number of recordings reached',
          type: 'error'
        })
        return
      }
      
      isRecording.value = true
      isPaused.value = false
      recordingTime.value = 0
      
      recordingTimer.value = setInterval(() => {
        recordingTime.value++
        if (recordingTime.value >= settings.value.maxRecordingLength) {
          stopRecording()
        }
      }, 1000)
      
      // Send recording start event
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:startRecording',
        data: {
          quality: recordingQuality.value,
          maxLength: settings.value.maxRecordingLength
        }
      })
    }
    
    const pauseRecording = () => {
      isPaused.value = true
      isRecording.value = false
      
      if (recordingTimer.value) {
        clearInterval(recordingTimer.value)
        recordingTimer.value = null
      }
      
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:pauseRecording'
      })
    }
    
    const resumeRecording = () => {
      isRecording.value = true
      isPaused.value = false
      
      recordingTimer.value = setInterval(() => {
        recordingTime.value++
        if (recordingTime.value >= settings.value.maxRecordingLength) {
          stopRecording()
        }
      }, 1000)
      
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:resumeRecording'
      })
    }
    
    const stopRecording = () => {
      isRecording.value = false
      isPaused.value = false
      
      if (recordingTimer.value) {
        clearInterval(recordingTimer.value)
        recordingTimer.value = null
      }
      
      if (recordingTime.value > 0) {
        const newRecording = {
          id: Date.now(),
          name: `Recording ${recordings.value.length + 1}`,
          duration: recordingTime.value,
          size: estimateFileSize(recordingTime.value, recordingQuality.value),
          quality: recordingQuality.value,
          createdAt: Date.now(),
          filePath: `/recordings/recording_${Date.now()}.mp3`
        }
        
        recordings.value.unshift(newRecording)
        
        // Send recording save event
        store.dispatch('phone/sendEvent', {
          event: 'voiceRecorder:saveRecording',
          data: {
            recording: newRecording,
            autoSave: settings.value.autoSave
          }
        })
        
        store.dispatch('phone/addNotification', {
          app: 'VoiceRecorder',
          title: 'Recording Saved',
          message: `"${newRecording.name}" saved successfully`,
          type: 'success'
        })
      }
      
      recordingTime.value = 0
    }
    
    const cancelRecording = () => {
      isRecording.value = false
      isPaused.value = false
      recordingTime.value = 0
      
      if (recordingTimer.value) {
        clearInterval(recordingTimer.value)
        recordingTimer.value = null
      }
      
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:cancelRecording'
      })
    }
    
    const togglePlayback = (recording) => {
      if (currentlyPlaying.value === recording.id) {
        // Stop playback
        currentlyPlaying.value = null
        if (playbackTimer.value) {
          clearInterval(playbackTimer.value)
          playbackTimer.value = null
        }
        
        store.dispatch('phone/sendEvent', {
          event: 'voiceRecorder:stopPlayback',
          data: { recordingId: recording.id }
        })
      } else {
        // Start playback
        currentlyPlaying.value = recording.id
        
        // Simulate playback timer
        playbackTimer.value = setTimeout(() => {
          currentlyPlaying.value = null
        }, recording.duration * 1000)
        
        store.dispatch('phone/sendEvent', {
          event: 'voiceRecorder:startPlayback',
          data: { recording: recording }
        })
      }
    }
    
    const shareRecording = (recording) => {
      shareRecordings.value = [recording]
      showShareModal.value = true
    }
    
    const shareSelectedRecordings = () => {
      shareRecordings.value = recordings.value.filter(r => selectedRecordings.value.includes(r.id))
      showShareModal.value = true
    }
    
    const renameRecording = (recording) => {
      renameForm.value = {
        id: recording.id,
        name: recording.name
      }
      showRenameModal.value = true
    }
    
    const deleteRecording = (recordingId) => {
      recordings.value = recordings.value.filter(r => r.id !== recordingId)
      selectedRecordings.value = selectedRecordings.value.filter(id => id !== recordingId)
      
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:deleteRecording',
        data: { recordingId }
      })
      
      store.dispatch('phone/addNotification', {
        app: 'VoiceRecorder',
        title: 'Recording Deleted',
        message: 'Recording has been deleted',
        type: 'info'
      })
    }
    
    const deleteSelectedRecordings = () => {
      const count = selectedRecordings.value.length
      recordings.value = recordings.value.filter(r => !selectedRecordings.value.includes(r.id))
      
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:deleteRecordings',
        data: { recordingIds: selectedRecordings.value }
      })
      
      selectedRecordings.value = []
      
      store.dispatch('phone/addNotification', {
        app: 'VoiceRecorder',
        title: 'Recordings Deleted',
        message: `${count} recording${count > 1 ? 's' : ''} deleted`,
        type: 'info'
      })
    }
    
    const toggleRecordingSelection = (recordingId) => {
      const index = selectedRecordings.value.indexOf(recordingId)
      if (index > -1) {
        selectedRecordings.value.splice(index, 1)
      } else {
        selectedRecordings.value.push(recordingId)
      }
    }
    
    const toggleSelectAll = () => {
      if (selectedRecordings.value.length === recordings.value.length) {
        selectedRecordings.value = []
      } else {
        selectedRecordings.value = recordings.value.map(r => r.id)
      }
    }
    
    const toggleSortOrder = () => {
      sortOrder.value = sortOrder.value === 'desc' ? 'asc' : 'desc'
    }
    
    const closeRenameModal = () => {
      showRenameModal.value = false
      renameForm.value = { id: null, name: '' }
    }
    
    const saveRename = () => {
      if (!renameForm.value.name.trim()) return
      
      const recording = recordings.value.find(r => r.id === renameForm.value.id)
      if (recording) {
        recording.name = renameForm.value.name.trim()
        
        store.dispatch('phone/sendEvent', {
          event: 'voiceRecorder:renameRecording',
          data: {
            recordingId: recording.id,
            newName: recording.name
          }
        })
      }
      
      closeRenameModal()
    }
    
    const closeShareModal = () => {
      showShareModal.value = false
      shareRecordings.value = []
    }
    
    const shareToMessages = () => {
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:shareToMessages',
        data: { recordings: shareRecordings.value }
      })
      closeShareModal()
    }
    
    const shareToEmail = () => {
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:shareToEmail',
        data: { recordings: shareRecordings.value }
      })
      closeShareModal()
    }
    
    const shareToCloud = () => {
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:shareToCloud',
        data: { recordings: shareRecordings.value }
      })
      closeShareModal()
    }
    
    const exportToDevice = () => {
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:exportToDevice',
        data: { recordings: shareRecordings.value }
      })
      closeShareModal()
    }
    
    const saveSettings = () => {
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:saveSettings',
        data: {
          quality: recordingQuality.value,
          settings: settings.value
        }
      })
    }
    
    const cleanupOldRecordings = () => {
      const oldRecordings = recordings.value
        .sort((a, b) => a.createdAt - b.createdAt)
        .slice(0, Math.floor(recordings.value.length * 0.3))
      
      const deletedIds = oldRecordings.map(r => r.id)
      recordings.value = recordings.value.filter(r => !deletedIds.includes(r.id))
      
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:cleanupRecordings',
        data: { deletedIds }
      })
      
      store.dispatch('phone/addNotification', {
        app: 'VoiceRecorder',
        title: 'Storage Cleaned',
        message: `${oldRecordings.length} old recordings removed`,
        type: 'success'
      })
    }
    
    // Utility functions
    const formatTime = (seconds) => {
      const mins = Math.floor(seconds / 60)
      const secs = seconds % 60
      return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
    }
    
    const formatFileSize = (bytes) => {
      if (bytes === 0) return '0 B'
      const k = 1024
      const sizes = ['B', 'KB', 'MB', 'GB']
      const i = Math.floor(Math.log(bytes) / Math.log(k))
      return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
    }
    
    const formatDate = (timestamp) => {
      const date = new Date(timestamp)
      const now = new Date()
      const diffTime = Math.abs(now - date)
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
      
      if (diffDays === 1) return 'Today'
      if (diffDays === 2) return 'Yesterday'
      if (diffDays <= 7) return `${diffDays} days ago`
      
      return date.toLocaleDateString()
    }
    
    const estimateFileSize = (duration, quality) => {
      const bitrates = {
        low: 32,
        medium: 64,
        high: 128,
        ultra: 256
      }
      
      const bitrate = bitrates[quality] || 64
      return (duration * bitrate * 1000) / 8 // Convert to bytes
    }
    
    const loadVoiceRecorderData = () => {
      store.dispatch('phone/sendEvent', {
        event: 'voiceRecorder:getData'
      })
    }
    
    // Lifecycle
    onMounted(() => {
      loadVoiceRecorderData()
    })
    
    onUnmounted(() => {
      if (recordingTimer.value) {
        clearInterval(recordingTimer.value)
      }
      if (playbackTimer.value) {
        clearTimeout(playbackTimer.value)
      }
    })
    
    return {
      // Reactive data
      activeTab,
      isRecording,
      isPaused,
      recordingTime,
      currentlyPlaying,
      selectedRecordings,
      sortOrder,
      showRenameModal,
      showShareModal,
      shareRecordings,
      recordingQuality,
      maxRecordings,
      maxStorage,
      settings,
      recordings,
      renameForm,
      
      // Static data
      tabs,
      
      // Computed
      sortedRecordings,
      totalStorageUsed,
      storagePercentage,
      
      // Methods
      startRecording,
      pauseRecording,
      resumeRecording,
      stopRecording,
      cancelRecording,
      togglePlayback,
      shareRecording,
      shareSelectedRecordings,
      renameRecording,
      deleteRecording,
      deleteSelectedRecordings,
      toggleRecordingSelection,
      toggleSelectAll,
      toggleSortOrder,
      closeRenameModal,
      saveRename,
      closeShareModal,
      shareToMessages,
      shareToEmail,
      shareToCloud,
      exportToDevice,
      saveSettings,
      cleanupOldRecordings,
      formatTime,
      formatFileSize,
      formatDate
    }
  }
}
</script>

<style scoped>
.voice-recorder-app {
  height: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  overflow-y: auto;
}

.app-header {
  padding: 20px;
  text-align: center;
  background: rgba(0, 0, 0, 0.2);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-content .app-title {
  font-size: 24px;
  font-weight: bold;
  margin: 0;
}

.header-content .app-subtitle {
  font-size: 14px;
  opacity: 0.8;
  margin: 5px 0 0 0;
}

.storage-info {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  opacity: 0.8;
}

.recording-section {
  padding: 30px 20px;
  text-align: center;
}

.recording-visualizer {
  height: 120px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.recording-visualizer.active {
  background: rgba(255, 255, 255, 0.2);
  animation: pulse 2s infinite;
}

.wave-container {
  display: flex;
  align-items: end;
  gap: 3px;
  height: 80px;
}

.wave-bar {
  width: 4px;
  background: linear-gradient(to top, #10b981, #34d399);
  border-radius: 2px;
  transition: height 0.1s ease;
  min-height: 8px;
}

.recording-info {
  margin-bottom: 30px;
}

.recording-status {
  font-size: 18px;
  font-weight: bold;
  margin-bottom: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.status-recording {
  color: #ef4444;
}

.status-recording i {
  animation: pulse 1s infinite;
}

.status-paused {
  color: #f59e0b;
}

.status-ready {
  color: #10b981;
}

.recording-timer {
  font-size: 32px;
  font-weight: bold;
  font-family: 'Courier New', monospace;
  margin-bottom: 10px;
}

.recording-quality {
  font-size: 14px;
  opacity: 0.8;
}

.recording-controls {
  display: flex;
  justify-content: center;
  gap: 15px;
  flex-wrap: wrap;
}

.control-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 15px;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  min-width: 80px;
}

.control-btn i {
  font-size: 24px;
}

.control-btn span {
  font-size: 12px;
  font-weight: bold;
}

.record-btn {
  background: #ef4444;
  color: white;
}

.record-btn:disabled {
  background: rgba(255, 255, 255, 0.2);
  opacity: 0.5;
  cursor: not-allowed;
}

.pause-btn {
  background: #f59e0b;
  color: white;
}

.resume-btn {
  background: #10b981;
  color: white;
}

.stop-btn {
  background: #6b7280;
  color: white;
}

.cancel-btn {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.nav-tabs {
  display: flex;
  background: rgba(0, 0, 0, 0.2);
}

.nav-tab {
  flex: 1;
  padding: 15px 10px;
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.7);
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
  position: relative;
}

.nav-tab.active {
  color: white;
  background: rgba(255, 255, 255, 0.1);
}

.nav-tab i {
  font-size: 18px;
}

.nav-tab span {
  font-size: 12px;
}

.tab-count {
  position: absolute;
  top: 5px;
  right: 10px;
  background: #ef4444;
  color: white;
  border-radius: 10px;
  padding: 2px 6px;
  font-size: 10px;
  min-width: 16px;
  text-align: center;
}

.tab-content {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-header h3 {
  margin: 0;
  font-size: 18px;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.sort-btn,
.select-all-btn {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.recordings-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
  margin-bottom: 20px;
}

.recording-item {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 15px;
  display: flex;
  align-items: center;
  gap: 15px;
  transition: all 0.3s ease;
}

.recording-item.playing {
  background: rgba(16, 185, 129, 0.2);
  border: 1px solid rgba(16, 185, 129, 0.5);
}

.recording-item.selected {
  background: rgba(59, 130, 246, 0.2);
  border: 1px solid rgba(59, 130, 246, 0.5);
}

.recording-checkbox {
  cursor: pointer;
  font-size: 18px;
  color: rgba(255, 255, 255, 0.7);
}

.recording-info {
  flex: 1;
  min-width: 0;
}

.recording-name {
  font-weight: bold;
  font-size: 16px;
  margin-bottom: 5px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.recording-meta {
  display: flex;
  gap: 15px;
  font-size: 14px;
  opacity: 0.8;
  margin-bottom: 5px;
}

.recording-quality-badge {
  display: inline-block;
  background: rgba(255, 255, 255, 0.2);
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: bold;
}

.recording-actions {
  display: flex;
  gap: 10px;
}

.action-btn {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.play-btn {
  background: #10b981;
  color: white;
}

.play-btn.playing {
  background: #f59e0b;
}

.share-btn {
  background: #3b82f6;
  color: white;
}

.rename-btn {
  background: #8b5cf6;
  color: white;
}

.delete-btn {
  background: #ef4444;
  color: white;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
}

.empty-state i {
  font-size: 48px;
  opacity: 0.5;
  margin-bottom: 15px;
}

.empty-state p {
  opacity: 0.7;
  margin-bottom: 20px;
}

.start-recording-btn {
  background: #ef4444;
  border: none;
  color: white;
  padding: 12px 24px;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
}

.bulk-actions {
  position: fixed;
  bottom: 20px;
  left: 20px;
  right: 20px;
  background: rgba(0, 0, 0, 0.9);
  border-radius: 12px;
  padding: 15px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  z-index: 100;
}

.bulk-info {
  font-size: 14px;
  opacity: 0.8;
}

.bulk-buttons {
  display: flex;
  gap: 10px;
}

.bulk-btn {
  padding: 8px 16px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
  font-weight: bold;
  display: flex;
  align-items: center;
  gap: 5px;
}

.bulk-btn.share-btn {
  background: #3b82f6;
  color: white;
}

.bulk-btn.delete-btn {
  background: #ef4444;
  color: white;
}

.settings-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
  margin-bottom: 30px;
}

.setting-item {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 15px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.setting-info .setting-name {
  font-weight: bold;
  font-size: 16px;
}

.setting-info .setting-desc {
  font-size: 14px;
  opacity: 0.8;
  margin-top: 2px;
}

.setting-control select {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 8px;
  color: white;
  padding: 8px 12px;
  font-size: 14px;
}

.toggle {
  position: relative;
  display: inline-block;
  width: 50px;
  height: 24px;
}

.toggle input {
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(255, 255, 255, 0.3);
  transition: 0.4s;
  border-radius: 24px;
}

.slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: 0.4s;
  border-radius: 50%;
}

input:checked + .slider {
  background-color: #10b981;
}

input:checked + .slider:before {
  transform: translateX(26px);
}

.storage-management {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 20px;
}

.storage-management h4 {
  margin: 0 0 15px 0;
  font-size: 16px;
}

.storage-bar {
  height: 8px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 10px;
}

.storage-used {
  height: 100%;
  background: linear-gradient(90deg, #10b981, #f59e0b, #ef4444);
  transition: width 0.3s ease;
}

.storage-details {
  display: flex;
  justify-content: space-between;
  font-size: 14px;
  opacity: 0.8;
  margin-bottom: 15px;
}

.cleanup-btn {
  background: #f59e0b;
  border: none;
  color: white;
  padding: 10px 16px;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
  display: flex;
  align-items: center;
  gap: 8px;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: #1f2937;
  border-radius: 12px;
  width: 90%;
  max-width: 400px;
  max-height: 80vh;
  overflow-y: auto;
}

.modal-header {
  padding: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h3 {
  margin: 0;
  color: white;
}

.close-btn {
  background: none;
  border: none;
  color: white;
  font-size: 18px;
  cursor: pointer;
}

.modal-body {
  padding: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  color: white;
  font-weight: bold;
}

.form-group input {
  width: 100%;
  padding: 12px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  font-size: 16px;
}

.form-group input::placeholder {
  color: rgba(255, 255, 255, 0.5);
}

.modal-footer {
  padding: 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  gap: 15px;
}

.cancel-btn,
.save-btn {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 8px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
}

.cancel-btn {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.save-btn {
  background: #10b981;
  color: white;
}

.save-btn:disabled {
  background: rgba(255, 255, 255, 0.2);
  opacity: 0.5;
  cursor: not-allowed;
}

.share-options {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.share-option {
  background: rgba(255, 255, 255, 0.1);
  border: none;
  color: white;
  padding: 15px;
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 15px;
  transition: all 0.3s ease;
}

.share-option:hover {
  background: rgba(255, 255, 255, 0.2);
}

.share-option i {
  font-size: 20px;
  width: 24px;
  text-align: center;
}

@keyframes pulse {
  0% { opacity: 1; }
  50% { opacity: 0.7; }
  100% { opacity: 1; }
}
</style>