<template>
  <div class="settings-page">
    <!-- Profile Section -->
    <div class="profile-section">
      <IOSCard variant="glass">
        <template #content>
          <div class="profile-content">
            <div class="profile-avatar">
              <img v-if="userProfile.avatar" :src="userProfile.avatar" :alt="userProfile.name" />
              <div v-else class="avatar-placeholder">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none">
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" stroke="currentColor" stroke-width="2"/>
                  <circle cx="12" cy="7" r="4" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
            </div>
            <div class="profile-info">
              <h3>{{ userProfile.name || 'User Name' }}</h3>
              <p>{{ userProfile.email || 'user@example.com' }}</p>
              <span class="profile-status">{{ userProfile.status || 'Verified Account' }}</span>
            </div>
            <button @click="editProfile" class="edit-profile-btn">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" stroke="currentColor" stroke-width="2"/>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" stroke="currentColor" stroke-width="2"/>
              </svg>
            </button>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Settings Groups -->
    <div class="settings-groups">
      <!-- Account Settings -->
      <div class="settings-group">
        <h4 class="group-title">Account</h4>
        <IOSCard variant="glass">
          <template #content>
            <div class="settings-list">
              <div class="setting-item" @click="navigateTo('personal-info')">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" stroke="currentColor" stroke-width="2"/>
                    <circle cx="12" cy="7" r="4" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Personal Information</span>
                  <span class="setting-description">Name, email, phone number</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>

              <div class="setting-item" @click="navigateTo('linked-accounts')">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" stroke="currentColor" stroke-width="2"/>
                    <rect x="8" y="2" width="8" height="4" rx="1" ry="1" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Linked Accounts</span>
                  <span class="setting-description">Bank accounts and cards</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>

              <div class="setting-item" @click="navigateTo('verification')">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M9 12l2 2 4-4" stroke="currentColor" stroke-width="2"/>
                    <path d="M21 12c-1 0-3-1-3-3s2-3 3-3 3 1 3 3-2 3-3 3" stroke="currentColor" stroke-width="2"/>
                    <path d="M3 12c1 0 3-1 3-3s-2-3-3-3-3 1-3 3 2 3 3 3" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Identity Verification</span>
                  <span class="setting-description">Verify your identity</span>
                </div>
                <div class="setting-badge verified">Verified</div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
            </div>
          </template>
        </IOSCard>
      </div>

      <!-- Security Settings -->
      <div class="settings-group">
        <h4 class="group-title">Security</h4>
        <IOSCard variant="glass">
          <template #content>
            <div class="settings-list">
              <div class="setting-item" @click="navigateTo('change-password')">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2" stroke="currentColor" stroke-width="2"/>
                    <circle cx="12" cy="16" r="1" fill="currentColor"/>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Change Password</span>
                  <span class="setting-description">Update your password</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>

              <div class="setting-item">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M9 12l2 2 4-4" stroke="currentColor" stroke-width="2"/>
                    <path d="M21 12c-1 0-3-1-3-3s2-3 3-3 3 1 3 3-2 3-3 3" stroke="currentColor" stroke-width="2"/>
                    <path d="M3 12c1 0 3-1 3-3s-2-3-3-3-3 1-3 3 2 3 3 3" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Two-Factor Authentication</span>
                  <span class="setting-description">Add extra security to your account</span>
                </div>
                <label class="toggle-switch">
                  <input type="checkbox" v-model="settings.twoFactorAuth" @change="updateSetting('twoFactorAuth', $event.target.checked)" />
                  <span class="toggle-slider"></span>
                </label>
              </div>

              <div class="setting-item">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2" stroke="currentColor" stroke-width="2"/>
                    <circle cx="9" cy="9" r="2" stroke="currentColor" stroke-width="2"/>
                    <path d="M21 15.5c-1-1.5-3-2.5-5-2.5s-4 1-5 2.5" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Biometric Authentication</span>
                  <span class="setting-description">Use fingerprint or face ID</span>
                </div>
                <label class="toggle-switch">
                  <input type="checkbox" v-model="settings.biometricAuth" @change="updateSetting('biometricAuth', $event.target.checked)" />
                  <span class="toggle-slider"></span>
                </label>
              </div>

              <div class="setting-item" @click="navigateTo('login-activity')">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Login Activity</span>
                  <span class="setting-description">View recent login attempts</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
            </div>
          </template>
        </IOSCard>
      </div>

      <!-- Notifications -->
      <div class="settings-group">
        <h4 class="group-title">Notifications</h4>
        <IOSCard variant="glass">
          <template #content>
            <div class="settings-list">
              <div class="setting-item">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" stroke="currentColor" stroke-width="2"/>
                    <path d="M13.73 21a2 2 0 0 1-3.46 0" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Push Notifications</span>
                  <span class="setting-description">Receive notifications on your device</span>
                </div>
                <label class="toggle-switch">
                  <input type="checkbox" v-model="settings.pushNotifications" @change="updateSetting('pushNotifications', $event.target.checked)" />
                  <span class="toggle-slider"></span>
                </label>
              </div>

              <div class="setting-item">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" stroke="currentColor" stroke-width="2"/>
                    <polyline points="22,6 12,13 2,6" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Email Notifications</span>
                  <span class="setting-description">Receive updates via email</span>
                </div>
                <label class="toggle-switch">
                  <input type="checkbox" v-model="settings.emailNotifications" @change="updateSetting('emailNotifications', $event.target.checked)" />
                  <span class="toggle-slider"></span>
                </label>
              </div>

              <div class="setting-item">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">SMS Notifications</span>
                  <span class="setting-description">Receive alerts via SMS</span>
                </div>
                <label class="toggle-switch">
                  <input type="checkbox" v-model="settings.smsNotifications" @change="updateSetting('smsNotifications', $event.target.checked)" />
                  <span class="toggle-slider"></span>
                </label>
              </div>

              <div class="setting-item">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <line x1="12" y1="1" x2="12" y2="23" stroke="currentColor" stroke-width="2"/>
                    <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Transaction Alerts</span>
                  <span class="setting-description">Get notified of all transactions</span>
                </div>
                <label class="toggle-switch">
                  <input type="checkbox" v-model="settings.transactionAlerts" @change="updateSetting('transactionAlerts', $event.target.checked)" />
                  <span class="toggle-slider"></span>
                </label>
              </div>
            </div>
          </template>
        </IOSCard>
      </div>

      <!-- Privacy -->
      <div class="settings-group">
        <h4 class="group-title">Privacy</h4>
        <IOSCard variant="glass">
          <template #content>
            <div class="settings-list">
              <div class="setting-item">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="currentColor" stroke-width="2"/>
                    <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Show Balance on Lock Screen</span>
                  <span class="setting-description">Display balance when phone is locked</span>
                </div>
                <label class="toggle-switch">
                  <input type="checkbox" v-model="settings.showBalanceOnLock" @change="updateSetting('showBalanceOnLock', $event.target.checked)" />
                  <span class="toggle-slider"></span>
                </label>
              </div>

              <div class="setting-item">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" stroke="currentColor" stroke-width="2"/>
                    <path d="M19 10v2a7 7 0 0 1-14 0v-2" stroke="currentColor" stroke-width="2"/>
                    <line x1="12" y1="19" x2="12" y2="23" stroke="currentColor" stroke-width="2"/>
                    <line x1="8" y1="23" x2="16" y2="23" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Analytics & Data</span>
                  <span class="setting-description">Help improve our services</span>
                </div>
                <label class="toggle-switch">
                  <input type="checkbox" v-model="settings.analyticsData" @change="updateSetting('analyticsData', $event.target.checked)" />
                  <span class="toggle-slider"></span>
                </label>
              </div>

              <div class="setting-item" @click="navigateTo('data-export')">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" stroke="currentColor" stroke-width="2"/>
                    <polyline points="7,10 12,15 17,10" stroke="currentColor" stroke-width="2"/>
                    <line x1="12" y1="15" x2="12" y2="3" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Export Data</span>
                  <span class="setting-description">Download your data</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
            </div>
          </template>
        </IOSCard>
      </div>

      <!-- Preferences -->
      <div class="settings-group">
        <h4 class="group-title">Preferences</h4>
        <IOSCard variant="glass">
          <template #content>
            <div class="settings-list">
              <div class="setting-item" @click="showCurrencyModal = true">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <line x1="12" y1="1" x2="12" y2="23" stroke="currentColor" stroke-width="2"/>
                    <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Currency</span>
                  <span class="setting-description">{{ settings.currency || 'USD' }}</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>

              <div class="setting-item" @click="showLanguageModal = true">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
                    <path d="M2 12h20" stroke="currentColor" stroke-width="2"/>
                    <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Language</span>
                  <span class="setting-description">{{ settings.language || 'English' }}</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>

              <div class="setting-item">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <circle cx="12" cy="12" r="5" stroke="currentColor" stroke-width="2"/>
                    <line x1="12" y1="1" x2="12" y2="3" stroke="currentColor" stroke-width="2"/>
                    <line x1="12" y1="21" x2="12" y2="23" stroke="currentColor" stroke-width="2"/>
                    <line x1="4.22" y1="4.22" x2="5.64" y2="5.64" stroke="currentColor" stroke-width="2"/>
                    <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" stroke="currentColor" stroke-width="2"/>
                    <line x1="1" y1="12" x2="3" y2="12" stroke="currentColor" stroke-width="2"/>
                    <line x1="21" y1="12" x2="23" y2="12" stroke="currentColor" stroke-width="2"/>
                    <line x1="4.22" y1="19.78" x2="5.64" y2="18.36" stroke="currentColor" stroke-width="2"/>
                    <line x1="18.36" y1="5.64" x2="19.78" y2="4.22" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Dark Mode</span>
                  <span class="setting-description">Use dark theme</span>
                </div>
                <label class="toggle-switch">
                  <input type="checkbox" v-model="settings.darkMode" @change="updateSetting('darkMode', $event.target.checked)" />
                  <span class="toggle-slider"></span>
                </label>
              </div>
            </div>
          </template>
        </IOSCard>
      </div>

      <!-- Support -->
      <div class="settings-group">
        <h4 class="group-title">Support</h4>
        <IOSCard variant="glass">
          <template #content>
            <div class="settings-list">
              <div class="setting-item" @click="navigateTo('help-center')">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
                    <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3" stroke="currentColor" stroke-width="2"/>
                    <line x1="12" y1="17" x2="12.01" y2="17" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Help Center</span>
                  <span class="setting-description">Get help and support</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>

              <div class="setting-item" @click="navigateTo('contact-us')">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" stroke="currentColor" stroke-width="2"/>
                    <polyline points="22,6 12,13 2,6" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Contact Us</span>
                  <span class="setting-description">Send us a message</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>

              <div class="setting-item" @click="navigateTo('feedback')">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Send Feedback</span>
                  <span class="setting-description">Help us improve</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>

              <div class="setting-item" @click="navigateTo('about')">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
                    <line x1="12" y1="16" x2="12" y2="12" stroke="currentColor" stroke-width="2"/>
                    <line x1="12" y1="8" x2="12.01" y2="8" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">About</span>
                  <span class="setting-description">App version and info</span>
                </div>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" class="chevron">
                  <polyline points="9,18 15,12 9,6" stroke="currentColor" stroke-width="2"/>
                </svg>
              </div>
            </div>
          </template>
        </IOSCard>
      </div>

      <!-- Danger Zone -->
      <div class="settings-group">
        <h4 class="group-title">Account Actions</h4>
        <IOSCard variant="glass">
          <template #content>
            <div class="settings-list">
              <div class="setting-item danger" @click="signOut">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" stroke="currentColor" stroke-width="2"/>
                    <polyline points="16,17 21,12 16,7" stroke="currentColor" stroke-width="2"/>
                    <line x1="21" y1="12" x2="9" y2="12" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Sign Out</span>
                  <span class="setting-description">Sign out of your account</span>
                </div>
              </div>

              <div class="setting-item danger" @click="deleteAccount">
                <div class="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <polyline points="3,6 5,6 21,6" stroke="currentColor" stroke-width="2"/>
                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" stroke="currentColor" stroke-width="2"/>
                    <line x1="10" y1="11" x2="10" y2="17" stroke="currentColor" stroke-width="2"/>
                    <line x1="14" y1="11" x2="14" y2="17" stroke="currentColor" stroke-width="2"/>
                  </svg>
                </div>
                <div class="setting-info">
                  <span class="setting-label">Delete Account</span>
                  <span class="setting-description">Permanently delete your account</span>
                </div>
              </div>
            </div>
          </template>
        </IOSCard>
      </div>
    </div>

    <!-- Currency Selection Modal -->
    <IOSModal
      v-model="showCurrencyModal"
      title="Select Currency"
      size="medium"
    >
      <div class="currency-list">
        <div
          v-for="currency in currencies"
          :key="currency.code"
          @click="selectCurrency(currency)"
          class="currency-item"
          :class="{ selected: settings.currency === currency.code }"
        >
          <div class="currency-info">
            <span class="currency-code">{{ currency.code }}</span>
            <span class="currency-name">{{ currency.name }}</span>
          </div>
          <div v-if="settings.currency === currency.code" class="currency-check">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <polyline points="20,6 9,17 4,12" stroke="currentColor" stroke-width="2"/>
            </svg>
          </div>
        </div>
      </div>
    </IOSModal>

    <!-- Language Selection Modal -->
    <IOSModal
      v-model="showLanguageModal"
      title="Select Language"
      size="medium"
    >
      <div class="language-list">
        <div
          v-for="language in languages"
          :key="language.code"
          @click="selectLanguage(language)"
          class="language-item"
          :class="{ selected: settings.language === language.name }"
        >
          <div class="language-info">
            <span class="language-name">{{ language.name }}</span>
            <span class="language-native">{{ language.native }}</span>
          </div>
          <div v-if="settings.language === language.name" class="language-check">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <polyline points="20,6 9,17 4,12" stroke="currentColor" stroke-width="2"/>
            </svg>
          </div>
        </div>
      </div>
    </IOSModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useStore } from 'vuex'

