# Custom App Development Guide

This guide will walk you through creating a custom app for the FiveM Smartphone NUI resource. We'll build a complete example app called "Notes" that allows players to create and manage personal notes.

## Overview

The phone system uses a modular architecture where each app consists of:
1. **Vue.js Component** (NUI) - The user interface
2. **Vuex Store Module** (NUI) - State management
3. **Server-side Handler** (Lua) - Business logic and database operations
4. **Client-side Handler** (Lua) - NUI callbacks and client events

## Example App: Notes

We'll create a notes app with the following features:
- Create new notes with title and content
- View list of all notes
- Edit existing notes
- Delete notes
- Persist notes in database

## Step 1: Database Schema

First, create the database table for storing notes.

### Create Migration

Add to `server/database.lua`:

```lua
-- Add this function to create the notes table
local function CreateNotesTable()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS phone_notes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_number VARCHAR(20) NOT NULL,
            title VARCHAR(100) NOT NULL,
            content TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_owner (owner_number),
            FOREIGN KEY (owner_number) REFERENCES phone_players(phone_number) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])
end

-- Add to the InitializeDatabase function
function InitializeDatabase()
    -- ... existing table creation ...
    CreateNotesTable()
    print('[Phone] Notes table initialized')
end
```

## Step 2: Server-side Handler

Create `server/apps/notes.lua`:

```lua
-- server/apps/notes.lua

local function GetPlayerPhoneNumber(source)
    local identifier = Framework:GetIdentifier(source)
    if not identifier then return nil end
    
    local result = MySQL.query.await('SELECT phone_number FROM phone_players WHERE identifier = ?', {
        identifier
    })
    
    return result[1] and result[1].phone_number or nil
end

-- Get all notes for a player
RegisterNetEvent('phone:server:getNotes', function()
    local source = source
    local phoneNumber = GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:notesError', source, 'Player not found')
        return
    end
    
    local notes = MySQL.query.await('SELECT * FROM phone_notes WHERE owner_number = ? ORDER BY updated_at DESC', {
        phoneNumber
    })
    
    TriggerClientEvent('phone:client:receiveNotes', source, notes or {})
end)

-- Create a new note
RegisterNetEvent('phone:server:createNote', function(title, content)
    local source = source
    local phoneNumber = GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:notesError', source, 'Player not found')
        return
    end
    
    -- Validate input
    if not title or title == '' then
        TriggerClientEvent('phone:client:notesError', source, 'Title is required')
        return
    end
    
    if not content or content == '' then
        TriggerClientEvent('phone:client:notesError', source, 'Content is required')
        return
    end
    
    -- Limit lengths
    title = string.sub(title, 1, 100)
    content = string.sub(content, 1, 5000)
    
    local result = MySQL.insert.await('INSERT INTO phone_notes (owner_number, title, content) VALUES (?, ?, ?)', {
        phoneNumber,
        title,
        content
    })
    
    if result then
        -- Return the new note
        local note = MySQL.query.await('SELECT * FROM phone_notes WHERE id = ?', { result })
        TriggerClientEvent('phone:client:noteCreated', source, note[1])
    else
        TriggerClientEvent('phone:client:notesError', source, 'Failed to create note')
    end
end)

-- Update an existing note
RegisterNetEvent('phone:server:updateNote', function(noteId, title, content)
    local source = source
    local phoneNumber = GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:notesError', source, 'Player not found')
        return
    end
    
    -- Validate input
    if not title or title == '' then
        TriggerClientEvent('phone:client:notesError', source, 'Title is required')
        return
    end
    
    if not content or content == '' then
        TriggerClientEvent('phone:client:notesError', source, 'Content is required')
        return
    end
    
    -- Limit lengths
    title = string.sub(title, 1, 100)
    content = string.sub(content, 1, 5000)
    
    -- Verify ownership
    local note = MySQL.query.await('SELECT * FROM phone_notes WHERE id = ? AND owner_number = ?', {
        noteId,
        phoneNumber
    })
    
    if not note or #note == 0 then
        TriggerClientEvent('phone:client:notesError', source, 'Note not found or access denied')
        return
    end
    
    local success = MySQL.update.await('UPDATE phone_notes SET title = ?, content = ? WHERE id = ?', {
        title,
        content,
        noteId
    })
    
    if success then
        -- Return updated note
        local updatedNote = MySQL.query.await('SELECT * FROM phone_notes WHERE id = ?', { noteId })
        TriggerClientEvent('phone:client:noteUpdated', source, updatedNote[1])
    else
        TriggerClientEvent('phone:client:notesError', source, 'Failed to update note')
    end
end)

-- Delete a note
RegisterNetEvent('phone:server:deleteNote', function(noteId)
    local source = source
    local phoneNumber = GetPlayerPhoneNumber(source)
    
    if not phoneNumber then
        TriggerClientEvent('phone:client:notesError', source, 'Player not found')
        return
    end
    
    -- Verify ownership
    local note = MySQL.query.await('SELECT * FROM phone_notes WHERE id = ? AND owner_number = ?', {
        noteId,
        phoneNumber
    })
    
    if not note or #note == 0 then
        TriggerClientEvent('phone:client:notesError', source, 'Note not found or access denied')
        return
    end
    
    local success = MySQL.execute.await('DELETE FROM phone_notes WHERE id = ?', { noteId })
    
    if success then
        TriggerClientEvent('phone:client:noteDeleted', source, noteId)
    else
        TriggerClientEvent('phone:client:notesError', source, 'Failed to delete note')
    end
end)
```

