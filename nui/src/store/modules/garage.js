import { sendNUIMessage } from '../../utils/nui';

const state = {
  vehicles: [],
  valetEnabled: true,
  valetCost: 100,
  loading: false,
  error: null
};

const getters = {
  getVehicleByPlate: (state) => (plate) => {
    return state.vehicles.find(v => v.plate === plate);
  },

  vehiclesByStatus: (state) => (status) => {
    return state.vehicles.filter(v => v.status === status);
  },

  storedVehicles: (state) => {
    return state.vehicles.filter(v => v.status === 'stored');
  },

  outVehicles: (state) => {
    return state.vehicles.filter(v => v.status === 'out');
  },

  impoundedVehicles: (state) => {
    return state.vehicles.filter(v => v.status === 'impounded');
  }
};

const mutations = {
  SET_VEHICLES(state, vehicles) {
    state.vehicles = vehicles;
  },

  ADD_VEHICLE(state, vehicle) {
    const index = state.vehicles.findIndex(v => v.plate === vehicle.plate);
    if (index !== -1) {
      state.vehicles.splice(index, 1, vehicle);
    } else {
      state.vehicles.push(vehicle);
    }
  },

  UPDATE_VEHICLE(state, { plate, updates }) {
    const vehicle = state.vehicles.find(v => v.plate === plate);
    if (vehicle) {
      Object.assign(vehicle, updates);
    }
  },

  UPDATE_VEHICLE_LOCATION(state, { plate, location }) {
    const vehicle = state.vehicles.find(v => v.plate === plate);
    if (vehicle) {
      vehicle.location_x = location.x;
      vehicle.location_y = location.y;
      vehicle.location_z = location.z;
    }
  },

  REMOVE_VEHICLE(state, plate) {
    const index = state.vehicles.findIndex(v => v.plate === plate);
    if (index !== -1) {
      state.vehicles.splice(index, 1);
    }
  },

  SET_VALET_CONFIG(state, { enabled, cost }) {
    state.valetEnabled = enabled;
    state.valetCost = cost;
  },

  SET_LOADING(state, loading) {
    state.loading = loading;
  },

  SET_ERROR(state, error) {
    state.error = error;
  }
};

const actions = {
  async fetchVehicles({ commit }) {
    commit('SET_LOADING', true);
    commit('SET_ERROR', null);

    try {
      const response = await sendNUIMessage('garage:getVehicles', {});

      if (response.success) {
        commit('SET_VEHICLES', response.vehicles || []);

        if (response.config) {
          commit('SET_VALET_CONFIG', {
            enabled: response.config.valetEnabled,
            cost: response.config.valetCost
          });
        }
      } else {
        throw new Error(response.message || 'Failed to fetch vehicles');
      }
    } catch (error) {
      console.error('Error fetching vehicles:', error);
      commit('SET_ERROR', error.message);
      throw error;
    } finally {
      commit('SET_LOADING', false);
    }
  },

  async requestValetService({ commit }, plate) {
    try {
      const response = await sendNUIMessage('garage:requestValet', { plate });

      if (response.success) {
        // Update vehicle status to 'out'
        commit('UPDATE_VEHICLE', {
          plate,
          updates: { status: 'out' }
        });
      }

      return response;
    } catch (error) {
      console.error('Error requesting valet:', error);
      throw error;
    }
  },

  async updateVehicleLocation({ commit }, { plate, location }) {
    commit('UPDATE_VEHICLE_LOCATION', { plate, location });
  },

  async locateVehicle({ commit }, plate) {
    try {
      const response = await sendNUIMessage('garage:locateVehicle', { plate });

      if (response.success && response.location) {
        commit('UPDATE_VEHICLE_LOCATION', {
          plate,
          location: response.location
        });
      }

      return response;
    } catch (error) {
      console.error('Error locating vehicle:', error);
      throw error;
    }
  },

  // Handle real-time updates from server
  handleVehicleUpdate({ commit }, vehicle) {
    commit('ADD_VEHICLE', vehicle);
  },

  handleVehicleStatusChange({ commit }, { plate, status }) {
    commit('UPDATE_VEHICLE', { plate, updates: { status } });
  },

  handleVehicleLocationUpdate({ commit }, { plate, location }) {
    commit('UPDATE_VEHICLE_LOCATION', { plate, location });
  }
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions
};
