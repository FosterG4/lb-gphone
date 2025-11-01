<template>
  <div class="phone-container">
    <div class="phone-frame">
      <div class="phone-notch"></div>
      <div class="phone-screen">
        <!-- Setup Flow -->
        <SetupFlow 
          v-if="!isSetupComplete" 
          @setup-complete="handleSetupComplete" 
        />

        <!-- Main Phone Interface -->
        <template v-else>
          <StatusBar />

          <div class="screen-content">
            <Lockscreen v-if="isLocked" @unlock="handleUnlock" />

            <template v-else>
              <Homescreen v-if="!currentApp" @open-app="openApp" />

              <div v-else class="app-view">
                <div class="app-header">
                  <button class="back-button" @click="goBack">
                    <svg
                      width="24"
                      height="24"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      stroke-width="2"
                    >
                      <path d="M19 12H5M12 19l-7-7 7-7" />
                    </svg>
                  </button>
                  <span class="app-title">{{ currentAppTitle }}</span>
                </div>

                <component :is="currentAppComponent" />
              </div>
            </template>
          </div>
        </template>
      </div>

      <div class="phone-home-indicator"></div>
      
      <!-- Share Request Notification -->
      <ShareRequestNotification
        v-if="currentShareRequest"
        :request="currentShareRequest"
        :visible="!!currentShareRequest"
        @accept="handleShareRequestAccept"
        @decline="handleShareRequestDecline"
        @expired="handleShareRequestExpired"
      />
    </div>
  </div>
</template>

<script>
import { computed, ref } from "vue";
import { useStore } from "vuex";
import StatusBar from "./StatusBar.vue";
import SetupFlow from "./SetupFlow.vue";
import Lockscreen from "./Lockscreen.vue";
import Homescreen from "./Homescreen.vue";
import Contacts from "../views/Contacts.vue";
import Messages from "../views/Messages.vue";
import Dialer from "../views/Dialer.vue";
import CallScreen from "../views/CallScreen.vue";
import Bank from "../apps/Bank.vue";
import Bankr from "../apps/Bankr.vue";
import Chirper from "../apps/Chirper.vue";
import Settings from "../apps/Settings.vue";
import Clock from "../apps/Clock.vue";
import Notes from "../apps/Notes.vue";
import Photos from "../apps/Photos.vue";
import Maps from "../apps/Maps.vue";
import Weather from "../apps/Weather.vue";
import AppStore from "../apps/AppStore.vue";
import CryptoX from "../apps/CryptoX.vue";
import Marketplace from "../apps/Marketplace.vue";
import Pages from "../apps/Pages.vue";
import Musicly from "../apps/Musicly.vue";
import Finder from "../apps/Finder.vue";
import SafeZone from "../apps/SafeZone.vue";
import VoiceRecorder from "../apps/VoiceRecorder.vue";
import Camera from "../apps/Camera.vue";
import Wallet from "../apps/Wallet.vue";
import ContactDetails from "./ContactDetails.vue";
import ShareRequestNotification from "./ShareRequestNotification.vue";