### Register Server File

Add to `fxmanifest.lua`:

```lua
server_scripts {
    -- ... existing files ...
    'server/apps/notes.lua',
}
```

## Step 3: Client-side Handler

Create `client/apps/notes.lua`:

```lua
-- client/apps/notes.lua

-- Request notes from server
RegisterNUICallback('getNotes', function(data, cb)
    TriggerServerEvent('phone:server:getNotes')
    cb({ success = true })
end)

-- Create new note
RegisterNUICallback('createNote', function(data, cb)
    if not data.title or not data.content then
        cb({ success = false, error = 'Missing required fields' })
        return
    end
    
    TriggerServerEvent('phone:server:createNote', data.title, data.content)
    cb({ success = true })
end)

-- Update note
RegisterNUICallback('updateNote', function(data, cb)
    if not data.id or not data.title or not data.content then
        cb({ success = false, error = 'Missing required fields' })
        return
    end
    
    TriggerServerEvent('phone:server:updateNote', data.id, data.title, data.content)
    cb({ success = true })
end)

-- Delete note
RegisterNUICallback('deleteNote', function(data, cb)
    if not data.id then
        cb({ success = false, error = 'Missing note ID' })
        return
    end
    
    TriggerServerEvent('phone:server:deleteNote', data.id)
    cb({ success = true })
end)

-- Receive notes from server
RegisterNetEvent('phone:client:receiveNotes', function(notes)
    SendNUIMessage({
        action = 'receiveNotes',
        notes = notes
    })
end)

-- Note created
RegisterNetEvent('phone:client:noteCreated', function(note)
    SendNUIMessage({
        action = 'noteCreated',
        note = note
    })
end)

-- Note updated
RegisterNetEvent('phone:client:noteUpdated', function(note)
    SendNUIMessage({
        action = 'noteUpdated',
        note = note
    })
end)

-- Note deleted
RegisterNetEvent('phone:client:noteDeleted', function(noteId)
    SendNUIMessage({
        action = 'noteDeleted',
        noteId = noteId
    })
end)

-- Error handling
RegisterNetEvent('phone:client:notesError', function(error)
    SendNUIMessage({
        action = 'notesError',
        error = error
    })
end)
```

### Register Client File

Add to `fxmanifest.lua`:

```lua
client_scripts {
    -- ... existing files ...
    'client/apps/notes.lua',
}
```

## Step 4: Vuex Store Module

Create `nui/src/store/modules/notes.js`:

