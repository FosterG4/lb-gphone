<template>
  <div class="setup-wizard">
    <!-- Progress Indicator -->
    <div class="wizard-progress">
      <div
        v-for="(step, index) in steps"
        :key="index"
        class="progress-step"
        :class="{
          active: currentStep === index,
          completed: currentStep > index
        }"
      >
        <div class="step-circle">
          <CheckIcon v-if="currentStep > index" class="check-icon" />
          <span v-else>{{ index + 1 }}</span>
        </div>
        <span class="step-label">{{ step.label }}</span>
      </div>
    </div>

    <!-- Step Content -->
    <div class="wizard-content">
      <!-- Step 1: Language Selection -->
      <div v-if="currentStep === 0" class="wizard-step">
        <div class="step-header">
          <GlobeIcon class="step-icon" />
          <h2 class="step-title">Select Default Language</h2>
          <p class="step-description">
            Choose the default language for your phone system. Players can change this in their settings.
          </p>
        </div>

        <div class="language-grid">
          <div
            v-for="locale in availableLocales"
            :key="locale.code"
            class="language-card"
            :class="{ selected: config.locale === locale.code }"
            @click="selectLanguage(locale.code)"
          >
            <div class="language-flag">{{ locale.flag }}</div>
            <div class="language-name">{{ locale.name }}</div>
            <div class="language-native">{{ locale.nativeName }}</div>
          </div>
        </div>
      </div>

      <!-- Step 2: Currency Selection -->
      <div v-if="currentStep === 1" class="wizard-step">
        <div class="step-header">
          <CurrencyIcon class="step-icon" />
          <h2 class="step-title">Configure Currency</h2>
          <p class="step-description">
            Set up currency formatting for your server. Maximum supported value: 999,000,000,000,000
          </p>
        </div>

        <div class="currency-config">
          <div class="config-section">
            <label class="config-label">Currency Symbol</label>
            <input
              v-model="config.currency.symbol"
              type="text"
              class="config-input"
              placeholder="$"
              maxlength="5"
            />
          </div>

          <div class="config-section">
            <label class="config-label">Symbol Position</label>
            <div class="radio-group">
              <label class="radio-option">
                <input
                  v-model="config.currency.position"
                  type="radio"
                  value="before"
                />
                <span>Before ($100)</span>
              </label>
              <label class="radio-option">
                <input
                  v-model="config.currency.position"
                  type="radio"
                  value="after"
                />
                <span>After (100$)</span>
              </label>
            </div>
          </div>

          <div class="config-section">
            <label class="config-label">Decimal Places</label>
            <input
              v-model.number="config.currency.decimalPlaces"
              type="number"
              class="config-input"
              min="0"
              max="8"
            />
          </div>

          <div class="config-section">
            <label class="config-label">Thousands Separator</label>
            <select v-model="config.currency.thousandsSeparator" class="config-select">
              <option value=",">Comma (,)</option>
              <option value=".">Period (.)</option>
              <option value=" ">Space ( )</option>
              <option value="">None</option>
            </select>
          </div>

          <div class="config-section">
            <label class="config-label">Decimal Separator</label>
            <select v-model="config.currency.decimalSeparator" class="config-select">
              <option value=".">Period (.)</option>
              <option value=",">Comma (,)</option>
            </select>
          </div>

          <div class="currency-preview">
            <div class="preview-label">Preview:</div>
            <div class="preview-value">{{ formatPreviewCurrency(1234567.89) }}</div>
          </div>
        </div>
      </div>

      <!-- Step 3: Feature Selection -->
      <div v-if="currentStep === 2" class="wizard-step">
        <div class="step-header">
          <AppsIcon class="step-icon" />
          <h2 class="step-title">Enable Features</h2>
          <p class="step-description">
            Select which apps and features to enable on your phone system
          </p>
        </div>

        <div class="feature-categories">
          <div
            v-for="category in featureCategories"
            :key="category.name"
            class="feature-category"
          >
            <div class="category-header">
              <h3 class="category-title">{{ category.name }}</h3>
              <button
                class="toggle-all-btn"
                @click="toggleCategory(category)"
              >
                {{ isCategoryEnabled(category) ? 'Disable All' : 'Enable All' }}
              </button>
            </div>

            <div class="feature-list">
              <label
                v-for="feature in category.features"
                :key="feature.key"
                class="feature-item"
              >
                <input
                  v-model="config.enabledApps[feature.key]"
                  type="checkbox"
                  class="feature-checkbox"
                />
                <div class="feature-info">
                  <span class="feature-name">{{ feature.name }}</span>
                  <span class="feature-description">{{ feature.description }}</span>
                </div>
              </label>
            </div>
          </div>
        </div>
      </div>

      <!-- Step 4: Review & Complete -->
      <div v-if="currentStep === 3" class="wizard-step">
        <div class="step-header">
          <CheckCircleIcon class="step-icon success" />
          <h2 class="step-title">Review Configuration</h2>
          <p class="step-description">
            Review your settings before completing the setup
          </p>
        </div>

        <div class="review-sections">
          <div class="review-section">
            <h3 class="review-title">Language</h3>
            <div class="review-value">
              {{ getLocaleName(config.locale) }}
            </div>
          </div>

          <div class="review-section">
            <h3 class="review-title">Currency</h3>
            <div class="review-value">
              Symbol: {{ config.currency.symbol }}<br />
              Position: {{ config.currency.position }}<br />
              Format: {{ formatPreviewCurrency(1234567.89) }}
            </div>
          </div>

          <div class="review-section">
            <h3 class="review-title">Enabled Features</h3>
            <div class="review-value">
              {{ enabledFeaturesCount }} of {{ totalFeaturesCount }} features enabled
            </div>
          </div>
        </div>

        <div class="completion-message">
          <p>Click "Complete Setup" to save your configuration and start using the phone system.</p>
        </div>
      </div>
    </div>

    <!-- Navigation Buttons -->
    <div class="wizard-navigation">
      <button
        v-if="currentStep > 0"
        class="nav-btn btn-secondary"
        @click="previousStep"
      >
        <ChevronLeftIcon />
        Previous
      </button>
      <div class="nav-spacer"></div>
      <button
        v-if="currentStep < steps.length - 1"
        class="nav-btn btn-primary"
        @click="nextStep"
      >
        Next
        <ChevronRightIcon />
      </button>
      <button
        v-if="currentStep === steps.length - 1"
        class="nav-btn btn-success"
        @click="completeSetup"
      >
        <CheckIcon />
        Complete Setup
      </button>
    </div>
  </div>
