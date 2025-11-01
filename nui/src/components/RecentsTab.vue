<template>
  <div class="recents-tab">
    <!-- Search Bar -->
    <div class="search-container">
      <div class="search-bar">
        <SearchIcon class="search-icon" />
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search recents..."
          class="search-input"
        />
        <button v-if="searchQuery" @click="clearSearch" class="clear-btn">
          <CloseIcon />
        </button>
      </div>
    </div>

    <!-- Filter Tabs -->
    <div class="filter-tabs">
      <button
        v-for="filter in filters"
        :key="filter.id"
        class="filter-tab"
        :class="{ active: activeFilter === filter.id }"
        @click="setActiveFilter(filter.id)"
      >
        {{ filter.label }}
        <span v-if="filter.count > 0" class="filter-count">{{ filter.count }}</span>
      </button>
    </div>

    <!-- Recent Items List -->
    <div class="recents-list">
      <div v-if="filteredItems.length === 0" class="empty-state">
        <div class="empty-icon">
          <ClockIcon />
        </div>
        <h3>No Recent Activity</h3>
        <p>Your recent apps, calls, and messages will appear here</p>
      </div>

      <div
        v-for="item in filteredItems"
        :key="item.id"
        class="recent-item"
        @click="openItem(item)"
      >
        <div class="item-icon" :style="{ background: item.color }">
          <component :is="item.icon" />
        </div>
        <div class="item-content">
          <div class="item-title">{{ item.title }}</div>
          <div class="item-subtitle">{{ item.subtitle }}</div>
          <div class="item-time">{{ formatTime(item.timestamp) }}</div>
        </div>
        <div class="item-action">
          <ChevronRightIcon />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from "vue";
import { h } from "vue";

// Icons
const SearchIcon = () =>
  h(
    "svg",
    {
      width: "20",
      height: "20",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z",
      }),
    ]
  );

const CloseIcon = () =>
  h(
    "svg",
    {
      width: "18",
      height: "18",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z",
      }),
    ]
  );

const ClockIcon = () =>
  h(
    "svg",
    {
      width: "48",
      height: "48",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z",
      }),
      h("path", { d: "M12.5 7H11v6l5.25 3.15.75-1.23-4.5-2.67z" }),
    ]
  );

const ChevronRightIcon = () =>
  h(
    "svg",
    {
      width: "20",
      height: "20",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z",
      }),
    ]
  );

// Sample app icons
const PhoneIcon = () =>
  h(
    "svg",
    {
      width: "24",
      height: "24",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z",
      }),
    ]
  );

const MessagesIcon = () =>
  h(
    "svg",
    {
      width: "24",
      height: "24",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z",
      }),
    ]
  );

const CameraIcon = () =>
  h(
    "svg",
    {
      width: "24",
      height: "24",
      viewBox: "0 0 24 24",
      fill: "white",
    },
    [
      h("path", {
        d: "M9 2L7.17 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2h-3.17L15 2H9zm3 15c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5z",
      }),
    ]
  );

export default {
  name: "RecentsTab",
  emits: ["open-app"],
  setup(props, { emit }) {
    const searchQuery = ref("");
    const activeFilter = ref("all");

    // Sample recent items data
    const recentItems = ref([
      {
        id: "1",
        type: "app",
        title: "Messages",
        subtitle: "Last opened",
        timestamp: Date.now() - 300000, // 5 minutes ago
        icon: MessagesIcon,
        color: "#34c759",
        appId: "messages",
      },
      {
        id: "2",
        type: "call",
        title: "John Doe",
        subtitle: "Outgoing call • 2m 15s",
        timestamp: Date.now() - 900000, // 15 minutes ago
        icon: PhoneIcon,
        color: "#007aff",
        appId: "dialer",
      },
      {
        id: "3",
        type: "app",
        title: "Camera",
        subtitle: "Last opened",
        timestamp: Date.now() - 1800000, // 30 minutes ago
        icon: CameraIcon,
        color: "#8e8e93",
        appId: "photos",
      },
      {
        id: "4",
        type: "message",
        title: "Jane Smith",
        subtitle: "Hey, are you free tonight?",
        timestamp: Date.now() - 3600000, // 1 hour ago
        icon: MessagesIcon,
        color: "#34c759",
        appId: "messages",
      },
      {
        id: "5",
        type: "call",
        title: "Mom",
        subtitle: "Incoming call • 5m 32s",
        timestamp: Date.now() - 7200000, // 2 hours ago
        icon: PhoneIcon,
        color: "#007aff",
        appId: "dialer",
      },
    ]);

    const filters = computed(() => [
      {
        id: "all",
        label: "All",
        count: recentItems.value.length,
      },
      {
        id: "app",
        label: "Apps",
        count: recentItems.value.filter((item) => item.type === "app").length,
      },
      {
        id: "call",
        label: "Calls",
        count: recentItems.value.filter((item) => item.type === "call").length,
      },
      {
        id: "message",
        label: "Messages",
        count: recentItems.value.filter((item) => item.type === "message").length,
      },
    ]);

    const filteredItems = computed(() => {
      let items = recentItems.value;

      // Filter by type
      if (activeFilter.value !== "all") {
        items = items.filter((item) => item.type === activeFilter.value);
      }

      // Filter by search query
      if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase();
        items = items.filter(
          (item) =>
            item.title.toLowerCase().includes(query) ||
            item.subtitle.toLowerCase().includes(query)
        );
      }

      // Sort by timestamp (most recent first)
      return items.sort((a, b) => b.timestamp - a.timestamp);
    });

    const setActiveFilter = (filterId) => {
      activeFilter.value = filterId;
    };

    const clearSearch = () => {
      searchQuery.value = "";
    };

    const openItem = (item) => {
      emit("open-app", item.appId);
    };

    const formatTime = (timestamp) => {
      const now = Date.now();
      const diff = now - timestamp;
      const minutes = Math.floor(diff / 60000);
      const hours = Math.floor(diff / 3600000);
      const days = Math.floor(diff / 86400000);

      if (minutes < 1) return "Just now";
      if (minutes < 60) return `${minutes}m ago`;
      if (hours < 24) return `${hours}h ago`;
      if (days < 7) return `${days}d ago`;
      return new Date(timestamp).toLocaleDateString();
    };

    return {
      searchQuery,
      activeFilter,
      filters,
      filteredItems,
      setActiveFilter,
      clearSearch,
      openItem,
      formatTime,
    };
  },
};
</script>

