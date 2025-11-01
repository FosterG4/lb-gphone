// Currency Utility Functions
import { getCurrentLocale } from '../i18n'

// Maximum currency value (999 trillion)
export const MAX_CURRENCY_VALUE = 999000000000000

/**
 * Format currency amount based on current locale
 * @param {number} amount - The amount to format
 * @param {string} locale - Optional locale override
 * @returns {string} Formatted currency string
 */
export function formatCurrency(amount, locale = null) {
    if (typeof amount !== 'number' || isNaN(amount)) {
        return '0'
    }

    // Validate amount doesn't exceed maximum
    if (amount > MAX_CURRENCY_VALUE) {
        amount = MAX_CURRENCY_VALUE
    }

    const currentLocale = locale || getCurrentLocale()
    
    // Currency formatting configurations for each locale
    const currencyConfigs = {
        'en': {
            symbol: '$',
            position: 'before',
            locale: 'en-US',
            currency: 'USD'
        },
        'ja': {
            symbol: '¥',
            position: 'before',
            locale: 'ja-JP',
            currency: 'JPY'
        },
        'es': {
            symbol: '€',
            position: 'after',
            locale: 'es-ES',
            currency: 'EUR'
        },
        'fr': {
            symbol: '€',
            position: 'after',
            locale: 'fr-FR',
            currency: 'EUR'
        },
        'de': {
            symbol: '€',
            position: 'after',
            locale: 'de-DE',
            currency: 'EUR'
        },
        'pt': {
            symbol: 'R$',
            position: 'before',
            locale: 'pt-BR',
            currency: 'BRL'
        }
    }

    const config = currencyConfigs[currentLocale] || currencyConfigs['en']

    try {
        // Use Intl.NumberFormat for proper locale-aware formatting
        const formatter = new Intl.NumberFormat(config.locale, {
            style: 'currency',
            currency: config.currency,
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        })

        return formatter.format(amount)
    } catch (error) {
        console.warn('Currency formatting error:', error)
        
        // Fallback formatting
        const formattedAmount = amount.toLocaleString(config.locale, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        })

        if (config.position === 'before') {
            return `${config.symbol}${formattedAmount}`
        } else {
            return `${formattedAmount} ${config.symbol}`
        }
    }
}

/**
 * Format currency amount without symbol (for input fields)
 * @param {number} amount - The amount to format
 * @param {string} locale - Optional locale override
 * @returns {string} Formatted number string
 */
export function formatCurrencyNumber(amount, locale = null) {
    if (typeof amount !== 'number' || isNaN(amount)) {
        return '0.00'
    }

    // Validate amount doesn't exceed maximum
    if (amount > MAX_CURRENCY_VALUE) {
        amount = MAX_CURRENCY_VALUE
    }

    const currentLocale = locale || getCurrentLocale()
    
    const localeConfigs = {
        'en': 'en-US',
        'ja': 'ja-JP',
        'es': 'es-ES',
        'fr': 'fr-FR',
        'de': 'de-DE',
        'pt': 'pt-BR'
    }

    const localeCode = localeConfigs[currentLocale] || 'en-US'

    return amount.toLocaleString(localeCode, {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    })
}

/**
 * Parse currency string to number
 * @param {string} currencyString - The currency string to parse
 * @returns {number} Parsed amount or 0 if invalid
 */
export function parseCurrency(currencyString) {
    if (typeof currencyString !== 'string') {
        return 0
    }

    // Remove currency symbols and spaces
    const cleanString = currencyString
        .replace(/[$¥€R\s]/g, '')
        .replace(/,/g, '.')
        .replace(/[^\d.-]/g, '')

    const amount = parseFloat(cleanString)
    
    if (isNaN(amount)) {
        return 0
    }

    // Validate amount doesn't exceed maximum
    return Math.min(amount, MAX_CURRENCY_VALUE)
}

/**
 * Validate currency amount
 * @param {number} amount - The amount to validate
 * @param {object} options - Validation options
 * @returns {object} Validation result with isValid, error message, and error key
 */
