<template>
  <div class="pages-app">
    <!-- Header -->
    <div class="pages-header">
      <div class="search-section">
        <input 
          v-model="searchQuery" 
          type="text" 
          placeholder="Search business pages..."
          class="search-input"
        />
      </div>
      
      <div class="filter-section">
        <select v-model="selectedCategory" class="category-filter">
          <option value="">All Categories</option>
          <option value="restaurant">Restaurant</option>
          <option value="retail">Retail</option>
          <option value="automotive">Automotive</option>
          <option value="services">Services</option>
          <option value="entertainment">Entertainment</option>
        </select>
      </div>
      
      <button @click="showCreatePage = true" class="create-page-btn">
        + Create Page
      </button>
    </div>

    <!-- Tabs -->
    <div class="tabs">
      <button 
        @click="activeTab = 'discover'" 
        class="tab"
        :class="{ active: activeTab === 'discover' }"
      >
        Discover
      </button>
      <button 
        @click="activeTab = 'my-pages'" 
        class="tab"
        :class="{ active: activeTab === 'my-pages' }"
      >
        My Pages
      </button>
      <button 
        @click="activeTab = 'following'" 
        class="tab"
        :class="{ active: activeTab === 'following' }"
      >
        Following
      </button>
    </div>

    <!-- Discover Tab -->
    <div v-if="activeTab === 'discover'" class="discover-section">
      <div class="pages-grid">
        <div 
          v-for="page in filteredPages" 
          :key="page.id"
          class="page-card"
          @click="viewPage(page)"
        >
          <div class="page-header">
            <div class="page-avatar">
              <div class="demo-avatar">{{ page.emoji }}</div>
            </div>
            <div class="page-info">
              <h4 class="page-name">{{ page.name }}</h4>
              <p class="page-category">{{ page.category }}</p>
              <div class="page-stats">
                <span class="followers-count">{{ page.followers }} followers</span>
                <span class="page-rating">⭐ {{ page.rating }}</span>
              </div>
            </div>
          </div>
          
          <div class="page-description">
            <p>{{ page.description }}</p>
          </div>
          
          <div class="page-contact">
            <span class="contact-phone">📞 {{ page.phone }}</span>
            <span class="contact-location">📍 {{ page.location }}</span>
          </div>
          
          <div class="page-actions">
            <button 
              @click.stop="toggleFollow(page)" 
              class="follow-btn"
              :class="{ following: page.isFollowing }"
            >
              {{ page.isFollowing ? 'Following' : 'Follow' }}
            </button>
            <button @click.stop="contactPage(page)" class="contact-btn">
              Contact
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- My Pages Tab -->
    <div v-if="activeTab === 'my-pages'" class="my-pages-section">
      <div class="my-pages-list">
        <div 
          v-for="page in myPages" 
          :key="page.id"
          class="my-page-item"
        >
          <div class="page-summary">
            <div class="page-avatar">
              <div class="demo-avatar">{{ page.emoji }}</div>
            </div>
            <div class="page-details">
              <h4>{{ page.name }}</h4>
              <p class="page-category">{{ page.category }}</p>
              <div class="page-metrics">
                <span>{{ page.followers }} followers</span>
                <span>{{ page.views }} views</span>
                <span>⭐ {{ page.rating }}</span>
              </div>
            </div>
          </div>
          
          <div class="page-management">
            <button @click="editPage(page)" class="edit-btn">Edit</button>
            <button @click="viewStats(page)" class="stats-btn">Stats</button>
            <button @click="deletePage(page)" class="delete-btn">Delete</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Following Tab -->
    <div v-if="activeTab === 'following'" class="following-section">
      <div class="following-list">
        <div 
          v-for="page in followingPages" 
          :key="page.id"
          class="following-item"
          @click="viewPage(page)"
        >
          <div class="page-avatar">
            <div class="demo-avatar">{{ page.emoji }}</div>
          </div>
          <div class="page-info">
            <h4>{{ page.name }}</h4>
            <p class="page-category">{{ page.category }}</p>
            <p class="last-update">Last updated: {{ page.lastUpdate }}</p>
          </div>
          <button @click.stop="toggleFollow(page)" class="unfollow-btn">
            Unfollow
          </button>
        </div>
      </div>
    </div>

    <!-- Create/Edit Page Modal -->
    <div v-if="showCreatePage || editingPage" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>{{ editingPage ? 'Edit Page' : 'Create Business Page' }}</h3>
          <button @click="closeModal" class="close-btn">×</button>
        </div>
        
        <div class="modal-body">
          <div class="form-group">
            <label>Business Name</label>
            <input 
              v-model="pageForm.name" 
              type="text" 
              placeholder="Enter business name"
              class="form-input"
            />
          </div>
          
          <div class="form-group">
            <label>Category</label>
            <select v-model="pageForm.category" class="form-select">
              <option value="">Select Category</option>
              <option value="restaurant">Restaurant</option>
              <option value="retail">Retail</option>
              <option value="automotive">Automotive</option>
              <option value="services">Services</option>
              <option value="entertainment">Entertainment</option>
            </select>
          </div>
          
          <div class="form-group">
            <label>Description</label>
            <textarea 
              v-model="pageForm.description" 
              placeholder="Describe your business"
              class="form-textarea"
              rows="4"
            ></textarea>
          </div>
          
          <div class="form-row">
            <div class="form-group">
              <label>Phone</label>
              <input 
                v-model="pageForm.phone" 
                type="text" 
                placeholder="Business phone"
                class="form-input"
              />
            </div>
            
            <div class="form-group">
              <label>Location</label>
              <input 
                v-model="pageForm.location" 
                type="text" 
                placeholder="Business address"
                class="form-input"
              />
            </div>
          </div>
        </div>
        
        <div class="modal-footer">
          <button @click="closeModal" class="cancel-btn">Cancel</button>
          <button @click="savePage" class="save-btn">
            {{ editingPage ? 'Update' : 'Create' }}
          </button>
        </div>
      </div>
    </div>

    <!-- View Page Modal -->
    <div v-if="viewingPage" class="modal-overlay" @click="closeViewModal">
      <div class="modal-content page-view-modal" @click.stop>
        <div class="modal-header">
          <h3>{{ viewingPage.name }}</h3>
          <button @click="closeViewModal" class="close-btn">×</button>
        </div>
        
        <div class="modal-body">
          <div class="page-detail-header">
            <div class="page-avatar large">
              <div class="demo-avatar large">{{ viewingPage.emoji }}</div>
            </div>
            <div class="page-info">
              <h2>{{ viewingPage.name }}</h2>
              <p class="category">{{ viewingPage.category }}</p>
              <div class="stats">
                <span>{{ viewingPage.followers }} followers</span>
                <span>⭐ {{ viewingPage.rating }}</span>
              </div>
            </div>
          </div>
          
          <div class="page-description">
            <h4>About</h4>
            <p>{{ viewingPage.description }}</p>
          </div>
          
          <div class="page-contact-info">
            <h4>Contact Information</h4>
            <p>📞 {{ viewingPage.phone }}</p>
            <p>📍 {{ viewingPage.location }}</p>
          </div>
          
          <div class="page-reviews">
            <h4>Recent Reviews</h4>
            <div class="review-item">
              <div class="review-header">
                <span class="reviewer">John D.</span>
                <span class="rating">⭐⭐⭐⭐⭐</span>
              </div>
              <p>"Great service and friendly staff!"</p>
            </div>
            <div class="review-item">
              <div class="review-header">
                <span class="reviewer">Sarah M.</span>
                <span class="rating">⭐⭐⭐⭐</span>
              </div>
              <p>"Good quality products, will visit again."</p>
            </div>
          </div>
        </div>
        
        <div class="modal-footer">
          <button @click="contactPage(viewingPage)" class="contact-btn">Contact</button>
          <button @click="toggleFollow(viewingPage)" class="follow-btn">
            {{ viewingPage.isFollowing ? 'Unfollow' : 'Follow' }}
          </button>
          <button @click="closeViewModal" class="close-btn-secondary">Close</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed } from 'vue'

