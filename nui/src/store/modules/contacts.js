// Contacts Store Module
import { nuiCallback } from '../../utils/nui'

export default {
  namespaced: true,
  
  state: {
    list: [],
    searchQuery: ''
  },
  
  getters: {
    // Get filtered and sorted contacts
    filteredContacts(state) {
      let contacts = [...state.list]
      
      // Filter by search query
      if (state.searchQuery) {
        const query = state.searchQuery.toLowerCase()
        contacts = contacts.filter(contact => 
          contact.contact_name.toLowerCase().includes(query) ||
          contact.contact_number.includes(query)
        )
      }
      
      // Sort alphabetically by name
      contacts.sort((a, b) => 
        a.contact_name.localeCompare(b.contact_name)
      )
      
      return contacts
    }
  },
  
  mutations: {
    setList(state, contacts) {
      state.list = contacts || []
    },
    
    setSearchQuery(state, query) {
      state.searchQuery = query
    },
    
    addContact(state, contact) {
      state.list.push(contact)
    },
    
    updateContact(state, updatedContact) {
      const index = state.list.findIndex(c => c.id === updatedContact.id)
      if (index !== -1) {
        state.list.splice(index, 1, updatedContact)
      }
    },
    
    removeContact(state, contactId) {
      const index = state.list.findIndex(c => c.id === contactId)
      if (index !== -1) {
        state.list.splice(index, 1)
      }
    }
  },
  
  actions: {
    // Fetch all contacts from server
    async fetchContacts({ commit }) {
      try {
        const response = await nuiCallback('getContacts', {})
        if (response.success) {
          commit('setList', response.contacts)
        }
        return response
      } catch (error) {
        console.error('Error fetching contacts:', error)
        return { success: false, error: 'FETCH_FAILED' }
      }
    },
    
    // Add new contact
    async addContact({ commit }, contactData) {
      try {
        const response = await nuiCallback('addContact', contactData)
        if (response.success) {
          commit('addContact', response.contact)
        }
        return response
      } catch (error) {
        console.error('Error adding contact:', error)
        return { success: false, error: 'ADD_FAILED' }
      }
    },
    
    // Edit existing contact
    async editContact({ commit }, { id, contactData }) {
      try {
        const response = await nuiCallback('editContact', { id, ...contactData })
        if (response.success) {
          commit('updateContact', response.contact)
        }
        return response
      } catch (error) {
        console.error('Error editing contact:', error)
        return { success: false, error: 'EDIT_FAILED' }
      }
    },
    
    // Delete contact
    async deleteContact({ commit }, contactId) {
      try {
        const response = await nuiCallback('deleteContact', { id: contactId })
        if (response.success) {
          commit('removeContact', contactId)
        }
        return response
      } catch (error) {
        console.error('Error deleting contact:', error)
        return { success: false, error: 'DELETE_FAILED' }
      }
    }
  }
}
