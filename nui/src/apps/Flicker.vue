<template>
  <div class="flicker-app">
    <!-- Header -->
    <div class="flicker-header">
      <div class="header-left">
        <button v-if="currentView !== 'swipe'" @click="goBack" class="back-btn">
          <i class="fas fa-arrow-left"></i>
        </button>
        <h1>{{ headerTitle }}</h1>
      </div>
      <div class="header-right">
        <button v-if="currentView === 'swipe'" @click="currentView = 'matches'" class="matches-btn">
          <i class="fas fa-comments"></i>
          <span v-if="matchCount > 0" class="badge">{{ matchCount }}</span>
        </button>
        <button @click="currentView = 'profile'" class="profile-btn">
          <i class="fas fa-user"></i>
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="loading">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Loading...</p>
    </div>

    <!-- No Profile State -->
    <div v-else-if="!hasProfile && currentView !== 'profile'" class="empty-state">
      <i class="fas fa-heart"></i>
      <p>Create your profile to start matching</p>
      <button @click="currentView = 'profile'" class="primary-btn">
        Create Profile
      </button>
    </div>

    <!-- Swipe View -->
    <div v-else-if="currentView === 'swipe'" class="swipe-container">
      <div v-if="currentProfile" class="profile-card" :style="cardStyle">
        <!-- Profile Images -->
        <div class="profile-images">
          <img 
            v-if="currentProfile.photos && currentProfile.photos.length > 0"
            :src="currentProfile.photos[currentPhotoIndex]" 
            :alt="currentProfile.display_name"
            @click="nextPhoto"
          />
          <div v-else class="no-photo">
            <i class="fas fa-user"></i>
          </div>
          
          <!-- Photo Indicators -->
          <div v-if="currentProfile.photos && currentProfile.photos.length > 1" class="photo-indicators">
            <span 
              v-for="(photo, index) in currentProfile.photos" 
              :key="index"
              :class="['indicator', { active: index === currentPhotoIndex }]"
            ></span>
          </div>
        </div>

        <!-- Profile Info -->
        <div class="profile-info">
          <div class="profile-name-age">
            <h2>{{ currentProfile.display_name }}</h2>
            <span v-if="currentProfile.age" class="age">, {{ currentProfile.age }}</span>
          </div>
          <div v-if="currentProfile.distance" class="distance">
            <i class="fas fa-map-marker-alt"></i>
            {{ currentProfile.distance }}m away
          </div>
          <p v-if="currentProfile.bio" class="bio">{{ currentProfile.bio }}</p>
        </div>

        <!-- Swipe Actions -->
        <div class="swipe-actions">
          <button @click="swipeLeft" class="action-btn pass-btn" :disabled="swiping">
            <i class="fas fa-times"></i>
          </button>
          <button @click="swipeRight" class="action-btn like-btn" :disabled="swiping">
            <i class="fas fa-heart"></i>
          </button>
        </div>
      </div>

      <!-- No More Profiles -->
      <div v-else class="empty-state">
        <i class="fas fa-search"></i>
        <p>No more profiles</p>
        <p class="hint">Check back later for new matches</p>
        <button @click="refreshProfiles" class="secondary-btn">
          <i class="fas fa-sync-alt"></i> Refresh
        </button>
      </div>
    </div>

    <!-- Matches View -->
    <div v-else-if="currentView === 'matches'" class="matches-container">
      <div v-if="matches.length === 0" class="empty-state">
        <i class="fas fa-heart-broken"></i>
        <p>No matches yet</p>
        <p class="hint">Keep swiping to find your match!</p>
      </div>

      <div v-else class="matches-list">
        <div 
          v-for="match in matches" 
          :key="match.phone_number"
          class="match-item"
          @click="openChat(match)"
        >
          <div class="match-avatar">
            <img 
              v-if="match.photos && match.photos.length > 0"
              :src="match.photos[0]" 
              :alt="match.display_name"
            />
            <div v-else class="no-photo">
              {{ getInitials(match.display_name) }}
            </div>
          </div>
          <div class="match-info">
            <div class="match-name">{{ match.display_name }}</div>
            <div v-if="match.last_message_at" class="match-time">
              {{ formatTime(match.last_message_at) }}
            </div>
            <div v-else class="match-time">
              Matched {{ formatTime(match.matched_at) }}
            </div>
          </div>
          <i class="fas fa-chevron-right"></i>
        </div>
      </div>
    </div>

    <!-- Chat View -->
    <div v-else-if="currentView === 'chat'" class="chat-container">
      <div class="messages-list" ref="messagesList">
        <div v-if="currentMessages.length === 0" class="empty-state">
          <i class="fas fa-comments"></i>
          <p>Start the conversation!</p>
        </div>

        <div 
          v-for="message in currentMessages" 
          :key="message.id"
          :class="['message', { sent: message.sender_number === myPhoneNumber, received: message.sender_number !== myPhoneNumber }]"
        >
          <div class="message-content">{{ message.content }}</div>
          <div class="message-time">{{ formatTime(message.created_at) }}</div>
        </div>
      </div>

      <div class="message-input-container">
        <input 
          v-model="messageInput"
          type="text"
          placeholder="Type a message..."
          @keyup.enter="sendMessage"
          maxlength="500"
        />
        <button @click="sendMessage" :disabled="!messageInput.trim()" class="send-btn">
          <i class="fas fa-paper-plane"></i>
        </button>
      </div>

      <div class="chat-actions">
        <button @click="confirmUnmatch" class="danger-btn">
          <i class="fas fa-user-times"></i> Unmatch
        </button>
      </div>
    </div>

    <!-- Profile View (Create/Edit) -->
    <div v-else-if="currentView === 'profile'" class="profile-container">
      <div class="profile-form">
        <div class="form-group">
          <label>Display Name *</label>
          <input 
            v-model="profileForm.displayName"
            type="text"
            placeholder="Enter your name"
            maxlength="100"
          />
        </div>

        <div class="form-group">
          <label>Age *</label>
          <input 
            v-model.number="profileForm.age"
            type="number"
            min="18"
            max="100"
            placeholder="Enter your age"
            @input="validateAge"
          />
          <div v-if="ageError" class="error-message">{{ ageError }}</div>
        </div>

        <div class="form-group">
          <label>Bio</label>
          <textarea 
            v-model="profileForm.bio"
            placeholder="Tell us about yourself..."
            maxlength="500"
            rows="4"
          ></textarea>
          <div class="char-count">{{ profileForm.bio.length }}/500</div>
        </div>

        <div class="form-group">
          <label>Photos ({{ profileForm.photos.length }}/6)</label>
          <div class="photo-hint">
            <i class="fas fa-camera"></i>
            <span>Add up to 6 photos to your profile. First photo will be your main photo.</span>
          </div>
          <div class="photos-grid">
            <div 
              v-for="(photo, index) in profileForm.photos" 
              :key="index"
              class="photo-item"
            >
              <img :src="photo" :alt="'Photo ' + (index + 1)" />
              <div v-if="index === 0" class="main-photo-badge">Main</div>
              <div class="photo-actions">
                <button v-if="index > 0" @click="movePhotoLeft(index)" class="photo-action-btn" title="Move left">
                  <i class="fas fa-chevron-left"></i>
                </button>
                <button v-if="index < profileForm.photos.length - 1" @click="movePhotoRight(index)" class="photo-action-btn" title="Move right">
                  <i class="fas fa-chevron-right"></i>
                </button>
              </div>
              <button @click="removePhoto(index)" class="remove-photo-btn">
                <i class="fas fa-times"></i>
              </button>
            </div>
            <button 
              v-if="profileForm.photos.length < 6"
              @click="addPhoto" 
              class="add-photo-btn"
              :disabled="photoUploadProgress"
            >
              <i v-if="!photoUploadProgress" class="fas fa-plus"></i>
              <i v-else class="fas fa-spinner fa-spin"></i>
              <span>{{ photoUploadProgress ? 'Uploading...' : 'Add Photo' }}</span>
            </button>
          </div>
        </div>

        <div class="form-group">
          <label>Preferences</label>
          <div class="preferences">
            <div class="pref-item">
              <span>Age Range</span>
              <div class="range-inputs">
                <input 
                  v-model.number="profileForm.preferences.minAge"
                  type="number"
                  min="18"
                  max="100"
                  placeholder="Min"
                  @input="validatePreferences"
                />
                <span>-</span>
                <input 
                  v-model.number="profileForm.preferences.maxAge"
                  type="number"
                  min="18"
                  max="100"
                  placeholder="Max"
                  @input="validatePreferences"
                />
              </div>
            </div>
            <div class="pref-item">
              <span>Max Distance</span>
              <div class="distance-input">
                <input 
                  v-model.number="profileForm.preferences.maxDistance"
                  type="number"
                  min="100"
                  max="10000"
                  step="100"
                  placeholder="5000"
                  @input="validatePreferences"
                />
                <span class="unit">meters</span>
              </div>
            </div>
            <div v-if="distanceError" class="error-message">{{ distanceError }}</div>
            <div class="pref-hint">
              <i class="fas fa-info-circle"></i>
              <span>Profiles within {{ formatDistance(profileForm.preferences.maxDistance) }} will be shown</span>
            </div>
          </div>
        </div>

        <div class="form-actions">
          <button @click="saveProfile" class="primary-btn" :disabled="!isProfileValid">
            <i class="fas fa-save"></i> Save Profile
          </button>
          <button v-if="hasProfile" @click="toggleActive" :class="['secondary-btn', { danger: profile.active }]">
            <i :class="['fas', profile.active ? 'fa-pause' : 'fa-play']"></i>
            {{ profile.active ? 'Deactivate' : 'Activate' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Match Notification Modal -->
    <div v-if="showMatchModal" class="modal-overlay" @click="closeMatchModal">
      <div class="match-modal" @click.stop>
        <div class="match-celebration">
          <i class="fas fa-heart"></i>
          <h2>It's a Match!</h2>
          <p>You and {{ matchedProfile?.display_name }} liked each other</p>
        </div>
        <div v-if="matchedProfile" class="matched-profile">
          <div class="matched-avatar">
            <img 
              v-if="matchedProfile.photos && matchedProfile.photos.length > 0"
              :src="matchedProfile.photos[0]" 
              :alt="matchedProfile.display_name"
            />
            <div v-else class="no-photo">
              {{ getInitials(matchedProfile.display_name) }}
            </div>
          </div>
          <h3>{{ matchedProfile.display_name }}</h3>
        </div>
        <div class="match-actions">
          <button @click="sendMessageToMatch" class="primary-btn">
            <i class="fas fa-comment"></i> Send Message
          </button>
          <button @click="closeMatchModal" class="secondary-btn">
            Keep Swiping
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapGetters, mapActions } from 'vuex';

export default {
  name: 'Flicker',
  
  data() {
    return {
      currentView: 'swipe', // 'swipe', 'matches', 'chat', 'profile'
      currentPhotoIndex: 0,
      swiping: false,
      cardStyle: {},
      messageInput: '',
      currentChatMatch: null,
      showMatchModal: false,
      matchedProfile: null,
      profileForm: {
        displayName: '',
        bio: '',
        age: 18,
        photos: [],
        preferences: {
          minAge: 18,
          maxAge: 100,
          maxDistance: 5000
        },
        active: true
      },
      ageError: null,
      distanceError: null,
      photoUploadProgress: false
    };
  },
  
  computed: {
    ...mapState('flicker', ['profile', 'potentialMatches', 'matches', 'currentProfile', 'loading', 'error', 'matchMessages']),
    ...mapGetters('flicker', ['hasProfile', 'matchCount', 'getMatchMessages', 'nextProfile']),
    ...mapState('phone', ['phoneNumber']),
    
    myPhoneNumber() {
      return this.phoneNumber;
    },
    
    headerTitle() {
      switch (this.currentView) {
        case 'swipe': return 'Flicker';
        case 'matches': return 'Matches';
        case 'chat': return this.currentChatMatch?.display_name || 'Chat';
        case 'profile': return this.hasProfile ? 'Edit Profile' : 'Create Profile';
        default: return 'Flicker';
      }
    },
    
    currentMessages() {
      if (!this.currentChatMatch) return [];
      return this.getMatchMessages(this.currentChatMatch.phone_number);
    },
    
    isProfileValid() {
      return this.profileForm.displayName.trim().length > 0 &&
             this.profileForm.age >= 18 &&
             this.profileForm.age <= 100 &&
             this.profileForm.preferences.minAge >= 18 &&
             this.profileForm.preferences.maxAge <= 100 &&
             this.profileForm.preferences.minAge <= this.profileForm.preferences.maxAge &&
             this.profileForm.preferences.maxDistance >= 100 &&
             this.profileForm.preferences.maxDistance <= 10000 &&
             !this.ageError &&
             !this.distanceError;
    }
  },
  
  watch: {
    profile: {
      handler(newProfile) {
        if (newProfile) {
          this.profileForm = {
            displayName: newProfile.display_name || '',
            bio: newProfile.bio || '',
            age: newProfile.age || 18,
            photos: [...(newProfile.photos || [])],
            preferences: {
              minAge: newProfile.preferences?.minAge || 18,
              maxAge: newProfile.preferences?.maxAge || 100,
              maxDistance: newProfile.preferences?.maxDistance || 5000
            },
            active: newProfile.active !== false
          };
        }
      },
      immediate: true
    }
  },
  
  mounted() {
    this.init();
  },
  
  methods: {
    ...mapActions('flicker', [
      'fetchProfile',
      'saveProfile',
      'fetchPotentialMatches',
      'swipeRight',
      'swipeLeft',
      'fetchMatches',
      'fetchMatchMessages',
      'sendMatchMessage',
      'unmatch',
      'setCurrentProfile'
    ]),
    
    async init() {
      await this.fetchProfile();
      
      if (this.hasProfile) {
        await this.fetchPotentialMatches({ limit: 10, refresh: true });
        await this.fetchMatches();
      } else {
        this.currentView = 'profile';
      }
    },
    
    goBack() {
      if (this.currentView === 'chat') {
        this.currentView = 'matches';
        this.currentChatMatch = null;
      } else if (this.currentView === 'matches' || this.currentView === 'profile') {
        this.currentView = 'swipe';
      }
    },
    
    nextPhoto() {
      if (this.currentProfile && this.currentProfile.photos && this.currentProfile.photos.length > 1) {
        this.currentPhotoIndex = (this.currentPhotoIndex + 1) % this.currentProfile.photos.length;
      }
    },
    
    async swipeLeft() {
      if (this.swiping || !this.currentProfile) return;
      
      this.swiping = true;
      this.animateSwipe('left');
      
      setTimeout(async () => {
        await this.swipeLeft();
        this.currentPhotoIndex = 0;
        this.swiping = false;
        this.cardStyle = {};
        
        // Load more if running low
        if (this.potentialMatches.length < 3) {
          await this.fetchPotentialMatches({ limit: 10 });
        }
      }, 300);
    },

    async swipeRight() {
      if (this.swiping || !this.currentProfile) return;
      
      this.swiping = true;
      this.animateSwipe('right');
      
      setTimeout(async () => {
        const result = await this.swipeRight();
        this.currentPhotoIndex = 0;
        this.swiping = false;
        this.cardStyle = {};
        
        // Check for match
        if (result && result.isMatch) {
          this.matchedProfile = result.match;
          this.showMatchModal = true;
          await this.fetchMatches();
        }
        
        // Load more if running low
        if (this.potentialMatches.length < 3) {
          await this.fetchPotentialMatches({ limit: 10 });
        }
      }, 300);
    },
    
    animateSwipe(direction) {
      const translateX = direction === 'left' ? '-150%' : '150%';
      const rotate = direction === 'left' ? '-30deg' : '30deg';
      this.cardStyle = {
        transform: `translateX(${translateX}) rotate(${rotate})`,
        opacity: '0',
        transition: 'all 0.3s ease-out'
      };
    },
    
    async refreshProfiles() {
      await this.fetchPotentialMatches({ limit: 10, refresh: true });
    },
    
    openChat(match) {
      this.currentChatMatch = match;
      this.currentView = 'chat';
      this.fetchMatchMessages(match.phone_number);
    },
    
    async sendMessage() {
      if (!this.messageInput.trim() || !this.currentChatMatch) return;
      
      const content = this.messageInput.trim();
      this.messageInput = '';
      
      await this.sendMatchMessage({
        phoneNumber: this.currentChatMatch.phone_number,
        content
      });
      
      // Scroll to bottom
      this.$nextTick(() => {
        const messagesList = this.$refs.messagesList;
        if (messagesList) {
          messagesList.scrollTop = messagesList.scrollHeight;
        }
      });
    },
    
    async confirmUnmatch() {
      if (!this.currentChatMatch) return;
      
      if (confirm(`Are you sure you want to unmatch with ${this.currentChatMatch.display_name}?`)) {
        await this.unmatch(this.currentChatMatch.phone_number);
        this.currentView = 'matches';
        this.currentChatMatch = null;
      }
    },
    
    async saveProfile() {
      if (!this.isProfileValid) return;
      
      // Validate one more time before saving
      this.validateAge();
      this.validatePreferences();
      
      if (this.ageError || this.distanceError) {
        return;
      }
      
      const result = await this.$store.dispatch('flicker/saveProfile', {
        displayName: this.profileForm.displayName.trim(),
        bio: this.profileForm.bio.trim(),
        age: this.profileForm.age,
        photos: this.profileForm.photos,
        preferences: {
          minAge: this.profileForm.preferences.minAge,
          maxAge: this.profileForm.preferences.maxAge,
          maxDistance: this.profileForm.preferences.maxDistance
        },
        active: this.profileForm.active
      });
      
      if (result && result.success) {
        // Update filters in store
        await this.$store.dispatch('flicker/updateFilters', this.profileForm.preferences);
        
        this.currentView = 'swipe';
        await this.fetchPotentialMatches({ limit: 10, refresh: true });
      }
    },
    
    async toggleActive() {
      this.profileForm.active = !this.profileForm.active;
      await this.saveProfile();
    },
    
    async addPhoto() {
      // Open photo picker from gallery
      try {
        const response = await this.$store.dispatch('media/selectPhotos', {
          multiple: false,
          maxSelection: 1
        });
        
        if (response && response.success && response.photos && response.photos.length > 0) {
          const photo = response.photos[0];
          if (this.profileForm.photos.length < 6) {
            this.profileForm.photos.push(photo.file_url);
          }
        }
      } catch (error) {
        console.error('Error selecting photo:', error);
        // Fallback to URL input for development
        const photoUrl = prompt('Enter photo URL:');
        if (photoUrl && this.profileForm.photos.length < 6) {
          this.profileForm.photos.push(photoUrl);
        }
      }
    },
    
    removePhoto(index) {
      this.profileForm.photos.splice(index, 1);
    },
    
    movePhotoLeft(index) {
      if (index > 0) {
        const photos = [...this.profileForm.photos];
        [photos[index - 1], photos[index]] = [photos[index], photos[index - 1]];
        this.profileForm.photos = photos;
      }
    },
    
    movePhotoRight(index) {
      if (index < this.profileForm.photos.length - 1) {
        const photos = [...this.profileForm.photos];
        [photos[index], photos[index + 1]] = [photos[index + 1], photos[index]];
        this.profileForm.photos = photos;
      }
    },
    
    validateAge() {
      this.ageError = null;
      const age = this.profileForm.age;
      
      if (!age || age < 18) {
        this.ageError = 'You must be at least 18 years old';
      } else if (age > 100) {
        this.ageError = 'Please enter a valid age';
      }
    },
    
    validatePreferences() {
      this.distanceError = null;
      
      const { minAge, maxAge, maxDistance } = this.profileForm.preferences;
      
      if (minAge < 18) {
        this.profileForm.preferences.minAge = 18;
      }
      
      if (maxAge > 100) {
        this.profileForm.preferences.maxAge = 100;
      }
      
      if (minAge > maxAge) {
        this.profileForm.preferences.maxAge = minAge;
      }
      
      if (maxDistance < 100) {
        this.distanceError = 'Minimum distance is 100 meters';
      } else if (maxDistance > 10000) {
        this.distanceError = 'Maximum distance is 10,000 meters';
      }
    },
    
    closeMatchModal() {
      this.showMatchModal = false;
      this.matchedProfile = null;
    },
    
    sendMessageToMatch() {
      if (this.matchedProfile) {
        this.openChat(this.matchedProfile);
        this.closeMatchModal();
      }
    },
    
    getInitials(name) {
      if (!name) return '?';
      return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
    },
    
    formatTime(timestamp) {
      if (!timestamp) return '';
      const date = new Date(timestamp);
      const now = new Date();
      const diff = now - date;
      
      const minutes = Math.floor(diff / 60000);
      const hours = Math.floor(diff / 3600000);
      const days = Math.floor(diff / 86400000);
      
      if (minutes < 1) return 'Just now';
      if (minutes < 60) return `${minutes}m ago`;
      if (hours < 24) return `${hours}h ago`;
      if (days < 7) return `${days}d ago`;
      
      return date.toLocaleDateString();
    },
    
    formatDistance(meters) {
      if (meters >= 1000) {
        return `${(meters / 1000).toFixed(1)} km`;
      }
      return `${meters} m`;
    }
  }
};
</script>

<style scoped>
.flicker-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--background-color);
}

