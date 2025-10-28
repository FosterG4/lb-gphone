// Flicker Store Module
// Manages Flicker dating profiles, matches, swipes, and messaging

import { postNUI } from '../../utils/nui';

const state = {
  profile: null, // Current user's profile
  potentialMatches: [], // Queue of profiles to swipe on
  matches: [], // List of matched users
  currentProfile: null, // Currently viewing profile
  matchMessages: {}, // Messages organized by match phone number
  loading: false,
  error: null,
  swipeHistory: [], // Recent swipes for undo functionality
  filters: {
    minAge: 18,
    maxAge: 100,
    maxDistance: 5000 // meters
  }
};

const getters = {
  profile: (state) => state.profile,
  potentialMatches: (state) => state.potentialMatches,
  matches: (state) => state.matches,
  currentProfile: (state) => state.currentProfile,
  loading: (state) => state.loading,
  error: (state) => state.error,
  filters: (state) => state.filters,
  swipeHistory: (state) => state.swipeHistory,
  
  hasProfile: (state) => !!state.profile,
  
  getMatchByNumber: (state) => (phoneNumber) => {
    return state.matches.find(match => match.phone_number === phoneNumber);
  },
  
  getMatchMessages: (state) => (phoneNumber) => {
    return state.matchMessages[phoneNumber] || [];
  },
  
  matchCount: (state) => state.matches.length,
  
  nextProfile: (state) => {
    return state.potentialMatches.length > 0 ? state.potentialMatches[0] : null;
  }
};

