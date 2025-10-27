<template>
  <div class="appstore-app">
    <div class="appstore-header">
      <h1>App Store</h1>
      <div class="view-toggle">
        <button 
          :class="{ active: viewMode === 'grid' }" 
          @click="viewMode = 'grid'"
          title="Grid View"
        >
          <span class="icon">⊞</span>
        </button>
        <button 
          :class="{ active: viewMode === 'list' }" 
          @click="viewMode = 'list'"
          title="List View"
        >
          <span class="icon">☰</span>
        </button>
      </div>
    </div>

    <!-- Search Bar -->
    <div class="search-bar">
      <input 
        v-model="searchQuery" 
        type="text" 
        placeholder="Search apps..."
        class="search-input"
      />
      <span class="search-icon">🔍</span>
    </div>

    <!-- Category Filter -->
    <div class="category-filter">
      <button 
        v-for="category in categories" 
        :key="category.id"
        :class="{ active: selectedCategory === category.id }"
        @click="selectedCategory = category.id"
        class="category-button"
      >
        {{ category.name }}
      </button>
    </div>

    <div class="appstore-content" v-if="!isLoading">
      <!-- Grid View -->
      <div v-if="viewMode === 'grid'" class="apps-grid">
        <div 
          v-for="app in filteredApps" 
          :key="app.id"
          class="app-card"
          @click="selectApp(app)"
        >
          <div class="app-icon">{{ app.icon }}</div>
          <div class="app-info">
            <h3 class="app-name">{{ app.name }}</h3>
            <div class="app-rating">
              <span class="stars">{{ getStarRating(app.rating) }}</span>
              <span class="rating-value">{{ app.rating }}</span>
            </div>
            <div class="app-status">
              <span v-if="isInstalled(app.id)" class="installed-badge">✓ Installed</span>
              <span v-else class="install-badge">Get</span>
            </div>
          </div>
        </div>
      </div>

      <!-- List View -->
      <div v-if="viewMode === 'list'" class="apps-list">
        <div 
          v-for="app in filteredApps" 
          :key="app.id"
          class="app-list-item"
          @click="selectApp(app)"
        >
          <div class="app-icon-small">{{ app.icon }}</div>
          <div class="app-details">
            <h3 class="app-name">{{ app.name }}</h3>
            <p class="app-description-short">{{ app.shortDescription }}</p>
            <div class="app-meta">
              <span class="app-category">{{ getCategoryName(app.category) }}</span>
              <span class="app-rating">
                {{ getStarRating(app.rating) }} {{ app.rating }}
              </span>
            </div>
          </div>
          <div class="app-action">
            <button 
              v-if="isInstalled(app.id)" 
              class="installed-button"
              @click.stop="uninstallApp(app)"
            >
              ✓ Installed
            </button>
            <button 
              v-else 
              class="install-button"
              @click.stop="installApp(app)"
            >
              Get
            </button>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="filteredApps.length === 0" class="empty-state">
        <div class="empty-icon">📱</div>
        <p>No apps found</p>
        <p class="empty-subtitle">Try adjusting your search or filters</p>
      </div>
    </div>

    <!-- Loading State -->
    <div class="loading-state" v-if="isLoading">
      <div class="spinner"></div>
      <p>Loading apps...</p>
    </div>

    <!-- App Detail Modal -->
    <div v-if="selectedAppDetail" class="app-detail-modal" @click="closeAppDetail">
      <div class="modal-content" @click.stop>
        <button class="close-button" @click="closeAppDetail">✕</button>
        
        <div class="app-detail-header">
          <div class="app-icon-large">{{ selectedAppDetail.icon }}</div>
          <div class="app-title-section">
            <h2>{{ selectedAppDetail.name }}</h2>
            <p class="app-developer">{{ selectedAppDetail.developer }}</p>
            <div class="app-rating-large">
              <span class="stars">{{ getStarRating(selectedAppDetail.rating) }}</span>
              <span class="rating-value">{{ selectedAppDetail.rating }}</span>
              <span class="rating-count">({{ selectedAppDetail.ratingCount }} ratings)</span>
            </div>
          </div>
        </div>

        <div class="app-action-buttons">
          <button 
            v-if="isInstalled(selectedAppDetail.id)" 
            class="uninstall-button"
            @click="uninstallApp(selectedAppDetail)"
          >
            Uninstall
          </button>
          <button 
            v-else 
            class="install-button-large"
            @click="installApp(selectedAppDetail)"
          >
            Install
          </button>
        </div>

        <div class="app-detail-body">
          <div class="detail-section">
            <h3>Description</h3>
            <p class="app-description">{{ selectedAppDetail.description }}</p>
          </div>

          <div class="detail-section" v-if="selectedAppDetail.screenshots && selectedAppDetail.screenshots.length > 0">
            <h3>Screenshots</h3>
            <div class="screenshots-gallery">
              <div 
                v-for="(screenshot, index) in selectedAppDetail.screenshots" 
                :key="index"
                class="screenshot-item"
              >
                <div class="screenshot-placeholder">
                  <span class="screenshot-icon">🖼️</span>
                  <span class="screenshot-label">Screenshot {{ index + 1 }}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="detail-section">
            <h3>Information</h3>
            <div class="info-grid">
              <div class="info-item">
                <span class="info-label">Category</span>
                <span class="info-value">{{ getCategoryName(selectedAppDetail.category) }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Version</span>
                <span class="info-value">{{ selectedAppDetail.version }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Size</span>
                <span class="info-value">{{ selectedAppDetail.size }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Developer</span>
                <span class="info-value">{{ selectedAppDetail.developer }}</span>
              </div>
            </div>
          </div>

          <div class="detail-section" v-if="selectedAppDetail.features && selectedAppDetail.features.length > 0">
            <h3>Features</h3>
            <ul class="features-list">
              <li v-for="(feature, index) in selectedAppDetail.features" :key="index">
                {{ feature }}
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { fetchNui } from '../utils/nui';

export default {
  name: 'AppStore',
  data() {
    return {
      apps: [],
      installedApps: [],
      searchQuery: '',
      selectedCategory: 'all',
      viewMode: 'grid', // 'grid' or 'list'
      selectedAppDetail: null,
      isLoading: true,
      categories: [
        { id: 'all', name: 'All' },
        { id: 'communication', name: 'Communication' },
        { id: 'media', name: 'Media' },
        { id: 'utilities', name: 'Utilities' },
        { id: 'social', name: 'Social' },
        { id: 'finance', name: 'Finance' },
        { id: 'entertainment', name: 'Entertainment' },
        { id: 'productivity', name: 'Productivity' }
      ]
    };
  },
  computed: {
    filteredApps() {
      let filtered = this.apps;

      // Filter by category
      if (this.selectedCategory !== 'all') {
        filtered = filtered.filter(app => app.category === this.selectedCategory);
      }

      // Filter by search query
      if (this.searchQuery.trim()) {
        const query = this.searchQuery.toLowerCase();
        filtered = filtered.filter(app => 
          app.name.toLowerCase().includes(query) ||
          app.description.toLowerCase().includes(query) ||
          app.shortDescription.toLowerCase().includes(query)
        );
      }

      return filtered;
    }
  },
  mounted() {
    this.loadApps();
  },
  methods: {
    async loadApps() {
      this.isLoading = true;

      try {
        const response = await fetchNui('getAvailableApps');
        
        if (response.success) {
          this.apps = response.apps || [];
          this.installedApps = response.installedApps || [];
        } else {
          console.error('Failed to load apps:', response.message);
        }
      } catch (error) {
        console.error('Failed to load apps:', error);
      } finally {
        this.isLoading = false;
      }
    },

    async installApp(app) {
      try {
        const response = await fetchNui('installApp', { appId: app.id });
        
        if (response.success) {
          this.installedApps.push(app.id);
          this.$store.commit('phone/showNotification', {
            title: 'App Installed',
            message: `${app.name} has been installed successfully`,
            type: 'success'
          });
        } else {
          this.$store.commit('phone/showNotification', {
            title: 'Installation Failed',
            message: response.message || 'Failed to install app',
            type: 'error'
          });
        }
      } catch (error) {
        console.error('Failed to install app:', error);
        this.$store.commit('phone/showNotification', {
          title: 'Installation Failed',
          message: 'An error occurred while installing the app',
          type: 'error'
        });
      }
    },

    async uninstallApp(app) {
      try {
        const response = await fetchNui('uninstallApp', { appId: app.id });
        
        if (response.success) {
          const index = this.installedApps.indexOf(app.id);
          if (index > -1) {
            this.installedApps.splice(index, 1);
          }
          this.$store.commit('phone/showNotification', {
            title: 'App Uninstalled',
            message: `${app.name} has been uninstalled`,
            type: 'success'
          });
        } else {
          this.$store.commit('phone/showNotification', {
            title: 'Uninstall Failed',
            message: response.message || 'Failed to uninstall app',
            type: 'error'
          });
        }
      } catch (error) {
        console.error('Failed to uninstall app:', error);
        this.$store.commit('phone/showNotification', {
          title: 'Uninstall Failed',
          message: 'An error occurred while uninstalling the app',
          type: 'error'
        });
      }
    },

    selectApp(app) {
      this.selectedAppDetail = app;
    },

    closeAppDetail() {
      this.selectedAppDetail = null;
    },

    isInstalled(appId) {
      return this.installedApps.includes(appId);
    },

    getStarRating(rating) {
      const fullStars = Math.floor(rating);
      const hasHalfStar = rating % 1 >= 0.5;
      let stars = '★'.repeat(fullStars);
      if (hasHalfStar) stars += '☆';
      const emptyStars = 5 - Math.ceil(rating);
      stars += '☆'.repeat(emptyStars);
      return stars;
    },

    getCategoryName(categoryId) {
      const category = this.categories.find(c => c.id === categoryId);
      return category ? category.name : categoryId;
    }
  }
};
</script>

<style scoped>
.appstore-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--background-color);
  color: var(--text-color);
}

.appstore-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid var(--border-color);
}

