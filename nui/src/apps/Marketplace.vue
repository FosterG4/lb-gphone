<template>
  <div class="marketplace-app">
    <!-- Header -->
    <div class="marketplace-header">
      <div class="search-section">
        <input 
          v-model="searchQuery" 
          type="text" 
          placeholder="Search marketplace..."
          class="search-input"
        />
      </div>
      
      <div class="filter-section">
        <select v-model="selectedCategory" class="category-filter">
          <option value="">All Categories</option>
          <option value="vehicles">Vehicles</option>
          <option value="electronics">Electronics</option>
          <option value="clothing">Clothing</option>
          <option value="furniture">Furniture</option>
          <option value="services">Services</option>
        </select>
      </div>
      
      <button @click="showCreateListing = true" class="create-listing-btn">
        + Create Listing
      </button>
    </div>

    <!-- Tabs -->
    <div class="tabs">
      <button 
        @click="activeTab = 'browse'" 
        class="tab"
        :class="{ active: activeTab === 'browse' }"
      >
        Browse
      </button>
      <button 
        @click="activeTab = 'my-listings'" 
        class="tab"
        :class="{ active: activeTab === 'my-listings' }"
      >
        My Listings
      </button>
    </div>

    <!-- Browse Tab -->
    <div v-if="activeTab === 'browse'" class="browse-section">
      <div class="listings-grid">
        <div 
          v-for="listing in filteredListings" 
          :key="listing.id"
          class="listing-card"
          @click="viewListing(listing)"
        >
          <div class="listing-image">
            <div class="demo-image">{{ listing.emoji }}</div>
          </div>
          <div class="listing-info">
            <h4 class="listing-title">{{ listing.title }}</h4>
            <p class="listing-description">{{ listing.description }}</p>
            <div class="listing-meta">
              <span class="listing-price">{{ formatMoney(listing.price) }}</span>
              <span class="listing-category">{{ listing.category }}</span>
            </div>
            <div class="listing-seller">
              Seller: {{ listing.seller }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- My Listings Tab -->
    <div v-if="activeTab === 'my-listings'" class="my-listings-section">
      <div class="listings-list">
        <div 
          v-for="listing in myListings" 
          :key="listing.id"
          class="my-listing-item"
        >
          <div class="listing-info">
            <h4>{{ listing.title }}</h4>
            <p>{{ formatMoney(listing.price) }} • {{ listing.category }}</p>
            <span class="status active">{{ listing.status }}</span>
          </div>
          <div class="listing-actions">
            <button @click="editListing(listing)" class="edit-btn">Edit</button>
            <button @click="deleteListing(listing.id)" class="delete-btn">Delete</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Create/Edit Listing Modal -->
    <div v-if="showCreateListing || editingListing" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>{{ editingListing ? 'Edit Listing' : 'Create Listing' }}</h3>
          <button @click="closeModal" class="close-btn">×</button>
        </div>
        
        <div class="modal-body">
          <div class="form-group">
            <label>Title</label>
            <input 
              v-model="listingForm.title" 
              type="text" 
              placeholder="Enter listing title"
              class="form-input"
            />
          </div>
          
          <div class="form-group">
            <label>Description</label>
            <textarea 
              v-model="listingForm.description" 
              placeholder="Describe your item"
              class="form-textarea"
              rows="4"
            ></textarea>
          </div>
          
          <div class="form-row">
            <div class="form-group">
              <label>Price</label>
              <input 
                v-model.number="listingForm.price" 
                type="number" 
                placeholder="0.00"
                class="form-input"
              />
            </div>
            
            <div class="form-group">
              <label>Category</label>
              <select v-model="listingForm.category" class="form-select">
                <option value="">Select Category</option>
                <option value="vehicles">Vehicles</option>
                <option value="electronics">Electronics</option>
                <option value="clothing">Clothing</option>
                <option value="furniture">Furniture</option>
                <option value="services">Services</option>
              </select>
            </div>
          </div>
          
          <div class="form-group">
            <label>Contact Phone</label>
            <input 
              v-model="listingForm.contact_phone" 
              type="text" 
              placeholder="Your phone number"
              class="form-input"
            />
          </div>
        </div>
        
        <div class="modal-footer">
          <button @click="closeModal" class="cancel-btn">Cancel</button>
          <button @click="saveListing" class="save-btn">
            {{ editingListing ? 'Update' : 'Create' }}
          </button>
        </div>
      </div>
    </div>

    <!-- View Listing Modal -->
    <div v-if="viewingListing" class="modal-overlay" @click="closeViewModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>{{ viewingListing.title }}</h3>
          <button @click="closeViewModal" class="close-btn">×</button>
        </div>
        
        <div class="modal-body">
          <div class="listing-detail-image">
            <div class="demo-image large">{{ viewingListing.emoji }}</div>
          </div>
          
          <div class="listing-details">
            <div class="price-section">
              <span class="price">{{ formatMoney(viewingListing.price) }}</span>
              <span class="category">{{ viewingListing.category }}</span>
            </div>
            
            <div class="description-section">
              <h4>Description</h4>
              <p>{{ viewingListing.description }}</p>
            </div>
            
            <div class="seller-section">
              <h4>Seller Information</h4>
              <p>{{ viewingListing.seller }}</p>
              <p>Phone: {{ viewingListing.phone }}</p>
            </div>
          </div>
        </div>
        
        <div class="modal-footer">
          <button @click="contactSeller" class="contact-btn">Contact Seller</button>
          <button @click="closeViewModal" class="close-btn-secondary">Close</button>
        </div>
      </div>
    </div>

    <!-- View Listing Modal -->
    <div v-if="viewingListing" class="modal-overlay" @click="closeViewModal">
      <div class="modal-content view-modal" @click.stop>
        <div class="modal-header">
          <h3>{{ viewingListing.title }}</h3>
          <button @click="closeViewModal" class="close-btn">×</button>
        </div>
        
        <div class="modal-body">
          <div v-if="viewingListing.image" class="listing-image-large">
            <img :src="viewingListing.image" :alt="viewingListing.title" />
          </div>
          
          <div class="listing-details">
            <div class="price-section">
              <span class="price">{{ formatMoney(viewingListing.price) }}</span>
              <span class="category">{{ viewingListing.category }}</span>
            </div>
            
            <div class="description-section">
              <h4>{{ $t('marketplace.listing.description') }}</h4>
              <p>{{ viewingListing.description }}</p>
            </div>
            
            <div class="seller-section">
              <h4>{{ $t('marketplace.listing.sellerInfo') }}</h4>
              <p>{{ $t('marketplace.listing.contact') }}: {{ viewingListing.contact_phone || viewingListing.seller_number }}</p>
              <p>{{ $t('marketplace.listing.listed') }}: {{ formatDate(viewingListing.created_at) }}</p>
            </div>
          </div>
        </div>
        
        <div class="modal-footer">
          <button @click="contactSeller" class="contact-btn">{{ $t('marketplace.actions.contactSeller') }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed } from 'vue'
import { formatCurrency } from '@/utils/currency'

export default {
  name: 'Marketplace',
  setup() {
    // State
    const activeTab = ref('browse')
    const searchQuery = ref('')
    const selectedCategory = ref('')
    const showCreateListing = ref(false)
    const editingListing = ref(null)
    const viewingListing = ref(null)
    
    const listingForm = ref({
      title: '',
      description: '',
      price: null,
      category: '',
      contact_phone: ''
    })
    
    // Demo data
    const demoListings = ref([
      {
        id: 1,
        title: 'Sports Car',
        description: 'Fast and reliable sports car in excellent condition',
        price: 85000,
        category: 'vehicles',
        seller: 'John Doe',
        phone: '555-0123',
        emoji: '🏎️'
      },
      {
        id: 2,
        title: 'Gaming Laptop',
        description: 'High-performance gaming laptop with RTX graphics',
        price: 1500,
        category: 'electronics',
        seller: 'Jane Smith',
        phone: '555-0456',
        emoji: '💻'
      },
      {
        id: 3,
        title: 'Designer Jacket',
        description: 'Premium leather jacket, barely worn',
        price: 300,
        category: 'clothing',
        seller: 'Mike Johnson',
        phone: '555-0789',
        emoji: '🧥'
      },
      {
        id: 4,
        title: 'Modern Sofa',
        description: 'Comfortable 3-seater sofa in great condition',
        price: 800,
        category: 'furniture',
        seller: 'Sarah Wilson',
        phone: '555-0321',
        emoji: '🛋️'
      },
      {
        id: 5,
        title: 'Web Development',
        description: 'Professional website development services',
        price: 500,
        category: 'services',
        seller: 'Tech Solutions',
        phone: '555-0654',
        emoji: '💻'
      }
    ])
    
    const demoMyListings = ref([
      {
        id: 6,
        title: 'Vintage Watch',
        description: 'Classic vintage watch collection',
        price: 1200,
        category: 'electronics',
        status: 'Active'
      },
      {
        id: 7,
        title: 'Mountain Bike',
        description: 'Professional mountain bike for trails',
        price: 600,
        category: 'vehicles',
        status: 'Active'
      }
    ])
    
    // Computed
    const filteredListings = computed(() => {
      let filtered = demoListings.value
      
      if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase()
        filtered = filtered.filter(listing => 
          listing.title.toLowerCase().includes(query) ||
          listing.description.toLowerCase().includes(query)
        )
      }
      
      if (selectedCategory.value) {
        filtered = filtered.filter(listing => listing.category === selectedCategory.value)
      }
      
      return filtered
    })
    
    const myListings = computed(() => demoMyListings.value)
    
    // Methods
    const viewListing = (listing) => {
      viewingListing.value = listing
    }
    
    const editListing = (listing) => {
      editingListing.value = listing
      listingForm.value = { ...listing }
      showCreateListing.value = false
    }
    
    const deleteListing = (listingId) => {
      if (confirm('Are you sure you want to delete this listing?')) {
        const index = demoMyListings.value.findIndex(l => l.id === listingId)
        if (index > -1) {
          demoMyListings.value.splice(index, 1)
        }
      }
    }
    
    const saveListing = () => {
      if (editingListing.value) {
        // Update existing listing
        const index = demoMyListings.value.findIndex(l => l.id === editingListing.value.id)
        if (index > -1) {
          demoMyListings.value[index] = { ...listingForm.value, id: editingListing.value.id, status: 'Active' }
        }
      } else {
        // Create new listing
        const newListing = {
          ...listingForm.value,
          id: Date.now(),
          status: 'Active'
        }
        demoMyListings.value.push(newListing)
      }
      closeModal()
    }
    
    const closeModal = () => {
      showCreateListing.value = false
      editingListing.value = null
      listingForm.value = {
        title: '',
        description: '',
        price: null,
        category: '',
        contact_phone: ''
      }
    }
    
    const closeViewModal = () => {
      viewingListing.value = null
    }
    
    const contactSeller = () => {
      alert('Contact seller feature - Demo only')
      closeViewModal()
    }
    
    // Formatting functions
    const formatMoney = (amount) => {
      return formatCurrency(amount)
    }
    
    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString()
    }
    
    return {
      activeTab,
      searchQuery,
      selectedCategory,
      showCreateListing,
      editingListing,
      viewingListing,
      listingForm,
      filteredListings,
      myListings,
      viewListing,
      editListing,
      deleteListing,
      saveListing,
      closeModal,
      closeViewModal,
      contactSeller,
      formatMoney,
      formatDate
    }
  }
}
</script>

