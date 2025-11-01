<template>
  <div class="setup-wizard-example">
    <h1>Setup Wizard Example</h1>
    
    <div v-if="!setupComplete" class="wizard-container">
      <SetupWizard @complete="handleSetupComplete" />
    </div>
    
    <div v-else class="completion-screen">
      <h2>Setup Complete!</h2>
      <div class="config-display">
        <h3>Configuration:</h3>
        <pre>{{ JSON.stringify(savedConfig, null, 2) }}</pre>
      </div>
      <button @click="resetSetup" class="reset-btn">
        Reset Setup
      </button>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue';
import SetupWizard from '../components/SetupWizard.vue';

export default {
  name: 'SetupWizardExample',
  components: {
    SetupWizard
  },
  setup() {
    const setupComplete = ref(false);
    const savedConfig = ref(null);

    const handleSetupComplete = (config) => {
      console.log('Setup completed with config:', config);
      savedConfig.value = config;
      setupComplete.value = true;
      
      // In a real implementation, you would send this to the server
      // fetch('https://phone/saveSetupConfig', {
      //   method: 'POST',
      //   body: JSON.stringify(config)
      // });
    };

    const resetSetup = () => {
      setupComplete.value = false;
      savedConfig.value = null;
    };

    return {
      setupComplete,
      savedConfig,
      handleSetupComplete,
      resetSetup
    };
  }
};
</script>

<style scoped>
.setup-wizard-example {
  width: 100vw;
  height: 100vh;
  background: #1a1a1a;
  color: white;
}

.wizard-container {
  width: 100%;
  height: 100%;
}

.completion-screen {
  padding: 40px;
  text-align: center;
}

.completion-screen h2 {
  font-size: 32px;
  margin-bottom: 24px;
  color: #4ade80;
}

.config-display {
  max-width: 800px;
  margin: 0 auto 24px;
  text-align: left;
}

.config-display h3 {
  font-size: 20px;
  margin-bottom: 16px;
}

.config-display pre {
  background: rgba(255, 255, 255, 0.1);
  padding: 20px;
  border-radius: 8px;
  overflow-x: auto;
  font-size: 14px;
  line-height: 1.6;
}

.reset-btn {
  background: #667eea;
  border: none;
  color: white;
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.reset-btn:hover {
  background: #5568d3;
  transform: translateY(-2px);
}
</style>
