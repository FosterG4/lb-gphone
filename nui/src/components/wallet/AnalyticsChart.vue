<template>
  <IOSCard variant="default" :elevated="true" class="analytics-chart">
    <template #header>
      <div class="analytics-chart__header">
        <h3 class="analytics-chart__title">{{ title }}</h3>
        <select v-model="selectedPeriod" class="analytics-chart__period">
          <option v-for="period in periods" :key="period.value" :value="period.value">
            {{ period.label }}
          </option>
        </select>
      </div>
    </template>

    <div class="analytics-chart__content">
      <!-- Chart Container -->
      <div class="analytics-chart__chart" ref="chartContainer">
        <svg :width="chartWidth" :height="chartHeight" class="analytics-chart__svg">
          <!-- Grid Lines -->
          <g class="analytics-chart__grid">
            <line
              v-for="(line, index) in gridLines"
              :key="`grid-${index}`"
              :x1="line.x1"
              :y1="line.y1"
              :x2="line.x2"
              :y2="line.y2"
              stroke="rgba(0, 0, 0, 0.1)"
              stroke-width="1"
            />
          </g>

          <!-- Chart Line -->
          <path
            v-if="chartType === 'line'"
            :d="linePath"
            fill="none"
            stroke="url(#gradient)"
            stroke-width="3"
            stroke-linecap="round"
            stroke-linejoin="round"
          />

          <!-- Chart Area -->
          <path
            v-if="chartType === 'area'"
            :d="areaPath"
            fill="url(#areaGradient)"
            opacity="0.3"
          />

          <!-- Chart Bars -->
          <g v-if="chartType === 'bar'" class="analytics-chart__bars">
            <rect
              v-for="(bar, index) in bars"
              :key="`bar-${index}`"
              :x="bar.x"
              :y="bar.y"
              :width="bar.width"
              :height="bar.height"
              :fill="bar.color"
              rx="4"
            />
          </g>

          <!-- Data Points -->
          <g v-if="showPoints" class="analytics-chart__points">
            <circle
              v-for="(point, index) in dataPoints"
              :key="`point-${index}`"
              :cx="point.x"
              :cy="point.y"
              r="4"
              fill="white"
              stroke="url(#gradient)"
              stroke-width="2"
              @mouseover="showTooltip(point, $event)"
              @mouseleave="hideTooltip"
            />
          </g>

          <!-- Gradients -->
          <defs>
            <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
              <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
            </linearGradient>
            <linearGradient id="areaGradient" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" style="stop-color:#667eea;stop-opacity:0.3" />
              <stop offset="100%" style="stop-color:#764ba2;stop-opacity:0.1" />
            </linearGradient>
          </defs>
        </svg>

        <!-- Tooltip -->
        <div
          v-if="tooltip.show"
          class="analytics-chart__tooltip"
          :style="{ left: tooltip.x + 'px', top: tooltip.y + 'px' }"
        >
          <div class="analytics-chart__tooltip-value">${{ tooltip.value }}</div>
          <div class="analytics-chart__tooltip-date">{{ tooltip.date }}</div>
        </div>
      </div>

      <!-- Legend -->
      <div v-if="showLegend" class="analytics-chart__legend">
        <div
          v-for="item in legendItems"
          :key="item.label"
          class="analytics-chart__legend-item"
        >
          <div
            class="analytics-chart__legend-color"
            :style="{ backgroundColor: item.color }"
          ></div>
          <span class="analytics-chart__legend-label">{{ item.label }}</span>
        </div>
      </div>
    </div>
  </IOSCard>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import IOSCard from '../ios/IOSCard.vue'

const props = defineProps({
  title: {
    type: String,
    default: 'Analytics'
  },
  data: {
    type: Array,
    default: () => []
  },
  chartType: {
    type: String,
    default: 'line',
    validator: (value) => ['line', 'area', 'bar'].includes(value)
  },
  showPoints: {
    type: Boolean,
    default: true
  },
  showLegend: {
    type: Boolean,
    default: false
  },
  periods: {
    type: Array,
    default: () => [
      { label: '7D', value: '7d' },
      { label: '1M', value: '1m' },
      { label: '3M', value: '3m' },
      { label: '1Y', value: '1y' }
    ]
  }
})

const emit = defineEmits(['period-change'])

const chartContainer = ref(null)
const selectedPeriod = ref('1m')
const tooltip = ref({
  show: false,
  x: 0,
  y: 0,
  value: 0,
  date: ''
})

const chartWidth = 320
const chartHeight = 200
const padding = { top: 20, right: 20, bottom: 20, left: 20 }

