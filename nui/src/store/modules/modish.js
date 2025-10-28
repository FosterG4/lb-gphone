// Modish Store Module
// Manages Modish videos, feed, and playback state

import { postNUI } from '../../utils/nui';

const state = {
  feed: [],
  myVideos: [],
  currentVideo: null,
  loading: false,
  error: null
};

const getters = {
  feed: (state) => state.feed,
  myVideos: (state) => state.myVideos,
  currentVideo: (state) => state.currentVideo,
  loading: (state) => state.loading,
  error: (state) => state.error,
  
  getVideoById: (state) => (id) => {
    return state.feed.find(video => video.id === id) || 
           state.myVideos.find(video => video.id === id);
  }
};

const mutations = {
  SET_FEED(state, feed) {
    state.feed = feed;
  },
  
  ADD_VIDEO_TO_FEED(state, video) {
    state.feed.unshift(video);
  },
  
  UPDATE_VIDEO_IN_FEED(state, { videoId, updates }) {
    const index = state.feed.findIndex(video => video.id === videoId);
    if (index !== -1) {
      state.feed[index] = { ...state.feed[index], ...updates };
    }
    
    const myIndex = state.myVideos.findIndex(video => video.id === videoId);
    if (myIndex !== -1) {
      state.myVideos[myIndex] = { ...state.myVideos[myIndex], ...updates };
    }
  },
  
  REMOVE_VIDEO_FROM_FEED(state, videoId) {
    state.feed = state.feed.filter(video => video.id !== videoId);
    state.myVideos = state.myVideos.filter(video => video.id !== videoId);
  },
  
  SET_MY_VIDEOS(state, videos) {
    state.myVideos = videos;
  },
  
  ADD_MY_VIDEO(state, video) {
    state.myVideos.unshift(video);
  },
  
  SET_CURRENT_VIDEO(state, video) {
    state.currentVideo = video;
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
  // Fetch feed
  async fetchFeed({ commit }, { limit = 20, offset = 0 } = {}) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getModishFeed', { limit, offset });
      
      if (response.success) {
        if (offset === 0) {
          commit('SET_FEED', response.feed || []);
        } else {
          // Append to existing feed for pagination
          const currentFeed = state.feed;
          commit('SET_FEED', [...currentFeed, ...(response.feed || [])]);
        }
        return response.feed;
      } else {
        commit('SET_ERROR', response.message || 'Failed to fetch feed');
        return [];
      }
    } catch (error) {
      console.error('Fetch feed error:', error);
      commit('SET_ERROR', 'Failed to fetch feed');
      return [];
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Fetch user's own videos
  async fetchMyVideos({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getMyModishVideos', {});
      
      if (response.success) {
        commit('SET_MY_VIDEOS', response.videos || []);
      } else {
        commit('SET_ERROR', response.message || 'Failed to fetch videos');
      }
    } catch (error) {
      console.error('Fetch my videos error:', error);
      commit('SET_ERROR', 'Failed to fetch videos');
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Create a new video
  async createModishVideo({ commit }, videoData) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('createModishVideo', videoData);
      
      if (response.success) {
        commit('ADD_VIDEO_TO_FEED', response.video);
        commit('ADD_MY_VIDEO', response.video);
        
        return response;
      } else {
        commit('SET_ERROR', response.message || 'Failed to create video');
        return response;
      }
    } catch (error) {
      console.error('Create video error:', error);
      commit('SET_ERROR', 'Failed to create video');
      return { success: false, error: 'Failed to create video' };
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Like a video
  async likeVideo({ commit }, videoId) {
    try {
      const response = await postNUI('likeModishVideo', { videoId });
      
      if (response.success) {
        commit('UPDATE_VIDEO_IN_FEED', {
          videoId: response.videoId,
          updates: {
            likes: response.likes,
            isLiked: response.isLiked
          }
        });
      }
      
      return response;
    } catch (error) {
      console.error('Like video error:', error);
      return { success: false };
    }
  },
  
  // Increment view count
  async incrementViews({ commit }, videoId) {
    try {
      const response = await postNUI('incrementModishViews', { videoId });
      
      return response;
    } catch (error) {
      console.error('Increment views error:', error);
      return { success: false };
    }
  },
  
  // Fetch comments for a video
  async fetchComments({ commit }, videoId) {
    try {
      const response = await postNUI('getModishComments', { videoId });
      
      if (response.success) {
        return response.comments || [];
      } else {
        return [];
      }
    } catch (error) {
      console.error('Fetch comments error:', error);
      return [];
    }
  },
  
  // Comment on a video
  async commentOnVideo({ commit }, { videoId, content }) {
    try {
      const response = await postNUI('commentOnModishVideo', { videoId, content });
      
      if (response.success) {
        // Update comment count in feed (if we track it)
        const video = state.feed.find(v => v.id === videoId);
        if (video) {
          commit('UPDATE_VIDEO_IN_FEED', {
            videoId: videoId,
            updates: {
              comments: (video.comments || 0) + 1
            }
          });
        }
      }
      
      return response;
    } catch (error) {
      console.error('Comment on video error:', error);
      return { success: false };
    }
  },
  
  // Handle real-time updates from server
  handleNewVideo({ commit }, video) {
    commit('ADD_VIDEO_TO_FEED', video);
  },
  
  handleVideoLikeUpdate({ commit }, { videoId, likes }) {
    commit('UPDATE_VIDEO_IN_FEED', {
      videoId,
      updates: { likes }
    });
  },
  
  handleVideoViewUpdate({ commit }, { videoId, views }) {
    commit('UPDATE_VIDEO_IN_FEED', {
      videoId,
      updates: { views }
    });
  },
  
  // Set current video
  setCurrentVideo({ commit }, video) {
    commit('SET_CURRENT_VIDEO', video);
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