.flicker-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: var(--card-background);
  border-bottom: 1px solid var(--border-color);
}

.header-left, .header-right {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.header-left h1 {
  font-size: 1.25rem;
  font-weight: 600;
  margin: 0;
}

.back-btn, .matches-btn, .profile-btn {
  background: none;
  border: none;
  color: var(--primary-color);
  font-size: 1.25rem;
  cursor: pointer;
  padding: 0.5rem;
  position: relative;
}

.badge {
  position: absolute;
  top: 0;
  right: 0;
  background: var(--accent-color);
  color: white;
  font-size: 0.7rem;
  padding: 0.2rem 0.4rem;
  border-radius: 10px;
  min-width: 18px;
  text-align: center;
}

.loading, .empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex: 1;
  padding: 2rem;
  text-align: center;
  color: var(--text-color);
}

.loading i, .empty-state i {
  font-size: 3rem;
  margin-bottom: 1rem;
  color: var(--primary-color);
}

.empty-state .hint {
  color: var(--text-secondary);
  font-size: 0.9rem;
  margin-top: 0.5rem;
}

/* Swipe View */
.swipe-container {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  overflow: hidden;
}

.profile-card {
  width: 100%;
  max-width: 400px;
  height: 600px;
  background: var(--card-background);
  border-radius: 20px;
  overflow: hidden;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  display: flex;
  flex-direction: column;
}