</template>

<script>
import { ref, computed, h } from 'vue';

// Icon Components
const GlobeIcon = () =>
  h('svg', { width: '48', height: '48', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
    h('circle', { cx: '12', cy: '12', r: '10' }),
    h('line', { x1: '2', y1: '12', x2: '22', y2: '12' }),
    h('path', { d: 'M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z' })
  ]);

const CurrencyIcon = () =>
  h('svg', { width: '48', height: '48', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
    h('line', { x1: '12', y1: '1', x2: '12', y2: '23' }),
    h('path', { d: 'M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6' })
  ]);

const AppsIcon = () =>
  h('svg', { width: '48', height: '48', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
    h('rect', { x: '3', y: '3', width: '7', height: '7' }),
    h('rect', { x: '14', y: '3', width: '7', height: '7' }),
    h('rect', { x: '14', y: '14', width: '7', height: '7' }),
    h('rect', { x: '3', y: '14', width: '7', height: '7' })
  ]);

const CheckCircleIcon = () =>
  h('svg', { width: '48', height: '48', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
    h('path', { d: 'M22 11.08V12a10 10 0 1 1-5.93-9.14' }),
    h('polyline', { points: '22 4 12 14.01 9 11.01' })
  ]);

const CheckIcon = () =>
  h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '3' }, [
    h('polyline', { points: '20 6 9 17 4 12' })
  ]);

const ChevronLeftIcon = () =>
  h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
    h('polyline', { points: '15 18 9 12 15 6' })
  ]);

const ChevronRightIcon = () =>
  h('svg', { width: '20', height: '20', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
    h('polyline', { points: '9 18 15 12 9 6' })
  ]);

