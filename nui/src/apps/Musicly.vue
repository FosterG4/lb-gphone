<template>
  <div class="musicly-app">
    <!-- Header with current playing info -->
    <div class="player-header" v-if="currentTrack">
      <div class="track-info">
        <div class="track-title">{{ currentTrack.title }}</div>
        <div class="track-artist">{{ currentTrack.artist }}</div>
      </div>
      <div class="player-controls">
        <button @click="togglePlayPause" class="control-btn">
          <i :class="isPlaying ? 'fas fa-pause' : 'fas fa-play'"></i>
        </button>
      </div>
    </div>

    <!-- Navigation tabs -->
    <div class="nav-tabs">
      <button 
        v-for="tab in tabs" 
        :key="tab.id"
        @click="activeTab = tab.id"
        class="nav-tab"
        :class="{ active: activeTab === tab.id }"
      >
        <i :class="tab.icon"></i>
        {{ tab.label }}
      </button>
    </div>

    <!-- Browse Tab -->
    <div v-if="activeTab === 'browse'" class="tab-content">
      <div class="search-section">
        <div class="search-bar">
          <i class="fas fa-search"></i>
          <input 
            v-model="searchQuery" 
            type="text" 
            placeholder="Search songs, artists, albums..."
            @input="handleSearch"
          />
        </div>
      </div>

      <div class="browse-categories">
        <div class="category-grid">
          <div 
            v-for="category in categories" 
            :key="category.id"
            @click="browseCategory(category)"
            class="category-card"
          >
            <div class="category-icon">
              <i :class="category.icon"></i>
            </div>
            <div class="category-name">{{ category.name }}</div>
          </div>
        </div>
      </div>

      <div v-if="searchResults.length > 0" class="search-results">
        <h3>Search Results</h3>
        <div class="track-list">
          <div 
            v-for="track in searchResults" 
            :key="track.id"
            @click="playTrack(track)"
            class="track-item"
            :class="{ playing: currentTrack && currentTrack.id === track.id }"
          >
            <div class="track-cover">
              <img :src="track.cover || '/assets/default-cover.jpg'" :alt="track.title" />
              <div class="play-overlay">
                <i class="fas fa-play"></i>
              </div>
            </div>
            <div class="track-details">
              <div class="track-title">{{ track.title }}</div>
              <div class="track-artist">{{ track.artist }}</div>
              <div class="track-duration">{{ formatDuration(track.duration) }}</div>
            </div>
            <button @click.stop="addToPlaylist(track)" class="add-btn">
              <i class="fas fa-plus"></i>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Playlists Tab -->
    <div v-if="activeTab === 'playlists'" class="tab-content">
      <div class="playlist-header">
        <h2>My Playlists</h2>
        <button @click="showCreatePlaylist = true" class="create-btn">
          <i class="fas fa-plus"></i>
          Create Playlist
        </button>
      </div>

      <div class="playlist-grid">
        <div 
          v-for="playlist in playlists" 
          :key="playlist.id"
          @click="openPlaylist(playlist)"
          class="playlist-card"
        >
          <div class="playlist-cover">
            <img :src="playlist.cover || '/assets/default-playlist.jpg'" :alt="playlist.name" />
            <div class="playlist-overlay">
              <i class="fas fa-play"></i>
            </div>
          </div>
          <div class="playlist-info">
            <div class="playlist-name">{{ playlist.name }}</div>
            <div class="playlist-count">{{ playlist.tracks.length }} songs</div>
          </div>
        </div>
      </div>

      <!-- Create Playlist Modal -->
      <div v-if="showCreatePlaylist" class="modal-overlay" @click="showCreatePlaylist = false">
        <div class="modal" @click.stop>
          <h3>Create New Playlist</h3>
          <input 
            v-model="newPlaylistName" 
            type="text" 
            placeholder="Playlist name"
            class="modal-input"
          />
          <div class="modal-actions">
            <button @click="showCreatePlaylist = false" class="cancel-btn">Cancel</button>
            <button @click="createPlaylist" class="create-btn">Create</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Now Playing Tab -->
    <div v-if="activeTab === 'playing'" class="tab-content">
      <div v-if="!currentTrack" class="empty-state">
        <i class="fas fa-music"></i>
        <p>No music playing</p>
        <p>Browse and select a song to start listening</p>
      </div>

      <div v-else class="now-playing">
        <div class="album-art">
          <img :src="currentTrack.cover || '/assets/default-cover.jpg'" :alt="currentTrack.title" />
        </div>

        <div class="track-info">
          <h2>{{ currentTrack.title }}</h2>
          <h3>{{ currentTrack.artist }}</h3>
          <p>{{ currentTrack.album }}</p>
        </div>

        <div class="progress-section">
          <div class="time-display">
            <span>{{ formatDuration(currentTime) }}</span>
            <span>{{ formatDuration(currentTrack.duration) }}</span>
          </div>
          <div class="progress-bar" @click="seekTo">
            <div class="progress-fill" :style="{ width: progressPercentage + '%' }"></div>
          </div>
        </div>

        <div class="player-controls">
          <button @click="previousTrack" class="control-btn">
            <i class="fas fa-step-backward"></i>
          </button>
          <button @click="togglePlayPause" class="control-btn play-btn">
            <i :class="isPlaying ? 'fas fa-pause' : 'fas fa-play'"></i>
          </button>
          <button @click="nextTrack" class="control-btn">
            <i class="fas fa-step-forward"></i>
          </button>
        </div>

        <div class="additional-controls">
          <button @click="toggleShuffle" class="control-btn" :class="{ active: isShuffled }">
            <i class="fas fa-random"></i>
          </button>
          <button @click="toggleRepeat" class="control-btn" :class="{ active: repeatMode !== 'off' }">
            <i :class="repeatMode === 'one' ? 'fas fa-redo' : 'fas fa-retweet'"></i>
          </button>
          <div class="volume-control">
            <i class="fas fa-volume-up"></i>
            <input 
              type="range" 
              min="0" 
              max="100" 
              v-model="volume"
              @input="updateVolume"
              class="volume-slider"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Stations Tab -->
    <div v-if="activeTab === 'stations'" class="tab-content">
      <h2>Radio Stations</h2>
      <div class="station-list">
        <div 
          v-for="station in radioStations" 
          :key="station.id"
          @click="playStation(station)"
          class="station-item"
          :class="{ playing: currentStation && currentStation.id === station.id }"
        >
          <div class="station-logo">
            <img :src="station.logo" :alt="station.name" />
          </div>
          <div class="station-info">
            <div class="station-name">{{ station.name }}</div>
            <div class="station-genre">{{ station.genre }}</div>
            <div class="station-description">{{ station.description }}</div>
          </div>
          <div class="station-controls">
            <button class="play-btn">
              <i :class="currentStation && currentStation.id === station.id && isPlaying ? 'fas fa-pause' : 'fas fa-play'"></i>
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
  name: 'Musicly',
  setup() {
    const store = useStore()
    
    const activeTab = ref('browse')
    const searchQuery = ref('')
    const searchResults = ref([])
    const showCreatePlaylist = ref(false)
    const newPlaylistName = ref('')
    
    const tabs = [
      { id: 'browse', label: 'Browse', icon: 'fas fa-search' },
      { id: 'playlists', label: 'Playlists', icon: 'fas fa-list' },
      { id: 'playing', label: 'Now Playing', icon: 'fas fa-music' },
      { id: 'stations', label: 'Radio', icon: 'fas fa-radio' }
    ]
    
    const categories = [
      { id: 'pop', name: 'Pop', icon: 'fas fa-star' },
      { id: 'rock', name: 'Rock', icon: 'fas fa-guitar' },
      { id: 'hip-hop', name: 'Hip Hop', icon: 'fas fa-microphone' },
      { id: 'electronic', name: 'Electronic', icon: 'fas fa-bolt' },
      { id: 'jazz', name: 'Jazz', icon: 'fas fa-saxophone' },
      { id: 'classical', name: 'Classical', icon: 'fas fa-music' }
    ]
    
    // Use Vuex state
    const currentTrack = computed(() => store.state.musicly.currentTrack)
    const currentStation = computed(() => store.state.musicly.currentStation)
    const isPlaying = computed(() => store.state.musicly.isPlaying)
    const playlists = computed(() => store.state.musicly.playlists)
    const radioStations = computed(() => store.state.musicly.radioStations)
    const currentTime = computed(() => store.state.musicly.position)
    const volume = computed({
      get: () => store.state.musicly.volume,
      set: (value) => store.dispatch('musicly/setVolume', value)
    })
    const isShuffled = computed({
      get: () => store.state.musicly.isShuffled,
      set: (value) => store.dispatch('musicly/toggleShuffle', value)
    })
    const repeatMode = computed({
      get: () => store.state.musicly.repeatMode,
      set: (value) => store.dispatch('musicly/setRepeatMode', value)
    })
    
    const progressPercentage = computed(() => {
      if (!currentTrack.value || !currentTrack.value.duration) return 0
      return (currentTime.value / currentTrack.value.duration) * 100
    })
    
    const formatDuration = (seconds) => {
      const mins = Math.floor(seconds / 60)
      const secs = Math.floor(seconds % 60)
      return `${mins}:${secs.toString().padStart(2, '0')}`
    }
    
    const handleSearch = async () => {
      if (searchQuery.value.length > 2) {
        const results = await store.dispatch('musicly/searchMusic', searchQuery.value)
        searchResults.value = results
      } else {
        searchResults.value = []
      }
    }
    
    const browseCategory = async (category) => {
      const results = await store.dispatch('musicly/browseMusicCategory', category.id)
      searchResults.value = results
    }
    
    const playTrack = async (track) => {
      await store.dispatch('musicly/playTrack', track)
      activeTab.value = 'playing'
    }
    
    const playStation = async (station) => {
      await store.dispatch('musicly/playRadioStation', station)
    }
    
    const togglePlayPause = () => {
      store.dispatch('musicly/togglePlayPause')
    }
    
    const previousTrack = () => {
      store.dispatch('musicly/previousTrack')
    }
    
    const nextTrack = () => {
      store.dispatch('musicly/nextTrack')
    }
    
    const toggleShuffle = () => {
      isShuffled.value = !isShuffled.value
    }
    
    const toggleRepeat = () => {
      const modes = ['off', 'all', 'one']
      const currentIndex = modes.indexOf(repeatMode.value)
      repeatMode.value = modes[(currentIndex + 1) % modes.length]
    }
    
    const updateVolume = () => {
      // Volume is already updated via computed setter
    }
    
    const seekTo = (event) => {
      if (!currentTrack.value) return
      const rect = event.target.getBoundingClientRect()
      const percentage = (event.clientX - rect.left) / rect.width
      const newTime = percentage * currentTrack.value.duration
      store.dispatch('musicly/seekTo', newTime)
    }
    
    const addToPlaylist = (track) => {
      // Show playlist selection modal
      store.dispatch('musicly/showAddToPlaylistModal', track)
    }
    
    const createPlaylist = async () => {
      if (newPlaylistName.value.trim()) {
        await store.dispatch('musicly/createPlaylist', {
          name: newPlaylistName.value.trim(),
          tracks: []
        })
        newPlaylistName.value = ''
        showCreatePlaylist.value = false
      }
    }
    
    const openPlaylist = async (playlist) => {
      const response = await store.dispatch('musicly/openPlaylist', playlist)
      if (response.success) {
        searchResults.value = store.state.musicly.playlistTracks
      }
    }
    
    // Update playback status periodically
    let statusInterval = null
    
    onMounted(async () => {
      await store.dispatch('musicly/initializeMusicly')
      
      // Update playback status every second
      statusInterval = setInterval(() => {
        store.dispatch('musicly/updatePlaybackStatus')
      }, 1000)
    })
    
    onUnmounted(() => {
      if (statusInterval) {
        clearInterval(statusInterval)
      }
    })
    
    return {
      activeTab,
      tabs,
      searchQuery,
      searchResults,
      categories,
      showCreatePlaylist,
      newPlaylistName,
      currentTrack,
      currentStation,
      isPlaying,
      playlists,
      radioStations,
      currentTime,
      volume,
      isShuffled,
      repeatMode,
      progressPercentage,
      formatDuration,
      handleSearch,
      browseCategory,
      playTrack,
      playStation,
      togglePlayPause,
      previousTrack,
      nextTrack,
      toggleShuffle,
      toggleRepeat,
      updateVolume,
      seekTo,
      addToPlaylist,
      createPlaylist,
      openPlaylist
    }
  }
}
</script>