export function validateCurrency(amount, options = {}) {
    const { allowZero = false, minAmount = 0 } = options
    
    if (typeof amount !== 'number' || isNaN(amount)) {
        return {
            isValid: false,
            error: 'currency.errors.invalidFormat',
            errorKey: 'invalidFormat',
            message: 'Invalid amount format'
        }
    }

    if (amount < 0) {
        return {
            isValid: false,
            error: 'currency.errors.negativeAmount',
            errorKey: 'negativeAmount',
            message: 'Amount cannot be negative'
        }
    }

    if (!allowZero && amount === 0) {
        return {
            isValid: false,
            error: 'currency.errors.belowMinimum',
            errorKey: 'belowMinimum',
            message: 'Amount must be greater than zero'
        }
    }

    if (amount < minAmount) {
        return {
            isValid: false,
            error: 'currency.errors.belowMinimum',
            errorKey: 'belowMinimum',
            message: `Amount must be at least ${formatCurrency(minAmount)}`
        }
    }

    if (amount > MAX_CURRENCY_VALUE) {
        return {
            isValid: false,
            error: 'currency.errors.exceedsMaximum',
            errorKey: 'exceedsMaximum',
            message: `Amount cannot exceed ${formatCurrency(MAX_CURRENCY_VALUE)}`
        }
    }

    return {
        isValid: true,
        error: null,
        errorKey: null,
        message: null
    }
}

/**
 * Validate currency input string
 * @param {string} input - The input string to validate
 * @param {object} options - Validation options
 * @returns {object} Validation result with isValid, parsed amount, and error
 */
export function validateCurrencyInput(input, options = {}) {
    if (!input || input.trim() === '') {
        return {
            isValid: false,
            error: 'currency.validation.required',
            errorKey: 'required',
            message: 'Amount is required',
            amount: null
        }
    }

    const amount = parseCurrency(input)
    
    if (amount === 0 && input.trim() !== '0') {
        return {
            isValid: false,
            error: 'currency.errors.parseError',
            errorKey: 'parseError',
            message: 'Unable to parse currency amount',
            amount: null
        }
    }

    const validation = validateCurrency(amount, options)
    
    return {
        ...validation,
        amount: validation.isValid ? amount : null
    }
}

/**
 * Format large numbers with abbreviations (K, M, B, T)
 * @param {number} amount - The amount to format
 * @param {string} locale - Optional locale override
 * @returns {string} Abbreviated currency string
 */
export function formatCurrencyAbbreviated(amount, locale = null) {
    if (typeof amount !== 'number' || isNaN(amount)) {
        return formatCurrency(0, locale)
    }

    const currentLocale = locale || getCurrentLocale()
    
    // Abbreviation thresholds
    const abbreviations = [
        { threshold: 1000000000000, suffix: 'T' }, // Trillion
        { threshold: 1000000000, suffix: 'B' },    // Billion
        { threshold: 1000000, suffix: 'M' },       // Million
        { threshold: 1000, suffix: 'K' }           // Thousand
    ]

    for (const abbrev of abbreviations) {
        if (amount >= abbrev.threshold) {
            const abbreviated = amount / abbrev.threshold
            const formattedAbbrev = abbreviated.toLocaleString(currentLocale, {
                minimumFractionDigits: abbreviated < 10 ? 1 : 0,
                maximumFractionDigits: abbreviated < 10 ? 1 : 0
            })
            
            // Get currency symbol
            const currencyConfigs = {
                'en': '$',
                'ja': '¥',
                'es': '€',
                'fr': '€',
                'de': '€',
                'pt': 'R$'
            }
            
            const symbol = currencyConfigs[currentLocale] || '$'
            return `${symbol}${formattedAbbrev}${abbrev.suffix}`
        }
    }

    return formatCurrency(amount, locale)
}

/**
 * Calculate percentage change between two amounts
 * @param {number} oldAmount - Previous amount
 * @param {number} newAmount - Current amount
 * @returns {object} Change data with percentage and direction
 */
export function calculateCurrencyChange(oldAmount, newAmount) {
    if (typeof oldAmount !== 'number' || typeof newAmount !== 'number' || 
        isNaN(oldAmount) || isNaN(newAmount) || oldAmount === 0) {
        return {
            percentage: 0,
            direction: 'neutral',
            change: 0
        }
    }

    const change = newAmount - oldAmount
    const percentage = (change / oldAmount) * 100
    
    return {
        percentage: Math.abs(percentage),
        direction: change > 0 ? 'up' : change < 0 ? 'down' : 'neutral',
        change: change
    }
}

/**
 * Get currency symbol for current locale
 * @param {string} locale - Optional locale override
 * @returns {string} Currency symbol
 */
export function getCurrencySymbol(locale = null) {
    const currentLocale = locale || getCurrentLocale()
    
    const symbols = {
        'en': '$',
        'ja': '¥',
        'es': '€',
        'fr': '€',
        'de': '€',
        'pt': 'R$'
    }
    
    return symbols[currentLocale] || '$'
}

export default {
    formatCurrency,
    formatCurrencyNumber,
    formatCurrencyAbbreviated,
    parseCurrency,
    validateCurrency,
    validateCurrencyInput,
    calculateCurrencyChange,
    getCurrencySymbol,
    MAX_CURRENCY_VALUE
}