const mutations = {
  SET_PROFILE(state, profile) {
    state.profile = profile;
  },
  
  UPDATE_PROFILE(state, updates) {
    if (state.profile) {
      state.profile = { ...state.profile, ...updates };
    }
  },
  
  SET_POTENTIAL_MATCHES(state, profiles) {
    state.potentialMatches = profiles;
  },
  
  ADD_POTENTIAL_MATCHES(state, profiles) {
    state.potentialMatches = [...state.potentialMatches, ...profiles];
  },
  
  REMOVE_FIRST_POTENTIAL_MATCH(state) {
    if (state.potentialMatches.length > 0) {
      state.potentialMatches = state.potentialMatches.slice(1);
    }
  },
  
  SET_CURRENT_PROFILE(state, profile) {
    state.currentProfile = profile;
  },
  
  SET_MATCHES(state, matches) {
    state.matches = matches;
  },
  
  ADD_MATCH(state, match) {
    // Check if match already exists
    const exists = state.matches.some(m => m.phone_number === match.phone_number);
    if (!exists) {
      state.matches.unshift(match);
    }
  },
  
  REMOVE_MATCH(state, phoneNumber) {
    state.matches = state.matches.filter(match => match.phone_number !== phoneNumber);
  },
  
  SET_MATCH_MESSAGES(state, { phoneNumber, messages }) {
    state.matchMessages = {
      ...state.matchMessages,
      [phoneNumber]: messages
    };
  },
  
  ADD_MATCH_MESSAGE(state, { phoneNumber, message }) {
    if (!state.matchMessages[phoneNumber]) {
      state.matchMessages[phoneNumber] = [];
    }
    state.matchMessages[phoneNumber].push(message);
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
  
  ADD_TO_SWIPE_HISTORY(state, swipe) {
    state.swipeHistory.unshift(swipe);
    // Keep only last 10 swipes
    if (state.swipeHistory.length > 10) {
      state.swipeHistory = state.swipeHistory.slice(0, 10);
    }
  },
  
  CLEAR_SWIPE_HISTORY(state) {
    state.swipeHistory = [];
  },
  
  SET_FILTERS(state, filters) {
    state.filters = { ...state.filters, ...filters };
  },
  
  RESET_STATE(state) {
    state.profile = null;
    state.potentialMatches = [];
    state.matches = [];
    state.currentProfile = null;
    state.matchMessages = {};
    state.swipeHistory = [];
    state.error = null;
  }
};

const actions = {
  // Fetch or create user's profile
  async fetchProfile({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getFlickerProfile', {});
      
      if (response.success) {
        commit('SET_PROFILE', response.profile);
        return response.profile;
      } else {
        commit('SET_ERROR', response.message || 'Failed to fetch profile');
        return null;
      }
    } catch (error) {
      console.error('Fetch profile error:', error);
      commit('SET_ERROR', 'Failed to fetch profile');
      return null;
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Create or update profile
  async saveProfile({ commit }, profileData) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('saveFlickerProfile', profileData);
      
      if (response.success) {
        commit('SET_PROFILE', response.profile);
        return response;
      } else {
        commit('SET_ERROR', response.message || 'Failed to save profile');
        return response;
      }
    } catch (error) {
      console.error('Save profile error:', error);
      commit('SET_ERROR', 'Failed to save profile');
      return { success: false, error: 'Failed to save profile' };
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Fetch potential matches
  async fetchPotentialMatches({ commit, state }, { limit = 10, refresh = false } = {}) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getFlickerPotentialMatches', {
        limit,
        filters: state.filters
      });
      
      if (response.success) {
        if (refresh) {
          commit('SET_POTENTIAL_MATCHES', response.profiles || []);
        } else {
          commit('ADD_POTENTIAL_MATCHES', response.profiles || []);
        }
        
        // Set first profile as current if none selected
        if (!state.currentProfile && response.profiles && response.profiles.length > 0) {
          commit('SET_CURRENT_PROFILE', response.profiles[0]);
        }
        
        return response.profiles;
      } else {
        commit('SET_ERROR', response.message || 'Failed to fetch matches');
        return [];
      }
    } catch (error) {
      console.error('Fetch potential matches error:', error);
      commit('SET_ERROR', 'Failed to fetch matches');
      return [];
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Swipe on a profile
  async swipeProfile({ commit, state, dispatch }, { phoneNumber, swipeType }) {
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('swipeFlickerProfile', {
        phoneNumber,
        swipeType // 'like' or 'pass'
      });
      
      if (response.success) {
        // Add to swipe history
        const swipedProfile = state.potentialMatches[0];
        if (swipedProfile) {
          commit('ADD_TO_SWIPE_HISTORY', {
            profile: swipedProfile,
            swipeType,
            timestamp: Date.now()
          });
        }
        
        // Remove from potential matches
        commit('REMOVE_FIRST_POTENTIAL_MATCH');
        
        // Set next profile as current
        if (state.potentialMatches.length > 0) {
          commit('SET_CURRENT_PROFILE', state.potentialMatches[0]);
        } else {
          commit('SET_CURRENT_PROFILE', null);
          // Fetch more profiles
          dispatch('fetchPotentialMatches', { limit: 10 });
        }
        
        // If it's a match, add to matches
        if (response.isMatch) {
          commit('ADD_MATCH', response.match);
          
          // Return match info for notification
          return {
            success: true,
            isMatch: true,
            match: response.match
          };
        }
        
        return { success: true, isMatch: false };
      } else {
        commit('SET_ERROR', response.message || 'Failed to swipe');
        return response;
      }
    } catch (error) {
      console.error('Swipe profile error:', error);
      commit('SET_ERROR', 'Failed to swipe');
      return { success: false, error: 'Failed to swipe' };
    }
  },
  
  // Swipe right (like)
  async swipeRight({ dispatch, state }) {
    if (state.currentProfile) {
      return await dispatch('swipeProfile', {
        phoneNumber: state.currentProfile.phone_number,
        swipeType: 'like'
      });
    }
    return { success: false, error: 'No profile to swipe' };
  },
  
  // Swipe left (pass)
  async swipeLeft({ dispatch, state }) {
    if (state.currentProfile) {
      return await dispatch('swipeProfile', {
        phoneNumber: state.currentProfile.phone_number,
        swipeType: 'pass'
      });
    }
    return { success: false, error: 'No profile to swipe' };
  },
  
  // Fetch matches
  async fetchMatches({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getFlickerMatches', {});
      
      if (response.success) {
        commit('SET_MATCHES', response.matches || []);
        return response.matches;
      } else {
        commit('SET_ERROR', response.message || 'Failed to fetch matches');
        return [];
      }
    } catch (error) {
      console.error('Fetch matches error:', error);
      commit('SET_ERROR', 'Failed to fetch matches');
      return [];
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Unmatch with a user
  async unmatch({ commit }, phoneNumber) {
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('unmatchFlicker', { phoneNumber });
      
      if (response.success) {
        commit('REMOVE_MATCH', phoneNumber);
        // Clear messages for this match
        commit('SET_MATCH_MESSAGES', { phoneNumber, messages: [] });
      } else {
        commit('SET_ERROR', response.message || 'Failed to unmatch');
      }
      
      return response;
    } catch (error) {
      console.error('Unmatch error:', error);
      commit('SET_ERROR', 'Failed to unmatch');
      return { success: false };
    }
  },
  
  // Fetch messages with a match
  async fetchMatchMessages({ commit }, phoneNumber) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('getFlickerMessages', { phoneNumber });
      
      if (response.success) {
        commit('SET_MATCH_MESSAGES', {
          phoneNumber,
          messages: response.messages || []
        });
        return response.messages;
      } else {
        commit('SET_ERROR', response.message || 'Failed to fetch messages');
        return [];
      }
    } catch (error) {
      console.error('Fetch match messages error:', error);
      commit('SET_ERROR', 'Failed to fetch messages');
      return [];
    } finally {
      commit('SET_LOADING', false);
    }
  },
  
  // Send message to a match
  async sendMatchMessage({ commit }, { phoneNumber, content }) {
    commit('CLEAR_ERROR');
    
    try {
      const response = await postNUI('sendFlickerMessage', {
        phoneNumber,
        content
      });
      
      if (response.success) {
        commit('ADD_MATCH_MESSAGE', {
          phoneNumber,
          message: response.message
        });
      } else {
        commit('SET_ERROR', response.message || 'Failed to send message');
      }
      
      return response;
    } catch (error) {
      console.error('Send match message error:', error);
      commit('SET_ERROR', 'Failed to send message');
      return { success: false };
    }
  },
  
  // Update filters
  updateFilters({ commit, dispatch }, filters) {
    commit('SET_FILTERS', filters);
    // Refresh potential matches with new filters
    dispatch('fetchPotentialMatches', { limit: 10, refresh: true });
  },
  
  // Set current profile
  setCurrentProfile({ commit }, profile) {
    commit('SET_CURRENT_PROFILE', profile);
  },
  
  // Handle real-time updates from server
  handleNewMatch({ commit }, match) {
    commit('ADD_MATCH', match);
  },
  
  handleNewMessage({ commit }, { phoneNumber, message }) {
    commit('ADD_MATCH_MESSAGE', { phoneNumber, message });
  },
  
  handleUnmatch({ commit }, { phoneNumber }) {
    commit('REMOVE_MATCH', phoneNumber);
  },
  
  // Clear error
  clearError({ commit }) {
    commit('CLEAR_ERROR');
  },
  
  // Reset state (e.g., when deactivating profile)
  resetState({ commit }) {
    commit('RESET_STATE');
  }
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions
};
