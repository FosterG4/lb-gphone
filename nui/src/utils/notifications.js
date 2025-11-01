// Notification Utility for Currency Errors and General Notifications

/**
 * Show a notification
 * @param {object} options - Notification options
 */
export function showNotification(options = {}) {
    const {
        type = 'info', // 'success', 'error', 'warning', 'info'
        title = '',
        message = '',
        duration = 5000,
        position = 'top-right'
    } = options

    // Dispatch custom event for notification system
    const event = new CustomEvent('phone-notification', {
        detail: {
            type,
            title,
            message,
            duration,
            position,
            timestamp: Date.now()
        }
    })
    
    window.dispatchEvent(event)
    
    // Also log to console for debugging
    console.log(`[Notification ${type.toUpperCase()}]`, title, message)
}

/**
 * Show a success notification
 * @param {string} message - Success message
 * @param {string} title - Optional title
 */
export function showSuccess(message, title = 'Success') {
    showNotification({
        type: 'success',
        title,
        message,
        duration: 3000
    })
}

/**
 * Show an error notification
 * @param {string} message - Error message
 * @param {string} title - Optional title
 */
export function showError(message, title = 'Error') {
    showNotification({
        type: 'error',
        title,
        message,
        duration: 5000
    })
}

/**
 * Show a warning notification
 * @param {string} message - Warning message
 * @param {string} title - Optional title
 */
export function showWarning(message, title = 'Warning') {
    showNotification({
        type: 'warning',
        title,
        message,
        duration: 4000
    })
}

/**
 * Show an info notification
 * @param {string} message - Info message
 * @param {string} title - Optional title
 */
export function showInfo(message, title = 'Info') {
    showNotification({
        type: 'info',
        title,
        message,
        duration: 3000
    })
}

/**
 * Show a currency validation error notification
 * @param {object} validation - Validation result from validateCurrency
 * @param {object} i18n - Vue I18n instance
 */
export function showCurrencyError(validation, i18n) {
    if (!validation || validation.isValid) return
    
    const message = validation.error && i18n 
        ? i18n.t(validation.error)
        : validation.message || 'Currency validation failed'
    
    showError(message, i18n ? i18n.t('currency.formatError') : 'Currency Error')
}

/**
 * Show a transaction error notification
 * @param {string} errorKey - Error key for translation
 * @param {object} i18n - Vue I18n instance
 */
export function showTransactionError(errorKey, i18n) {
    const message = i18n 
        ? i18n.t(`currency.errors.${errorKey}`)
        : 'Transaction failed'
    
    showError(message, i18n ? i18n.t('bank.failed') : 'Transaction Failed')
}

/**
 * Show insufficient funds notification
 * @param {object} i18n - Vue I18n instance
 */
export function showInsufficientFunds(i18n) {
    const message = i18n 
        ? i18n.t('currency.errors.insufficientFunds')
        : 'Insufficient funds for this transaction'
    
    showError(message, i18n ? i18n.t('bank.insufficient') : 'Insufficient Funds')
}

/**
 * Show amount exceeds maximum notification
 * @param {number} maxAmount - Maximum allowed amount
 * @param {object} i18n - Vue I18n instance
 */
export function showAmountExceedsMaximum(maxAmount, i18n) {
    const message = i18n 
        ? i18n.t('currency.errors.exceedsMaximum', { max: maxAmount })
        : `Amount exceeds maximum limit of ${maxAmount}`
    
    showError(message, i18n ? i18n.t('currency.formatError') : 'Amount Too Large')
}

// ============================================================================
// Contact Sharing Notifications
// ============================================================================

/**
 * Show contact added notification
 * @param {string} contactName - Name of the contact that was added
 * @param {object} i18n - Vue I18n instance (optional)
 */
export function showContactAddedNotification(contactName, i18n) {
    const message = i18n 
        ? i18n.t('contact_sharing.contact_added', { name: contactName })
        : `${contactName} added to contacts`
    
    const title = i18n 
        ? i18n.t('contact_sharing.contact_added_title') 
        : 'Contact Added'
    
    showNotification({
        type: 'success',
        title,
        message,
        duration: 3000
    })
}

/**
 * Show share success notification (when request is accepted)
 * @param {string} contactName - Name of the contact that was shared
 * @param {object} i18n - Vue I18n instance (optional)
 */
