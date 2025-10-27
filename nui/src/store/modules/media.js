// Media Store Module
// Manages photos, videos, and audio recordings

import { postNUI } from '../../utils/nui';

const state = {
  photos: [],
  videos: [],
  voiceRecordings: [],
  albums: [],
  currentAlbum: null,
  isRecording: false,
  loading: false,
  error: null
};

const getters = {
  allPhotos: (state) => state.photos,
  allVideos: (state) => state.videos,
  allVoiceRecordings: (state) => state.voiceRecordings,
  allAlbums: (state) => state.albums,
  currentAlbum: (state) => state.currentAlbum,
  isRecording: (state) => state.isRecording,
  
  getPhotoById: (state) => (id) => {
    return state.photos.find(photo => photo.id === id);
  },
  
  getVideoById: (state) => (id) => {
    return state.videos.find(video => video.id === id);
  },
  
  getAlbumById: (state) => (id) => {
    return state.albums.find(album => album.id === id);
  },
  
  totalMediaCount: (state) => {
    return state.photos.length + state.videos.length + state.voiceRecordings.length;
  }
};

const mutations = {
  SET_PHOTOS(state, photos) {
    state.photos = photos;
  },
  
  ADD_PHOTO(state, photo) {
    state.photos.unshift(photo);
  },
  
  REMOVE_PHOTO(state, photoId) {
    state.photos = state.photos.filter(photo => photo.id !== photoId);
  },
  
  SET_VIDEOS(state, videos) {
    state.videos = videos;
  },
  
  ADD_VIDEO(state, video) {
    state.videos.unshift(video);
  },
  
  REMOVE_VIDEO(state, videoId) {
    state.videos = state.videos.filter(video => video.id !== videoId);
  },
  
  SET_VOICE_RECORDINGS(state, recordings) {
    state.voiceRecordings = recordings;
  },
  
  ADD_VOICE_RECORDING(state, recording) {
    state.voiceRecordings.unshift(recording);
  },
  
  REMOVE_VOICE_RECORDING(state, recordingId) {
    state.voiceRecordings = state.voiceRecordings.filter(rec => rec.id !== recordingId);
  },
  
  SET_ALBUMS(state, albums) {
    state.albums = albums;
  },
  
  ADD_ALBUM(state, album) {
    state.albums.push(album);
  },
  
  UPDATE_ALBUM(state, { albumId, updates }) {
    const index = state.albums.findIndex(album => album.id === albumId);
    if (index !== -1) {
      state.albums[index] = { ...state.albums[index], ...updates };
    }
  },
  
  REMOVE_ALBUM(state, albumId) {
    state.albums = state.albums.filter(album => album.id !== albumId);
  },
  
  SET_CURRENT_ALBUM(state, album) {
    state.currentAlbum = album;
  },
  
  SET_RECORDING(state, isRecording) {
    state.isRecording = isRecording;
  },
  
  SET_LOADING(state, loading) {
    state.loading = loading;
  },
  
  SET_ERROR(state, error) {
    state.error = error;
  },
  
  CLEAR_ERROR(state) {
    state.error = null;
  }
};