<style scoped>
.musicly-app {
  flex: 1;
  overflow-y: auto;
  background: #000;
  color: #fff;
}

.player-header {
  background: linear-gradient(135deg, #1db954 0%, #1ed760 100%);
  padding: 15px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.track-info .track-title {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 4px;
}

.track-info .track-artist {
  font-size: 14px;
  opacity: 0.8;
}

.nav-tabs {
  display: flex;
  background: #111;
  border-bottom: 1px solid #333;
}

.nav-tab {
  flex: 1;
  padding: 12px 8px;
  background: none;
  border: none;
  color: #999;
  font-size: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.nav-tab.active {
  color: #1db954;
  background: #1a1a1a;
}

.nav-tab i {
  font-size: 16px;
}

.tab-content {
  padding: 20px;
}

.search-section {
  margin-bottom: 20px;
}

.search-bar {
  position: relative;
  display: flex;
  align-items: center;
  background: #222;
  border-radius: 25px;
  padding: 12px 20px;
}

.search-bar i {
  color: #999;
  margin-right: 10px;
}

.search-bar input {
  flex: 1;
  background: none;
  border: none;
  color: #fff;
  font-size: 16px;
  outline: none;
}

.search-bar input::placeholder {
  color: #999;
}

.category-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
  margin-bottom: 20px;
}

.category-card {
  background: #222;
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s;
}

.category-card:hover {
  background: #333;
  transform: translateY(-2px);
}

.category-icon {
  font-size: 24px;
  color: #1db954;
  margin-bottom: 10px;
}

.category-name {
  font-size: 14px;
  font-weight: 500;
}

.track-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.track-item {
  display: flex;
  align-items: center;
  background: #111;
  border-radius: 8px;
  padding: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.track-item:hover {
  background: #222;
}

.track-item.playing {
  background: #1db954;
  color: #000;
}

.track-cover {
  position: relative;
  width: 50px;
  height: 50px;
  border-radius: 6px;
  overflow: hidden;
  margin-right: 12px;
}

.track-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.play-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.2s;
}

.track-item:hover .play-overlay {
  opacity: 1;
}

.track-details {
  flex: 1;
}

.track-details .track-title {
  font-size: 14px;
  font-weight: 500;
  margin-bottom: 4px;
}

.track-details .track-artist {
  font-size: 12px;
  opacity: 0.7;
  margin-bottom: 2px;
}

.track-details .track-duration {
  font-size: 11px;
  opacity: 0.5;
}

.add-btn {
  background: none;
  border: none;
  color: #1db954;
  font-size: 16px;
  cursor: pointer;
  padding: 8px;
  border-radius: 50%;
  transition: all 0.2s;
}

.add-btn:hover {
  background: #1db954;
  color: #000;
}

.playlist-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.playlist-header h2 {
  font-size: 24px;
  font-weight: 600;
}

.create-btn {
  background: #1db954;
  color: #000;
  border: none;
  padding: 10px 16px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.2s;
}

.create-btn:hover {
  background: #1ed760;
  transform: translateY(-1px);
}

.playlist-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
}

.playlist-card {
  background: #111;
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.2s;
}

.playlist-card:hover {
  background: #222;
  transform: translateY(-2px);
}

.playlist-cover {
  position: relative;
  aspect-ratio: 1;
  overflow: hidden;
}

.playlist-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.playlist-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.2s;
  font-size: 24px;
  color: #1db954;
}

