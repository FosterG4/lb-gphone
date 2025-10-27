<template>
  <div class="homescreen">
    <div class="wallpaper"></div>

    <div class="app-grid">
      <div
        v-for="app in apps"
        :key="app.id"
        class="app-icon"
        @click="openApp(app.id)"
      >
        <div class="icon-container" :style="{ background: app.color }">
          <component :is="app.icon" />
        </div>
        <span class="app-name">{{ app.name }}</span>
      </div>
    </div>

    <div class="dock">
      <div
        v-for="dockApp in dockApps"
        :key="dockApp.id"
        class="dock-icon"
        @click="openApp(dockApp.id)"
      >
        <div class="icon-container" :style="{ background: dockApp.color }">
          <component :is="dockApp.icon" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { h } from "vue";

// SVG Icon Components
const ContactsIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z",
      }),
    ]
  );

const MessagesIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z",
      }),
    ]
  );

const PhoneIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z",
      }),
    ]
  );

const BankIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M11.8 10.9c-2.27-.59-3-1.2-3-2.15 0-1.09 1.01-1.85 2.7-1.85 1.78 0 2.44.85 2.5 2.1h2.21c-.07-1.72-1.12-3.3-3.21-3.81V3h-3v2.16c-1.94.42-3.5 1.68-3.5 3.61 0 2.31 1.91 3.46 4.7 4.13 2.5.6 3 1.48 3 2.41 0 .69-.49 1.79-2.7 1.79-2.06 0-2.87-.92-2.98-2.1h-2.2c.12 2.19 1.76 3.42 3.68 3.83V21h3v-2.15c1.95-.37 3.5-1.5 3.5-3.55 0-2.84-2.43-3.81-4.7-4.4z",
      }),
    ]
  );

const ChirperIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M22.46 6c-.85.38-1.78.64-2.75.76 1-.6 1.76-1.55 2.12-2.68-.93.55-1.96.95-3.06 1.17-.88-.94-2.13-1.53-3.51-1.53-2.66 0-4.81 2.16-4.81 4.81 0 .38.04.75.13 1.10-4-.2-7.54-2.12-9.91-5.04-.42.72-.66 1.55-.66 2.44 0 1.67.85 3.14 2.14 4-.79-.03-1.53-.24-2.18-.6v.06c0 2.33 1.66 4.28 3.86 4.72-.4.11-.83.17-1.27.17-.31 0-.62-.03-.92-.08.62 1.94 2.42 3.35 4.55 3.39-1.67 1.31-3.77 2.09-6.05 2.09-.39 0-.78-.02-1.17-.07 2.18 1.4 4.77 2.21 7.55 2.21 9.06 0 14.01-7.5 14.01-14.01 0-.21 0-.42-.02-.63.96-.7 1.8-1.56 2.46-2.55z",
      }),
    ]
  );

const CryptoIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M12 2L2 7v10c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7l-10-5zm0 10.99h7c-.53 4.12-3.28 7.79-7 8.94V12H5V9.99h7V8h-7V6.3l7-3.11v5.8h7v2H12v2z",
      }),
    ]
  );

const ClockIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z",
      }),
      h("path", { d: "M12.5 7H11v6l5.25 3.15.75-1.23-4.5-2.67z" }),
    ]
  );

const NotesIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z",
      }),
    ]
  );

const PhotosIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z",
      }),
    ]
  );

const MapsIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z",
      }),
    ]
  );

const WeatherIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M6.76 4.84l-1.8-1.79-1.41 1.41 1.79 1.79 1.42-1.41zM4 10.5H1v2h3v-2zm9-9.95h-2V3.5h2V.55zm7.45 3.91l-1.41-1.41-1.79 1.79 1.41 1.41 1.79-1.79zm-3.21 13.7l1.79 1.8 1.41-1.41-1.8-1.79-1.4 1.4zM20 10.5v2h3v-2h-3zm-8-5c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6zm-1 16.95h2V19.5h-2v2.95zm-7.45-3.91l1.41 1.41 1.79-1.8-1.41-1.41-1.79 1.8z",
      }),
    ]
  );

const SettingsIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z",
      }),
    ]
  );

const AppStoreIcon = () =>
  h(
    "svg",
    {
      width: "32",
      height: "32",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [h("path", { d: "M4 6h16v2H4zm0 5h16v2H4zm0 5h16v2H4z" })]
  );

export default {
  name: "Homescreen",
  emits: ["open-app"],
  setup(props, { emit }) {
    const apps = [
      {
        id: "contacts",
        name: "Contacts",
        color: "#8e8e93",
        icon: ContactsIcon,
      },
      {
        id: "messages",
        name: "Messages",
        color: "#34c759",
        icon: MessagesIcon,
      },
      { id: "bank", name: "Bank", color: "#007aff", icon: BankIcon },
      { id: "chirper", name: "Chirper", color: "#1da1f2", icon: ChirperIcon },
      { id: "crypto", name: "Crypto", color: "#ff9500", icon: CryptoIcon },
      { id: "clock", name: "Clock", color: "#000000", icon: ClockIcon },
      { id: "notes", name: "Notes", color: "#ffcc00", icon: NotesIcon },
      { id: "photos", name: "Photos", color: "#ff3b30", icon: PhotosIcon },
      { id: "maps", name: "Maps", color: "#5ac8fa", icon: MapsIcon },
      { id: "weather", name: "Weather", color: "#5ac8fa", icon: WeatherIcon },
      {
        id: "appstore",
        name: "App Store",
        color: "#007aff",
        icon: AppStoreIcon,
      },
      {
        id: "settings",
        name: "Settings",
        color: "#8e8e93",
        icon: SettingsIcon,
      },
    ];

    const dockApps = [
      { id: "dialer", name: "Phone", color: "#34c759", icon: PhoneIcon },
    ];

    const openApp = (appId) => {
      emit("open-app", appId);
    };

    return {
      apps,
      dockApps,
      openApp,
    };
  },
};
</script>

<style scoped>
.homescreen {
  flex: 1;
  display: flex;
  flex-direction: column;
  position: relative;
  padding: 20px;
}

.wallpaper {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  z-index: 0;
}

.app-grid {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-auto-rows: 100px;
  gap: 20px;
  padding: 20px 0;
  z-index: 1;
  align-content: start;
}

.app-icon {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  transition: transform 0.2s;
}

.app-icon:active {
  transform: scale(0.95);
}

.icon-container {
  width: 60px;
  height: 60px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  transition: box-shadow 0.2s;
}

.app-icon:hover .icon-container {
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.4);
}

.app-name {
  color: #fff;
  font-size: 12px;
  font-weight: 500;
  text-align: center;
  text-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
}

.dock {
  display: flex;
  justify-content: center;
  gap: 20px;
  padding: 16px;
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(20px);
  border-radius: 24px;
  z-index: 1;
  margin-bottom: 10px;
}

.dock-icon {
  cursor: pointer;
  transition: transform 0.2s;
}

.dock-icon:active {
  transform: scale(0.95);
}

.dock-icon .icon-container {
  width: 64px;
  height: 64px;
  border-radius: 16px;
}

/* Responsive adjustments */
@media (max-width: 1600px) and (max-height: 900px) {
  .app-grid {
    grid-auto-rows: 90px;
    gap: 16px;
  }

  .icon-container {
    width: 54px;
    height: 54px;
  }

  .app-name {
    font-size: 11px;
  }

  .dock-icon .icon-container {
    width: 58px;
    height: 58px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .homescreen {
    padding: 16px;
  }

  .app-grid {
    grid-auto-rows: 80px;
    gap: 12px;
    padding: 16px 0;
  }

  .icon-container {
    width: 48px;
    height: 48px;
    border-radius: 12px;
  }

  .app-name {
    font-size: 10px;
  }

  .dock {
    padding: 12px;
    border-radius: 20px;
  }

  .dock-icon .icon-container {
    width: 52px;
    height: 52px;
    border-radius: 14px;
  }
}
</style>