// Components
import IOSCard from '../../ios/IOSCard.vue'
import IOSModal from '../../ios/IOSModal.vue'

const store = useStore()

// State
const showCurrencyModal = ref(false)
const showLanguageModal = ref(false)

// Computed properties
const userProfile = computed(() => store.state.wallet.userProfile || {})
const settings = computed(() => store.state.wallet.settings || {})

// Currency options
const currencies = [
  { code: 'USD', name: 'US Dollar' },
  { code: 'EUR', name: 'Euro' },
  { code: 'GBP', name: 'British Pound' },
  { code: 'JPY', name: 'Japanese Yen' },
  { code: 'CAD', name: 'Canadian Dollar' },
  { code: 'AUD', name: 'Australian Dollar' },
  { code: 'CHF', name: 'Swiss Franc' },
  { code: 'CNY', name: 'Chinese Yuan' }
]

// Language options
const languages = [
  { code: 'en', name: 'English', native: 'English' },
  { code: 'es', name: 'Spanish', native: 'Español' },
  { code: 'fr', name: 'French', native: 'Français' },
  { code: 'de', name: 'German', native: 'Deutsch' },
  { code: 'it', name: 'Italian', native: 'Italiano' },
  { code: 'pt', name: 'Portuguese', native: 'Português' },
  { code: 'ru', name: 'Russian', native: 'Русский' },
  { code: 'ja', name: 'Japanese', native: '日本語' },
  { code: 'ko', name: 'Korean', native: '한국어' },
  { code: 'zh', name: 'Chinese', native: '中文' }
]

