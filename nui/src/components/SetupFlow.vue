<template>
  <div class="setup-flow">
    <!-- Language Selection Screen -->
    <div v-if="currentStepName === 'language'" class="setup-screen">
      <div class="setup-content">
        <div class="logo-section">
          <div class="lb-logo">LB</div>
          <h1 class="setup-title">Hello</h1>
        </div>
        
        <div class="language-section">
          <div class="section-header">
            <GlobeIcon class="globe-icon" />
            <span>Select your language</span>
          </div>
          
          <div class="language-list">
            <div
              v-for="language in languages"
              :key="language.code"
              class="language-item"
              :class="{ selected: selectedLanguage === language.code }"
              @click="selectLanguage(language)"
            >
              <span class="language-name">{{ language.name }}</span>
              <ChevronRightIcon class="chevron-icon" />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- PIN Setup Screen -->
    <div v-if="currentStepName === 'pin'" class="setup-screen">
      <div class="setup-content">
        <button class="back-button" @click="prevStep">
          <ChevronLeftIcon />
        </button>
        
        <div class="pin-section">
          <div class="pin-icon">
            <LockIcon />
          </div>
          <h1 class="setup-title">Set a pin</h1>
          <p class="setup-subtitle">
            A pin code is used to secure your<br>
            device and is required to unlock it.
          </p>
          
          <div class="pin-dots">
            <div
              v-for="i in 4"
              :key="i"
              class="pin-dot"
              :class="{ filled: pin.length >= i }"
            ></div>
          </div>
          
          <button class="skip-button" @click="nextStep">Skip</button>
          
          <div class="keypad">
            <div
              v-for="number in [1,2,3,4,5,6,7,8,9,0]"
              :key="number"
              class="keypad-button"
              @click="addToPin(number.toString())"
            >
              <span class="number">{{ number }}</span>
              <span v-if="number === 2" class="letters">ABC</span>
              <span v-if="number === 3" class="letters">DEF</span>
              <span v-if="number === 4" class="letters">GHI</span>
              <span v-if="number === 5" class="letters">JKL</span>
              <span v-if="number === 6" class="letters">MNO</span>
              <span v-if="number === 7" class="letters">PQRS</span>
              <span v-if="number === 8" class="letters">TUV</span>
              <span v-if="number === 9" class="letters">WXYZ</span>
            </div>
            <div class="keypad-button" @click="removeFromPin">
              <BackspaceIcon />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Theme Selection Screen -->
    <div v-if="currentStepName === 'theme'" class="setup-screen">
      <div class="setup-content">
        <button class="back-button" @click="prevStep">
          <ChevronLeftIcon />
        </button>
        
        <div class="theme-section">
          <div class="theme-icon">
            <PaletteIcon />
          </div>
          <h1 class="setup-title">Theme</h1>
          <p class="setup-subtitle">
            Select a dark or light theme<br>
            for your device
          </p>
          
          <div class="theme-options">
            <div
              class="theme-option"
              :class="{ selected: selectedTheme === 'light' }"
              @click="selectTheme('light')"
            >
              <div class="theme-preview light-preview">
                <div class="preview-time">11:42</div>
                <div class="preview-content"></div>
              </div>
              <div class="theme-label">Light</div>
              <div class="theme-radio" :class="{ selected: selectedTheme === 'light' }"></div>
            </div>
            
            <div
              class="theme-option"
              :class="{ selected: selectedTheme === 'dark' }"
              @click="selectTheme('dark')"
            >
              <div class="theme-preview dark-preview">
                <div class="preview-time">11:42</div>
                <div class="preview-content"></div>
              </div>
              <div class="theme-label">Dark</div>
              <div class="theme-radio" :class="{ selected: selectedTheme === 'dark' }"></div>
            </div>
          </div>
          
          <button class="continue-button" @click="nextStep">Continue</button>
        </div>
      </div>
    </div>

    <!-- Welcome Screen -->
    <div v-if="currentStepName === 'welcome'" class="setup-screen">
      <div class="setup-content">
        <button class="back-button" @click="prevStep">
          <ChevronLeftIcon />
        </button>
        
        <div class="welcome-section">
          <h1 class="welcome-title">Welcome to LB Phone</h1>
          <button class="get-started-button" @click="completeSetup">
            Click to get started
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed } from "vue";
import { h } from "vue";