<style scoped>
.marketplace-app {
  padding: 20px;
  height: 100%;
  overflow-y: auto;
}

.marketplace-header {
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

.create-listing-btn {
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

.create-listing-btn:hover {
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

.loading-state, .empty-state {
  text-align: center;
  padding: 40px 20px;
  color: rgba(255, 255, 255, 0.6);
  font-size: 16px;
}

.listings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
}

.listing-card {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.2s, background 0.2s;
}

.listing-card:hover {
  transform: translateY(-2px);
  background: rgba(255, 255, 255, 0.15);
}

.listing-image {
  height: 160px;
  background: rgba(255, 255, 255, 0.05);
  display: flex;
  align-items: center;
  justify-content: center;
}

.listing-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.demo-image {
  font-size: 48px;
  opacity: 0.8;
}

.demo-image.large {
  font-size: 80px;
  text-align: center;
  padding: 40px;
}

.no-image {
  font-size: 48px;
  opacity: 0.3;
}

.listing-info {
  padding: 16px;
}

.listing-title {
  font-size: 16px;
  font-weight: 600;
  margin: 0 0 8px 0;
  color: #fff;
}

.listing-description {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.7);
  margin: 0 0 12px 0;
  line-height: 1.4;
}

.listing-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.listing-price {
  font-size: 18px;
  font-weight: 700;
  color: #34C759;
}

.listing-category {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.6);
  text-transform: capitalize;
}