export default {
  name: 'Pages',
  setup() {
    // State
    const activeTab = ref('discover')
    const searchQuery = ref('')
    const selectedCategory = ref('')
    const showCreatePage = ref(false)
    const editingPage = ref(null)
    const viewingPage = ref(null)
    
    const pageForm = ref({
      name: '',
      category: '',
      description: '',
      phone: '',
      location: ''
    })
    
    // Demo data
    const demoPages = ref([
      {
        id: 1,
        name: 'Pizza Palace',
        category: 'restaurant',
        description: 'Authentic Italian pizza made with fresh ingredients',
        phone: '555-0123',
        location: 'Downtown Plaza',
        followers: 1250,
        rating: 4.8,
        emoji: '🍕',
        isFollowing: false
      },
      {
        id: 2,
        name: 'Tech Repair Shop',
        category: 'services',
        description: 'Professional electronics repair and maintenance',
        phone: '555-0456',
        location: 'Tech District',
        followers: 890,
        rating: 4.6,
        emoji: '🔧',
        isFollowing: true
      },
      {
        id: 3,
        name: 'Fashion Boutique',
        category: 'retail',
        description: 'Trendy clothing and accessories for all occasions',
        phone: '555-0789',
        location: 'Shopping Center',
        followers: 2100,
        rating: 4.9,
        emoji: '👗',
        isFollowing: false
      },
      {
        id: 4,
        name: 'Auto Service Center',
        category: 'automotive',
        description: 'Complete automotive repair and maintenance services',
        phone: '555-0321',
        location: 'Industrial Area',
        followers: 650,
        rating: 4.5,
        emoji: '🚗',
        isFollowing: false
      },
      {
        id: 5,
        name: 'Entertainment Hub',
        category: 'entertainment',
        description: 'Gaming, movies, and fun activities for everyone',
        phone: '555-0654',
        location: 'Entertainment District',
        followers: 1800,
        rating: 4.7,
        emoji: '🎮',
        isFollowing: true
      }
    ])
    
    const demoMyPages = ref([
      {
        id: 6,
        name: 'My Coffee Shop',
        category: 'restaurant',
        description: 'Cozy coffee shop with homemade pastries',
        phone: '555-0987',
        location: 'Main Street',
        followers: 420,
        views: 1250,
        rating: 4.4,
        emoji: '☕'
      }
    ])
    
    const demoFollowingPages = ref([
      {
        id: 2,
        name: 'Tech Repair Shop',
        category: 'services',
        lastUpdate: '2 days ago',
        emoji: '🔧'
      },
      {
        id: 5,
        name: 'Entertainment Hub',
        category: 'entertainment',
        lastUpdate: '1 week ago',
        emoji: '🎮'
      }
    ])
    
    // Computed
    const filteredPages = computed(() => {
      let filtered = demoPages.value
      
      if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase()
        filtered = filtered.filter(page => 
          page.name.toLowerCase().includes(query) ||
          page.description.toLowerCase().includes(query)
        )
      }
      
      if (selectedCategory.value) {
        filtered = filtered.filter(page => page.category === selectedCategory.value)
      }
      
      return filtered
    })
    
    const myPages = computed(() => demoMyPages.value)
    const followingPages = computed(() => demoFollowingPages.value)
    
    // Methods
    const viewPage = (page) => {
      viewingPage.value = page
    }
    
    const editPage = (page) => {
      editingPage.value = page
      pageForm.value = { ...page }
      showCreatePage.value = false
    }
    
    const deletePage = (page) => {
      if (confirm('Are you sure you want to delete this page?')) {
        const index = demoMyPages.value.findIndex(p => p.id === page.id)
        if (index > -1) {
          demoMyPages.value.splice(index, 1)
        }
      }
    }
    
    const savePage = () => {
      if (editingPage.value) {
        // Update existing page
        const index = demoMyPages.value.findIndex(p => p.id === editingPage.value.id)
        if (index > -1) {
          demoMyPages.value[index] = { 
            ...pageForm.value, 
            id: editingPage.value.id, 
            followers: editingPage.value.followers,
            views: editingPage.value.views,
            rating: editingPage.value.rating,
            emoji: editingPage.value.emoji
          }
        }
      } else {
        // Create new page
        const newPage = {
          ...pageForm.value,
          id: Date.now(),
          followers: 0,
          views: 0,
          rating: 0,
          emoji: '🏢'
        }
        demoMyPages.value.push(newPage)
      }
      closeModal()
    }
    
    const toggleFollow = (page) => {
      page.isFollowing = !page.isFollowing
      if (page.isFollowing) {
        page.followers += 1
        // Add to following list if not already there
        if (!demoFollowingPages.value.find(p => p.id === page.id)) {
          demoFollowingPages.value.push({
            id: page.id,
            name: page.name,
            category: page.category,
            lastUpdate: 'Just now',
            emoji: page.emoji
          })
        }
      } else {
        page.followers -= 1
        // Remove from following list
        const index = demoFollowingPages.value.findIndex(p => p.id === page.id)
        if (index > -1) {
          demoFollowingPages.value.splice(index, 1)
        }
      }
    }
    
    const contactPage = (page) => {
      alert(`Contact ${page.name} - Demo only`)
    }
    
    const viewStats = (page) => {
      alert(`Page statistics for ${page.name} - Demo only`)
    }
    
    const closeModal = () => {
      showCreatePage.value = false
      editingPage.value = null
      pageForm.value = {
        name: '',
        category: '',
        description: '',
        phone: '',
        location: ''
      }
    }
    
    const closeViewModal = () => {
      viewingPage.value = null
    }
    
    return {
      activeTab,
      searchQuery,
      selectedCategory,
      showCreatePage,
      editingPage,
      viewingPage,
      pageForm,
      filteredPages,
      myPages,
      followingPages,
      viewPage,
      editPage,
      deletePage,
      savePage,
      toggleFollow,
      contactPage,
      viewStats,
      closeModal,
      closeViewModal
    }
  }
}
</script>