export function showShareSuccessNotification(contactName, i18n) {
    const message = i18n 
        ? i18n.t('contact_sharing.contact_shared', { name: contactName })
        : `Contact shared with ${contactName}`
    
    const title = i18n 
        ? i18n.t('contact_sharing.share_success') 
        : 'Contact Shared'
    
    showNotification({
        type: 'success',
        title,
        message,
        duration: 3000
    })
}

/**
 * Show share declined notification (when request is declined)
 * @param {string} contactName - Name of the person who declined
 * @param {object} i18n - Vue I18n instance (optional)
 */
export function showShareDeclinedNotification(contactName, i18n) {
    const message = i18n 
        ? i18n.t('contact_sharing.request_declined', { name: contactName })
        : `${contactName} declined your contact request`
    
    const title = i18n 
        ? i18n.t('contact_sharing.request_declined_title') 
        : 'Request Declined'
    
    showNotification({
        type: 'warning',
        title,
        message,
        duration: 4000
    })
}

/**
 * Show share error notification with optional retry
 * @param {string} errorMessage - Error message to display
 * @param {function} onRetry - Optional retry callback function
 * @param {object} i18n - Vue I18n instance (optional)
 */
export function showShareErrorNotification(errorMessage, onRetry = null, i18n) {
    const title = i18n 
        ? i18n.t('contact_sharing.share_error') 
        : 'Share Failed'
    
    // Translate common error codes
    let message = errorMessage
    if (i18n && errorMessage) {
        const errorKey = `contact_sharing.errors.${errorMessage}`
        const translated = i18n.t(errorKey)
        if (translated !== errorKey) {
            message = translated
        }
    }
    
    showNotification({
        type: 'error',
        title,
        message: message || 'Failed to share contact',
        duration: 5000
    })
    
    // If retry callback provided, dispatch retry event
    if (onRetry && typeof onRetry === 'function') {
        const retryEvent = new CustomEvent('phone-notification-retry', {
            detail: {
                action: 'retry-share',
                callback: onRetry
            }
        })
        window.dispatchEvent(retryEvent)
    }
}

/**
 * Show broadcast started notification
 * @param {number} duration - Duration of the broadcast in seconds
 * @param {object} i18n - Vue I18n instance (optional)
 */
export function showBroadcastStartedNotification(duration, i18n) {
    const message = i18n 
        ? i18n.t('contact_sharing.visible_to_nearby')
        : 'Your contact is visible to nearby players'
    
    const title = i18n 
        ? i18n.t('contact_sharing.sharing_contact') 
        : 'Sharing Contact'
    
    showNotification({
        type: 'info',
        title,
        message,
        duration: 3000
    })
}

/**
 * Show broadcast stopped notification
 * @param {string} reason - Reason for stopping (expired, manual, etc.)
 * @param {object} i18n - Vue I18n instance (optional)
 */
export function showBroadcastStoppedNotification(reason, i18n) {
    const message = i18n 
        ? i18n.t(`contact_sharing.broadcast_stopped_${reason}`)
        : 'Contact sharing stopped'
    
    const title = i18n 
        ? i18n.t('contact_sharing.sharing_stopped') 
        : 'Sharing Stopped'
    
    showNotification({
        type: 'info',
        title,
        message,
        duration: 2000
    })
}

/**
 * Show someone added your broadcast contact notification
 * @param {string} addedBy - Name of person who added the contact
 * @param {object} i18n - Vue I18n instance (optional)
 */
export function showBroadcastContactAddedNotification(addedBy, i18n) {
    const message = i18n 
        ? i18n.t('contact_sharing.broadcast_contact_added', { name: addedBy })
        : `${addedBy} added your contact`
    
    const title = i18n 
        ? i18n.t('contact_sharing.contact_added_title') 
        : 'Contact Added'
    
    showNotification({
        type: 'success',
        title,
        message,
        duration: 3000
    })
}

export default {
    showNotification,
    showSuccess,
    showError,
    showWarning,
    showInfo,
    showCurrencyError,
    showTransactionError,
    showInsufficientFunds,
    showAmountExceedsMaximum,
    showContactAddedNotification,
    showShareSuccessNotification,
    showShareDeclinedNotification,
    showShareErrorNotification,
    showBroadcastStartedNotification,
    showBroadcastStoppedNotification,
    showBroadcastContactAddedNotification
}