// Methods
const editProfile = () => {
  // Navigate to profile editing
  console.log('Edit profile')
}

const navigateTo = (page) => {
  // Navigate to specific settings page
  console.log('Navigate to:', page)
}

const updateSetting = (key, value) => {
  store.dispatch('wallet/updateSetting', { key, value })
}

const selectCurrency = (currency) => {
  updateSetting('currency', currency.code)
  showCurrencyModal.value = false
}

const selectLanguage = (language) => {
  updateSetting('language', language.name)
  showLanguageModal.value = false
}

const signOut = () => {
  if (confirm('Are you sure you want to sign out?')) {
    store.dispatch('wallet/signOut')
  }
}

const deleteAccount = () => {
  if (confirm('Are you sure you want to delete your account? This action cannot be undone.')) {
    if (confirm('This will permanently delete all your data. Are you absolutely sure?')) {
      store.dispatch('wallet/deleteAccount')
    }
  }
}

// Initialize data
onMounted(() => {
  store.dispatch('wallet/fetchUserProfile')
  store.dispatch('wallet/fetchSettings')
})
</script>

<style scoped>
.settings-page {
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding-bottom: 20px;
}

/* Profile Section */
.profile-section {
  margin-bottom: 8px;
}

.profile-content {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px;
}

.profile-avatar {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  overflow: hidden;
  background: linear-gradient(135deg, #007AFF, #0A84FF);
  display: flex;
  align-items: center;
  justify-content: center;
}

.profile-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-placeholder {
  color: white;
}

.profile-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.profile-info h3 {
  font-size: 20px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.profile-info p {
  font-size: 14px;
  color: #8e8e93;
  margin: 0;
}

.profile-status {
  font-size: 12px;
  color: #34C759;
  font-weight: 600;
}

.edit-profile-btn {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: none;
  background: rgba(0, 122, 255, 0.1);
  color: #007AFF;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
}

.edit-profile-btn:hover {
  background: rgba(0, 122, 255, 0.2);
}

/* Settings Groups */
.settings-groups {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.settings-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.group-title {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
  padding: 0 4px;
}

.settings-list {
  display: flex;
  flex-direction: column;
}

.setting-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  cursor: pointer;
  transition: all 0.2s ease;
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
}

.setting-item:last-child {
  border-bottom: none;
}

.setting-item:hover {
  background: rgba(0, 0, 0, 0.02);
}

.setting-item.danger {
  color: #FF3B30;
}

.setting-item.danger .setting-icon {
  color: #FF3B30;
}

.setting-icon {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: rgba(0, 122, 255, 0.1);
  color: #007AFF;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.setting-item.danger .setting-icon {
  background: rgba(255, 59, 48, 0.1);
}

.setting-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.setting-label {
  font-size: 16px;
  font-weight: 500;
  color: #1d1d1f;
}

.setting-item.danger .setting-label {
  color: #FF3B30;
}

.setting-description {
  font-size: 12px;
  color: #8e8e93;
}

.setting-badge {
  padding: 4px 8px;
  border-radius: 6px;
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
}

.setting-badge.verified {
  background: rgba(52, 199, 89, 0.1);
  color: #34C759;
}

.chevron {
  color: #8e8e93;
  flex-shrink: 0;
}

/* Toggle Switch */
.toggle-switch {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
  flex-shrink: 0;
}

.toggle-switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.toggle-slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #ccc;
  transition: 0.3s;
  border-radius: 24px;
}

.toggle-slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: 0.3s;
  border-radius: 50%;
}