.appstore-header h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.view-toggle {
  display: flex;
  gap: 5px;
}

.view-toggle button {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.view-toggle button.active {
  background: var(--primary-color);
  border-color: var(--primary-color);
  color: white;
}

.view-toggle button:hover:not(.active) {
  background: var(--border-color);
}

.view-toggle .icon {
  font-size: 18px;
}

/* Search Bar */
.search-bar {
  position: relative;
  padding: 15px 20px;
  border-bottom: 1px solid var(--border-color);
}

.search-input {
  width: 100%;
  padding: 12px 40px 12px 15px;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 10px;
  font-size: 14px;
  color: var(--text-color);
  transition: all 0.3s;
}

.search-input:focus {
  outline: none;
  border-color: var(--primary-color);
}

.search-icon {
  position: absolute;
  right: 35px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 18px;
  opacity: 0.5;
  pointer-events: none;
}

/* Category Filter */
.category-filter {
  display: flex;
  gap: 8px;
  padding: 15px 20px;
  overflow-x: auto;
  border-bottom: 1px solid var(--border-color);
}

.category-filter::-webkit-scrollbar {
  height: 4px;
}

.category-filter::-webkit-scrollbar-track {
  background: transparent;
}

.category-filter::-webkit-scrollbar-thumb {
  background: var(--border-color);
  border-radius: 2px;
}

.category-button {
  flex-shrink: 0;
  padding: 8px 16px;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 20px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s;
  white-space: nowrap;
}

.category-button.active {
  background: var(--primary-color);
  border-color: var(--primary-color);
  color: white;
}

.category-button:hover:not(.active) {
  background: var(--border-color);
}

/* Content */
.appstore-content {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
}

/* Grid View */
.apps-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 15px;
}

