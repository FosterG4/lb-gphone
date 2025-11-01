<template>
  <div id="phone-app" :class="{ 'phone-visible': isVisible }">
    <Phone />
    <Notification 
      v-for="(notification, index) in notifications" 
      :key="notification.id"
      :notification="notification"
      :index="index"
      @close="removeNotification(notification.id)"
    />
  </div>
</template>

<script>
import { computed, onMounted, onUnmounted } from 'vue'
import { useStore } from 'vuex'
import Phone from './components/Phone.vue'
import Notification from './components/Notification.vue'

export default {
  name: 'App',
  components: {
    Phone,
    Notification
  },
  setup() {
    const store = useStore()
    
    const isVisible = computed(() => store.state.phone.isVisible)
    const notifications = computed(() => store.state.phone.notifications)
    
    const removeNotification = (id) => {
      store.commit('phone/removeNotification', id)
    }
    
    // Listen for phone-notification custom events
    const handlePhoneNotification = (event) => {
      if (event.detail) {
        store.dispatch('phone/showNotification', event.detail)
      }
    }
    
    onMounted(() => {
      window.addEventListener('phone-notification', handlePhoneNotification)
    })
    
    onUnmounted(() => {
      window.removeEventListener('phone-notification', handlePhoneNotification)
    })
    
    return {
      isVisible,
      notifications,
      removeNotification
    }
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

#phone-app {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  display: none;
  justify-content: flex-end;
  align-items: flex-end;
  padding: 20px;
  pointer-events: none;
  z-index: 9999;
}

#phone-app > * {
  pointer-events: auto;
}

#phone-app.phone-visible {
  display: flex;
}
</style>
