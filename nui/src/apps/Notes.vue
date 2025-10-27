<template>
  <div class="notes-app">
    <div class="notes-header">
      <h1>Notes</h1>
      <button class="add-note-button" @click="createNewNote">
        <span class="icon">+</span>
      </button>
    </div>

    <div v-if="!selectedNote" class="notes-container">
      <!-- Search Bar -->
      <div class="search-bar">
        <input 
          type="text" 
          v-model="searchQuery"
          placeholder="Search notes..."
          class="search-input"
        />
      </div>

      <!-- Notes List -->
      <div class="notes-list">
        <div v-if="filteredNotes.length === 0" class="empty-state">
          <p v-if="searchQuery">No notes found</p>
          <p v-else>No notes yet. Create your first note!</p>
        </div>
        <div 
          v-for="note in filteredNotes" 
          :key="note.id"
          class="note-item"
          @click="selectNote(note)"
        >
          <div class="note-preview">
            <div class="note-title">{{ note.title || 'Untitled' }}</div>
            <div class="note-content-preview">{{ getPreview(note.content) }}</div>
            <div class="note-meta">
              <span class="note-date">{{ formatDate(note.updated_at || note.created_at) }}</span>
              <span class="note-length">{{ note.content.length }} / 5000</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Note Editor -->
    <div v-else class="note-editor">
      <div class="editor-header">
        <button class="back-button" @click="closeEditor">
          <span class="icon">←</span>
        </button>
        <button class="delete-button" @click="deleteCurrentNote">
          <span class="icon">🗑</span>
        </button>
      </div>

      <div class="editor-content">
        <input 
          type="text" 
          v-model="selectedNote.title"
          placeholder="Title"
          class="note-title-input"
          maxlength="200"
          @input="onNoteChange"
        />
        <textarea 
          v-model="selectedNote.content"
          placeholder="Start typing..."
          class="note-content-input"
          :maxlength="5000"
          @input="onNoteChange"
        ></textarea>
        <div class="character-count">
          {{ selectedNote.content.length }} / 5000 characters
        </div>
      </div>

      <div v-if="saveStatus" class="save-status">
        {{ saveStatus }}
      </div>
    </div>
  </div>
</template>

<script>
import { fetchNui } from '../utils/nui';

export default {
  name: 'Notes',
  data() {
    return {
      notes: [],
      selectedNote: null,
      searchQuery: '',
      saveStatus: '',
      saveTimeout: null,
      loading: false
    };
  },
  computed: {
    filteredNotes() {
      if (!this.searchQuery) {
        return this.notes;
      }
      
      const query = this.searchQuery.toLowerCase();
      return this.notes.filter(note => {
        const title = (note.title || '').toLowerCase();
        const content = (note.content || '').toLowerCase();
        return title.includes(query) || content.includes(query);
      });
    }
  },
  mounted() {
    this.loadNotes();
  },
  beforeUnmount() {
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout);
      if (this.selectedNote && this.selectedNote.id) {
        this.saveNote(this.selectedNote, false);
      }
    }
  },
  methods: {
    async loadNotes() {
      this.loading = true;
      try {
        const response = await fetchNui('getNotes');
        if (response.success) {
          this.notes = response.notes || [];
          // Sort by updated_at descending
          this.notes.sort((a, b) => {
            const dateA = new Date(a.updated_at || a.created_at);
            const dateB = new Date(b.updated_at || b.created_at);
            return dateB - dateA;
          });
        }
      } catch (error) {
        console.error('Failed to load notes:', error);
      } finally {
        this.loading = false;
      }
    },
    
    createNewNote() {
      this.selectedNote = {
        id: null,
        title: '',
        content: '',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
    },
    
    selectNote(note) {
      // Create a copy to avoid direct mutation
      this.selectedNote = { ...note };
    },
    
    closeEditor() {
      if (this.selectedNote) {
        // Save before closing if there's content
        if (this.selectedNote.content.trim() || this.selectedNote.title.trim()) {
          this.saveNote(this.selectedNote, false);
        }
      }
      this.selectedNote = null;
      this.saveStatus = '';
      if (this.saveTimeout) {
        clearTimeout(this.saveTimeout);
      }
    },
    
    onNoteChange() {
      // Clear existing timeout
      if (this.saveTimeout) {
        clearTimeout(this.saveTimeout);
      }
      
      // Set new timeout for auto-save (2 seconds after last change)
      this.saveTimeout = setTimeout(() => {
        this.saveNote(this.selectedNote, true);
      }, 2000);
      
      this.saveStatus = 'Typing...';
    },
    
    async saveNote(note, showStatus = true) {
      // Don't save empty notes
      if (!note.content.trim() && !note.title.trim()) {
        return;
      }
      
      if (showStatus) {
        this.saveStatus = 'Saving...';
      }
      
      try {
        const response = await fetchNui('saveNote', {
          noteId: note.id,
          title: note.title,
          content: note.content
        });
        
        if (response.success) {
          if (showStatus) {
            this.saveStatus = 'Saved';
            setTimeout(() => {
              this.saveStatus = '';
            }, 2000);
          }
          
          // Update note with server data
          const savedNote = response.note;
          
          if (!note.id) {
            // New note - add to list
            this.notes.unshift(savedNote);
            if (this.selectedNote) {
              this.selectedNote.id = savedNote.id;
            }
          } else {
            // Update existing note in list
            const index = this.notes.findIndex(n => n.id === savedNote.id);
            if (index !== -1) {
              this.notes[index] = savedNote;
            }
          }
          
          // Re-sort notes
          this.notes.sort((a, b) => {
            const dateA = new Date(a.updated_at || a.created_at);
            const dateB = new Date(b.updated_at || b.created_at);
            return dateB - dateA;
          });
        } else {
          if (showStatus) {
            this.saveStatus = 'Failed to save';
            setTimeout(() => {
              this.saveStatus = '';
            }, 3000);
          }
        }
      } catch (error) {
        console.error('Failed to save note:', error);
        if (showStatus) {
          this.saveStatus = 'Error saving';
          setTimeout(() => {
            this.saveStatus = '';
          }, 3000);
        }
      }
    },
    
    async deleteCurrentNote() {
      if (!this.selectedNote) return;
      
      if (!confirm('Are you sure you want to delete this note?')) {
        return;
      }
      
      // If it's a new note that hasn't been saved, just close
      if (!this.selectedNote.id) {
        this.closeEditor();
        return;
      }
      
      try {
        const response = await fetchNui('deleteNote', {
          noteId: this.selectedNote.id
        });
        
        if (response.success) {
          // Remove from list
          this.notes = this.notes.filter(n => n.id !== this.selectedNote.id);
          this.selectedNote = null;
          this.saveStatus = '';
        } else {
          alert('Failed to delete note');
        }
      } catch (error) {
        console.error('Failed to delete note:', error);
        alert('Error deleting note');
      }
    },
    
    getPreview(content) {
      if (!content) return 'No content';
      const preview = content.substring(0, 100);
      return preview.length < content.length ? preview + '...' : preview;
    },
    
    formatDate(dateString) {
      if (!dateString) return '';
      
      const date = new Date(dateString);
      const now = new Date();
      const diffMs = now - date;
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMs / 3600000);
      const diffDays = Math.floor(diffMs / 86400000);
      
      if (diffMins < 1) return 'Just now';
      if (diffMins < 60) return `${diffMins}m ago`;
      if (diffHours < 24) return `${diffHours}h ago`;
      if (diffDays < 7) return `${diffDays}d ago`;
      
      return date.toLocaleDateString('en-US', { 
        month: 'short', 
        day: 'numeric',
        year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined
      });
    }
  }
};
</script>