.app-card {
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 12px;
  padding: 15px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
}

.app-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  border-color: var(--primary-color);
}

.app-icon {
  font-size: 48px;
  margin-bottom: 10px;
}

.app-info {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.app-name {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.app-rating {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  font-size: 12px;
}

.stars {
  color: #FFD700;
}

.rating-value {
  opacity: 0.7;
}

.app-status {
  margin-top: 5px;
}

.installed-badge {
  display: inline-block;
  padding: 4px 12px;
  background: var(--primary-color);
  color: white;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}

.install-badge {
  display: inline-block;
  padding: 4px 12px;
  background: var(--accent-color);
  color: white;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
}

/* List View */
.apps-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.app-list-item {
  display: flex;
  align-items: center;
  gap: 15px;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 12px;
  padding: 15px;
  cursor: pointer;
  transition: all 0.3s;
}

.app-list-item:hover {
  border-color: var(--primary-color);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.app-icon-small {
  font-size: 40px;
  flex-shrink: 0;
}

.app-details {
  flex: 1;
  min-width: 0;
}

.app-description-short {
  margin: 5px 0;
  font-size: 13px;
  opacity: 0.7;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.app-meta {
  display: flex;
  gap: 15px;
  font-size: 12px;
  opacity: 0.6;
}

.app-category {
  text-transform: capitalize;
}

.app-action {
  flex-shrink: 0;
}

.installed-button,
.install-button {
  padding: 8px 20px;
  border: none;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.installed-button {
  background: var(--primary-color);
  color: white;
}

.install-button {
  background: var(--accent-color);
  color: white;
}

.installed-button:hover,
.install-button:hover {
  opacity: 0.8;
  transform: scale(1.05);
}

/* Empty State */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
}

.empty-icon {
  font-size: 64px;
  margin-bottom: 20px;
  opacity: 0.3;
}

.empty-state p {
  margin: 5px 0;
  font-size: 16px;
}

.empty-subtitle {
  font-size: 14px;
  opacity: 0.6;
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

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.loading-state p {
  font-size: 14px;
  opacity: 0.7;
}

/* App Detail Modal */
.app-detail-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.modal-content {
  background: var(--background-color);
  border-radius: 16px;
  max-width: 500px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  position: relative;
}

.close-button {
  position: absolute;
  top: 15px;
  right: 15px;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 50%;
  font-size: 18px;
  cursor: pointer;
  transition: all 0.3s;
  z-index: 1;
}

.close-button:hover {
  background: var(--accent-color);
  color: white;
  border-color: var(--accent-color);
}

.app-detail-header {
  display: flex;
  gap: 20px;
  padding: 30px;
  border-bottom: 1px solid var(--border-color);
}

.app-icon-large {
  font-size: 80px;
  flex-shrink: 0;
}

.app-title-section {
  flex: 1;
}

.app-title-section h2 {
  margin: 0 0 5px 0;
  font-size: 22px;
  font-weight: 600;
}

.app-developer {
  margin: 0 0 10px 0;
  font-size: 14px;
  opacity: 0.7;
}

.app-rating-large {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}

.rating-count {
  opacity: 0.6;
}

.app-action-buttons {
  padding: 20px 30px;
  border-bottom: 1px solid var(--border-color);
}

.install-button-large,
.uninstall-button {
  width: 100%;
  padding: 14px;
  border: none;
  border-radius: 12px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.install-button-large {
  background: var(--accent-color);
  color: white;
}

.uninstall-button {
  background: var(--card-background);
  color: var(--accent-color);
  border: 2px solid var(--accent-color);
}

.install-button-large:hover,
.uninstall-button:hover {
  opacity: 0.8;
  transform: translateY(-2px);
}

.app-detail-body {
  padding: 30px;
}

.detail-section {
  margin-bottom: 30px;
}

.detail-section:last-child {
  margin-bottom: 0;
}

.detail-section h3 {
  margin: 0 0 15px 0;
  font-size: 18px;
  font-weight: 600;
}

.app-description {
  margin: 0;
  font-size: 14px;
  line-height: 1.6;
  opacity: 0.8;
}

/* Screenshots */
.screenshots-gallery {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  padding-bottom: 10px;
}

.screenshots-gallery::-webkit-scrollbar {
  height: 6px;
}

.screenshots-gallery::-webkit-scrollbar-track {
  background: var(--card-background);
  border-radius: 3px;
}

.screenshots-gallery::-webkit-scrollbar-thumb {
  background: var(--border-color);
  border-radius: 3px;
}

.screenshot-item {
  flex-shrink: 0;
  width: 200px;
  height: 120px;
  border-radius: 8px;
  overflow: hidden;
}

.screenshot-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 8px;
}

.screenshot-icon {
  font-size: 32px;
  opacity: 0.3;
  margin-bottom: 5px;
}

.screenshot-label {
  font-size: 11px;
  opacity: 0.5;
}

/* Info Grid */
.info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 15px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.info-label {
  font-size: 12px;
  opacity: 0.6;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.info-value {
  font-size: 14px;
  font-weight: 500;
}

/* Features List */
.features-list {
  margin: 0;
  padding-left: 20px;
}

.features-list li {
  margin-bottom: 8px;
  font-size: 14px;
  line-height: 1.5;
  opacity: 0.8;
}

.features-list li:last-child {
  margin-bottom: 0;
}
</style>