<style scoped>
.pages-app {
  padding: 20px;
  height: 100%;
  overflow-y: auto;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
}

.pages-header {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  align-items: center;
}

.search-input {
  flex: 1;
  padding: 12px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  font-size: 14px;
}

.search-input::placeholder {
  color: rgba(255, 255, 255, 0.6);
}

.category-filter {
  padding: 12px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  font-size: 14px;
  min-width: 140px;
}

.create-page-btn {
  padding: 12px 16px;
  background: #007AFF;
  border: none;
  border-radius: 8px;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  white-space: nowrap;
}

.create-page-btn:hover {
  background: #0056CC;
}

.tabs {
  display: flex;
  margin-bottom: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.tab {
  flex: 1;
  padding: 12px;
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.6);
  font-size: 16px;
  cursor: pointer;
  border-bottom: 2px solid transparent;
}

.tab.active {
  color: #fff;
  border-bottom-color: #007AFF;
}

.pages-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
}

.page-card {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 16px;
  cursor: pointer;
  transition: transform 0.2s, background 0.2s;
}

.page-card:hover {
  transform: translateY(-2px);
  background: rgba(255, 255, 255, 0.15);
}

.page-header {
  display: flex;
  gap: 12px;
  margin-bottom: 12px;
}

.page-avatar {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
}

