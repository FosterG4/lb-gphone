// Musicly Store Module
import { nuiCallback } from '../../utils/nui'

export default {
  namespaced: true,
  
  state: {
    currentTrack: null,
    currentStation: null,
    isPlaying: false,
    volume: 50,
    repeatMode: 'off', // 'off', 'all', 'one'
    isShuffled: false,
    playlists: [],
    radioStations: [],
    currentPlaylist: null,
    playlistTracks: [],
    position: 0,
    duration: 0,
    isLoading: false
  },
  
  mutations: {
    setCurrentTrack(state, track) {
      state.currentTrack = track
      state.currentStation = null
    },
    
    setCurrentStation(state, station) {
      state.currentStation = station
      state.currentTrack = null
    },
    
    setIsPlaying(state, isPlaying) {
      state.isPlaying = isPlaying
    },
    
    setVolume(state, volume) {
      state.volume = volume
    },
    
    setRepeatMode(state, mode) {
      state.repeatMode = mode
    },
    
    setIsShuffled(state, isShuffled) {
      state.isShuffled = isShuffled
    },
    
    setPlaylists(state, playlists) {
      state.playlists = playlists || []
    },
    
    setRadioStations(state, stations) {
      state.radioStations = stations || []
    },
    
    setCurrentPlaylist(state, playlist) {
      state.currentPlaylist = playlist
    },
    
    setPlaylistTracks(state, tracks) {
      state.playlistTracks = tracks || []
    },
    
    addPlaylist(state, playlist) {
      state.playlists.unshift(playlist)
    },
    
    removePlaylist(state, playlistId) {
      const index = state.playlists.findIndex(p => p.id === playlistId)
      if (index > -1) {
        state.playlists.splice(index, 1)
      }
    },
    
    setPosition(state, position) {
      state.position = position
    },
    
    setDuration(state, duration) {
      state.duration = duration
    },
    
    setLoading(state, isLoading) {
      state.isLoading = isLoading
    },
    
    clearPlayback(state) {
      state.currentTrack = null
      state.currentStation = null
      state.isPlaying = false
      state.position = 0
      state.duration = 0
    }
  },
  
  actions: {
    // Initialize Musicly app
    async initializeMusicly({ commit }) {
      commit('setLoading', true)
      try {
        const response = await nuiCallback('initializeMusicly', {})
        
        if (response.success) {
          commit('setPlaylists', response.playlists || [])
          commit('setRadioStations', response.radioStations || [])
        }
        
        return response
      } catch (error) {
        console.error('Error initializing Musicly:', error)
        return { success: false, error: 'INIT_FAILED' }
      } finally {
        commit('setLoading', false)
      }
    },
    
    // Search for music
    async searchMusic({ commit }, query) {
      try {
        const response = await nuiCallback('searchMusic', { query })
        return response.results || []
      } catch (error) {
        console.error('Error searching music:', error)
        return []
      }
    },
    
    // Browse music by category
    async browseMusicCategory({ commit }, categoryId) {
      try {
        const response = await nuiCallback('browseMusicCategory', { categoryId })
        return response.tracks || []
      } catch (error) {
        console.error('Error browsing category:', error)
        return []
      }
    },
    
    // Play a track
    async playTrack({ commit, state }, track) {
      try {
        const response = await nuiCallback('musicPlayTrack', { track })
        
        if (response.success) {
          commit('setCurrentTrack', track)
          commit('setIsPlaying', true)
          commit('setDuration', track.duration || 0)
          commit('setPosition', 0)
        }
        
        return response
      } catch (error) {
        console.error('Error playing track:', error)
        return { success: false, error: 'PLAY_FAILED' }
      }
    },
    
    // Play a radio station
    async playRadioStation({ commit }, station) {
      try {
        const response = await nuiCallback('musicPlayStation', { station })
        
        if (response.success) {
          commit('setCurrentStation', station)
          commit('setIsPlaying', true)
        }
        
        return response
      } catch (error) {
        console.error('Error playing station:', error)
        return { success: false, error: 'PLAY_FAILED' }
      }
    },
    
    // Toggle play/pause
    async togglePlayPause({ commit, state }) {
      try {
        const response = await nuiCallback('musicTogglePlayPause', {})
        
        if (response.success) {
          commit('setIsPlaying', response.isPlaying)
        }
        
        return response
      } catch (error) {
        console.error('Error toggling play/pause:', error)
        return { success: false, error: 'TOGGLE_FAILED' }
      }
    },
    
    // Stop playback
    async stopPlayback({ commit }) {
      try {
        const response = await nuiCallback('musicStop', {})
        
        if (response.success) {
          commit('clearPlayback')
        }
        
        return response
      } catch (error) {
        console.error('Error stopping playback:', error)
        return { success: false, error: 'STOP_FAILED' }
      }
    },
    
    // Next track
    async nextTrack({ commit }) {
      try {
        const response = await nuiCallback('musicNextTrack', {})
        return response
      } catch (error) {
        console.error('Error skipping to next track:', error)
        return { success: false, error: 'NEXT_FAILED' }
      }
    },
    
    // Previous track
    async previousTrack({ commit }) {
      try {
        const response = await nuiCallback('musicPreviousTrack', {})
        return response
      } catch (error) {
        console.error('Error going to previous track:', error)
        return { success: false, error: 'PREV_FAILED' }
      }
    },
    
    // Set volume
    async setVolume({ commit }, volume) {
      try {
        const response = await nuiCallback('musicSetVolume', { volume })
        
        if (response.success) {
          commit('setVolume', volume)
        }
        
        return response
      } catch (error) {
        console.error('Error setting volume:', error)
        return { success: false, error: 'VOLUME_FAILED' }
      }
    },
    
    // Set repeat mode
    async setRepeatMode({ commit }, mode) {
      try {
        const response = await nuiCallback('musicSetRepeatMode', { mode })
        
        if (response.success) {
          commit('setRepeatMode', mode)
        }
        
        return response
      } catch (error) {
        console.error('Error setting repeat mode:', error)
        return { success: false, error: 'REPEAT_FAILED' }
      }
    },
    
    // Toggle shuffle
    async toggleShuffle({ commit, state }, enabled) {
      try {
        const response = await nuiCallback('musicSetShuffle', { enabled })
        
        if (response.success) {
          commit('setIsShuffled', enabled)
        }
        
        return response
      } catch (error) {
        console.error('Error toggling shuffle:', error)
        return { success: false, error: 'SHUFFLE_FAILED' }
      }
    },
    
    // Seek to position
    async seekTo({ commit }, position) {
      try {
        const response = await nuiCallback('musicSeekTo', { position })
        
        if (response.success) {
          commit('setPosition', position)
        }
        
        return response
      } catch (error) {
        console.error('Error seeking:', error)
        return { success: false, error: 'SEEK_FAILED' }
      }
    },
    
    // Create playlist
    async createPlaylist({ commit }, data) {
      try {
        const response = await nuiCallback('createPlaylist', data)
        
        if (response.success && response.playlist) {
          commit('addPlaylist', response.playlist)
        }
        
        return response
      } catch (error) {
        console.error('Error creating playlist:', error)
        return { success: false, error: 'CREATE_FAILED' }
      }
    },
    
    // Delete playlist
    async deletePlaylist({ commit }, playlistId) {
      try {
        const response = await nuiCallback('deletePlaylist', { playlistId })
        
        if (response.success) {
          commit('removePlaylist', playlistId)
        }
        
        return response
      } catch (error) {
        console.error('Error deleting playlist:', error)
        return { success: false, error: 'DELETE_FAILED' }
      }
    },
    
    // Get playlist tracks
    async openPlaylist({ commit }, playlist) {
      try {
        const response = await nuiCallback('getPlaylistTracks', { playlistId: playlist.id })
        
        if (response.success) {
          commit('setCurrentPlaylist', response.playlist)
          commit('setPlaylistTracks', response.tracks || [])
          
          // Set playlist for playback
          await nuiCallback('musicSetPlaylist', {
            tracks: response.tracks || [],
            startIndex: 1
          })
        }
        
        return response
      } catch (error) {
        console.error('Error opening playlist:', error)
        return { success: false, error: 'OPEN_FAILED' }
      }
    },
    
    // Add track to playlist
    async addToPlaylist({ commit }, { playlistId, track }) {
      try {
        const response = await nuiCallback('addTrackToPlaylist', {
          playlistId,
          track
        })
        
        return response
      } catch (error) {
        console.error('Error adding track to playlist:', error)
        return { success: false, error: 'ADD_FAILED' }
      }
    },
    
    // Show add to playlist modal
    showAddToPlaylistModal({ commit }, track) {
      // This would trigger a modal in the UI
      // Implementation depends on your modal system
      console.log('Show add to playlist modal for track:', track)
    },
    
    // Update playback status (called periodically)
    async updatePlaybackStatus({ commit }) {
      try {
        const response = await nuiCallback('musicGetStatus', {})
        
        if (response) {
          commit('setIsPlaying', response.isPlaying)
          commit('setPosition', response.position || 0)
          commit('setDuration', response.duration || 0)
          commit('setVolume', response.volume || 50)
          commit('setRepeatMode', response.repeatMode || 'off')
          commit('setIsShuffled', response.isShuffled || false)
          
          if (response.currentTrack) {
            commit('setCurrentTrack', response.currentTrack)
          }
          
          if (response.currentStation) {
            commit('setCurrentStation', response.currentStation)
          }
        }
        
        return response
      } catch (error) {
        console.error('Error updating playback status:', error)
        return null
      }
    }
  }
}
