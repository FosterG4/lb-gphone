/**
 * Haptic Feedback Utility
 * Provides haptic feedback for contact sharing interactions
 * with fallback support for platforms without haptic capabilities
 */

// Check if haptic feedback is supported
const isHapticSupported = () => {
  return 'vibrate' in navigator || 
         ('hapticFeedback' in navigator) ||
         (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.haptic)
}

// Check if haptic feedback is enabled in settings
const isHapticEnabled = () => {
  try {
    const enabled = localStorage.getItem('lb-phone-haptic-enabled')
    // Default to true if not set
    return enabled === null || enabled === 'true'
  } catch (error) {
    console.warn('Could not read haptic settings:', error)
    return true
  }
}

/**
 * Trigger haptic feedback with specified pattern
 * @param {string} type - Type of haptic feedback: 'light', 'medium', 'heavy', 'success', 'warning', 'error'
 */
export const triggerHaptic = (type = 'light') => {
  // Check if haptics are enabled
  if (!isHapticEnabled()) {
    return
  }

  // Check if haptics are supported
  if (!isHapticSupported()) {
    // Fallback: visual feedback only (no haptic)
    return
  }

  try {
    // Define vibration patterns for different feedback types
    const patterns = {
      light: [10],           // Quick tap
      medium: [20],          // Medium tap
      heavy: [30],           // Strong tap
      success: [10, 50, 10], // Double tap
      warning: [20, 100, 20], // Double medium tap
      error: [30, 100, 30, 100, 30], // Triple strong tap
      selection: [5],        // Very light tap for selection
      notification: [15, 50, 15] // Double light tap
    }

    const pattern = patterns[type] || patterns.light

    // Try WebKit haptic feedback first (iOS)
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.haptic) {
      window.webkit.messageHandlers.haptic.postMessage({ type })
      return
    }

    // Try Vibration API (Android and some browsers)
    if ('vibrate' in navigator) {
      navigator.vibrate(pattern)
      return
    }

    // Try experimental Haptic Feedback API
    if ('hapticFeedback' in navigator && typeof navigator.hapticFeedback === 'function') {
      navigator.hapticFeedback(type)
      return
    }
  } catch (error) {
    console.warn('Haptic feedback error:', error)
  }
}

/**
 * Trigger light haptic feedback (for button taps, selections)
 */
export const hapticLight = () => {
  triggerHaptic('light')
}

/**
 * Trigger medium haptic feedback (for important actions)
 */
export const hapticMedium = () => {
  triggerHaptic('medium')
}

/**
 * Trigger heavy haptic feedback (for critical actions)
 */
export const hapticHeavy = () => {
  triggerHaptic('heavy')
}

/**
 * Trigger success haptic feedback (for successful operations)
 */
export const hapticSuccess = () => {
  triggerHaptic('success')
}

/**
 * Trigger warning haptic feedback (for warnings)
 */
export const hapticWarning = () => {
  triggerHaptic('warning')
}

/**
 * Trigger error haptic feedback (for errors)
 */
export const hapticError = () => {
  triggerHaptic('error')
}

/**
 * Trigger selection haptic feedback (for list item selection)
 */
export const hapticSelection = () => {
  triggerHaptic('selection')
}

/**
 * Trigger notification haptic feedback (for incoming notifications)
 */
export const hapticNotification = () => {
  triggerHaptic('notification')
}

/**
 * Enable haptic feedback
 */
export const enableHaptics = () => {
  try {
    localStorage.setItem('lb-phone-haptic-enabled', 'true')
  } catch (error) {
    console.warn('Could not save haptic settings:', error)
  }
}

/**
 * Disable haptic feedback
 */
export const disableHaptics = () => {
  try {
    localStorage.setItem('lb-phone-haptic-enabled', 'false')
  } catch (error) {
    console.warn('Could not save haptic settings:', error)
  }
}

/**
 * Get haptic support status
 * @returns {Object} Object with support and enabled status
 */
export const getHapticStatus = () => {
  return {
    supported: isHapticSupported(),
    enabled: isHapticEnabled()
  }
}

export default {
  triggerHaptic,
  hapticLight,
  hapticMedium,
  hapticHeavy,
  hapticSuccess,
  hapticWarning,
  hapticError,
  hapticSelection,
  hapticNotification,
  enableHaptics,
  disableHaptics,
  getHapticStatus
}
