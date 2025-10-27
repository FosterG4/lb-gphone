<template>
  <div class="weather-app">
    <div class="weather-header">
      <h1>Weather</h1>
      <button class="refresh-button" @click="refreshWeather" :disabled="isLoading">
        <span class="icon" :class="{ spinning: isLoading }">🔄</span>
      </button>
    </div>

    <div class="weather-content" v-if="!isLoading && currentWeather">
      <!-- Current Weather -->
      <div class="current-weather">
        <div class="weather-icon-large">
          {{ getWeatherIcon(currentWeather.type) }}
        </div>
        <div class="temperature-display">
          <span class="temperature">{{ currentWeather.temperature }}°</span>
          <span class="weather-type">{{ formatWeatherType(currentWeather.type) }}</span>
        </div>
        <div class="weather-details">
          <div class="detail-item">
            <span class="detail-icon">💨</span>
            <span class="detail-label">Wind</span>
            <span class="detail-value">{{ currentWeather.windSpeed }} mph</span>
          </div>
          <div class="detail-item">
            <span class="detail-icon">💧</span>
            <span class="detail-label">Humidity</span>
            <span class="detail-value">{{ currentWeather.humidity }}%</span>
          </div>
          <div class="detail-item">
            <span class="detail-icon">🌧️</span>
            <span class="detail-label">Precipitation</span>
            <span class="detail-value">{{ currentWeather.precipitation }}%</span>
          </div>
        </div>
      </div>

      <!-- 24-Hour Forecast -->
      <div class="forecast-section" v-if="forecast && forecast.length > 0">
        <h2>24-Hour Forecast</h2>
        <div class="forecast-list">
          <div 
            v-for="(hour, index) in forecast" 
            :key="index"
            class="forecast-item"
          >
            <div class="forecast-time">{{ hour.time }}</div>
            <div class="forecast-icon">{{ getWeatherIcon(hour.type) }}</div>
            <div class="forecast-temp">{{ hour.temperature }}°</div>
            <div class="forecast-precipitation">
              <span class="icon">💧</span>
              <span>{{ hour.precipitation }}%</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Additional Info -->
      <div class="additional-info">
        <div class="info-card">
          <div class="info-icon">🌅</div>
          <div class="info-content">
            <div class="info-label">Sunrise</div>
            <div class="info-value">{{ currentWeather.sunrise || '06:00' }}</div>
          </div>
        </div>
        <div class="info-card">
          <div class="info-icon">🌇</div>
          <div class="info-content">
            <div class="info-label">Sunset</div>
            <div class="info-value">{{ currentWeather.sunset || '18:00' }}</div>
          </div>
        </div>
      </div>

      <!-- Last Updated -->
      <div class="last-updated">
        Last updated: {{ formatLastUpdated(lastUpdated) }}
      </div>
    </div>

    <!-- Loading State -->
    <div class="loading-state" v-if="isLoading">
      <div class="spinner"></div>
      <p>Loading weather data...</p>
    </div>

    <!-- Error State -->
    <div class="error-state" v-if="error && !isLoading">
      <div class="error-icon">⚠️</div>
      <p>{{ error }}</p>
      <button class="retry-button" @click="refreshWeather">Try Again</button>
    </div>
  </div>
</template>

<script>
import { fetchNui } from '../utils/nui';

export default {
  name: 'Weather',
  data() {
    return {
      currentWeather: null,
      forecast: [],
      lastUpdated: null,
      isLoading: true,
      error: null,
      updateInterval: null
    };
  },
  mounted() {
    this.loadWeatherData();
    this.startAutoUpdate();
  },
  beforeUnmount() {
    this.stopAutoUpdate();
  },
  methods: {
    async loadWeatherData() {
      this.isLoading = true;
      this.error = null;

      try {
        const response = await fetchNui('getWeatherData');
        
        if (response.success) {
          this.currentWeather = response.current;
          this.forecast = response.forecast || [];
          this.lastUpdated = Date.now();
        } else {
          this.error = response.message || 'Failed to load weather data';
        }
      } catch (error) {
        console.error('Failed to load weather data:', error);
        this.error = 'Unable to connect to weather service';
      } finally {
        this.isLoading = false;
      }
    },

    async refreshWeather() {
      await this.loadWeatherData();
    },

    startAutoUpdate() {
      // Update weather every 5 minutes
      this.updateInterval = setInterval(() => {
        this.loadWeatherData();
      }, 300000); // 5 minutes
    },

    stopAutoUpdate() {
      if (this.updateInterval) {
        clearInterval(this.updateInterval);
      }
    },

    getWeatherIcon(weatherType) {
      const icons = {
        'CLEAR': '☀️',
        'EXTRASUNNY': '🌞',
        'CLOUDS': '☁️',
        'OVERCAST': '☁️',
        'RAIN': '🌧️',
        'CLEARING': '🌤️',
        'THUNDER': '⛈️',
        'SMOG': '🌫️',
        'FOGGY': '🌫️',
        'XMAS': '❄️',
        'SNOWLIGHT': '🌨️',
        'BLIZZARD': '❄️',
        'SNOW': '❄️',
        'HALLOWEEN': '🎃',
        'NEUTRAL': '🌤️'
      };
      
      return icons[weatherType] || '🌤️';
    },

    formatWeatherType(weatherType) {
      const names = {
        'CLEAR': 'Clear',
        'EXTRASUNNY': 'Extra Sunny',
        'CLOUDS': 'Cloudy',
        'OVERCAST': 'Overcast',
        'RAIN': 'Rainy',
        'CLEARING': 'Clearing',
        'THUNDER': 'Thunderstorm',
        'SMOG': 'Smoggy',
        'FOGGY': 'Foggy',
        'XMAS': 'Snowy',
        'SNOWLIGHT': 'Light Snow',
        'BLIZZARD': 'Blizzard',
        'SNOW': 'Snowy',
        'HALLOWEEN': 'Spooky',
        'NEUTRAL': 'Neutral'
      };
      
      return names[weatherType] || weatherType;
    },

    formatLastUpdated(timestamp) {
      if (!timestamp) return 'Never';
      
      const now = Date.now();
      const diff = now - timestamp;
      const minutes = Math.floor(diff / 60000);
      
      if (minutes < 1) return 'Just now';
      if (minutes === 1) return '1 minute ago';
      if (minutes < 60) return `${minutes} minutes ago`;
      
      const hours = Math.floor(minutes / 60);
      if (hours === 1) return '1 hour ago';
      return `${hours} hours ago`;
    }
  }
};
</script>

