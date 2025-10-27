// Vuex Store
import { createStore } from 'vuex'
import phone from './modules/phone'
import contacts from './modules/contacts'
import messages from './modules/messages'
import calls from './modules/calls'
import apps from './modules/apps'
import settings from './modules/settings'
import media from './modules/media'
import garage from './modules/garage'

export default createStore({
  modules: {
    phone,
    contacts,
    messages,
    calls,
    apps,
    settings,
    media,
    garage
  }
})
