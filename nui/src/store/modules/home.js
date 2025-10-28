import { nuiCallback } from '../../utils/nui';

const state = {
  properties: [],
  loading: false,
  error: null
};

const getters = {
  getPropertyById: (state) => (id) => {
    return state.properties.find(p => p.id === id);
  },

  lockedProperties: (state) => {
    return state.properties.filter(p => p.locked);
  },

  unlockedProperties: (state) => {
    return state.properties.filter(p => !p.locked);
  }
};

const mutations = {
  SET_PROPERTIES(state, properties) {
    state.properties = properties;
  },

  ADD_PROPERTY(state, property) {
    const index = state.properties.findIndex(p => p.id === property.id);
    if (index !== -1) {
      state.properties.splice(index, 1, property);
    } else {
      state.properties.push(property);
    }
  },

  UPDATE_PROPERTY(state, { id, updates }) {
    const property = state.properties.find(p => p.id === id);
    if (property) {
      Object.assign(property, updates);
    }
  },

  REMOVE_PROPERTY(state, id) {
    const index = state.properties.findIndex(p => p.id === id);
    if (index !== -1) {
      state.properties.splice(index, 1);
    }
  },

  SET_LOADING(state, loading) {
    state.loading = loading;
  },

  SET_ERROR(state, error) {
    state.error = error;
  }
};

const actions = {
  async fetchProperties({ commit }) {
    commit('SET_LOADING', true);
    commit('SET_ERROR', null);

    try {
      const response = await nuiCallback('home:getProperties', {});

      if (response.success) {
        commit('SET_PROPERTIES', response.properties || []);
      } else {
        throw new Error(response.message || 'Failed to fetch properties');
      }
    } catch (error) {
      console.error('Error fetching properties:', error);
      commit('SET_ERROR', error.message);
      throw error;
    } finally {
      commit('SET_LOADING', false);
    }
  },

  async toggleLock({ commit }, { propertyId, action }) {
    try {
      const response = await nuiCallback('home:toggleLock', {
        propertyId,
        action
      });

      if (response.success) {
        commit('UPDATE_PROPERTY', {
          id: propertyId,
          updates: { locked: action === 'lock' }
        });
      }

      return response;
    } catch (error) {
      console.error('Error toggling lock:', error);
      throw error;
    }
  },

  async grantKey({ commit }, { propertyId, targetNumber, expirationHours }) {
    try {
      const response = await nuiCallback('home:grantKey', {
        propertyId,
        targetNumber,
        expirationHours
      });

      return response;
    } catch (error) {
      console.error('Error granting key:', error);
      throw error;
    }
  },

  async revokeKey({ commit }, keyId) {
    try {
      const response = await nuiCallback('home:revokeKey', {
        keyId
      });

      return response;
    } catch (error) {
      console.error('Error revoking key:', error);
      throw error;
    }
  },

  // Handle real-time updates from server
  handlePropertyUpdate({ commit }, property) {
    commit('ADD_PROPERTY', property);
  },

  handlePropertyLockChange({ commit }, { id, locked }) {
    commit('UPDATE_PROPERTY', { id, updates: { locked } });
  }
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions
};
