<template>
  <div
    :class="[
      'ios-card',
      `ios-card--${variant}`,
      {
        'ios-card--clickable': clickable,
        'ios-card--elevated': elevated
      }
    ]"
    @click="handleClick"
  >
    <div v-if="$slots.header" class="ios-card__header">
      <slot name="header" />
    </div>
    
    <div class="ios-card__content">
      <slot />
    </div>
    
    <div v-if="$slots.footer" class="ios-card__footer">
      <slot name="footer" />
    </div>
  </div>
</template>

<script setup>
import { defineEmits } from 'vue'

const props = defineProps({
  variant: {
    type: String,
    default: 'default',
    validator: (value) => ['default', 'filled', 'outlined', 'glass'].includes(value)
  },
  clickable: {
    type: Boolean,
    default: false
  },
  elevated: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['click'])

const handleClick = (event) => {
  if (props.clickable) {
    emit('click', event)
  }
}
</script>

<style scoped>
.ios-card {
  border-radius: 16px;
  overflow: hidden;
  transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

.ios-card--clickable {
  cursor: pointer;
}

.ios-card--clickable:hover {
  transform: translateY(-2px);
}

.ios-card--clickable:active {
  transform: scale(0.98);
}

/* Variants */
.ios-card--default {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(0, 0, 0, 0.1);
}

.ios-card--filled {
  background: #f2f2f7;
}

.ios-card--outlined {
  background: transparent;
  border: 1px solid rgba(0, 0, 0, 0.2);
}

.ios-card--glass {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.ios-card--elevated {
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
}

/* Content areas */
.ios-card__header {
  padding: 16px 20px 0;
}

.ios-card__content {
  padding: 20px;
}

.ios-card__footer {
  padding: 0 20px 16px;
}

/* When header exists, reduce content top padding */
.ios-card__header + .ios-card__content {
  padding-top: 16px;
}

/* When footer exists, reduce content bottom padding */
.ios-card__content:has(+ .ios-card__footer) {
  padding-bottom: 16px;
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .ios-card--default {
    background: rgba(28, 28, 30, 0.8);
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .ios-card--filled {
    background: #1c1c1e;
  }

  .ios-card--outlined {
    border: 1px solid rgba(255, 255, 255, 0.2);
  }

  .ios-card--glass {
    background: rgba(28, 28, 30, 0.3);
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .ios-card--elevated {
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
  }
}
</style>