<style scoped>
.notes-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--background-color);
  color: var(--text-color);
}

.notes-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid var(--border-color);
}

.notes-header h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.add-note-button {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--primary-color);
  color: white;
  border: none;
  font-size: 24px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.2s;
}

.add-note-button:hover {
  transform: scale(1.1);
}

.add-note-button .icon {
  line-height: 1;
}

.notes-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.search-bar {
  padding: 15px 20px;
  border-bottom: 1px solid var(--border-color);
}

.search-input {
  width: 100%;
  padding: 12px 15px;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  color: var(--text-color);
  font-size: 14px;
}

.search-input:focus {
  outline: none;
  border-color: var(--primary-color);
}

.notes-list {
  flex: 1;
  overflow-y: auto;
  padding: 10px;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: var(--text-color);
  opacity: 0.5;
  font-size: 16px;
}

.note-item {
  background: var(--card-background);
  border-radius: 8px;
  padding: 15px;
  margin-bottom: 10px;
  cursor: pointer;
  transition: all 0.2s;
  border: 1px solid transparent;
}

.note-item:hover {
  border-color: var(--primary-color);
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

.note-preview {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.note-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-color);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.note-content-preview {
  font-size: 14px;
  color: var(--text-color);
  opacity: 0.7;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  line-height: 1.4;
}

.note-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: var(--text-color);
  opacity: 0.5;
}

/* Note Editor */
.note-editor {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.editor-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  border-bottom: 1px solid var(--border-color);
}

.back-button,
.delete-button {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  color: var(--text-color);
  font-size: 20px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.back-button:hover {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.delete-button:hover {
  background: var(--accent-color);
  color: white;
  border-color: var(--accent-color);
}

.editor-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 20px;
  overflow-y: auto;
}

.note-title-input {
  width: 100%;
  padding: 15px 0;
  background: transparent;
  border: none;
  border-bottom: 1px solid var(--border-color);
  color: var(--text-color);
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 20px;
}

.note-title-input:focus {
  outline: none;
  border-bottom-color: var(--primary-color);
}

.note-title-input::placeholder {
  color: var(--text-color);
  opacity: 0.3;
}

.note-content-input {
  flex: 1;
  width: 100%;
  padding: 0;
  background: transparent;
  border: none;
  color: var(--text-color);
  font-size: 16px;
  line-height: 1.6;
  resize: none;
  font-family: inherit;
}

.note-content-input:focus {
  outline: none;
}

.note-content-input::placeholder {
  color: var(--text-color);
  opacity: 0.3;
}

.character-count {
  text-align: right;
  font-size: 12px;
  color: var(--text-color);
  opacity: 0.5;
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid var(--border-color);
}

.save-status {
  padding: 10px 20px;
  text-align: center;
  font-size: 12px;
  color: var(--text-color);
  opacity: 0.7;
  background: var(--card-background);
  border-top: 1px solid var(--border-color);
}

/* Scrollbar styling */
.notes-list::-webkit-scrollbar,
.editor-content::-webkit-scrollbar {
  width: 6px;
}

.notes-list::-webkit-scrollbar-track,
.editor-content::-webkit-scrollbar-track {
  background: transparent;
}

.notes-list::-webkit-scrollbar-thumb,
.editor-content::-webkit-scrollbar-thumb {
  background: var(--border-color);
  border-radius: 3px;
}

.notes-list::-webkit-scrollbar-thumb:hover,
.editor-content::-webkit-scrollbar-thumb:hover {
  background: var(--primary-color);
}
</style>