export default {
  name: "Phone",
  components: {
    StatusBar,
    SetupFlow,
    Lockscreen,
    Homescreen,
    Contacts,
    Messages,
    Dialer,
    CallScreen,
    Bank,
    Bankr,
    Chirper,
    Settings,
    Clock,
    Notes,
    Photos,
    Maps,
    Weather,
    AppStore,
    CryptoX,
    Marketplace,
    Pages,
    Musicly,
    Finder,
    SafeZone,
    VoiceRecorder,
    Camera,
    Wallet,
    ContactDetails,
    ShareRequestNotification,
  },
  setup() {
    const store = useStore();
    const isLocked = ref(false);
    const isSetupComplete = ref(false); // Start with setup flow
    
    // Share request notification queue
    const shareRequestQueue = ref([])
    const currentShareRequest = ref(null)

    const currentApp = computed(() => store.state.phone.currentApp);

    const appComponents = {
      contacts: Contacts,
      messages: Messages,
      dialer: Dialer,
      "call-screen": CallScreen,
      bank: Bank,
      bankr: Bankr,
      chirper: Chirper,
      settings: Settings,
      clock: Clock,
      notes: Notes,
      photos: Photos,
      maps: Maps,
      weather: Weather,
      appstore: AppStore,
      cryptox: CryptoX,
      marketplace: Marketplace,
      pages: Pages,
      musicly: Musicly,
      finder: Finder,
      safezone: SafeZone,
      voicerecorder: VoiceRecorder,
      camera: Camera,
      wallet: Wallet,
      "contact-details": ContactDetails,
    };

    const appTitles = {
      contacts: "Contacts",
      messages: "Messages",
      dialer: "Phone",
      "call-screen": "Call",
      bank: "Bank",
      bankr: "Bankr",
      chirper: "Chirper",
      settings: "Settings",
      clock: "Clock",
      notes: "Notes",
      photos: "Photos",
      maps: "Maps",
      weather: "Weather",
      appstore: "App Store",
      cryptox: "CryptoX",
      marketplace: "Marketplace",
      pages: "Business Pages",
      musicly: "Musicly",
      finder: "Finder",
      safezone: "SafeZone",
      voicerecorder: "Voice Recorder",
      camera: "Camera",
      wallet: "Wallet",
      "contact-details": "Contact",
    };

    const currentAppComponent = computed(() => {
      return currentApp.value ? appComponents[currentApp.value] : null;
    });

    const currentAppTitle = computed(() => {
      return currentApp.value ? appTitles[currentApp.value] : "";
    });

    const handleSetupComplete = (setupData) => {
      console.log("Setup completed with data:", setupData);
      // Store setup data in localStorage or Vuex store
      localStorage.setItem("lb-phone-setup", JSON.stringify(setupData));
      isSetupComplete.value = true;
    };

    const handleUnlock = () => {
      isLocked.value = false;
    };

    const openApp = (appName) => {
      store.commit("phone/setCurrentApp", appName);
    };

    const goBack = () => {
      store.commit("phone/setCurrentApp", null);
    };
    
    // Share request notification handlers
    const showShareRequest = (request) => {
      // Add to queue
      shareRequestQueue.value.push(request)
      
      // Show immediately if no current request
      if (!currentShareRequest.value) {
        showNextShareRequest()
      }
    }
    
    const showNextShareRequest = () => {
      if (shareRequestQueue.value.length > 0) {
        currentShareRequest.value = shareRequestQueue.value.shift()
      } else {
        currentShareRequest.value = null
      }
    }
    
    const handleShareRequestAccept = (data) => {
      console.log('Share request accepted:', data)
      
      // Refresh contacts list
      store.dispatch('contacts/fetchContacts')
      
      // Show next request in queue
      showNextShareRequest()
    }
    
    const handleShareRequestDecline = (data) => {
      console.log('Share request declined:', data)
      
      // Show next request in queue
      showNextShareRequest()
    }
    
    const handleShareRequestExpired = (data) => {
      console.log('Share request expired:', data)
      
      // Show next request in queue
      showNextShareRequest()
    }
    
    // Listen for share request events from client
    window.addEventListener('message', (event) => {
      if (event.data.type === 'shareRequestReceived') {
        showShareRequest(event.data.request)
      }
    })

    // Check if setup was already completed
    const savedSetup = localStorage.getItem("lb-phone-setup");
    if (savedSetup) {
      isSetupComplete.value = true;
    }

    return {
      isLocked,
      isSetupComplete,
      currentApp,
      currentAppComponent,
      currentAppTitle,
      currentShareRequest,
      handleSetupComplete,
      handleUnlock,
      openApp,
      goBack,
      handleShareRequestAccept,
      handleShareRequestDecline,
      handleShareRequestExpired,
    };
  },
};
</script>

<style scoped>
.phone-container {
  width: 400px;
  height: 850px;
  position: relative;
}

.phone-frame {
  width: 100%;
  height: 100%;
  background: linear-gradient(145deg, #2a2a2a, #1a1a1a);
  border-radius: 45px;
  padding: 12px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.8),
    inset 0 1px 2px rgba(255, 255, 255, 0.1);
  position: relative;
  display: flex;
  flex-direction: column;
}

.phone-notch {
  position: absolute;
  top: 12px;
  left: 50%;
  transform: translateX(-50%);
  width: 150px;
  height: 30px;
  background: #000;
  border-radius: 0 0 20px 20px;
  z-index: 10;
}

.phone-screen {
  flex: 1;
  background: #000;
  border-radius: 35px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  position: relative;
}

.screen-content {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.app-view {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: #000;
}

.app-header {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  background: rgba(20, 20, 20, 0.95);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.back-button {
  background: none;
  border: none;
  color: #007aff;
  cursor: pointer;
  padding: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  border-radius: 8px;
}

.back-button:hover {
  background: rgba(0, 122, 255, 0.1);
}

.app-title {
  flex: 1;
  text-align: center;
  color: #fff;
  font-size: 18px;
  font-weight: 600;
  margin-right: 40px;
}

.phone-home-indicator {
  position: absolute;
  bottom: 8px;
  left: 50%;
  transform: translateX(-50%);
  width: 140px;
  height: 5px;
  background: rgba(255, 255, 255, 0.3);
  border-radius: 3px;
}

/* Responsive design */
@media (max-width: 1920px) and (max-height: 1080px) {
  .phone-container {
    width: 360px;
    height: 760px;
  }
}

@media (max-width: 1600px) and (max-height: 900px) {
  .phone-container {
    width: 320px;
    height: 680px;
  }

  .phone-frame {
    border-radius: 40px;
    padding: 10px;
  }

  .phone-screen {
    border-radius: 32px;
  }

  .phone-notch {
    width: 130px;
    height: 26px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .phone-container {
    width: 280px;
    height: 600px;
  }

  .phone-frame {
    border-radius: 35px;
    padding: 8px;
  }

  .phone-screen {
    border-radius: 28px;
  }

  .phone-notch {
    width: 120px;
    height: 25px;
  }

  .app-header {
    padding: 10px 14px;
  }

  .app-title {
    font-size: 16px;
  }
}
</style>