const actions = {
  // Fetch all media
  async fetchMedia({ commit }, { mediaType = null, limit = 20, offset = 0 } = {}) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getMedia', { mediaType, limit, offset });
      
      if (response.success) {
        if (!mediaType || mediaType === 'photo') {
          commit('SET_PHOTOS', response.data.photos || []);
        }
        if (!mediaType || mediaType === 'video') {
          commit('SET_VIDEOS', response.data.videos || []);
        }
        if (!mediaType || mediaType === 'audio') {
          commit('SET_VOICE_RECORDINGS', response.data.audio || []);
        }
      } else {
        commit('SET_ERROR', response.error || 'Failed to fetch media');
      }
    } catch (error) {
      console.error('Fetch media error:', error);
      commit('SET_ERROR', 'Failed to fetch media');
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Add photo
  addPhoto({ commit }, photo) {
    commit('ADD_PHOTO', photo);
  },
  
  // Delete photo
  async deletePhoto({ commit }, photoId) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('deleteMedia', { mediaId: photoId, mediaType: 'photo' });
      
      if (response.success) {
        commit('REMOVE_PHOTO', photoId);
        return true;
      } else {
        commit('SET_ERROR', response.error || 'Failed to delete photo');
        return false;
      }
    } catch (error) {
      console.error('Delete photo error:', error);
      commit('SET_ERROR', 'Failed to delete photo');
      return false;
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Add video
  addVideo({ commit }, video) {
    commit('ADD_VIDEO', video);
  },
  
  // Delete video
  async deleteVideo({ commit }, videoId) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('deleteMedia', { mediaId: videoId, mediaType: 'video' });
      
      if (response.success) {
        commit('REMOVE_VIDEO', videoId);
        return true;
      } else {
        commit('SET_ERROR', response.error || 'Failed to delete video');
        return false;
      }
    } catch (error) {
      console.error('Delete video error:', error);
      commit('SET_ERROR', 'Failed to delete video');
      return false;
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Add voice recording
  addVoiceRecording({ commit }, recording) {
    commit('ADD_VOICE_RECORDING', recording);
  },
  
  // Delete voice recording
  async deleteVoiceRecording({ commit }, recordingId) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('deleteMedia', { mediaId: recordingId, mediaType: 'audio' });
      
      if (response.success) {
        commit('REMOVE_VOICE_RECORDING', recordingId);
        return true;
      } else {
        commit('SET_ERROR', response.error || 'Failed to delete recording');
        return false;
      }
    } catch (error) {
      console.error('Delete recording error:', error);
      commit('SET_ERROR', 'Failed to delete recording');
      return false;
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Bulk delete media
  async bulkDeleteMedia({ commit }, mediaIds) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('bulkDeleteMedia', { mediaIds });
      
      if (response.success) {
        // Remove deleted media from state
        mediaIds.forEach(mediaId => {
          commit('REMOVE_PHOTO', mediaId);
          commit('REMOVE_VIDEO', mediaId);
          commit('REMOVE_VOICE_RECORDING', mediaId);
        });
        return response;
      } else {
        commit('SET_ERROR', response.error || 'Failed to delete media');
        return response;
      }
    } catch (error) {
      console.error('Bulk delete error:', error);
      commit('SET_ERROR', 'Failed to delete media');
      return { success: false, error: 'Failed to delete media' };
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Fetch albums
  async fetchAlbums({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getAlbums', {});
      
      if (response.success) {
        commit('SET_ALBUMS', response.data || []);
      } else {
        commit('SET_ERROR', response.error || 'Failed to fetch albums');
      }
    } catch (error) {
      console.error('Fetch albums error:', error);
      commit('SET_ERROR', 'Failed to fetch albums');
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Create album
  async createAlbum({ commit }, { name, coverMediaId = null }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('createAlbum', { name, coverMediaId });
      
      if (response.success) {
        commit('ADD_ALBUM', response.data);
        return response.data;
      } else {
        commit('SET_ERROR', response.error || 'Failed to create album');
        return null;
      }
    } catch (error) {
      console.error('Create album error:', error);
      commit('SET_ERROR', 'Failed to create album');
      return null;
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Update album
  async updateAlbum({ commit }, { albumId, updates }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('updateAlbum', { albumId, updates });
      
      if (response.success) {
        commit('UPDATE_ALBUM', { albumId, updates });
        return true;
      } else {
        commit('SET_ERROR', response.error || 'Failed to update album');
        return false;
      }
    } catch (error) {
      console.error('Update album error:', error);
      commit('SET_ERROR', 'Failed to update album');
      return false;
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Delete album
  async deleteAlbum({ commit }, albumId) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('deleteAlbum', { albumId });
      
      if (response.success) {
        commit('REMOVE_ALBUM', albumId);
        return true;
      } else {
        commit('SET_ERROR', response.error || 'Failed to delete album');
        return false;
      }
    } catch (error) {
      console.error('Delete album error:', error);
      commit('SET_ERROR', 'Failed to delete album');
      return false;
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Add media to album
  async addMediaToAlbum({ commit }, { albumId, mediaIds }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('addMediaToAlbum', { albumId, mediaIds });
      
      if (response.success) {
        return true;
      } else {
        commit('SET_ERROR', response.error || 'Failed to add media to album');
        return false;
      }
    } catch (error) {
      console.error('Add media to album error:', error);
      commit('SET_ERROR', 'Failed to add media to album');
      return false;
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Remove media from album
  async removeMediaFromAlbum({ commit }, { albumId, mediaIds }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('removeMediaFromAlbum', { albumId, mediaIds });
      
      if (response.success) {
        return true;
      } else {
        commit('SET_ERROR', response.error || 'Failed to remove media from album');
        return false;
      }
    } catch (error) {
      console.error('Remove media from album error:', error);
      commit('SET_ERROR', 'Failed to remove media from album');
      return false;
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Get album media
  async fetchAlbumMedia({ commit }, albumId) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getAlbumMedia', { albumId });
      
      if (response.success) {
        return response.data || [];
      } else {
        commit('SET_ERROR', response.error || 'Failed to fetch album media');
        return [];
      }
    } catch (error) {
      console.error('Fetch album media error:', error);
      commit('SET_ERROR', 'Failed to fetch album media');
      return [];
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Set album cover
  async setAlbumCover({ commit }, { albumId, mediaId }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('setAlbumCover', { albumId, mediaId });
      
      if (response.success) {
        commit('UPDATE_ALBUM', { albumId, updates: { cover_media_id: mediaId } });
        return true;
      } else {
        commit('SET_ERROR', response.error || 'Failed to set album cover');
        return false;
      }
    } catch (error) {
      console.error('Set album cover error:', error);
      commit('SET_ERROR', 'Failed to set album cover');
      return false;
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Set current album
  setCurrentAlbum({ commit }, album) {
    commit('SET_CURRENT_ALBUM', album);
  },
  
  // Set recording state
  setRecording({ commit }, isRecording) {
    commit('SET_RECORDING', isRecording);
  },
  
  // Clear error
  clearError({ commit }) {
    commit('CLEAR_ERROR');
  }
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions
};
