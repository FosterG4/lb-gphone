<template>
  <div class="contacts-view">
    <div class="contacts-header">
      <h2>Contacts</h2>
      <button class="add-btn" @click="showAddModal = true">+</button>
    </div>
    
    <div class="search-bar">
      <input 
        type="text" 
        v-model="searchQuery" 
        placeholder="Search contacts..."
        class="search-input"
      />
    </div>
    
    <div class="contacts-list">
      <div 
        v-for="contact in filteredContacts" 
        :key="contact.id"
        class="contact-item"
      >
        <div class="contact-info">
          <div class="contact-name">{{ contact.contact_name }}</div>
          <div class="contact-number">{{ contact.contact_number }}</div>
        </div>
        <div class="contact-actions">
          <button @click="editContact(contact)" class="action-btn edit-btn">Edit</button>
          <button @click="deleteContactConfirm(contact)" class="action-btn delete-btn">Delete</button>
        </div>
      </div>
      
      <div v-if="filteredContacts.length === 0" class="no-contacts">
        <p v-if="searchQuery">No contacts found</p>
        <p v-else>No contacts yet. Add one to get started!</p>
      </div>
    </div>
    
    <!-- Add/Edit Contact Modal -->
    <div v-if="showAddModal || showEditModal" class="modal-overlay" @click="closeModals">
      <div class="modal-content" @click.stop>
        <h3>{{ showEditModal ? 'Edit Contact' : 'Add Contact' }}</h3>
        
        <div class="form-group">
          <label>Name</label>
          <input 
            type="text" 
            v-model="formData.name" 
            placeholder="Contact name"
            maxlength="100"
          />
        </div>
        
        <div class="form-group">
          <label>Phone Number</label>
          <input 
            type="text" 
            v-model="formData.number" 
            placeholder="Phone number"
            maxlength="20"
          />
        </div>
        
        <div class="modal-actions">
          <button @click="closeModals" class="btn-cancel">Cancel</button>
          <button @click="saveContact" class="btn-save">Save</button>
        </div>
      </div>
    </div>
    
    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteModal" class="modal-overlay" @click="showDeleteModal = false">
      <div class="modal-content" @click.stop>
        <h3>Delete Contact</h3>
        <p>Are you sure you want to delete {{ contactToDelete?.contact_name }}?</p>
        
        <div class="modal-actions">
          <button @click="showDeleteModal = false" class="btn-cancel">Cancel</button>
          <button @click="confirmDelete" class="btn-delete">Delete</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { computed, ref } from 'vue'
import { useStore } from 'vuex'

export default {
  name: 'Contacts',
  
  setup() {
    const store = useStore()
    
    // State
    const showAddModal = ref(false)
    const showEditModal = ref(false)
    const showDeleteModal = ref(false)
    const contactToDelete = ref(null)
    const editingContact = ref(null)
    const formData = ref({
      name: '',
      number: ''
    })
    
    // Computed
    const searchQuery = computed({
      get: () => store.state.contacts.searchQuery,
      set: (value) => store.commit('contacts/setSearchQuery', value)
    })
    
    const filteredContacts = computed(() => store.getters['contacts/filteredContacts'])
    
    // Methods
    const closeModals = () => {
      showAddModal.value = false
      showEditModal.value = false
      editingContact.value = null
      formData.value = { name: '', number: '' }
    }
    
    const editContact = (contact) => {
      editingContact.value = contact
      formData.value = {
        name: contact.contact_name,
        number: contact.contact_number
      }
      showEditModal.value = true
    }
    
    const deleteContactConfirm = (contact) => {
      contactToDelete.value = contact
      showDeleteModal.value = true
    }
    
    const saveContact = async () => {
      // Validation
      if (!formData.value.name.trim()) {
        alert('Please enter a contact name')
        return
      }
      
      if (!formData.value.number.trim()) {
        alert('Please enter a phone number')
        return
      }
      
      let response
      
      if (showEditModal.value) {
        // Edit existing contact
        response = await store.dispatch('contacts/editContact', {
          id: editingContact.value.id,
          contactData: {
            name: formData.value.name.trim(),
            number: formData.value.number.trim()
          }
        })
      } else {
        // Add new contact
        response = await store.dispatch('contacts/addContact', {
          name: formData.value.name.trim(),
          number: formData.value.number.trim()
        })
      }
      
      if (response.success) {
        closeModals()
      } else {
        alert(response.message || 'Failed to save contact')
      }
    }
    
    const confirmDelete = async () => {
      if (!contactToDelete.value) return
      
      const response = await store.dispatch('contacts/deleteContact', contactToDelete.value.id)
      
      if (response.success) {
        showDeleteModal.value = false
        contactToDelete.value = null
      } else {
        alert(response.message || 'Failed to delete contact')
      }
    }
    
    return {
      searchQuery,
      filteredContacts,
      showAddModal,
      showEditModal,
      showDeleteModal,
      contactToDelete,
      formData,
      closeModals,
      editContact,
      deleteContactConfirm,
      saveContact,
      confirmDelete
    }
  }
}
</script>

<style scoped>
.contacts-view {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #000;
  color: #fff;
}

.contacts-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #333;
}

.contacts-header h2 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.add-btn {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #007aff;
  color: white;
  border: none;
  font-size: 24px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.add-btn:hover {
  background: #0051d5;
}

.search-bar {
  padding: 15px 20px;
  border-bottom: 1px solid #333;
}

.search-input {
  width: 100%;
  padding: 10px 15px;
  background: #1c1c1e;
  border: 1px solid #333;
  border-radius: 10px;
  color: #fff;
  font-size: 16px;
}

.search-input::placeholder {
  color: #666;
}

.contacts-list {
  flex: 1;
  overflow-y: auto;
  padding: 10px 0;
}

.contact-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  border-bottom: 1px solid #222;
  transition: background 0.2s;
}

.contact-item:hover {
  background: #1c1c1e;
}

.contact-info {
  flex: 1;
}

.contact-name {
  font-size: 18px;
  font-weight: 500;
  margin-bottom: 4px;
}

.contact-number {
  font-size: 14px;
  color: #888;
}

.contact-actions {
  display: flex;
  gap: 8px;
}

.action-btn {
  padding: 6px 12px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  cursor: pointer;
  transition: opacity 0.2s;
}

.action-btn:hover {
  opacity: 0.8;
}

.edit-btn {
  background: #007aff;
  color: white;
}

.delete-btn {
  background: #ff3b30;
  color: white;
}

.no-contacts {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 200px;
  color: #666;
  font-size: 16px;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: #1c1c1e;
  border-radius: 12px;
  padding: 24px;
  width: 90%;
  max-width: 400px;
}

.modal-content h3 {
  margin: 0 0 20px 0;
  font-size: 20px;
  font-weight: 600;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-size: 14px;
  color: #888;
}

.form-group input {
  width: 100%;
  padding: 10px 15px;
  background: #2c2c2e;
  border: 1px solid #444;
  border-radius: 8px;
  color: #fff;
  font-size: 16px;
}

.modal-actions {
  display: flex;
  gap: 12px;
  margin-top: 24px;
}

.modal-actions button {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: opacity 0.2s;
}

.modal-actions button:hover {
  opacity: 0.8;
}

.btn-cancel {
  background: #444;
  color: white;
}

.btn-save {
  background: #007aff;
  color: white;
}

.btn-delete {
  background: #ff3b30;
  color: white;
}
</style>
