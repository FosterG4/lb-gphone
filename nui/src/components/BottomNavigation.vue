<template>
  <div class="bottom-navigation">
    <div class="nav-container">
      <div
        v-for="tab in tabs"
        :key="tab.id"
        class="nav-tab"
        :class="{ active: activeTab === tab.id }"
        @click="switchTab(tab.id)"
      >
        <div class="tab-icon">
          <component :is="tab.icon" :class="{ active: activeTab === tab.id }" />
        </div>
        <span class="tab-label" :class="{ active: activeTab === tab.id }">
          {{ tab.label }}
        </span>
        <div v-if="tab.badge" class="tab-badge">{{ tab.badge }}</div>
      </div>
    </div>
  </div>
</template>

<script>
import { h } from "vue";

// Tab Icons
const HomeIcon = () =>
  h(
    "svg",
    {
      width: "24",
      height: "24",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z",
      }),
    ]
  );

const RecentsIcon = () =>
  h(
    "svg",
    {
      width: "24",
      height: "24",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M13 3c-4.97 0-9 4.03-9 9H1l3.89 3.89.07.14L9 12H6c0-3.87 3.13-7 7-7s7 3.13 7 7-3.13 7-7 7c-1.93 0-3.68-.79-4.94-2.06l-1.42 1.42C8.27 19.99 10.51 21 13 21c4.97 0 9-4.03 9-9s-4.03-9-9-9zm-1 5v5l4.28 2.54.72-1.21-3.5-2.08V8H12z",
      }),
    ]
  );

const FavoritesIcon = () =>
  h(
    "svg",
    {
      width: "24",
      height: "24",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z",
      }),
    ]
  );

const SettingsIcon = () =>
  h(
    "svg",
    {
      width: "24",
      height: "24",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z",
      }),
    ]
  );

export default {
  name: "BottomNavigation",
  props: {
    activeTab: {
      type: String,
      default: "home",
    },
  },
  emits: ["tab-change"],
  setup(props, { emit }) {
    const tabs = [
      {
        id: "home",
        label: "Home",
        icon: HomeIcon,
      },
      {
        id: "recents",
        label: "Recents",
        icon: RecentsIcon,
        badge: null, // Will be populated with recent items count
      },
      {
        id: "favorites",
        label: "Favorites",
        icon: FavoritesIcon,
      },
      {
        id: "settings",
        label: "Settings",
        icon: SettingsIcon,
      },
    ];

    const switchTab = (tabId) => {
      emit("tab-change", tabId);
    };

    return {
      tabs,
      switchTab,
    };
  },
};
</script>

<style scoped>
.bottom-navigation {
  position: relative;
  background: rgba(28, 28, 30, 0.95);
  backdrop-filter: blur(20px);
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding: 8px 0 12px 0;
}

.nav-container {
  display: flex;
  justify-content: space-around;
  align-items: center;
  max-width: 100%;
  margin: 0 auto;
}

.nav-tab {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-width: 44px;
  min-height: 44px;
  padding: 4px 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
  border-radius: 12px;
}

.nav-tab:hover {
  background: rgba(255, 255, 255, 0.05);
}

.nav-tab:active {
  transform: scale(0.95);
}

.tab-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 2px;
  transition: all 0.2s ease;
}

.tab-icon svg {
  color: rgba(255, 255, 255, 0.6);
  transition: color 0.2s ease;
}

.tab-icon.active svg {
  color: #007aff;
}

.tab-label {
  font-size: 10px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.6);
  transition: color 0.2s ease;
  text-align: center;
  line-height: 1;
}

.tab-label.active {
  color: #007aff;
}

.tab-badge {
  position: absolute;
  top: 2px;
  right: 8px;
  background: #ff3b30;
  color: white;
  font-size: 10px;
  font-weight: 600;
  min-width: 16px;
  height: 16px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 4px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

/* Active tab indicator */
.nav-tab.active::before {
  content: "";
  position: absolute;
  top: -8px;
  left: 50%;
  transform: translateX(-50%);
  width: 4px;
  height: 4px;
  background: #007aff;
  border-radius: 2px;
  opacity: 0;
  animation: fadeIn 0.3s ease forwards;
}

@keyframes fadeIn {
  to {
    opacity: 1;
  }
}

/* Responsive design */
@media (max-width: 1600px) and (max-height: 900px) {
  .nav-tab {
    min-width: 40px;
    min-height: 40px;
    padding: 3px 6px;
  }

  .tab-icon svg {
    width: 22px;
    height: 22px;
  }

  .tab-label {
    font-size: 9px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .bottom-navigation {
    padding: 6px 0 10px 0;
  }

  .nav-tab {
    min-width: 36px;
    min-height: 36px;
    padding: 2px 4px;
  }

  .tab-icon svg {
    width: 20px;
    height: 20px;
  }

  .tab-label {
    font-size: 8px;
  }

  .tab-badge {
    min-width: 14px;
    height: 14px;
    font-size: 9px;
    top: 1px;
    right: 6px;
  }
}
</style>