.listing-seller {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.5);
}

.my-listing-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  margin-bottom: 12px;
}

.my-listing-item h4 {
  margin: 0 0 4px 0;
  color: #fff;
}

.my-listing-item p {
  margin: 0 0 4px 0;
  color: rgba(255, 255, 255, 0.7);
  font-size: 14px;
}

.status {
  font-size: 12px;
  padding: 4px 8px;
  border-radius: 4px;
  text-transform: capitalize;
}

.status.active {
  background: rgba(52, 199, 89, 0.2);
  color: #34C759;
}

.status.sold {
  background: rgba(255, 149, 0, 0.2);
  color: #FF9500;
}

.status.deleted {
  background: rgba(255, 59, 48, 0.2);
  color: #FF3B30;
}

.listing-actions {
  display: flex;
  gap: 8px;
}

.edit-btn, .delete-btn {
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

.view-modal {
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

.cancel-btn, .save-btn {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  cursor: pointer;
}

.cancel-btn {
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
}

.save-btn {
  background: #007AFF;
  color: #fff;
}

.save-btn:disabled {
  background: rgba(0, 122, 255, 0.3);
  cursor: not-allowed;
}

.contact-btn {
  flex: 1;
  padding: 12px;
  background: #34C759;
  border: none;
  border-radius: 8px;
  color: #fff;
  font-size: 16px;
  cursor: pointer;
}

.close-btn-secondary {
  flex: 1;
  padding: 12px;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  border-radius: 8px;
  color: #fff;
  font-size: 16px;
  cursor: pointer;
}

.listing-detail-image {
  margin-bottom: 20px;
  text-align: center;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
}

.listing-image-large {
  margin-bottom: 20px;
}

.listing-image-large img {
  width: 100%;
  max-height: 300px;
  object-fit: cover;
  border-radius: 8px;
}

.price-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.price {
  font-size: 24px;
  font-weight: 700;
  color: #34C759;
}

.description-section, .seller-section {
  margin-bottom: 20px;
}

.description-section h4, .seller-section h4 {
  margin: 0 0 8px 0;
  color: #fff;
}

.description-section p, .seller-section p {
  margin: 0 0 4px 0;
  color: rgba(255, 255, 255, 0.7);
  line-height: 1.5;
}

.error-message {
  margin-top: 12px;
  padding: 12px;
  background: rgba(255, 59, 48, 0.2);
  border: 1px solid rgba(255, 59, 48, 0.4);
  border-radius: 8px;
  color: #FF3B30;
  font-size: 14px;
}
</style>