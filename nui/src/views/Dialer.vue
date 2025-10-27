<template>
  <div class="dialer-view">
    <div class="dialer-header">
      <h2>Phone</h2>
    </div>
    
    <div class="number-display">
      <input 
        type="text" 
        v-model="dialedNumber" 
        placeholder="Enter number"
        class="number-input"
        readonly
      />
    </div>
    
    <div class="number-pad">
      <button 
        v-for="button in numberButtons" 
        :key="button.value"
        @click="addDigit(button.value)"
        class="pad-button"
      >
        <span class="digit">{{ button.value }}</span>
        <span v-if="button.letters" class="letters">{{ button.letters }}</span>
      </button>
      
      <button @click="addDigit('*')" class="pad-button">
        <span class="digit">*</span>
      </button>
      
      <button @click="addDigit('0')" class="pad-button">
        <span class="digit">0</span>
        <span class="letters">+</span>
      </button>
      
      <button @click="addDigit('#')" class="pad-button">
        <span class="digit">#</span>
      </button>
    </div>
    
    <div class="dialer-actions">
      <button 
        @click="clearDigit" 
        class="action-button backspace-btn"
        :disabled="dialedNumber.length === 0"
      >
        ⌫
      </button>
      
      <button 
        @click="initiateCall" 
        class="action-button call-btn"
        :disabled="dialedNumber.length === 0"
      >
        <span class="call-icon">📞</span>
      </button>
      
      <button 
        @click="clearAll" 
        class="action-button clear-btn"
        :disabled="dialedNumber.length === 0"
      >
        Clear
      </button>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useStore } from 'vuex'

export default {
  name: 'Dialer',
  
  setup() {
    const store = useStore()
    const dialedNumber = ref('')
    
    const numberButtons = [
      { value: '1', letters: '' },
      { value: '2', letters: 'ABC' },
      { value: '3', letters: 'DEF' },
      { value: '4', letters: 'GHI' },
      { value: '5', letters: 'JKL' },
      { value: '6', letters: 'MNO' },
      { value: '7', letters: 'PQRS' },
      { value: '8', letters: 'TUV' },
      { value: '9', letters: 'WXYZ' }
    ]
    
    const addDigit = (digit) => {
      if (dialedNumber.value.length < 20) {
        dialedNumber.value += digit
      }
    }
    
    const clearDigit = () => {
      dialedNumber.value = dialedNumber.value.slice(0, -1)
    }
    
    const clearAll = () => {
      dialedNumber.value = ''
    }
    
    const initiateCall = async () => {
      if (!dialedNumber.value.trim()) {
        return
      }
      
      const response = await store.dispatch('calls/initiateCall', dialedNumber.value.trim())
      
      if (response.success) {
        // Number will be cleared when call state changes
      } else {
        alert(response.message || 'Failed to initiate call')
      }
    }
    
    return {
      dialedNumber,
      numberButtons,
      addDigit,
      clearDigit,
      clearAll,
      initiateCall
    }
  }
}
</script>

<style scoped>
.dialer-view {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #000;
  color: #fff;
  padding: 20px;
}

.dialer-header {
  text-align: center;
  margin-bottom: 30px;
}

.dialer-header h2 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.number-display {
  margin-bottom: 30px;
}

.number-input {
  width: 100%;
  padding: 15px;
  background: #1c1c1e;
  border: 1px solid #333;
  border-radius: 10px;
  color: #fff;
  font-size: 28px;
  text-align: center;
  font-weight: 300;
  letter-spacing: 2px;
}

.number-input::placeholder {
  color: #666;
}

.number-pad {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 15px;
  margin-bottom: 20px;
}

.pad-button {
  aspect-ratio: 1;
  background: #1c1c1e;
  border: 1px solid #333;
  border-radius: 50%;
  color: #fff;
  font-size: 24px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  transition: background 0.2s;
}

.pad-button:hover {
  background: #2c2c2e;
}

.pad-button:active {
  background: #3c3c3e;
}

.digit {
  font-size: 28px;
  font-weight: 300;
}

.letters {
  font-size: 10px;
  color: #888;
  margin-top: 2px;
  letter-spacing: 1px;
}

.dialer-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 15px;
  margin-top: auto;
}

.action-button {
  padding: 15px 20px;
  border: none;
  border-radius: 10px;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;
  transition: opacity 0.2s;
}

.action-button:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.action-button:not(:disabled):hover {
  opacity: 0.8;
}

.backspace-btn {
  background: #444;
  color: white;
  flex: 1;
}

.call-btn {
  background: #34c759;
  color: white;
  flex: 2;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.call-icon {
  font-size: 20px;
}

.clear-btn {
  background: #ff3b30;
  color: white;
  flex: 1;
}
</style>