.page-avatar.large {
  width: 80px;
  height: 80px;
}

.demo-avatar {
  font-size: 24px;
}

.demo-avatar.large {
  font-size: 40px;
}

.page-info {
  flex: 1;
}

.page-name {
  margin: 0 0 4px 0;
  font-size: 16px;
  font-weight: 600;
  color: #fff;
}

.page-category {
  margin: 0 0 8px 0;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.7);
  text-transform: capitalize;
}

.page-stats {
  display: flex;
  gap: 12px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.6);
}

.page-description {
  margin-bottom: 12px;
}

.page-description p {
  margin: 0;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  line-height: 1.4;
}

.page-contact {
  display: flex;
  gap: 16px;
  margin-bottom: 12px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.6);
}

.page-actions {
  display: flex;
  gap: 8px;
}

.follow-btn, .contact-btn, .unfollow-btn {
  padding: 8px 12px;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
}

.follow-btn {
  background: #007AFF;
  color: #fff;
}

.follow-btn.following {
  background: #34C759;
}

.contact-btn {
  background: rgba(255, 255, 255, 0.2);
  color: #fff;
}

.unfollow-btn {
  background: #FF3B30;
  color: #fff;
}

.my-pages-list, .following-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.my-page-item, .following-item {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 16px;
}

.page-summary {
  display: flex;
  gap: 12px;
  flex: 1;
}