// Icons
const GlobeIcon = () =>
  h(
    "svg",
    {
      width: "20",
      height: "20",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zm6.93 6h-2.95c-.32-1.25-.78-2.45-1.38-3.56 1.84.63 3.37 1.91 4.33 3.56zM12 4.04c.83 1.2 1.48 2.53 1.91 3.96h-3.82c.43-1.43 1.08-2.76 1.91-3.96zM4.26 14C4.1 13.36 4 12.69 4 12s.1-1.36.26-2h3.38c-.08.66-.14 1.32-.14 2 0 .68.06 1.34.14 2H4.26zm.82 2h2.95c.32 1.25.78 2.45 1.38 3.56-1.84-.63-3.37-1.9-4.33-3.56zm2.95-8H5.08c.96-1.66 2.49-2.93 4.33-3.56C8.81 5.55 8.35 6.75 8.03 8zM12 19.96c-.83-1.2-1.48-2.53-1.91-3.96h3.82c-.43 1.43-1.08 2.76-1.91 3.96zM14.34 14H9.66c-.09-.66-.16-1.32-.16-2 0-.68.07-1.35.16-2h4.68c.09.65.16 1.32.16 2 0 .68-.07 1.34-.16 2zm.25 5.56c.6-1.11 1.06-2.31 1.38-3.56h2.95c-.96 1.65-2.49 2.93-4.33 3.56zM16.36 14c.08-.66.14-1.32.14-2 0-.68-.06-1.34-.14-2h3.38c.16.64.26 1.31.26 2s-.1 1.36-.26 2h-3.38z",
      }),
    ]
  );

const ChevronRightIcon = () =>
  h(
    "svg",
    {
      width: "20",
      height: "20",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M10 6L8.59 7.41 13.17 12l-4.58 4.59L10 18l6-6z",
      }),
    ]
  );

const ChevronLeftIcon = () =>
  h(
    "svg",
    {
      width: "24",
      height: "24",
      viewBox: "0 0 24 24",
      fill: "currentColor",
    },
    [
      h("path", {
        d: "M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z",
      }),
    ]
  );

// Define icon components
const LBIcon = () =>
  h(
    "svg",
    {
      width: "60",
      height: "60",
      viewBox: "0 0 100 100",
      fill: "none",
    },
    [
      h("rect", {
        width: "100",
        height: "100",
        rx: "20",
        fill: "url(#gradient)",
      }),
      h("text", {
        x: "50",
        y: "65",
        "text-anchor": "middle",
        fill: "white",
        "font-size": "36",
        "font-weight": "bold",
        "font-family": "system-ui",
      }, "LB"),
      h("defs", {}, [
        h("linearGradient", { id: "gradient", x1: "0%", y1: "0%", x2: "100%", y2: "100%" }, [
          h("stop", { offset: "0%", "stop-color": "#8B5CF6" }),
          h("stop", { offset: "100%", "stop-color": "#3B82F6" }),
        ]),
      ]),
    ]
  );

const BackspaceIcon = () =>
  h(
    "svg",
    {
      width: "24",
      height: "24",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": "2",
    },
    [
      h("path", {
        d: "M9 9l6 6m0-6l-6 6M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
      }),
    ]
  );

const PaletteIcon = () =>
  h(
    "svg",
    {
      width: "48",
      height: "48",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": "2",
    },
    [
      h("circle", { cx: "13.5", cy: "6.5", r: ".5" }),
      h("circle", { cx: "17.5", cy: "10.5", r: ".5" }),
      h("circle", { cx: "8.5", cy: "7.5", r: ".5" }),
      h("circle", { cx: "6.5", cy: "12.5", r: ".5" }),
      h("path", {
        d: "M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z",
      }),
    ]
  );

const LockIcon = () =>
  h(
    "svg",
    {
      width: "48",
      height: "48",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": "2",
    },
    [
      h("rect", { x: "3", y: "11", width: "18", height: "11", rx: "2", ry: "2" }),
      h("circle", { cx: "12", cy: "16", r: "1" }),
      h("path", { d: "M7 11V7a5 5 0 0 1 10 0v4" }),
    ]
  );

const CheckIcon = () =>
  h(
    "svg",
    {
      width: "24",
      height: "24",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": "3",
    },
    [
      h("polyline", { points: "20,6 9,17 4,12" }),
    ]
  );