<style scoped>
.recents-tab {
  flex: 1;
  display: flex;
  flex-direction: column;
  background: #000;
  overflow: hidden;
}

.search-container {
  padding: 16px;
  background: rgba(28, 28, 30, 0.95);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.search-bar {
  position: relative;
  display: flex;
  align-items: center;
  background: rgba(118, 118, 128, 0.12);
  border-radius: 10px;
  padding: 8px 12px;
}

.search-icon {
  color: rgba(255, 255, 255, 0.6);
  margin-right: 8px;
}

.search-input {
  flex: 1;
  background: none;
  border: none;
  color: #fff;
  font-size: 16px;
  outline: none;
}

.search-input::placeholder {
  color: rgba(255, 255, 255, 0.6);
}

.clear-btn {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.6);
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: background 0.2s;
}

.clear-btn:hover {
  background: rgba(255, 255, 255, 0.1);
}

.filter-tabs {
  display: flex;
  padding: 12px 16px;
  gap: 8px;
  background: rgba(28, 28, 30, 0.95);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  overflow-x: auto;
}

.filter-tab {
  background: rgba(118, 118, 128, 0.12);
  border: none;
  color: rgba(255, 255, 255, 0.8);
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
  display: flex;
  align-items: center;
  gap: 6px;
}

.filter-tab:hover {
  background: rgba(118, 118, 128, 0.2);
}

.filter-tab.active {
  background: #007aff;
  color: #fff;
}

.filter-count {
  background: rgba(255, 255, 255, 0.2);
  color: inherit;
  font-size: 12px;
  font-weight: 600;
  min-width: 18px;
  height: 18px;
  border-radius: 9px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 6px;
}

.filter-tab.active .filter-count {
  background: rgba(255, 255, 255, 0.3);
}

.recents-list {
  flex: 1;
  overflow-y: auto;
  padding: 8px 0;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
}

.empty-icon {
  color: rgba(255, 255, 255, 0.3);
  margin-bottom: 16px;
}

.empty-state h3 {
  color: #fff;
  font-size: 20px;
  font-weight: 600;
  margin: 0 0 8px 0;
}

.empty-state p {
  color: rgba(255, 255, 255, 0.6);
  font-size: 16px;
  margin: 0;
  line-height: 1.4;
}

.recent-item {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  cursor: pointer;
  transition: background 0.2s;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.recent-item:hover {
  background: rgba(255, 255, 255, 0.05);
}

.recent-item:active {
  background: rgba(255, 255, 255, 0.1);
}

.item-icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.item-content {
  flex: 1;
  min-width: 0;
}

.item-title {
  color: #fff;
  font-size: 16px;
  font-weight: 500;
  margin-bottom: 2px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.item-subtitle {
  color: rgba(255, 255, 255, 0.6);
  font-size: 14px;
  margin-bottom: 2px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.item-time {
  color: rgba(255, 255, 255, 0.4);
  font-size: 12px;
}

.item-action {
  color: rgba(255, 255, 255, 0.3);
  margin-left: 8px;
}

/* Responsive design */
@media (max-width: 1600px) and (max-height: 900px) {
  .search-container {
    padding: 14px;
  }

  .filter-tabs {
    padding: 10px 14px;
  }

  .recent-item {
    padding: 10px 14px;
  }

  .item-icon {
    width: 40px;
    height: 40px;
  }

  .item-title {
    font-size: 15px;
  }

  .item-subtitle {
    font-size: 13px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .search-container {
    padding: 12px;
  }

  .search-bar {
    padding: 6px 10px;
  }

  .search-input {
    font-size: 14px;
  }

  .filter-tabs {
    padding: 8px 12px;
  }

  .filter-tab {
    padding: 6px 12px;
    font-size: 13px;
  }

  .recent-item {
    padding: 8px 12px;
  }

  .item-icon {
    width: 36px;
    height: 36px;
    border-radius: 10px;
  }

  .item-title {
    font-size: 14px;
  }

  .item-subtitle {
    font-size: 12px;
  }

  .item-time {
    font-size: 11px;
  }
}
</style>