const processedData = computed(() => {
  if (!props.data.length) return []
  
  return props.data.map((item, index) => ({
    ...item,
    x: padding.left + (index * (chartWidth - padding.left - padding.right)) / (props.data.length - 1),
    y: padding.top + (chartHeight - padding.top - padding.bottom) * (1 - (item.value - minValue.value) / (maxValue.value - minValue.value))
  }))
})

const minValue = computed(() => {
  return Math.min(...props.data.map(d => d.value))
})

const maxValue = computed(() => {
  return Math.max(...props.data.map(d => d.value))
})

const gridLines = computed(() => {
  const lines = []
  const gridCount = 4
  
  // Horizontal lines
  for (let i = 0; i <= gridCount; i++) {
    const y = padding.top + (i * (chartHeight - padding.top - padding.bottom)) / gridCount
    lines.push({
      x1: padding.left,
      y1: y,
      x2: chartWidth - padding.right,
      y2: y
    })
  }
  
  return lines
})

const linePath = computed(() => {
  if (!processedData.value.length) return ''
  
  let path = `M ${processedData.value[0].x} ${processedData.value[0].y}`
  
  for (let i = 1; i < processedData.value.length; i++) {
    const point = processedData.value[i]
    path += ` L ${point.x} ${point.y}`
  }
  
  return path
})

const areaPath = computed(() => {
  if (!processedData.value.length) return ''
  
  let path = `M ${processedData.value[0].x} ${chartHeight - padding.bottom}`
  path += ` L ${processedData.value[0].x} ${processedData.value[0].y}`
  
  for (let i = 1; i < processedData.value.length; i++) {
    const point = processedData.value[i]
    path += ` L ${point.x} ${point.y}`
  }
  
  path += ` L ${processedData.value[processedData.value.length - 1].x} ${chartHeight - padding.bottom}`
  path += ' Z'
  
  return path
})

const bars = computed(() => {
  if (!processedData.value.length) return []
  
  const barWidth = (chartWidth - padding.left - padding.right) / processedData.value.length * 0.6
  
  return processedData.value.map((point, index) => ({
    x: point.x - barWidth / 2,
    y: point.y,
    width: barWidth,
    height: chartHeight - padding.bottom - point.y,
    color: `hsl(${240 + index * 10}, 70%, 60%)`
  }))
})

const dataPoints = computed(() => processedData.value)

const legendItems = computed(() => [
  { label: 'Income', color: '#30D158' },
  { label: 'Expenses', color: '#FF453A' }
])

const showTooltip = (point, event) => {
  const rect = chartContainer.value.getBoundingClientRect()
  tooltip.value = {
    show: true,
    x: event.clientX - rect.left + 10,
    y: event.clientY - rect.top - 10,
    value: point.value.toFixed(2),
    date: point.date || point.label
  }
}

const hideTooltip = () => {
  tooltip.value.show = false
}

watch(selectedPeriod, (newPeriod) => {
  emit('period-change', newPeriod)
})
</script>

<style scoped>
.analytics-chart {
  margin-bottom: 24px;
}

.analytics-chart__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.analytics-chart__title {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.analytics-chart__period {
  background: rgba(0, 122, 255, 0.1);
  border: 1px solid rgba(0, 122, 255, 0.2);
  border-radius: 8px;
  color: #007AFF;
  padding: 6px 12px;
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  font-size: 14px;
  font-weight: 500;
  outline: none;
  cursor: pointer;
}

.analytics-chart__content {
  position: relative;
}

.analytics-chart__chart {
  position: relative;
  overflow: hidden;
  border-radius: 12px;
}

.analytics-chart__svg {
  width: 100%;
  height: auto;
}

.analytics-chart__tooltip {
  position: absolute;
  background: rgba(0, 0, 0, 0.8);
  color: white;
  padding: 8px 12px;
  border-radius: 8px;
  font-size: 12px;
  pointer-events: none;
  z-index: 10;
  backdrop-filter: blur(10px);
}

.analytics-chart__tooltip-value {
  font-weight: 600;
  margin-bottom: 2px;
}

.analytics-chart__tooltip-date {
  font-size: 10px;
  opacity: 0.8;
}

.analytics-chart__legend {
  display: flex;
  justify-content: center;
  gap: 24px;
  margin-top: 16px;
}

.analytics-chart__legend-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.analytics-chart__legend-color {
  width: 12px;
  height: 12px;
  border-radius: 2px;
}

.analytics-chart__legend-label {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  font-size: 12px;
  font-weight: 500;
  color: #8e8e93;
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .analytics-chart__title {
    color: #f2f2f7;
  }

  .analytics-chart__period {
    background: rgba(10, 132, 255, 0.2);
    border: 1px solid rgba(10, 132, 255, 0.3);
    color: #0A84FF;
  }

  .analytics-chart__legend-label {
    color: #8e8e93;
  }
}
</style>