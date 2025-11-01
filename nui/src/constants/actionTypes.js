// NUI Action Types - Centralized constants for message handling
export const PHONE_ACTIONS = {
  // Phone State
  SET_VISIBLE: 'setVisible',
  SET_PHONE_NUMBER: 'setPhoneNumber',
  SET_THEME: 'setTheme',
  LOAD_PHONE_DATA: 'loadPhoneData',
  
  // Notifications
  SHOW_NOTIFICATION: 'showNotification',
  NOTIFICATION: 'notification',
  
  // Messages
  RECEIVE_MESSAGE: 'receiveMessage',
  
  // Calls
  INCOMING_CALL: 'incomingCall',
  CALL_ACCEPTED: 'callAccepted',
  CALL_ENDED: 'callEnded',
  CALL_BUSY: 'callBusy',
  CALL_TIMEOUT: 'callTimeout',
  UPDATE_CALL_STATE: 'updateCallState',
  SWITCH_TO_CALL_SCREEN: 'switchToCallScreen',
  
  // Social Media
  NEW_TWEET: 'newTweet',
  TWEET_LIKE_UPDATE: 'tweetLikeUpdate',
  
  // Settings
  SET_VOLUME: 'setVolume',
  SET_NOTIFICATION_ENABLED: 'setNotificationEnabled',
  SET_SOUND_ENABLED: 'setSoundEnabled',
  SET_CUSTOM_SETTINGS: 'setCustomSettings',
  SETTINGS_LOADED: 'settingsLoaded',
  SETTINGS_UPDATED: 'settingsUpdated',
  SETTINGS_ERROR: 'settingsError',
  
  // Contact Sharing
  SHOW_SHARE_DECLINED_NOTIFICATION: 'showShareDeclinedNotification',
  SHOW_SHARE_ERROR_NOTIFICATION: 'showShareErrorNotification',
  SHOW_BROADCAST_CONTACT_ADDED_NOTIFICATION: 'showBroadcastContactAddedNotification'
}

// Action handler registry for better organization
export const createActionHandlers = (store, i18n, notificationUtils) => ({
  [PHONE_ACTIONS.SET_VISIBLE]: (data) => {
    store.commit('phone/setVisible', data.visible)
  },
  
  [PHONE_ACTIONS.SHOW_NOTIFICATION]: (data) => {
    store.dispatch('phone/showNotification', data)
  },
  
  [PHONE_ACTIONS.SET_PHONE_NUMBER]: (data) => {
    store.commit('phone/setPhoneNumber', data.phoneNumber)
  },
  
  [PHONE_ACTIONS.LOAD_PHONE_DATA]: (data) => {
    if (data.contacts) store.commit('contacts/setList', data.contacts)
    if (data.messages) store.commit('messages/setConversations', data.messages)
    if (data.callHistory) store.commit('calls/setHistory', data.callHistory)
  },
  
  [PHONE_ACTIONS.RECEIVE_MESSAGE]: (data) => {
    store.dispatch('messages/receiveMessage', data)
  },
  
  [PHONE_ACTIONS.INCOMING_CALL]: (data) => {
    store.dispatch('calls/receiveIncomingCall', data)
    store.commit('phone/setCurrentApp', 'call-screen')
  },
  
  [PHONE_ACTIONS.CALL_ACCEPTED]: () => {
    store.dispatch('calls/callAccepted')
  },
  
  [PHONE_ACTIONS.CALL_ENDED]: () => {
    store.dispatch('calls/callEnded')
    store.commit('phone/setCurrentApp', null)
  },
  
  [PHONE_ACTIONS.CALL_BUSY]: () => {
    store.dispatch('calls/callEnded')
    store.commit('phone/setCurrentApp', null)
    store.dispatch('phone/showNotification', {
      type: 'error',
      title: 'Call Failed',
      message: 'The person you are calling is busy'
    })
  },
  
  [PHONE_ACTIONS.CALL_TIMEOUT]: () => {
    store.dispatch('calls/callEnded')
    store.commit('phone/setCurrentApp', null)
    store.dispatch('phone/showNotification', {
      type: 'error',
      title: 'Call Failed',
      message: 'Call timed out'
    })
  },
  
  [PHONE_ACTIONS.UPDATE_CALL_STATE]: (data) => {
    store.commit('calls/setState', data.state)
  },
  
  [PHONE_ACTIONS.SWITCH_TO_CALL_SCREEN]: () => {
    store.commit('phone/setCurrentApp', 'call-screen')
  },
  
  [PHONE_ACTIONS.NEW_TWEET]: (data) => {
    store.commit('apps/addTweetToFeed', data)
  },
  
  [PHONE_ACTIONS.TWEET_LIKE_UPDATE]: (data) => {
    store.commit('apps/updateTweetLikes', {
      tweetId: data.tweetId,
      likes: data.likes,
      isLiked: false
    })
  },
  
  [PHONE_ACTIONS.NOTIFICATION]: (data) => {
    store.dispatch('phone/showNotification', data)
  },
  
  [PHONE_ACTIONS.SET_THEME]: (data) => {
    store.commit('settings/setTheme', data.theme || data)
  },
  
  [PHONE_ACTIONS.SET_VOLUME]: (data) => {
    store.commit('settings/setVolume', data.volume || data)
  },
  
  [PHONE_ACTIONS.SET_NOTIFICATION_ENABLED]: (data) => {
    store.commit('settings/setNotificationEnabled', data.enabled !== undefined ? data.enabled : data)
  },
  
  [PHONE_ACTIONS.SET_SOUND_ENABLED]: (data) => {
    store.commit('settings/setSoundEnabled', data.enabled !== undefined ? data.enabled : data)
  },
  
  [PHONE_ACTIONS.SET_CUSTOM_SETTINGS]: (data) => {
    if (data.settings) {
      Object.keys(data.settings).forEach(key => {
        store.commit('settings/setCustomSetting', { key, value: data.settings[key] })
      })
    }
  },
  
  [PHONE_ACTIONS.SETTINGS_LOADED]: (data) => {
    if (data.settings) {
      store.commit('settings/setAllSettings', data.settings)
      if (data.settings.locale) {
        import('../i18n').then(({ loadLocaleFromSettings }) => {
          loadLocaleFromSettings(data.settings)
        })
      }
    }
  },
  
  [PHONE_ACTIONS.SETTINGS_UPDATED]: (data) => {
    if (data.settings) {
      store.commit('settings/setAllSettings', data.settings)
      if (data.settings.locale) {
        import('../i18n').then(({ loadLocaleFromSettings }) => {
          loadLocaleFromSettings(data.settings)
        })
      }
    }
  },
  
  [PHONE_ACTIONS.SETTINGS_ERROR]: (data) => {
    store.dispatch('phone/showNotification', {
      type: 'error',
      title: 'Settings Error',
      message: data.error || 'Failed to update settings'
    })
  },
  
  [PHONE_ACTIONS.SHOW_SHARE_DECLINED_NOTIFICATION]: (data) => {
    notificationUtils.showShareDeclinedNotification(data.contactName, i18n.global)
  },
  
  [PHONE_ACTIONS.SHOW_SHARE_ERROR_NOTIFICATION]: (data) => {
    notificationUtils.showShareErrorNotification(data.errorMessage, null, i18n.global)
  },
  
  [PHONE_ACTIONS.SHOW_BROADCAST_CONTACT_ADDED_NOTIFICATION]: (data) => {
    notificationUtils.showBroadcastContactAddedNotification(data.addedBy, i18n.global)
  }
})
