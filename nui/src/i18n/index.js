import { createI18n } from 'vue-i18n'

// Supported locales
const SUPPORTED_LOCALES = ['en', 'ja', 'es', 'fr', 'de', 'pt']

// Lazy load locale files
const localeModules = {
  en: () => import('./locales/en.json'),
  ja: () => import('./locales/ja.json'),
  es: () => import('./locales/es.json'),
  fr: () => import('./locales/fr.json'),
  de: () => import('./locales/de.json'),
  pt: () => import('./locales/pt.json')
}

// Function to get default locale
function getDefaultLocale() {
  // First check localStorage (set by user preference)
  const stored = localStorage.getItem('phone-locale')
  if (stored && SUPPORTED_LOCALES.includes(stored)) {
    return stored
  }
  
  // Fall back to browser language
  const browserLang = navigator.language.split('-')[0]
  return SUPPORTED_LOCALES.includes(browserLang) ? browserLang : 'en'
}

// Create i18n instance with empty messages (will be loaded async)
const i18n = createI18n({
  legacy: false,
  locale: getDefaultLocale(),
  fallbackLocale: 'en',
  messages: {},
  numberFormats: {
    en: {
      currency: {
        style: 'currency',
        currency: 'USD',
        notation: 'standard'
      },
      decimal: {
        style: 'decimal',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      },
      percent: {
        style: 'percent',
        useGrouping: false
      }
    },
    ja: {
      currency: {
        style: 'currency',
        currency: 'JPY',
        notation: 'standard'
      },
      decimal: {
        style: 'decimal',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
      },
      percent: {
        style: 'percent',
        useGrouping: false
      }
    },
    es: {
      currency: {
        style: 'currency',
        currency: 'EUR',
        notation: 'standard'
      },
      decimal: {
        style: 'decimal',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      },
      percent: {
        style: 'percent',
        useGrouping: false
      }
    },
    fr: {
      currency: {
        style: 'currency',
        currency: 'EUR',
        notation: 'standard'
      },
      decimal: {
        style: 'decimal',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      },
      percent: {
        style: 'percent',
        useGrouping: false
      }
    },
    de: {
      currency: {
        style: 'currency',
        currency: 'EUR',
        notation: 'standard'
      },
      decimal: {
        style: 'decimal',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      },
      percent: {
        style: 'percent',
        useGrouping: false
      }
    },
    pt: {
      currency: {
        style: 'currency',
        currency: 'BRL',
        notation: 'standard'
      },
      decimal: {
        style: 'decimal',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      },
      percent: {
        style: 'percent',
        useGrouping: false
      }
    }
  }
})

// Helper functions
export function setLocale(locale) {
  if (SUPPORTED_LOCALES.includes(locale)) {
    i18n.global.locale.value = locale
    localStorage.setItem('phone-locale', locale)
    return true
  }
  return false
}

// Load locale from server settings
export function loadLocaleFromSettings(settings) {
  if (settings && settings.locale && SUPPORTED_LOCALES.includes(settings.locale)) {
    setLocale(settings.locale)
    return true
  }
  return false
}

export function getCurrentLocale() {
  return i18n.global.locale.value
}

export function getAvailableLocales() {
  return SUPPORTED_LOCALES
}

export function getLocaleDisplayName(locale) {
  const displayNames = {
    en: 'English',
    ja: '日本語',
    es: 'Español',
    fr: 'Français',
    de: 'Deutsch',
    pt: 'Português'
  }
  return displayNames[locale] || locale
}

// Load locale messages dynamically
export async function loadLocaleMessages(locale) {
  if (!SUPPORTED_LOCALES.includes(locale)) {
    console.warn(`Locale ${locale} is not supported`)
    return false
  }
  
  // Check if already loaded
  if (i18n.global.availableLocales.includes(locale)) {
    return true
  }
  
  try {
    const loader = localeModules[locale]
    if (!loader) {
      console.error(`No loader found for locale ${locale}`)
      return false
    }
    
    const messages = await loader()
    i18n.global.setLocaleMessage(locale, messages.default || messages)
    return true
  } catch (error) {
    console.error(`Failed to load locale ${locale}:`, error)
    return false
  }
}

// Initialize with default locale
export async function initI18n() {
  const defaultLocale = getDefaultLocale()
  await loadLocaleMessages(defaultLocale)
  await loadLocaleMessages('en') // Always load fallback
  return i18n
}

export default i18n