.page-details h4 {
  margin: 0 0 4px 0;
  color: #fff;
}

.page-details p {
  margin: 0 0 4px 0;
  color: rgba(255, 255, 255, 0.7);
  font-size: 14px;
}

.page-metrics {
  display: flex;
  gap: 12px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.6);
}

.page-management {
  display: flex;
  gap: 8px;
}

.edit-btn, .stats-btn, .delete-btn {
  padding: 8px 12px;
  border: none;
  border-radius: 6px;
  font-size: 12px;
  cursor: pointer;
}

.edit-btn {
  background: #007AFF;
  color: #fff;
}

.stats-btn {
  background: #34C759;
  color: #fff;
}

.delete-btn {
  background: #FF3B30;
  color: #fff;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: #1C1C1E;
  border-radius: 12px;
  width: 90%;
  max-width: 500px;
  max-height: 80vh;
  overflow-y: auto;
}

.page-view-modal {
  max-width: 600px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.modal-header h3 {
  margin: 0;
  color: #fff;
}

.close-btn {
  background: none;
  border: none;
  color: #fff;
  font-size: 24px;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-body {
  padding: 20px;
}

.form-group {
  margin-bottom: 16px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.form-group label {
  display: block;
  margin-bottom: 6px;
  color: #fff;
  font-size: 14px;
  font-weight: 500;
}

.form-input, .form-textarea, .form-select {
  width: 100%;
  padding: 12px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
  font-size: 14px;
  box-sizing: border-box;
}

.form-textarea {
  resize: vertical;
  min-height: 80px;
}

.form-input::placeholder, .form-textarea::placeholder {
  color: rgba(255, 255, 255, 0.6);
}

.modal-footer {
  display: flex;
  gap: 12px;
  padding: 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
}

.cancel-btn, .save-btn, .close-btn-secondary {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  cursor: pointer;
}

.cancel-btn, .close-btn-secondary {
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
}

.save-btn {
  background: #007AFF;
  color: #fff;
}

.page-detail-header {
  display: flex;
  gap: 16px;
  margin-bottom: 20px;
  align-items: center;
}

.page-detail-header h2 {
  margin: 0 0 4px 0;
  color: #fff;
}

.page-detail-header .category {
  margin: 0 0 8px 0;
  color: rgba(255, 255, 255, 0.7);
  text-transform: capitalize;
}

.page-detail-header .stats {
  display: flex;
  gap: 12px;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.6);
}

.page-description, .page-contact-info, .page-reviews {
  margin-bottom: 20px;
}

.page-description h4, .page-contact-info h4, .page-reviews h4 {
  margin: 0 0 8px 0;
  color: #fff;
}

.page-description p, .page-contact-info p {
  margin: 0 0 4px 0;
  color: rgba(255, 255, 255, 0.8);
  line-height: 1.5;
}

.review-item {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 8px;
}

.review-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 4px;
}

.reviewer {
  font-weight: 600;
  color: #fff;
}

.rating {
  color: #FFD700;
}

.review-item p {
  margin: 0;
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
}
</style>