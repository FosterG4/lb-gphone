// Shotz Store Module
// Manages Shotz posts, feed, profile, followers, and live streams

import { postNUI } from '../../utils/nui';

const state = {
  feed: [],
  myPosts: [],
  profile: {
    name: '',
    phoneNumber: '',
    followers: 0,
    following: 0,
    bio: ''
  },
  currentPost: null,
  loading: false,
  error: null,
  liveStreams: [] // Active live streams
};

const getters = {
  feed: (state) => state.feed,
  myPosts: (state) => state.myPosts,
  profile: (state) => state.profile,
  currentPost: (state) => state.currentPost,
  loading: (state) => state.loading,
  error: (state) => state.error,
  liveStreams: (state) => state.liveStreams,
  
  getPostById: (state) => (id) => {
    return state.feed.find(post => post.id === id) || 
           state.myPosts.find(post => post.id === id);
  },
  
  isLiveStreamActive: (state) => (postId) => {
    return state.liveStreams.some(stream => stream.postId === postId);
  }
};

const mutations = {
  SET_FEED(state, feed) {
    state.feed = feed;
  },
  
  ADD_POST_TO_FEED(state, post) {
    state.feed.unshift(post);
  },
  
  UPDATE_POST_IN_FEED(state, { postId, updates }) {
    const index = state.feed.findIndex(post => post.id === postId);
    if (index !== -1) {
      state.feed[index] = { ...state.feed[index], ...updates };
    }
    
    const myIndex = state.myPosts.findIndex(post => post.id === postId);
    if (myIndex !== -1) {
      state.myPosts[myIndex] = { ...state.myPosts[myIndex], ...updates };
    }
  },
  
  REMOVE_POST_FROM_FEED(state, postId) {
    state.feed = state.feed.filter(post => post.id !== postId);
    state.myPosts = state.myPosts.filter(post => post.id !== postId);
  },
  
  SET_MY_POSTS(state, posts) {
    state.myPosts = posts;
  },
  
  ADD_MY_POST(state, post) {
    state.myPosts.unshift(post);
  },
  
  SET_PROFILE(state, profile) {
    state.profile = profile;
  },
  
  UPDATE_PROFILE(state, updates) {
    state.profile = { ...state.profile, ...updates };
  },
  
  SET_CURRENT_POST(state, post) {
    state.currentPost = post;
  },
  
  SET_LOADING(state, loading) {
    state.loading = loading;
  },
  
  SET_ERROR(state, error) {
    state.error = error;
  },
  
  CLEAR_ERROR(state) {
    state.error = null;
  },
  
  ADD_LIVE_STREAM(state, stream) {
    state.liveStreams.push(stream);
  },
  
  REMOVE_LIVE_STREAM(state, postId) {
    state.liveStreams = state.liveStreams.filter(stream => stream.postId !== postId);
  },
  
  UPDATE_LIVE_STREAM(state, { postId, updates }) {
    const index = state.liveStreams.findIndex(stream => stream.postId === postId);
    if (index !== -1) {
      state.liveStreams[index] = { ...state.liveStreams[index], ...updates };
    }
  }
};