```javascript
// nui/src/store/modules/notes.js

export default {
    namespaced: true,
    
    state: {
        notes: [],
        currentNote: null,
        loading: false,
        error: null
    },
    
    mutations: {
        SET_NOTES(state, notes) {
            state.notes = notes;
        },
        
        SET_CURRENT_NOTE(state, note) {
            state.currentNote = note;
        },
        
        ADD_NOTE(state, note) {
            state.notes.unshift(note);
        },
        
        UPDATE_NOTE(state, updatedNote) {
            const index = state.notes.findIndex(n => n.id === updatedNote.id);
            if (index !== -1) {
                state.notes.splice(index, 1, updatedNote);
            }
        },
        
        DELETE_NOTE(state, noteId) {
            state.notes = state.notes.filter(n => n.id !== noteId);
            if (state.currentNote && state.currentNote.id === noteId) {
                state.currentNote = null;
            }
        },
        
        SET_LOADING(state, loading) {
            state.loading = loading;
        },
        
        SET_ERROR(state, error) {
            state.error = error;
        }
    },
    
    actions: {
        async fetchNotes({ commit }) {
            commit('SET_LOADING', true);
            commit('SET_ERROR', null);
            
            try {
                await fetch(`https://${GetParentResourceName()}/getNotes`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({})
                });
            } catch (error) {
                commit('SET_ERROR', 'Failed to fetch notes');
            } finally {
                commit('SET_LOADING', false);
            }
        },
        
        async createNote({ commit }, { title, content }) {
            commit('SET_LOADING', true);
            commit('SET_ERROR', null);
            
            try {
                const response = await fetch(`https://${GetParentResourceName()}/createNote`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ title, content })
                });
                
                const data = await response.json();
                if (!data.success) {
                    commit('SET_ERROR', data.error || 'Failed to create note');
                }
            } catch (error) {
                commit('SET_ERROR', 'Failed to create note');
            } finally {
                commit('SET_LOADING', false);
            }
        },
        
        async updateNote({ commit }, { id, title, content }) {
            commit('SET_LOADING', true);
            commit('SET_ERROR', null);
            
            try {
                const response = await fetch(`https://${GetParentResourceName()}/updateNote`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ id, title, content })
                });
                
                const data = await response.json();
                if (!data.success) {
                    commit('SET_ERROR', data.error || 'Failed to update note');
                }
            } catch (error) {
                commit('SET_ERROR', 'Failed to update note');
            } finally {
                commit('SET_LOADING', false);
            }
        },
        
        async deleteNote({ commit }, noteId) {
            commit('SET_LOADING', true);
            commit('SET_ERROR', null);
            
            try {
                const response = await fetch(`https://${GetParentResourceName()}/deleteNote`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ id: noteId })
                });
                
                const data = await response.json();
                if (!data.success) {
                    commit('SET_ERROR', data.error || 'Failed to delete note');
                }
            } catch (error) {
                commit('SET_ERROR', 'Failed to delete note');
            } finally {
                commit('SET_LOADING', false);
            }
        },
        
        receiveNotes({ commit }, notes) {
            commit('SET_NOTES', notes);
        },
        
        noteCreated({ commit }, note) {
            commit('ADD_NOTE', note);
        },
        
        noteUpdated({ commit }, note) {
            commit('UPDATE_NOTE', note);
        },
        
        noteDeleted({ commit }, noteId) {
            commit('DELETE_NOTE', noteId);
        },
        
        setError({ commit }, error) {
            commit('SET_ERROR', error);
        }
    },
    
    getters: {
        allNotes: state => state.notes,
        currentNote: state => state.currentNote,
        isLoading: state => state.loading,
        error: state => state.error,
        noteCount: state => state.notes.length
    }
};
```

### Register Store Module

Add to `nui/src/store/index.js`:

```javascript
import notes from './modules/notes';

export default new Vuex.Store({
    modules: {
        // ... existing modules ...
        notes
    }
});
```

## Step 5: Vue Component

Create `nui/src/apps/Notes.vue`:

```vue
<template>
    <div class="notes-app">
        <div class="notes-header">
            <h2>Notes</h2>
            <button @click="showNewNoteForm" class="btn-new">
                <i class="icon-plus"></i> New Note
            </button>
        </div>
        
        <div v-if="error" class="error-message">
            {{ error }}
        </div>
        
        <div v-if="loading" class="loading">
            Loading...
        </div>
        
        <!-- Note List -->
        <div v-else-if="!currentNote && !showForm" class="notes-list">
            <div 
                v-for="note in allNotes" 
                :key="note.id"
                class="note-item"
                @click="selectNote(note)"
            >
                <h3>{{ note.title }}</h3>
                <p class="note-preview">{{ truncate(note.content, 100) }}</p>
                <span class="note-date">{{ formatDate(note.updated_at) }}</span>
            </div>
            
            <div v-if="noteCount === 0" class="empty-state">
                <p>No notes yet. Create your first note!</p>
            </div>
        </div>
        
        <!-- Note Form (Create/Edit) -->
        <div v-else-if="showForm" class="note-form">
            <input 
                v-model="formData.title" 
                type="text" 
                placeholder="Note Title"
                class="input-title"
                maxlength="100"
            />
            <textarea 
                v-model="formData.content" 
                placeholder="Note content..."
                class="input-content"
                maxlength="5000"
            ></textarea>
            
            <div class="form-actions">
                <button @click="saveNote" class="btn-save">Save</button>
                <button @click="cancelForm" class="btn-cancel">Cancel</button>
            </div>
        </div>
        
        <!-- Note View -->
        <div v-else-if="currentNote" class="note-view">
            <div class="note-view-header">
                <button @click="backToList" class="btn-back">
                    <i class="icon-back"></i>
                </button>
                <div class="note-actions">
                    <button @click="editNote" class="btn-edit">Edit</button>
                    <button @click="deleteNote" class="btn-delete">Delete</button>
                </div>
            </div>
            
            <h2>{{ currentNote.title }}</h2>
            <p class="note-date">{{ formatDate(currentNote.updated_at) }}</p>
            <div class="note-content">
                {{ currentNote.content }}
            </div>
        </div>
    </div>