.profile-images {
  position: relative;
  flex: 1;
  overflow: hidden;
}

.profile-images img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.no-photo {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--border-color);
  color: var(--text-secondary);
  font-size: 5rem;
}

.photo-indicators {
  position: absolute;
  top: 1rem;
  left: 0;
  right: 0;
  display: flex;
  gap: 0.5rem;
  padding: 0 1rem;
}

.indicator {
  flex: 1;
  height: 3px;
  background: rgba(255, 255, 255, 0.3);
  border-radius: 2px;
}

.indicator.active {
  background: white;
}

.profile-info {
  padding: 1.5rem;
  background: linear-gradient(to top, var(--card-background), transparent);
}

.profile-name-age {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.profile-name-age h2 {
  font-size: 1.75rem;
  font-weight: 600;
  margin: 0;
}

.age {
  font-size: 1.5rem;
  color: var(--text-secondary);
}

.distance {
  color: var(--text-secondary);
  font-size: 0.9rem;
  margin-bottom: 0.5rem;
}

.bio {
  color: var(--text-color);
  line-height: 1.5;
  margin: 0;
}

.swipe-actions {
  display: flex;
  justify-content: center;
  gap: 2rem;
  padding: 1.5rem;
}

.action-btn {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  transition: transform 0.2s;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.action-btn:hover:not(:disabled) {
  transform: scale(1.1);
}

.action-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.pass-btn {
  background: #ff4458;
  color: white;
}

.like-btn {
  background: #00d4a1;
  color: white;
}

/* Matches View */
.matches-container {
  flex: 1;
  overflow-y: auto;
}

.matches-list {
  padding: 0.5rem;
}

.match-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: var(--card-background);
  border-radius: 12px;
  margin-bottom: 0.5rem;
  cursor: pointer;
  transition: background 0.2s;
}

.match-item:hover {
  background: var(--border-color);
}

.match-avatar {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  overflow: hidden;
  flex-shrink: 0;
}

.match-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.match-avatar .no-photo {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--primary-color);
  color: white;
  font-size: 1.5rem;
  font-weight: 600;
}

