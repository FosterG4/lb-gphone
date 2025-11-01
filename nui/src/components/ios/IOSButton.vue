<template>
  <button
    :class="[
      'ios-button',
      `ios-button--${variant}`,
      `ios-button--${size}`,
      {
        'ios-button--disabled': disabled,
        'ios-button--loading': loading,
        'ios-button--full-width': fullWidth
      }
    ]"
    :disabled="disabled || loading"
    @click="handleClick"
  >
    <div v-if="loading" class="ios-button__spinner">
      <div class="spinner"></div>
    </div>
    <div v-else class="ios-button__content">
      <slot name="icon" />
      <span v-if="$slots.default" class="ios-button__text">
        <slot />
      </span>
    </div>
  </button>
</template>

<script setup>
import { defineEmits } from 'vue'

const props = defineProps({
  variant: {
    type: String,
    default: 'primary',
    validator: (value) => ['primary', 'secondary', 'tertiary', 'destructive'].includes(value)
  },
  size: {
    type: String,
    default: 'medium',
    validator: (value) => ['small', 'medium', 'large'].includes(value)
  },
  disabled: {
    type: Boolean,
    default: false
  },
  loading: {
    type: Boolean,
    default: false
  },
  fullWidth: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['click'])

const handleClick = (event) => {
  if (!props.disabled && !props.loading) {
    emit('click', event)
  }
}
</script>

<style scoped>
.ios-button {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  border-radius: 12px;
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  user-select: none;
  outline: none;
}

.ios-button:active {
  transform: scale(0.96);
}

/* Variants */
.ios-button--primary {
  background: linear-gradient(135deg, #007AFF 0%, #0051D5 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(0, 122, 255, 0.3);
}

.ios-button--primary:hover {
  box-shadow: 0 6px 16px rgba(0, 122, 255, 0.4);
}

.ios-button--secondary {
  background: rgba(120, 120, 128, 0.16);
  color: #007AFF;
  backdrop-filter: blur(10px);
}

.ios-button--secondary:hover {
  background: rgba(120, 120, 128, 0.24);
}

.ios-button--tertiary {
  background: transparent;
  color: #007AFF;
}

.ios-button--tertiary:hover {
  background: rgba(0, 122, 255, 0.1);
}

.ios-button--destructive {
  background: linear-gradient(135deg, #FF3B30 0%, #D70015 100%);
  color: white;
  box-shadow: 0 4px 12px rgba(255, 59, 48, 0.3);
}

.ios-button--destructive:hover {
  box-shadow: 0 6px 16px rgba(255, 59, 48, 0.4);
}

/* Sizes */
.ios-button--small {
  padding: 8px 16px;
  font-size: 14px;
  min-height: 32px;
}

.ios-button--medium {
  padding: 12px 24px;
  font-size: 16px;
  min-height: 44px;
}

.ios-button--large {
  padding: 16px 32px;
  font-size: 18px;
  min-height: 52px;
}

/* States */
.ios-button--disabled {
  opacity: 0.4;
  cursor: not-allowed;
  transform: none !important;
}

.ios-button--loading {
  cursor: not-allowed;
}

.ios-button--full-width {
  width: 100%;
}

/* Content */
.ios-button__content {
  display: flex;
  align-items: center;
  gap: 8px;
}

.ios-button__text {
  line-height: 1;
}

/* Spinner */
.ios-button__spinner {
  display: flex;
  align-items: center;
  justify-content: center;
}

.spinner {
  width: 20px;
  height: 20px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top: 2px solid currentColor;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>