input:checked + .toggle-slider {
  background-color: #007AFF;
}

input:checked + .toggle-slider:before {
  transform: translateX(20px);
}

/* Currency and Language Modals */
.currency-list,
.language-list {
  display: flex;
  flex-direction: column;
  max-height: 400px;
  overflow-y: auto;
}

.currency-item,
.language-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  cursor: pointer;
  transition: all 0.2s ease;
  border-bottom: 1px solid rgba(0, 0, 0, 0.05);
}

.currency-item:last-child,
.language-item:last-child {
  border-bottom: none;
}

.currency-item:hover,
.language-item:hover {
  background: rgba(0, 0, 0, 0.02);
}

.currency-item.selected,
.language-item.selected {
  background: rgba(0, 122, 255, 0.05);
}

.currency-info,
.language-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.currency-code,
.language-name {
  font-size: 16px;
  font-weight: 500;
  color: #1d1d1f;
}

.currency-name,
.language-native {
  font-size: 12px;
  color: #8e8e93;
}

.currency-check,
.language-check {
  color: #007AFF;
}

/* Responsive Design */
@media (max-width: 768px) {
  .profile-content {
    padding: 16px;
  }

  .profile-avatar {
    width: 56px;
    height: 56px;
  }

  .profile-info h3 {
    font-size: 18px;
  }

  .setting-item {
    padding: 14px 16px;
  }

  .setting-icon {
    width: 36px;
    height: 36px;
  }

  .setting-label {
    font-size: 15px;
  }
}

@media (max-width: 375px) {
  .profile-content {
    flex-direction: column;
    text-align: center;
    gap: 12px;
  }

  .edit-profile-btn {
    align-self: center;
  }

  .setting-item {
    padding: 12px 16px;
    gap: 12px;
  }

  .setting-icon {
    width: 32px;
    height: 32px;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .group-title {
    color: #f2f2f7;
  }

  .profile-info h3 {
    color: #f2f2f7;
  }

  .setting-label {
    color: #f2f2f7;
  }

  .setting-item:hover {
    background: rgba(255, 255, 255, 0.02);
  }

  .setting-item.selected {
    background: rgba(0, 122, 255, 0.1);
  }

  .currency-item:hover,
  .language-item:hover {
    background: rgba(255, 255, 255, 0.02);
  }

  .currency-item.selected,
  .language-item.selected {
    background: rgba(0, 122, 255, 0.1);
  }

  .currency-code,
  .language-name {
    color: #f2f2f7;
  }

  .toggle-slider {
    background-color: #48484a;
  }

  input:checked + .toggle-slider {
    background-color: #0A84FF;
  }
}
</style>