export default {
  name: "SetupFlow",
  components: {
    LBIcon,
    BackspaceIcon,
    PaletteIcon,
    LockIcon,
    CheckIcon,
  },
  emits: ["setupComplete"],
  setup(props, { emit }) {
    const currentStep = ref(0);
    const selectedLanguage = ref("");
    const pin = ref("");
    const selectedTheme = ref("light");

    const languages = [
      { code: "en", name: "English" },
      { code: "de", name: "Deutsch" },
      { code: "fr", name: "Français" },
      { code: "es", name: "Español" },
      { code: "nl", name: "Nederlands" },
      { code: "da", name: "Dansk" },
      { code: "no", name: "Norsk" },
      { code: "ar", name: "العربية" },
    ];

    const steps = ["language", "pin", "theme", "welcome"];

    const currentStepName = computed(() => steps[currentStep.value]);

    const selectLanguage = (language) => {
      selectedLanguage.value = language.code;
      setTimeout(() => {
        nextStep();
      }, 300);
    };

    const addToPin = (digit) => {
      if (pin.value.length < 4) {
        pin.value += digit;
        if (pin.value.length === 4) {
          setTimeout(() => {
            nextStep();
          }, 500);
        }
      }
    };

    const removeFromPin = () => {
      pin.value = pin.value.slice(0, -1);
    };

    const selectTheme = (theme) => {
      selectedTheme.value = theme;
    };

    const nextStep = () => {
      if (currentStep.value < steps.length - 1) {
        currentStep.value++;
      }
    };

    const prevStep = () => {
      if (currentStep.value > 0) {
        currentStep.value--;
      }
    };

    const completeSetup = () => {
      const setupData = {
        language: selectedLanguage.value,
        pin: pin.value,
        theme: selectedTheme.value,
      };
      emit("setupComplete", setupData);
    };

    return {
      currentStep,
      currentStepName,
      selectedLanguage,
      pin,
      selectedTheme,
      languages,
      selectLanguage,
      addToPin,
      removeFromPin,
      selectTheme,
      nextStep,
      prevStep,
      completeSetup,
    };
  },
};
</script>

<style scoped>
.setup-flow {
  width: 100%;
  height: 100%;
  background: #f2f2f7;
  overflow: hidden;
}

