<template>
  <Teleport to="body">
    <Transition name="modal" appear>
      <div v-if="modelValue" class="ios-modal-overlay" @click="handleOverlayClick">
        <div class="ios-modal" :class="modalClasses" @click.stop>
          <!-- Header -->
          <div v-if="showHeader" class="ios-modal__header">
            <button
              v-if="showCloseButton"
              class="ios-modal__close"
              @click="handleClose"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M18 6L6 18M6 6l12 12" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
              </svg>
            </button>
            <h2 v-if="title" class="ios-modal__title">{{ title }}</h2>
            <div class="ios-modal__actions">
              <slot name="header-actions" />
            </div>
          </div>

          <!-- Content -->
          <div class="ios-modal__content">
            <slot />
          </div>

          <!-- Footer -->
          <div v-if="$slots.footer" class="ios-modal__footer">
            <slot name="footer" />
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { computed, watch } from 'vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  title: {
    type: String,
    default: ''
  },
  size: {
    type: String,
    default: 'medium',
    validator: (value) => ['small', 'medium', 'large', 'fullscreen'].includes(value)
  },
  showHeader: {
    type: Boolean,
    default: true
  },
  showCloseButton: {
    type: Boolean,
    default: true
  },
  closeOnOverlay: {
    type: Boolean,
    default: true
  },
  persistent: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue', 'close'])

const modalClasses = computed(() => [
  `ios-modal--${props.size}`
])

const handleClose = () => {
  if (!props.persistent) {
    emit('update:modelValue', false)
    emit('close')
  }
}

const handleOverlayClick = () => {
  if (props.closeOnOverlay) {
    handleClose()
  }
}

// Prevent body scroll when modal is open
watch(() => props.modelValue, (isOpen) => {
  if (isOpen) {
    document.body.style.overflow = 'hidden'
  } else {
    document.body.style.overflow = ''
  }
})
</script>

<style scoped>
.ios-modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(10px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.ios-modal {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  border-radius: 20px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

/* Sizes */
.ios-modal--small {
  width: 100%;
  max-width: 320px;
}

.ios-modal--medium {
  width: 100%;
  max-width: 480px;
}

.ios-modal--large {
  width: 100%;
  max-width: 640px;
}

.ios-modal--fullscreen {
  width: 100%;
  height: 100%;
  max-width: none;
  max-height: none;
  border-radius: 0;
}

/* Header */
.ios-modal__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px 16px;
  border-bottom: 1px solid rgba(0, 0, 0, 0.1);
  position: relative;
}

.ios-modal__close {
  position: absolute;
  left: 20px;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  color: #007AFF;
  cursor: pointer;
  padding: 4px;
  border-radius: 8px;
  transition: background-color 0.2s;
}

.ios-modal__close:hover {
  background: rgba(0, 122, 255, 0.1);
}

.ios-modal__title {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
  text-align: center;
  flex: 1;
}

.ios-modal__actions {
  position: absolute;
  right: 20px;
  top: 50%;
  transform: translateY(-50%);
}

/* Content */
.ios-modal__content {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
}

/* Footer */
.ios-modal__footer {
  padding: 16px 24px 24px;
  border-top: 1px solid rgba(0, 0, 0, 0.1);
}

/* Transitions */
.modal-enter-active,
.modal-leave-active {
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-from .ios-modal,
.modal-leave-to .ios-modal {
  transform: scale(0.9) translateY(20px);
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .ios-modal {
    background: rgba(28, 28, 30, 0.95);
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .ios-modal__title {
    color: #f2f2f7;
  }

  .ios-modal__header,
  .ios-modal__footer {
    border-color: rgba(255, 255, 255, 0.1);
  }
}
</style>