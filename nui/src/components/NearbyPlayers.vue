<template>
  <transition name="nearby-section">
    <div v-if="hasNearbyPlayers" class="nearby-section">
      <div class="section-header">
        <span>{{ $t('contactSharing.nearbyTitle') }}</span>
        <span class="count">{{ nearbyCount }}</span>
      </div>
      
      <transition-group name="nearby-list" tag="div" class="nearby-list">
        <button 
          v-for="player in sortedPlayers" 
          :key="player.source"
          class="nearby-player-item"
          @click="handlePlayerClick(player)"
          :aria-label="`${player.characterName}, ${formatDistance(player.distance)} away${player.isBroadcasting ? ', sharing contact' : ''}`"
        >
          <div class="player-avatar">
            <span class="avatar-text">{{ getInitials(player.characterName) }}</span>
          </div>
          
          <div class="player-info">
            <div class="player-name">{{ player.characterName }}</div>
            <div class="player-distance">{{ formatDistance(player.distance) }}</div>
          </div>
          
          <div v-if="player.isBroadcasting" class="broadcast-indicator" aria-label="Sharing contact">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              <polyline points="16 6 12 2 8 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              <line x1="12" y1="2" x2="12" y2="15" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
          </div>
          
          <svg class="chevron-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <path d="m9 18 6-6-6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
      </transition-group>
    </div>
  </transition>
</template>

<script>
import { computed } from 'vue'
import { useStore } from 'vuex'
import { hapticSelection } from '../utils/haptics'

export default {
  name: 'NearbyPlayers',
  
  emits: ['player-selected'],
  
  setup(props, { emit }) {
    const store = useStore()
    
    // Computed
    const sortedPlayers = computed(() => {
      return store.getters['nearbyPlayers/sortedPlayers']
    })
    
    const nearbyCount = computed(() => {
      return store.getters['nearbyPlayers/count']
    })
    
    const hasNearbyPlayers = computed(() => {
      return nearbyCount.value > 0
    })
    
    // Methods
    const getInitials = (name) => {
      if (!name) return '?'
      return name
        .split(' ')
        .map(n => n.charAt(0))
        .join('')
        .toUpperCase()
        .slice(0, 2)
    }
    
    const formatDistance = (meters) => {
      if (meters < 1) {
        return '<1m'
      } else if (meters < 10) {
        return `${meters.toFixed(1)}m`
      } else {
        return `${Math.round(meters)}m`
      }
    }
    
    const handlePlayerClick = (player) => {
      // Trigger haptic feedback on player selection
      hapticSelection()
      emit('player-selected', player)
    }
    
    return {
      sortedPlayers,
      nearbyCount,
      hasNearbyPlayers,
      getInitials,
      formatDistance,
      handlePlayerClick
    }
  }
}
</script>

<style scoped>
.nearby-section {
  background: #fff;
  border-bottom: 1px solid #e5e5ea;
  margin-bottom: 20px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 20px 4px;
  font-size: 13px;
  font-weight: 600;
  color: #8e8e93;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  background: #f2f2f7;
  border-bottom: 1px solid #e5e5ea;
}

.section-header .count {
  background: #8e8e93;
  color: #fff;
  border-radius: 10px;
  padding: 2px 8px;
  font-size: 12px;
  font-weight: 600;
  min-width: 20px;
  text-align: center;
}

.nearby-list {
  background: #fff;
}

.nearby-player-item {
  display: flex;
  align-items: center;
  padding: 12px 20px;
  background: #fff;
  border: none;
  border-bottom: 1px solid #e5e5ea;
  cursor: pointer;
  transition: background-color 0.2s;
  min-height: 64px;
  width: 100%;
  text-align: left;
}

.nearby-player-item:hover {
  background: #f8f8f8;
}

.nearby-player-item:active {
  background: #e5e5ea;
}

.nearby-player-item:focus {
  outline: 2px solid #007aff;
  outline-offset: -2px;
}

.player-avatar {
  width: 40px;
  height: 40px;
  border-radius: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
  flex-shrink: 0;
}

.avatar-text {
  font-size: 16px;
  font-weight: 600;
  color: #fff;
}

.player-info {
  flex: 1;
  min-width: 0;
}

.player-name {
  font-size: 17px;
  font-weight: 400;
  color: #000;
  margin-bottom: 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.player-distance {
  font-size: 15px;
  color: #8e8e93;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.broadcast-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: 8px;
  margin-right: 8px;
  color: #007aff;
  animation: pulse 2s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.7;
    transform: scale(1.1);
  }
}

.chevron-icon {
  color: #c7c7cc;
  margin-left: 8px;
  flex-shrink: 0;
}

/* Transitions */
.nearby-section-enter-active,
.nearby-section-leave-active {
  transition: all 0.3s ease;
}

.nearby-section-enter-from {
  opacity: 0;
  transform: translateY(-20px);
}

.nearby-section-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}

.nearby-list-enter-active,
.nearby-list-leave-active {
  transition: all 0.3s ease;
}

.nearby-list-enter-from {
  opacity: 0;
  transform: translateX(-20px);
}

.nearby-list-leave-to {
  opacity: 0;
  transform: translateX(20px);
}

.nearby-list-move {
  transition: transform 0.3s ease;
}

/* Responsive Design */
@media (max-width: 480px) {
  .nearby-player-item {
    padding: 12px 16px;
  }
  
  .player-avatar {
    width: 36px;
    height: 36px;
  }
  
  .player-name {
    font-size: 16px;
  }
  
  .player-distance {
    font-size: 13px;
  }
}

@media (max-width: 375px) {
  .nearby-player-item {
    padding: 10px 16px;
  }
  
  .player-avatar {
    width: 32px;
    height: 32px;
  }
  
  .player-name {
    font-size: 15px;
  }
  
  .player-distance {
    font-size: 12px;
  }
  
  .section-header {
    padding: 6px 16px;
    font-size: 12px;
  }
}

@media (max-width: 320px) {
  .nearby-player-item {
    padding: 8px 12px;
  }
  
  .player-avatar {
    width: 28px;
    height: 28px;
  }
  
  .player-name {
    font-size: 14px;
  }
  
  .player-distance {
    font-size: 11px;
  }
}

/* High contrast mode support */
@media (prefers-contrast: high) {
  .nearby-player-item {
    border: 1px solid;
  }
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
  .nearby-section-enter-active,
  .nearby-section-leave-active,
  .nearby-list-enter-active,
  .nearby-list-leave-active,
  .nearby-list-move,
  .nearby-player-item,
  .broadcast-indicator {
    transition: none !important;
    animation: none !important;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .nearby-section {
    background: #1c1c1e;
    border-bottom-color: #38383a;
  }
  
  .section-header {
    background: #000;
    border-bottom-color: #38383a;
  }
  
  .nearby-list {
    background: #1c1c1e;
  }
  
  .nearby-player-item {
    background: #1c1c1e;
    border-bottom-color: #38383a;
  }
  
  .nearby-player-item:hover {
    background: #2c2c2e;
  }
  
  .player-name {
    color: #fff;
  }
}
</style>