.playlist-card:hover .playlist-overlay {
  opacity: 1;
}

.playlist-info {
  padding: 12px;
}

.playlist-name {
  font-size: 14px;
  font-weight: 500;
  margin-bottom: 4px;
}

.playlist-count {
  font-size: 12px;
  opacity: 0.7;
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

.modal {
  background: #222;
  border-radius: 12px;
  padding: 24px;
  width: 90%;
  max-width: 400px;
}

.modal h3 {
  margin-bottom: 16px;
  font-size: 18px;
}

.modal-input {
  width: 100%;
  background: #333;
  border: none;
  border-radius: 8px;
  padding: 12px;
  color: #fff;
  font-size: 16px;
  margin-bottom: 20px;
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.cancel-btn {
  background: none;
  border: 1px solid #666;
  color: #fff;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #999;
}

.empty-state i {
  font-size: 48px;
  margin-bottom: 16px;
  color: #333;
}

.now-playing {
  text-align: center;
  max-width: 400px;
  margin: 0 auto;
}

.album-art {
  width: 250px;
  height: 250px;
  margin: 0 auto 30px;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.album-art img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.track-info h2 {
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 8px;
}

.track-info h3 {
  font-size: 18px;
  color: #1db954;
  margin-bottom: 4px;
}

.track-info p {
  font-size: 14px;
  opacity: 0.7;
  margin-bottom: 30px;
}

.progress-section {
  margin-bottom: 30px;
}

.time-display {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  opacity: 0.7;
  margin-bottom: 8px;
}

.progress-bar {
  height: 4px;
  background: #333;
  border-radius: 2px;
  cursor: pointer;
  position: relative;
}

.progress-fill {
  height: 100%;
  background: #1db954;
  border-radius: 2px;
  transition: width 0.1s;
}

.player-controls {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 20px;
  margin-bottom: 30px;
}

.control-btn {
  background: none;
  border: none;
  color: #fff;
  font-size: 20px;
  cursor: pointer;
  padding: 12px;
  border-radius: 50%;
  transition: all 0.2s;
}

.control-btn:hover {
  background: #333;
  transform: scale(1.1);
}

.play-btn {
  background: #1db954;
  color: #000;
  font-size: 24px;
  width: 60px;
  height: 60px;
}

.play-btn:hover {
  background: #1ed760;
}

.additional-controls {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 15px;
}

.control-btn.active {
  color: #1db954;
}

.volume-control {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
  max-width: 120px;
}

.volume-slider {
  flex: 1;
  height: 4px;
  background: #333;
  border-radius: 2px;
  outline: none;
  cursor: pointer;
}

.station-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.station-item {
  display: flex;
  align-items: center;
  background: #111;
  border-radius: 12px;
  padding: 16px;
  cursor: pointer;
  transition: all 0.2s;
}

.station-item:hover {
  background: #222;
}

.station-item.playing {
  background: #1db954;
  color: #000;
}

.station-logo {
  width: 60px;
  height: 60px;
  border-radius: 8px;
  overflow: hidden;
  margin-right: 16px;
}

.station-logo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.station-info {
  flex: 1;
}

.station-name {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 4px;
}

.station-genre {
  font-size: 14px;
  color: #1db954;
  margin-bottom: 4px;
}

.station-description {
  font-size: 12px;
  opacity: 0.7;
}

.station-controls .play-btn {
  background: #1db954;
  color: #000;
  border: none;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 16px;
  transition: all 0.2s;
}

.station-controls .play-btn:hover {
  background: #1ed760;
  transform: scale(1.1);
}
</style>