<style scoped>
.weather-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--background-color);
  color: var(--text-color);
}

.weather-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid var(--border-color);
}

.weather-header h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.refresh-button {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.3s;
}

.refresh-button:hover:not(:disabled) {
  background: var(--primary-color);
  border-color: var(--primary-color);
}

.refresh-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.refresh-button .icon {
  font-size: 20px;
  transition: transform 0.3s;
}

.refresh-button .icon.spinning {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.weather-content {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
}

/* Current Weather */
.current-weather {
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--accent-color) 100%);
  border-radius: 16px;
  padding: 30px;
  color: white;
  text-align: center;
  margin-bottom: 20px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.weather-icon-large {
  font-size: 80px;
  margin-bottom: 10px;
  animation: float 3s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

.temperature-display {
  margin-bottom: 20px;
}

.temperature {
  display: block;
  font-size: 64px;
  font-weight: 700;
  line-height: 1;
}

.weather-type {
  display: block;
  font-size: 20px;
  font-weight: 500;
  opacity: 0.9;
  margin-top: 5px;
}

.weather-details {
  display: flex;
  justify-content: space-around;
  margin-top: 20px;
  padding-top: 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.3);
}

.detail-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
}

.detail-icon {
  font-size: 24px;
}

.detail-label {
  font-size: 12px;
  opacity: 0.8;
}

.detail-value {
  font-size: 16px;
  font-weight: 600;
}

/* Forecast Section */
.forecast-section {
  margin-bottom: 20px;
}

.forecast-section h2 {
  margin: 0 0 15px 0;
  font-size: 18px;
  font-weight: 600;
}

.forecast-list {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  padding-bottom: 10px;
}

.forecast-list::-webkit-scrollbar {
  height: 6px;
}

.forecast-list::-webkit-scrollbar-track {
  background: var(--card-background);
  border-radius: 3px;
}

.forecast-list::-webkit-scrollbar-thumb {
  background: var(--border-color);
  border-radius: 3px;
}

.forecast-item {
  flex-shrink: 0;
  width: 80px;
  background: var(--card-background);
  border-radius: 12px;
  padding: 15px 10px;
  text-align: center;
  transition: all 0.3s;
}

.forecast-item:hover {
  background: var(--primary-color);
  color: white;
  transform: translateY(-2px);
}

.forecast-time {
  font-size: 12px;
  font-weight: 600;
  margin-bottom: 8px;
  opacity: 0.7;
}

.forecast-icon {
  font-size: 32px;
  margin-bottom: 8px;
}

.forecast-temp {
  font-size: 18px;
  font-weight: 700;
  margin-bottom: 5px;
}

.forecast-precipitation {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 3px;
  font-size: 11px;
  opacity: 0.7;
}

.forecast-precipitation .icon {
  font-size: 12px;
}

/* Additional Info */
.additional-info {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 15px;
  margin-bottom: 20px;
}

.info-card {
  display: flex;
  align-items: center;
  gap: 15px;
  background: var(--card-background);
  border-radius: 12px;
  padding: 20px;
}

.info-icon {
  font-size: 32px;
}

.info-content {
  flex: 1;
}

.info-label {
  font-size: 12px;
  opacity: 0.7;
  margin-bottom: 5px;
}

.info-value {
  font-size: 18px;
  font-weight: 600;
}

/* Last Updated */
.last-updated {
  text-align: center;
  font-size: 12px;
  opacity: 0.5;
  padding: 10px;
}

/* Loading State */
.loading-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 4px solid var(--border-color);
  border-top-color: var(--primary-color);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

.loading-state p {
  font-size: 14px;
  opacity: 0.7;
}

/* Error State */
.error-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
  padding: 40px;
  text-align: center;
}

.error-icon {
  font-size: 64px;
}

.error-state p {
  font-size: 16px;
  opacity: 0.7;
}

.retry-button {
  padding: 12px 24px;
  background: var(--primary-color);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.retry-button:hover {
  background: var(--accent-color);
  transform: translateY(-2px);
}
</style>