</template>

<script>
import { mapGetters, mapActions, mapMutations } from 'vuex';

export default {
    name: 'Notes',
    
    data() {
        return {
            showForm: false,
            formData: {
                id: null,
                title: '',
                content: ''
            }
        };
    },
    
    computed: {
        ...mapGetters('notes', ['allNotes', 'currentNote', 'isLoading', 'error', 'noteCount']),
        loading() {
            return this.isLoading;
        }
    },
    
    mounted() {
        this.fetchNotes();
        
        // Listen for NUI messages
        window.addEventListener('message', this.handleNUIMessage);
    },
    
    beforeUnmount() {
        window.removeEventListener('message', this.handleNUIMessage);
    },
    
    methods: {
        ...mapActions('notes', [
            'fetchNotes',
            'createNote',
            'updateNote',
            'deleteNote',
            'receiveNotes',
            'noteCreated',
            'noteUpdated',
            'noteDeleted',
            'setError'
        ]),
        
        ...mapMutations('notes', ['SET_CURRENT_NOTE']),
        
        handleNUIMessage(event) {
            const { action, notes, note, noteId, error } = event.data;
            
            switch (action) {
                case 'receiveNotes':
                    this.receiveNotes(notes);
                    break;
                case 'noteCreated':
                    this.noteCreated(note);
                    this.showForm = false;
                    this.resetForm();
                    break;
                case 'noteUpdated':
                    this.noteUpdated(note);
                    this.showForm = false;
                    this.SET_CURRENT_NOTE(note);
                    break;
                case 'noteDeleted':
                    this.noteDeleted(noteId);
                    this.backToList();
                    break;
                case 'notesError':
                    this.setError(error);
                    break;
            }
        },
        
        showNewNoteForm() {
            this.resetForm();
            this.showForm = true;
            this.SET_CURRENT_NOTE(null);
        },
        
        selectNote(note) {
            this.SET_CURRENT_NOTE(note);
        },
        
        editNote() {
            if (!this.currentNote) return;
            
            this.formData = {
                id: this.currentNote.id,
                title: this.currentNote.title,
                content: this.currentNote.content
            };
            this.showForm = true;
        },
        
        async saveNote() {
            if (!this.formData.title || !this.formData.content) {
                this.setError('Title and content are required');
                return;
            }
            
            if (this.formData.id) {
                // Update existing note
                await this.updateNote({
                    id: this.formData.id,
                    title: this.formData.title,
                    content: this.formData.content
                });
            } else {
                // Create new note
                await this.createNote({
                    title: this.formData.title,
                    content: this.formData.content
                });
            }
        },
        
        async deleteNote() {
            if (!this.currentNote) return;
            
            if (confirm('Are you sure you want to delete this note?')) {
                await this.deleteNote(this.currentNote.id);
            }
        },
        
        cancelForm() {
            this.showForm = false;
            this.resetForm();
        },
        
        backToList() {
            this.SET_CURRENT_NOTE(null);
        },
        
        resetForm() {
            this.formData = {
                id: null,
                title: '',
                content: ''
            };
        },
        
        truncate(text, length) {
            if (text.length <= length) return text;
            return text.substring(0, length) + '...';
        },
        
        formatDate(dateString) {
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
        }
    }
};
</script>

<style scoped>
.notes-app {
    padding: 20px;
    height: 100%;
    overflow-y: auto;
}

.notes-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}

.notes-header h2 {
    margin: 0;
}

.btn-new {
    background: #4CAF50;
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 5px;
    cursor: pointer;
}

.error-message {
    background: #f44336;
    color: white;
    padding: 10px;
    border-radius: 5px;
    margin-bottom: 10px;
}