.match-info {
  flex: 1;
}

.match-name {
  font-weight: 600;
  margin-bottom: 0.25rem;
}

.match-time {
  font-size: 0.85rem;
  color: var(--text-secondary);
}

/* Chat View */
.chat-container {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.messages-list {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.message {
  max-width: 70%;
  display: flex;
  flex-direction: column;
}

.message.sent {
  align-self: flex-end;
}

.message.received {
  align-self: flex-start;
}

.message-content {
  padding: 0.75rem 1rem;
  border-radius: 18px;
  word-wrap: break-word;
}

.message.sent .message-content {
  background: var(--primary-color);
  color: white;
  border-bottom-right-radius: 4px;
}

.message.received .message-content {
  background: var(--card-background);
  color: var(--text-color);
  border-bottom-left-radius: 4px;
}

.message-time {
  font-size: 0.75rem;
  color: var(--text-secondary);
  margin-top: 0.25rem;
  padding: 0 0.5rem;
}

.message-input-container {
  display: flex;
  gap: 0.5rem;
  padding: 1rem;
  background: var(--card-background);
  border-top: 1px solid var(--border-color);
}

.message-input-container input {
  flex: 1;
  padding: 0.75rem 1rem;
  border: 1px solid var(--border-color);
  border-radius: 24px;
  background: var(--background-color);
  color: var(--text-color);
  font-size: 1rem;
}

.send-btn {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: none;
  background: var(--primary-color);
  color: white;
  font-size: 1rem;
  cursor: pointer;
  transition: transform 0.2s;
}

.send-btn:hover:not(:disabled) {
  transform: scale(1.1);
}

.send-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.chat-actions {
  padding: 1rem;
  border-top: 1px solid var(--border-color);
}

/* Profile View */
.profile-container {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
}

.profile-form {
  max-width: 600px;
  margin: 0 auto;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  font-weight: 600;
  margin-bottom: 0.5rem;
  color: var(--text-color);
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  background: var(--background-color);
  color: var(--text-color);
  font-size: 1rem;
  font-family: inherit;
}

.char-count {
  text-align: right;
  font-size: 0.85rem;
  color: var(--text-secondary);
  margin-top: 0.25rem;
}

.photo-hint {
  display: flex;
  align-items: flex-start;
  gap: 0.5rem;
  padding: 0.75rem;
  background: var(--card-background);
  border-radius: 8px;
  font-size: 0.85rem;
  color: var(--text-secondary);
  margin-bottom: 1rem;
}

.photo-hint i {
  color: var(--primary-color);
  margin-top: 0.1rem;
}

.photos-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.5rem;
}

.photo-item {
  position: relative;
  aspect-ratio: 1;
  border-radius: 8px;
  overflow: hidden;
}

.photo-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.main-photo-badge {
  position: absolute;
  bottom: 0.25rem;
  left: 0.25rem;
  background: var(--primary-color);
  color: white;
  font-size: 0.7rem;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-weight: 600;
}

.remove-photo-btn {
  position: absolute;
  top: 0.25rem;
  right: 0.25rem;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  border: none;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  font-size: 0.75rem;
  cursor: pointer;
  transition: background 0.2s;
}

.remove-photo-btn:hover {
  background: rgba(255, 68, 88, 0.9);
}

.photo-actions {
  position: absolute;
  bottom: 0.25rem;
  right: 0.25rem;
  display: flex;
  gap: 0.25rem;
}

.photo-action-btn {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  border: none;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  font-size: 0.7rem;
  cursor: pointer;
  transition: background 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.photo-action-btn:hover {
  background: rgba(0, 122, 255, 0.9);
}

.add-photo-btn {
  aspect-ratio: 1;
  border: 2px dashed var(--border-color);
  border-radius: 8px;
  background: var(--card-background);
  color: var(--text-secondary);
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  font-size: 0.9rem;
  transition: all 0.2s;
}

.add-photo-btn:hover:not(:disabled) {
  border-color: var(--primary-color);
  color: var(--primary-color);
  background: var(--background-color);
}

.add-photo-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.preferences {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.pref-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.range-inputs {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.range-inputs input {
  width: 70px;
}

.distance-input {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.distance-input input {
  flex: 1;
}

.distance-input .unit {
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.error-message {
  color: var(--accent-color);
  font-size: 0.85rem;
  margin-top: 0.25rem;
}

.pref-hint {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem;
  background: var(--card-background);
  border-radius: 8px;
  font-size: 0.85rem;
  color: var(--text-secondary);
  margin-top: 0.5rem;
}

.pref-hint i {
  color: var(--primary-color);
}

.form-actions {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
}

.primary-btn, .secondary-btn, .danger-btn {
  flex: 1;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s;
}

.primary-btn {
  background: var(--primary-color);
  color: white;
}

.secondary-btn {
  background: var(--card-background);
  color: var(--text-color);
  border: 1px solid var(--border-color);
}

.danger-btn {
  background: var(--accent-color);
  color: white;
}

.primary-btn:disabled,
.secondary-btn:disabled,
.danger-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Match Modal */
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
  padding: 1rem;
}

.match-modal {
  background: var(--card-background);
  border-radius: 20px;
  padding: 2rem;
  max-width: 400px;
  width: 100%;
  text-align: center;
}

.match-celebration {
  margin-bottom: 2rem;
}

.match-celebration i {
  font-size: 4rem;
  color: #ff4458;
  animation: heartbeat 1s infinite;
}

@keyframes heartbeat {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.2); }
}

.match-celebration h2 {
  font-size: 2rem;
  margin: 1rem 0 0.5rem;
}

.matched-profile {
  margin-bottom: 2rem;
}

.matched-avatar {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  overflow: hidden;
  margin: 0 auto 1rem;
  border: 4px solid var(--primary-color);
}

.matched-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.matched-avatar .no-photo {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--primary-color);
  color: white;
  font-size: 3rem;
  font-weight: 600;
}

.match-actions {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
