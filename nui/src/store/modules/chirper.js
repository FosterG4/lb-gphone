// Chirper Store Module
// Manages Chirper posts (Twitter-like), feed, trending topics, and replies

import { postNUI } from '../../utils/nui';

const state = {
  feed: [],
  myPosts: [],
  trending: [],
  currentThread: null,
  loading: false,
  error: null
};

const getters = {
  feed: (state) => state.feed,
  myPosts: (state) => state.myPosts,
  trending: (state) => state.trending,
  currentThread: (state) => state.currentThread,
  loading: (state) => state.loading,
  error: (state) => state.error,
  
  getPostById: (state) => (id) => {
    return state.feed.find(post => post.id === id) || 
           state.myPosts.find(post => post.id === id);
  },
  
  getRepliesForPost: (state) => (postId) => {
    return state.feed.filter(post => post.parent_id === postId);
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
  
  SET_TRENDING(state, trending) {
    state.trending = trending;
  },
  
  SET_CURRENT_THREAD(state, thread) {
    state.currentThread = thread;
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
      const response = await postNUI('getChirperFeed', { limit, offset });
      
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
      const response = await postNUI('getMyChirperPosts', {});
      
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
  
  // Fetch trending topics
  async fetchTrending({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getChirperTrending', {});
      
      if (response.success) {
        commit('SET_TRENDING', response.trending || []);
      } else {
        commit('SET_ERROR', response.message || 'Failed to fetch trending');
      }
    } catch (error) {
      console.error('Fetch trending error:', error);
      commit('SET_ERROR', 'Failed to fetch trending');
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Fetch post thread (post + replies)
  async fetchThread({ commit }, postId) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getChirperThread', { postId });
      
      if (response.success) {
        commit('SET_CURRENT_THREAD', response.thread || null);
        return response.thread;
      } else {
        commit('SET_ERROR', response.message || 'Failed to fetch thread');
        return null;
      }
    } catch (error) {
      console.error('Fetch thread error:', error);
      commit('SET_ERROR', 'Failed to fetch thread');
      return null;
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Create a new post
  async createChirperPost({ commit }, postData) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('createChirperPost', postData);
      
      if (response.success) {
        commit('ADD_POST_TO_FEED', response.post);
        commit('ADD_MY_POST', response.post);
        
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
      const response = await postNUI('likeChirperPost', { postId });
      
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
  
  // Repost a post
  async repostPost({ commit }, postId) {
    try {
      const response = await postNUI('repostChirperPost', { postId });
      
      if (response.success) {
        commit('UPDATE_POST_IN_FEED', {
          postId: response.postId,
          updates: {
            reposts: response.reposts,
            isReposted: response.isReposted
          }
        });
        
        // If reposted, add to feed
        if (response.isReposted && response.repost) {
          commit('ADD_POST_TO_FEED', response.repost);
        }
      }
      
      return response;
    } catch (error) {
      console.error('Repost error:', error);
      return { success: false };
    }
  },
  
  // Reply to a post
  async replyToPost({ commit }, { postId, content }) {
    try {
      const response = await postNUI('replyToChirperPost', { postId, content });
      
      if (response.success) {
        // Update reply count in feed
        commit('UPDATE_POST_IN_FEED', {
          postId: postId,
          updates: {
            replies: (state.feed.find(p => p.id === postId)?.replies || 0) + 1
          }
        });
        
        // Add reply to feed
        if (response.reply) {
          commit('ADD_POST_TO_FEED', response.reply);
        }
      }
      
      return response;
    } catch (error) {
      console.error('Reply error:', error);
      return { success: false };
    }
  },
  
  // Delete a post
  async deletePost({ commit }, postId) {
    try {
      const response = await postNUI('deleteChirperPost', { postId });
      
      if (response.success) {
        commit('REMOVE_POST_FROM_FEED', postId);
      }
      
      return response;
    } catch (error) {
      console.error('Delete post error:', error);
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
  
  handlePostRepostUpdate({ commit }, { postId, reposts }) {
    commit('UPDATE_POST_IN_FEED', {
      postId,
      updates: { reposts }
    });
  },
  
  handlePostReplyUpdate({ commit }, { postId, replies }) {
    commit('UPDATE_POST_IN_FEED', {
      postId,
      updates: { replies }
    });
  },
  
  handlePostDeleted({ commit }, { postId }) {
    commit('REMOVE_POST_FROM_FEED', postId);
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