export default {
  name: 'SetupWizard',
  components: {
    GlobeIcon,
    CurrencyIcon,
    AppsIcon,
    CheckCircleIcon,
    CheckIcon,
    ChevronLeftIcon,
    ChevronRightIcon
  },
  emits: ['complete'],
  setup(props, { emit }) {
    const currentStep = ref(0);

    const steps = [
      { label: 'Language' },
      { label: 'Currency' },
      { label: 'Features' },
      { label: 'Review' }
    ];

    const availableLocales = [
      { code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸' },
      { code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵' },
      { code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸' },
      { code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷' },
      { code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪' },
      { code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇧🇷' }
    ];

    const config = ref({
      locale: 'en',
      currency: {
        symbol: '$',
        position: 'before',
        decimalPlaces: 2,
        thousandsSeparator: ',',
        decimalSeparator: '.'
      },
      enabledApps: {
        // Core Communication
        contacts: true,
        messages: true,
        dialer: true,
        // Media
        camera: true,
        photos: true,
        voice_recorder: true,
        // Utilities
        settings: true,
        clock: true,
        notes: true,
        maps: true,
        weather: true,
        appstore: true,
        // Vehicle & Property
        garage: true,
        home: true,
        // Social Media
        shotz: true,
        chirper: true,
        modish: true,
        flicker: true,
        // Commerce
        marketplace: true,
        pages: true,
        // Finance
        wallet: true,
        crypto: true,
        cryptox: true,
        // Entertainment
        musicly: true,
        // Safety
        finder: true,
        safezone: true,
        // Productivity
        voicerecorder: true
      }
    });

    const featureCategories = [
      {
        name: 'Core Communication',
        features: [
          { key: 'contacts', name: 'Contacts', description: 'Manage contact list' },
          { key: 'messages', name: 'Messages', description: 'Send and receive SMS' },
          { key: 'dialer', name: 'Phone', description: 'Make voice calls' }
        ]
      },
      {
        name: 'Media',
        features: [
          { key: 'camera', name: 'Camera', description: 'Capture photos and videos' },
          { key: 'photos', name: 'Photos', description: 'View and organize media' },
          { key: 'voice_recorder', name: 'Voice Recorder', description: 'Record audio memos' }
        ]
      },
      {
        name: 'Utilities',
        features: [
          { key: 'settings', name: 'Settings', description: 'Configure phone settings' },
          { key: 'clock', name: 'Clock', description: 'Alarms, timers, stopwatch' },
          { key: 'notes', name: 'Notes', description: 'Create and manage notes' },
          { key: 'maps', name: 'Maps', description: 'Navigation and location sharing' },
          { key: 'weather', name: 'Weather', description: 'Weather forecasts' },
          { key: 'appstore', name: 'App Store', description: 'Browse and install apps' }
        ]
      },
      {
        name: 'Vehicle & Property',
        features: [
          { key: 'garage', name: 'Garage', description: 'Manage vehicles and valet' },
          { key: 'home', name: 'Home', description: 'Property and key management' }
        ]
      },
      {
        name: 'Social Media',
        features: [
          { key: 'shotz', name: 'Shotz', description: 'Photo and video sharing' },
          { key: 'chirper', name: 'Chirper', description: 'Social microblogging' },
          { key: 'modish', name: 'Modish', description: 'Short video platform' },
          { key: 'flicker', name: 'Flicker', description: 'Dating and matching' }
        ]
      },
      {
        name: 'Commerce',
        features: [
          { key: 'marketplace', name: 'Marketplace', description: 'Buy and sell items' },
          { key: 'pages', name: 'Pages', description: 'Business profiles' }
        ]
      },
      {
        name: 'Finance',
        features: [
          { key: 'wallet', name: 'Wallet', description: 'Banking and transactions' },
          { key: 'crypto', name: 'Crypto', description: 'Basic cryptocurrency trading' },
          { key: 'cryptox', name: 'CryptoX', description: 'Advanced crypto trading' }
        ]
      },
      {
        name: 'Entertainment & Safety',
        features: [
          { key: 'musicly', name: 'Musicly', description: 'Music streaming' },
          { key: 'finder', name: 'Finder', description: 'Device locator' },
          { key: 'safezone', name: 'SafeZone', description: 'Emergency services' }
        ]
      }
    ];

    const selectLanguage = (code) => {
      config.value.locale = code;
      
      // Update currency defaults based on locale
      const currencyDefaults = {
        en: { symbol: '$', position: 'before', decimalPlaces: 2, thousandsSeparator: ',', decimalSeparator: '.' },
        ja: { symbol: '¥', position: 'before', decimalPlaces: 0, thousandsSeparator: ',', decimalSeparator: '.' },
        es: { symbol: '€', position: 'after', decimalPlaces: 2, thousandsSeparator: '.', decimalSeparator: ',' },
        fr: { symbol: '€', position: 'after', decimalPlaces: 2, thousandsSeparator: ' ', decimalSeparator: ',' },
        de: { symbol: '€', position: 'after', decimalPlaces: 2, thousandsSeparator: '.', decimalSeparator: ',' },
        pt: { symbol: 'R$', position: 'before', decimalPlaces: 2, thousandsSeparator: '.', decimalSeparator: ',' }
      };
      
      if (currencyDefaults[code]) {
        config.value.currency = { ...currencyDefaults[code] };
      }
    };

    const formatPreviewCurrency = (amount) => {
      const { symbol, position, decimalPlaces, thousandsSeparator, decimalSeparator } = config.value.currency;
      
      // Format the number
      let formatted = amount.toFixed(decimalPlaces);
      
      // Split into integer and decimal parts
      const parts = formatted.split('.');
      let integerPart = parts[0];
      const decimalPart = parts[1];
      
      // Add thousands separator
      if (thousandsSeparator) {
        integerPart = integerPart.replace(/\B(?=(\d{3})+(?!\d))/g, thousandsSeparator);
      }
      
      // Combine with decimal separator
      formatted = decimalPlaces > 0 ? `${integerPart}${decimalSeparator}${decimalPart}` : integerPart;
      
      // Add currency symbol
      return position === 'before' ? `${symbol}${formatted}` : `${formatted} ${symbol}`;
    };

    const toggleCategory = (category) => {
      const isEnabled = isCategoryEnabled(category);
      category.features.forEach(feature => {
        config.value.enabledApps[feature.key] = !isEnabled;
      });
    };

    const isCategoryEnabled = (category) => {
      return category.features.every(feature => config.value.enabledApps[feature.key]);
    };

    const getLocaleName = (code) => {
      const locale = availableLocales.find(l => l.code === code);
      return locale ? `${locale.name} (${locale.nativeName})` : code;
    };

    const enabledFeaturesCount = computed(() => {
      return Object.values(config.value.enabledApps).filter(Boolean).length;
    });

    const totalFeaturesCount = computed(() => {
      return Object.keys(config.value.enabledApps).length;
    });

    const nextStep = () => {
      if (currentStep.value < steps.length - 1) {
        currentStep.value++;
      }
    };

    const previousStep = () => {
      if (currentStep.value > 0) {
        currentStep.value--;
      }
    };

    const completeSetup = () => {
      emit('complete', config.value);
    };

    return {
      currentStep,
      steps,
      availableLocales,
      config,
      featureCategories,
      selectLanguage,
      formatPreviewCurrency,
      toggleCategory,
      isCategoryEnabled,
      getLocaleName,
      enabledFeaturesCount,
      totalFeaturesCount,
      nextStep,
      previousStep,
      completeSetup
    };
  }
};
</script>

<style scoped>
.setup-wizard {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  overflow: hidden;
}

/* Progress Indicator */
.wizard-progress {
  display: flex;
  justify-content: space-between;
  padding: 30px 40px 20px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.progress-step {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  flex: 1;
  position: relative;
}

.progress-step:not(:last-child)::after {
  content: '';
  position: absolute;
  top: 20px;
  left: 50%;
  width: 100%;
  height: 2px;
  background: rgba(255, 255, 255, 0.3);
  z-index: 0;
}

.progress-step.completed:not(:last-child)::after {
  background: rgba(255, 255, 255, 0.8);
}

.step-circle {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 16px;
  position: relative;
  z-index: 1;
  transition: all 0.3s;
}

.progress-step.active .step-circle {
  background: white;
  color: #667eea;
  box-shadow: 0 4px 12px rgba(255, 255, 255, 0.3);
}

.progress-step.completed .step-circle {
  background: rgba(255, 255, 255, 0.9);
  color: #667eea;
}

.check-icon {
  color: #667eea;
}

.step-label {
  font-size: 12px;
  font-weight: 500;
  opacity: 0.7;
  transition: opacity 0.3s;
}

.progress-step.active .step-label {
  opacity: 1;
  font-weight: 600;
}

/* Wizard Content */
.wizard-content {
  flex: 1;
  overflow-y: auto;
  padding: 40px;
}

.wizard-step {
  max-width: 800px;
  margin: 0 auto;
  animation: fadeIn 0.4s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.step-header {
  text-align: center;
  margin-bottom: 40px;
}

.step-icon {
  color: white;
  margin-bottom: 20px;
  filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.2));
}

.step-icon.success {
  color: #4ade80;
}

.step-title {
  font-size: 32px;
  font-weight: 700;
  margin: 0 0 12px 0;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.step-description {
  font-size: 16px;
  opacity: 0.9;
  margin: 0;
  line-height: 1.5;
}

/* Language Selection */
.language-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
}

.language-card {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(10px);
  border: 2px solid transparent;
  border-radius: 16px;
  padding: 24px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
}

.language-card:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
}

.language-card.selected {
  background: rgba(255, 255, 255, 0.25);
  border-color: white;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.language-flag {
  font-size: 48px;
  margin-bottom: 12px;
}

.language-name {
  display: block;
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 4px;
}

.language-native {
  display: block;
  font-size: 14px;
  opacity: 0.8;
}

/* Currency Configuration */
.currency-config {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(10px);
  border-radius: 16px;
  padding: 32px;
}

.config-section {
  margin-bottom: 24px;
}

.config-section:last-child {
  margin-bottom: 0;
}

.config-label {
  display: block;
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 8px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.config-input,
.config-select {
  width: 100%;
  padding: 12px 16px;
  background: rgba(255, 255, 255, 0.2);
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 8px;
  color: white;
  font-size: 16px;
  transition: all 0.3s;
}

.config-input:focus,
.config-select:focus {
  outline: none;
  background: rgba(255, 255, 255, 0.25);
  border-color: white;
}

.config-input::placeholder {
  color: rgba(255, 255, 255, 0.5);
}

.radio-group {
  display: flex;
  gap: 16px;
}

.radio-option {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px;
  background: rgba(255, 255, 255, 0.2);
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.radio-option:hover {
  background: rgba(255, 255, 255, 0.25);
}

.radio-option input[type="radio"] {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.currency-preview {
  margin-top: 32px;
  padding: 24px;
  background: rgba(255, 255, 255, 0.25);
  border-radius: 12px;
  text-align: center;
}

.preview-label {
  font-size: 14px;
  font-weight: 600;
  margin-bottom: 8px;
  opacity: 0.8;
}

.preview-value {
  font-size: 32px;
  font-weight: 700;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

/* Feature Selection */
.feature-categories {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.feature-category {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(10px);
  border-radius: 16px;
  padding: 24px;
}

.category-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 16px;
  border-bottom: 2px solid rgba(255, 255, 255, 0.2);
}

.category-title {
  font-size: 18px;
  font-weight: 700;
  margin: 0;
}

.toggle-all-btn {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: white;
  padding: 8px 16px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.toggle-all-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.feature-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.feature-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 12px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.feature-item:hover {
  background: rgba(255, 255, 255, 0.15);
}

.feature-checkbox {
  width: 20px;
  height: 20px;
  margin-top: 2px;
  cursor: pointer;
}

.feature-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.feature-name {
  font-size: 16px;
  font-weight: 600;
}

.feature-description {
  font-size: 14px;
  opacity: 0.8;
}

/* Review Section */
.review-sections {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.review-section {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(10px);
  border-radius: 16px;
  padding: 24px;
}

.review-title {
  font-size: 18px;
  font-weight: 700;
  margin: 0 0 12px 0;
  padding-bottom: 12px;
  border-bottom: 2px solid rgba(255, 255, 255, 0.2);
}

.review-value {
  font-size: 16px;
  line-height: 1.6;
  opacity: 0.9;
}

.completion-message {
  margin-top: 32px;
  padding: 24px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 12px;
  text-align: center;
}

.completion-message p {
  margin: 0;
  font-size: 16px;
  line-height: 1.6;
}

/* Navigation */
.wizard-navigation {
  display: flex;
  gap: 16px;
  padding: 24px 40px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.nav-spacer {
  flex: 1;
}

.nav-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 14px 28px;
  border: none;
  border-radius: 12px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-secondary {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.btn-secondary:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.btn-primary {
  background: white;
  color: #667eea;
}

.btn-primary:hover {
  background: rgba(255, 255, 255, 0.95);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.btn-success {
  background: #4ade80;
  color: white;
}

.btn-success:hover {
  background: #22c55e;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

/* Responsive Design */
@media (max-width: 1600px) and (max-height: 900px) {
  .wizard-progress {
    padding: 24px 32px 16px;
  }

  .wizard-content {
    padding: 32px;
  }

  .step-title {
    font-size: 28px;
  }

  .language-grid {
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 16px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .wizard-progress {
    padding: 20px 24px 12px;
  }

  .step-circle {
    width: 36px;
    height: 36px;
    font-size: 14px;
  }

  .step-label {
    font-size: 11px;
  }

  .wizard-content {
    padding: 24px;
  }

  .step-title {
    font-size: 24px;
  }

  .step-description {
    font-size: 14px;
  }

  .language-grid {
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 12px;
  }

  .language-card {
    padding: 20px;
  }

  .language-flag {
    font-size: 40px;
  }
}

/* Scrollbar Styling */
.wizard-content::-webkit-scrollbar {
  width: 8px;
}

.wizard-content::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 4px;
}

.wizard-content::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.3);
  border-radius: 4px;
}

.wizard-content::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.4);
}
</style>