.loading {
    text-align: center;
    padding: 40px;
}

.notes-list {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.note-item {
    background: #f5f5f5;
    padding: 15px;
    border-radius: 8px;
    cursor: pointer;
    transition: background 0.2s;
}

.note-item:hover {
    background: #e0e0e0;
}

.note-item h3 {
    margin: 0 0 10px 0;
}

.note-preview {
    color: #666;
    margin: 0 0 10px 0;
}

.note-date {
    font-size: 12px;
    color: #999;
}

.empty-state {
    text-align: center;
    padding: 40px;
    color: #999;
}

.note-form {
    display: flex;
    flex-direction: column;
    gap: 15px;
}

.input-title {
    padding: 12px;
    font-size: 18px;
    border: 1px solid #ddd;
    border-radius: 5px;
}

.input-content {
    padding: 12px;
    min-height: 300px;
    border: 1px solid #ddd;
    border-radius: 5px;
    resize: vertical;
    font-family: inherit;
}

.form-actions {
    display: flex;
    gap: 10px;
}

.btn-save {
    flex: 1;
    background: #4CAF50;
    color: white;
    border: none;
    padding: 12px;
    border-radius: 5px;
    cursor: pointer;
}

.btn-cancel {
    flex: 1;
    background: #999;
    color: white;
    border: none;
    padding: 12px;
    border-radius: 5px;
    cursor: pointer;
}

.note-view {
    display: flex;
    flex-direction: column;
}

.note-view-header {
    display: flex;
    justify-content: space-between;
    margin-bottom: 20px;
}

.note-actions {
    display: flex;
    gap: 10px;
}

.btn-back, .btn-edit, .btn-delete {
    padding: 8px 16px;
    border: none;
    border-radius: 5px;
    cursor: pointer;
}

.btn-back {
    background: #999;
    color: white;
}

.btn-edit {
    background: #2196F3;
    color: white;
}

.btn-delete {
    background: #f44336;
    color: white;
}

.note-content {
    white-space: pre-wrap;
    line-height: 1.6;
}
</style>
```

## Step 6: Register App in Phone

Add the Notes app to the homescreen. Edit `nui/src/components/Homescreen.vue`:

```vue
<template>
    <div class="homescreen">
        <!-- ... existing apps ... -->
        
        <div class="app-icon" @click="openApp('notes')">
            <i class="icon-notes"></i>
            <span>Notes</span>
        </div>
    </div>
</template>
```

Add route in `nui/src/router/index.js`:

```javascript
import Notes from '../apps/Notes.vue';

const routes = [
    // ... existing routes ...
    {
        path: '/notes',
        name: 'Notes',
        component: Notes
    }
];
```

## Step 7: Enable in Config

Add to `config.lua`:

```lua
Config.EnabledApps = {
    -- ... existing apps ...
    notes = true
}
```

## Step 8: Build and Test

```bash
cd nui
npm run build
```

Restart your server and test the Notes app!

## Best Practices

### Security

1. **Always validate input** on the server
2. **Verify ownership** before operations
3. **Use parameterized queries** to prevent SQL injection
4. **Limit data sizes** to prevent abuse

### Performance

1. **Index database columns** used in WHERE clauses
2. **Limit query results** with LIMIT clause
3. **Cache frequently accessed data** in Vuex store
4. **Debounce user input** for search/filter operations

### User Experience

1. **Show loading states** during async operations
2. **Display error messages** clearly
3. **Confirm destructive actions** (delete, etc.)
4. **Provide feedback** for successful operations

## Troubleshooting

### App not showing

- Check that app is enabled in config
- Verify component is registered in router
- Check console for Vue errors

### NUI callbacks not working

- Ensure resource name matches in fetch URLs
- Check that callbacks are registered in client script
- Verify fxmanifest includes client script

### Database errors

- Check that table was created successfully
- Verify foreign key constraints
- Check server console for SQL errors

### State not updating

- Ensure mutations are committed
- Check that actions are dispatched correctly
- Verify NUI message handlers are registered

## Next Steps

- Add search functionality
- Implement note categories/tags
- Add note sharing between players
- Implement rich text editing
- Add note attachments

## Resources

- [Vue.js Documentation](https://vuejs.org/)
- [Vuex Documentation](https://vuex.vuejs.org/)
- [FiveM NUI Documentation](https://docs.fivem.net/docs/scripting-reference/nui/)
- [oxmysql Documentation](https://overextended.dev/oxmysql)
