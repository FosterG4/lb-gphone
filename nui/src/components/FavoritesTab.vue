<template>
  <div class="favorites-tab">
    <!-- Header -->
    <div class="favorites-header">
      <h1>Favorites</h1>
      <button @click="toggleEditMode" class="edit-btn">
        {{ isEditMode ? "Done" : "Edit" }}
      </button>
    </div>

    <!-- Search Bar -->
    <div class="search-container">
      <div class="search-bar">
        <SearchIcon class="search-icon" />
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search favorites..."
          class="search-input"
        />
        <button v-if="searchQuery" @click="clearSearch" class="clear-btn">
          <CloseIcon />
        </button>
      </div>
    </div>

    <!-- Favorites Grid -->
    <div class="favorites-content">
      <div v-if="filteredFavorites.length === 0 && !searchQuery" class="empty-state">
        <div class="empty-icon">
          <HeartIcon />
        </div>
        <h3>No Favorites Yet</h3>
        <p>Add your most used apps to favorites for quick access</p>
        <button @click="showAllApps" class="add-favorites-btn">
          <PlusIcon />
          Add Favorites
        </button>
      </div>

      <div v-else-if="filteredFavorites.length === 0 && searchQuery" class="empty-state">
        <div class="empty-icon">
          <SearchIcon />
        </div>
        <h3>No Results</h3>
        <p>No favorites match "{{ searchQuery }}"</p>
      </div>

      <div v-else class="favorites-grid">
        <div
          v-for="app in filteredFavorites"
          :key="app.id"
          class="favorite-item"
          :class="{ 'edit-mode': isEditMode }"
          @click="!isEditMode && openApp(app.id)"
        >
          <div class="favorite-icon" :style="{ background: app.color }">
            <component :is="app.icon" />
            <button
              v-if="isEditMode"
              @click.stop="removeFavorite(app.id)"
              class="remove-btn"
            >
              <MinusIcon />
            </button>
          </div>
          <span class="favorite-name">{{ app.name }}</span>
        </div>

        <!-- Add New Favorite Button (in edit mode) -->
        <div v-if="isEditMode" class="favorite-item add-item" @click="showAllApps">
          <div class="favorite-icon add-icon">
            <PlusIcon />
          </div>
          <span class="favorite-name">Add App</span>
        </div>
      </div>
    </div>

    <!-- All Apps Modal -->
    <div v-if="showAppsModal" class="apps-modal" @click="hideAllApps">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h2>Add to Favorites</h2>
          <button @click="hideAllApps" class="close-modal-btn">
            <CloseIcon />
          </button>
        </div>
        <div class="modal-search">
          <div class="search-bar">
            <SearchIcon class="search-icon" />
            <input
              v-model="modalSearchQuery"
              type="text"
              placeholder="Search apps..."
              class="search-input"
            />
          </div>
        </div>
        <div class="apps-grid">
          <div
            v-for="app in availableApps"
            :key="app.id"
            class="app-item"
            @click="addToFavorites(app)"
          >
            <div class="app-icon" :style="{ background: app.color }">
              <component :is="app.icon" />
            </div>
            <span class="app-name">{{ app.name }}</span>
          </div>
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