.setup-screen {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateX(20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.setup-content {
  flex: 1;
  padding: 20px;
  display: flex;
  flex-direction: column;
}

.back-button {
  background: none;
  border: none;
  color: #007aff;
  cursor: pointer;
  padding: 8px;
  align-self: flex-start;
  margin-bottom: 20px;
  border-radius: 50%;
  transition: background 0.2s;
}

.back-button:hover {
  background: rgba(0, 122, 255, 0.1);
}

/* Language Selection */
.logo-section {
  text-align: center;
  margin: 40px 0 60px 0;
}

.lb-logo {
  width: 80px;
  height: 80px;
  background: linear-gradient(135deg, #8b5cf6, #a855f7);
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  font-weight: 700;
  color: white;
  margin: 0 auto 20px auto;
}

.setup-title {
  font-size: 32px;
  font-weight: 600;
  color: #1c1c1e;
  margin: 0;
}

.setup-subtitle {
  font-size: 16px;
  color: #8e8e93;
  margin: 8px 0 0 0;
  line-height: 1.4;
  text-align: center;
}

.language-section {
  flex: 1;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #8e8e93;
  font-size: 16px;
  margin-bottom: 20px;
}

.globe-icon {
  color: #8e8e93;
}

.language-list {
  display: flex;
  flex-direction: column;
  gap: 1px;
  background: #fff;
  border-radius: 12px;
  overflow: hidden;
}

.language-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  background: #fff;
  cursor: pointer;
  transition: background 0.2s;
}

.language-item:hover {
  background: #f8f8f8;
}

.language-item.selected {
  background: #e3f2fd;
}

.language-name {
  font-size: 16px;
  color: #1c1c1e;
  font-weight: 400;
}

.chevron-icon {
  color: #c7c7cc;
}

/* PIN Setup */
.pin-section {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.pin-icon {
  color: #8b5cf6;
  margin: 40px 0 20px 0;
}

.pin-dots {
  display: flex;
  gap: 16px;
  margin: 40px 0 20px 0;
}

.pin-dot {
  width: 16px;
  height: 16px;
  border: 2px solid #d1d1d6;
  border-radius: 50%;
  transition: all 0.2s;
}

.pin-dot.filled {
  background: #1c1c1e;
  border-color: #1c1c1e;
}

.skip-button {
  background: none;
  border: none;
  color: #007aff;
  font-size: 16px;
  cursor: pointer;
  padding: 8px 16px;
  margin-bottom: 40px;
  border-radius: 8px;
  transition: background 0.2s;
}

.skip-button:hover {
  background: rgba(0, 122, 255, 0.1);
}

.keypad {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  max-width: 280px;
  width: 100%;
}

.keypad-button {
  width: 80px;
  height: 80px;
  background: #fff;
  border: none;
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.keypad-button:hover {
  background: #f8f8f8;
  transform: scale(1.05);
}

.keypad-button:active {
  transform: scale(0.95);
}

.keypad-button .number {
  font-size: 24px;
  font-weight: 400;
  color: #1c1c1e;
  line-height: 1;
}

.keypad-button .letters {
  font-size: 10px;
  color: #8e8e93;
  font-weight: 500;
  margin-top: 2px;
}

.keypad-button:nth-child(10) {
  grid-column: 2;
}

.keypad-button:nth-child(11) {
  grid-column: 3;
  color: #8e8e93;
}

/* Theme Selection */
.theme-section {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.theme-icon {
  color: #8b5cf6;
  margin: 40px 0 20px 0;
}

.theme-options {
  display: flex;
  gap: 20px;
  margin: 40px 0;
}

.theme-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  cursor: pointer;
  transition: transform 0.2s;
}

.theme-option:hover {
  transform: scale(1.02);
}

.theme-preview {
  width: 120px;
  height: 200px;
  border-radius: 20px;
  position: relative;
  overflow: hidden;
  margin-bottom: 12px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
}

.light-preview {
  background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%);
}

.dark-preview {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.preview-time {
  position: absolute;
  top: 16px;
  left: 50%;
  transform: translateX(-50%);
  font-size: 14px;
  font-weight: 600;
  color: white;
}

.preview-content {
  position: absolute;
  bottom: 20px;
  left: 20px;
  right: 20px;
  height: 60px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 12px;
  backdrop-filter: blur(10px);
}

.theme-label {
  font-size: 16px;
  color: #1c1c1e;
  font-weight: 500;
  margin-bottom: 8px;
}

.theme-radio {
  width: 20px;
  height: 20px;
  border: 2px solid #d1d1d6;
  border-radius: 50%;
  position: relative;
  transition: all 0.2s;
}

.theme-radio.selected {
  border-color: #007aff;
}

.theme-radio.selected::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 10px;
  height: 10px;
  background: #007aff;
  border-radius: 50%;
}

.continue-button {
  background: #007aff;
  border: none;
  color: white;
  font-size: 16px;
  font-weight: 600;
  padding: 16px 32px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
  margin-top: auto;
  margin-bottom: 40px;
}

.continue-button:hover {
  background: #0056cc;
  transform: translateY(-1px);
}

/* Welcome Screen */
.welcome-section {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
}

.welcome-title {
  font-size: 28px;
  font-weight: 600;
  color: #1c1c1e;
  margin: 0 0 60px 0;
}

.get-started-button {
  background: none;
  border: none;
  color: #8e8e93;
  font-size: 16px;
  cursor: pointer;
  padding: 16px 24px;
  border-radius: 8px;
  transition: all 0.2s;
  position: absolute;
  bottom: 60px;
  left: 50%;
  transform: translateX(-50%);
}

.get-started-button:hover {
  background: rgba(142, 142, 147, 0.1);
  color: #1c1c1e;
}

/* Responsive design */
@media (max-width: 1600px) and (max-height: 900px) {
  .setup-content {
    padding: 18px;
  }

  .lb-logo {
    width: 70px;
    height: 70px;
    font-size: 28px;
  }

  .setup-title {
    font-size: 28px;
  }

  .keypad-button {
    width: 70px;
    height: 70px;
  }

  .theme-preview {
    width: 100px;
    height: 180px;
  }
}

@media (max-width: 1366px) and (max-height: 768px) {
  .setup-content {
    padding: 16px;
  }

  .logo-section {
    margin: 30px 0 40px 0;
  }

  .lb-logo {
    width: 60px;
    height: 60px;
    font-size: 24px;
  }

  .setup-title {
    font-size: 24px;
  }

  .setup-subtitle {
    font-size: 14px;
  }

  .keypad {
    gap: 16px;
    max-width: 240px;
  }

  .keypad-button {
    width: 60px;
    height: 60px;
  }

  .keypad-button .number {
    font-size: 20px;
  }

  .keypad-button .letters {
    font-size: 9px;
  }

  .theme-preview {
    width: 90px;
    height: 160px;
  }

  .welcome-title {
    font-size: 24px;
  }
}
</style>