const actions = {
  // Fetch feed
  async fetchFeed({ commit }, { limit = 20, offset = 0 } = {}) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getShotzFeed', { limit, offset });
      
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
  
  // Fetch user's own posts
  async fetchMyPosts({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getMyShotzPosts', {});
      
      if (response.success) {
        commit('SET_MY_POSTS', response.posts || []);
      } else {
        commit('SET_ERROR', response.message || 'Failed to fetch posts');
      }
    } catch (error) {
      console.error('Fetch my posts error:', error);
      commit('SET_ERROR', 'Failed to fetch posts');
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Fetch profile
  async fetchProfile({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getShotzProfile', {});
      
      if (response.success) {
        commit('SET_PROFILE', response.profile);
      } else {
        commit('SET_ERROR', response.message || 'Failed to fetch profile');
      }
    } catch (error) {
      console.error('Fetch profile error:', error);
      commit('SET_ERROR', 'Failed to fetch profile');
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Create a new post
  async createShotzPost({ commit }, postData) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('createShotzPost', postData);
      
      if (response.success) {
        commit('ADD_POST_TO_FEED', response.post);
        commit('ADD_MY_POST', response.post);
        
        // If it's a live stream, add to active streams
        if (postData.isLive) {
          commit('ADD_LIVE_STREAM', {
            postId: response.post.id,
            authorNumber: response.post.author_number,
            authorName: response.post.author_name,
            viewers: 0
          });
        }
        
        return response;
      } else {
        commit('SET_ERROR', response.message || 'Failed to create post');
        return response;
      }
    } catch (error) {
      console.error('Create post error:', error);
      commit('SET_ERROR', 'Failed to create post');
      return { success: false, error: 'Failed to create post' };
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Like a post
  async likePost({ commit }, postId) {
    try {
      const response = await postNUI('likeShotzPost', { postId });
      
      if (response.success) {
        commit('UPDATE_POST_IN_FEED', {
          postId: response.postId,
          updates: {
            likes: response.likes,
            isLiked: response.isLiked
          }
        });
      }
      
      return response;
    } catch (error) {
      console.error('Like post error:', error);
      return { success: false };
    }
  },
  
  // Fetch comments for a post
  async fetchComments({ commit }, postId) {
    try {
      const response = await postNUI('getShotzComments', { postId });
      
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
  
  // Comment on a post
  async commentOnPost({ commit }, { postId, content }) {
    try {
      const response = await postNUI('commentOnShotzPost', { postId, content });
      
      if (response.success) {
        // Update comment count in feed
        commit('UPDATE_POST_IN_FEED', {
          postId: postId,
          updates: {
            comments: (state.feed.find(p => p.id === postId)?.comments || 0) + 1
          }
        });
      }
      
      return response;
    } catch (error) {
      console.error('Comment on post error:', error);
      return { success: false };
    }
  },
  
  // Follow/unfollow a user
  async toggleFollow({ commit }, targetNumber) {
    try {
      const response = await postNUI('toggleShotzFollow', { targetNumber });
      
      if (response.success) {
        // Update profile follower count if following/unfollowing affects current user
        if (response.isFollowing) {
          commit('UPDATE_PROFILE', {
            following: state.profile.following + 1
          });
        } else {
          commit('UPDATE_PROFILE', {
            following: Math.max(0, state.profile.following - 1)
          });
        }
        
        // Update isFollowing status for posts by this user
        state.feed.forEach(post => {
          if (post.author_number === targetNumber) {
            commit('UPDATE_POST_IN_FEED', {
              postId: post.id,
              updates: { isFollowing: response.isFollowing }
            });
          }
        });
      }
      
      return response;
    } catch (error) {
      console.error('Toggle follow error:', error);
      return { success: false };
    }
  },
  
  // Share a post
  async sharePost({ commit }, postId) {
    try {
      const response = await postNUI('shareShotzPost', { postId });
      
      return response;
    } catch (error) {
      console.error('Share post error:', error);
      return { success: false };
    }
  },
  
  // Start live stream
  async startLiveStream({ commit }, postId) {
    try {
      const response = await postNUI('startShotzLiveStream', { postId });
      
      if (response.success) {
        const post = state.feed.find(p => p.id === postId) || 
                     state.myPosts.find(p => p.id === postId);
        
        if (post) {
          commit('ADD_LIVE_STREAM', {
            postId: postId,
            authorNumber: post.author_number,
            authorName: post.author_name,
            viewers: 0
          });
        }
      }
      
      return response;
    } catch (error) {
      console.error('Start live stream error:', error);
      return { success: false };
    }
  },
  
  // End live stream
  async endLiveStream({ commit }, postId) {
    try {
      const response = await postNUI('endShotzLiveStream', { postId });
      
      if (response.success) {
        commit('REMOVE_LIVE_STREAM', postId);
        commit('UPDATE_POST_IN_FEED', {
          postId: postId,
          updates: { is_live: false }
        });
      }
      
      return response;
    } catch (error) {
      console.error('End live stream error:', error);
      return { success: false };
    }
  },
  
  // Join live stream as viewer
  async joinLiveStream({ commit }, postId) {
    try {
      const response = await postNUI('joinShotzLiveStream', { postId });
      
      return response;
    } catch (error) {
      console.error('Join live stream error:', error);
      return { success: false };
    }
  },
  
  // Leave live stream
  async leaveLiveStream({ commit }, postId) {
    try {
      const response = await postNUI('leaveShotzLiveStream', { postId });
      
      return response;
    } catch (error) {
      console.error('Leave live stream error:', error);
      return { success: false };
    }
  },
  
  // Handle real-time updates from server
  handleNewPost({ commit }, post) {
    commit('ADD_POST_TO_FEED', post);
  },
  
  handlePostLikeUpdate({ commit }, { postId, likes }) {
    commit('UPDATE_POST_IN_FEED', {
      postId,
      updates: { likes }
    });
  },
  
  handlePostCommentUpdate({ commit }, { postId, comments }) {
    commit('UPDATE_POST_IN_FEED', {
      postId,
      updates: { comments }
    });
  },
  
  handlePostShareUpdate({ commit }, { postId, shares }) {
    commit('UPDATE_POST_IN_FEED', {
      postId,
      updates: { shares }
    });
  },
  
  handleLiveStreamStarted({ commit }, { postId, authorNumber, authorName }) {
    commit('ADD_LIVE_STREAM', {
      postId,
      authorNumber,
      authorName,
      viewers: 0
    });
    
    commit('UPDATE_POST_IN_FEED', {
      postId,
      updates: { is_live: true }
    });
  },
  
  handleLiveStreamEnded({ commit }, { postId }) {
    commit('REMOVE_LIVE_STREAM', postId);
    commit('UPDATE_POST_IN_FEED', {
      postId,
      updates: { is_live: false }
    });
  },
  
  handleLiveStreamViewerUpdate({ commit }, { postId, viewers }) {
    commit('UPDATE_LIVE_STREAM', {
      postId,
      updates: { viewers }
    });
  },
  
  // Set current post
  setCurrentPost({ commit }, post) {
    commit('SET_CURRENT_POST', post);
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
