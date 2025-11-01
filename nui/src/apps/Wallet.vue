<template>
  <div class="wallet-app">
    <!-- Header -->
    <div class="wallet-header">
      <h1 class="wallet-title">Wallet</h1>
      <button class="profile-btn" @click="openProfile">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/>
          <path d="M12 1v6M12 17v6M4.22 4.22l4.24 4.24M15.54 15.54l4.24 4.24M1 12h6M17 12h6M4.22 19.78l4.24-4.24M15.54 8.46l4.24-4.24" stroke="currentColor" stroke-width="2"/>
        </svg>
      </button>
    </div>

    <!-- Main Content -->
    <div class="wallet-content">
      <!-- Dashboard Page -->
      <div v-if="activeTab === 'dashboard'" class="page-content">
        <DashboardPage />
      </div>

      <!-- Transactions Page -->
      <div v-else-if="activeTab === 'transactions'" class="page-content">
        <TransactionsPage />
      </div>

      <!-- Transfer Page -->
      <div v-else-if="activeTab === 'transfer'" class="page-content">
        <TransferPage />
      </div>

      <!-- Analytics Page -->
      <div v-else-if="activeTab === 'analytics'" class="page-content">
        <AnalyticsPage />
      </div>

      <!-- Cards Page -->
      <div v-else-if="activeTab === 'cards'" class="page-content">
        <CardsPage />
      </div>

      <!-- Settings Page -->
      <div v-else-if="activeTab === 'settings'" class="page-content">
        <SettingsPage />
      </div>

      <!-- Customization Page -->
      <div v-else-if="activeTab === 'customization'" class="page-content">
        <CustomizationPage />
      </div>
    </div>

    <!-- Tab Bar -->
    <IOSTabBar
      :tabs="tabs"
      :active-tab="activeTab"
      @tab-change="handleTabChange"
    />

    <!-- Profile Modal -->
    <IOSModal
      v-model="showProfileModal"
      title="Profile"
      size="medium"
    >
      <div class="profile-content">
        <div class="profile-avatar">
          <div class="avatar-circle">
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" stroke="currentColor" stroke-width="2"/>
              <circle cx="12" cy="7" r="4" stroke="currentColor" stroke-width="2"/>
            </svg>
          </div>
        </div>
        <div class="profile-info">
          <h3 class="profile-name">{{ userProfile.name }}</h3>
          <p class="profile-email">{{ userProfile.email }}</p>
        </div>
        <div class="profile-actions">
          <IOSButton variant="secondary" full-width @click="editProfile">
            Edit Profile
          </IOSButton>
        </div>
      </div>
    </IOSModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useStore } from 'vuex'
import { 
  Home, 
  Receipt, 
  Send, 
  BarChart3, 
  CreditCard, 
  Settings, 
  Palette 
} from 'lucide-vue-next'

// Components
import IOSTabBar from '../components/ios/IOSTabBar.vue'
import IOSModal from '../components/ios/IOSModal.vue'
import IOSButton from '../components/ios/IOSButton.vue'

// Pages
import DashboardPage from '../components/wallet/pages/DashboardPage.vue'
import TransactionsPage from '../components/wallet/pages/TransactionsPage.vue'
import TransferPage from '../components/wallet/pages/TransferPage.vue'
import AnalyticsPage from '../components/wallet/pages/AnalyticsPage.vue'
import CardsPage from '../components/wallet/pages/CardsPage.vue'
import SettingsPage from '../components/wallet/pages/SettingsPage.vue'
import CustomizationPage from '../components/wallet/pages/CustomizationPage.vue'

const store = useStore()

// State
const activeTab = ref('dashboard')
const showProfileModal = ref(false)

// User profile data
const userProfile = ref({
  name: 'LB Phone User',
  email: 'user@lbphone.com'
})

// Tab configuration
const tabs = [
  {
    id: 'dashboard',
    label: 'Home',
    icon: Home
  },
  {
    id: 'transactions',
    label: 'History',
    icon: Receipt
  },
  {
    id: 'transfer',
    label: 'Transfer',
    icon: Send
  },
  {
    id: 'analytics',
    label: 'Analytics',
    icon: BarChart3
  },
  {
    id: 'cards',
    label: 'Cards',
    icon: CreditCard
  }
]

// Computed
const walletData = computed(() => store.state.wallet)

// Methods
const handleTabChange = (tabId) => {
  activeTab.value = tabId
}

const openProfile = () => {
  showProfileModal.value = true
}

const editProfile = () => {
  // Navigate to settings page
  activeTab.value = 'settings'
  showProfileModal.value = false
}

// Initialize wallet data
onMounted(() => {
  store.dispatch('wallet/fetchAccounts')
  store.dispatch('wallet/fetchTransactions')
  store.dispatch('wallet/fetchAnalytics')
  store.dispatch('wallet/fetchUserSettings')
})
</script>

<style scoped>
.wallet-app {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
  overflow: hidden;
}

.wallet-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.1);
  position: sticky;
  top: 0;
  z-index: 10;
}

.wallet-title {
  font-size: 28px;
  font-weight: 700;
  color: #1d1d1f;
  margin: 0;
  letter-spacing: -0.02em;
}

.profile-btn {
  background: rgba(0, 122, 255, 0.1);
  border: 1px solid rgba(0, 122, 255, 0.2);
  border-radius: 12px;
  color: #007AFF;
  padding: 8px;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

.profile-btn:hover {
  background: rgba(0, 122, 255, 0.2);
  transform: scale(1.05);
}

.profile-btn:active {
  transform: scale(0.95);
}

.wallet-content {
  flex: 1;
  overflow-y: auto;
  padding-bottom: 100px; /* Space for tab bar */
}

.page-content {
  padding: 24px;
  min-height: calc(100vh - 200px);
}

/* Profile Modal Content */
.profile-content {
  text-align: center;
  padding: 20px 0;
}

.profile-avatar {
  margin-bottom: 20px;
}

.avatar-circle {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto;
  color: white;
}

.profile-info {
  margin-bottom: 24px;
}

.profile-name {
  font-size: 20px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0 0 4px 0;
}

.profile-email {
  font-size: 14px;
  color: #8e8e93;
  margin: 0;
}

.profile-actions {
  margin-top: 24px;
}

/* Responsive adjustments */
@media (max-width: 375px) {
  .wallet-header {
    padding: 12px 20px;
  }

  .wallet-title {
    font-size: 24px;
  }

  .page-content {
    padding: 20px;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .wallet-app {
    background: linear-gradient(135deg, #1c1c1e 0%, #2c2c2e 100%);
  }

  .wallet-header {
    background: rgba(28, 28, 30, 0.95);
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  }

  .wallet-title {
    color: #f2f2f7;
  }

  .profile-btn {
    background: rgba(10, 132, 255, 0.2);
    border: 1px solid rgba(10, 132, 255, 0.3);
    color: #0A84FF;
  }

  .profile-btn:hover {
    background: rgba(10, 132, 255, 0.3);
  }

  .profile-name {
    color: #f2f2f7;
  }
}

/* Smooth transitions */
.page-content {
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

/* Loading states */
.wallet-content:empty::before {
  content: '';
  display: block;
  width: 40px;
  height: 40px;
  margin: 50px auto;
  border: 3px solid rgba(0, 122, 255, 0.3);
  border-top: 3px solid #007AFF;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>