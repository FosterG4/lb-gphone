<template>
  <div class="analytics-page">
    <!-- Period Selection -->
    <div class="period-selector">
      <button
        v-for="period in periods"
        :key="period.value"
        @click="selectedPeriod = period.value"
        class="period-btn"
        :class="{ active: selectedPeriod === period.value }"
      >
        {{ period.label }}
      </button>
    </div>

    <!-- Overview Cards -->
    <div class="overview-cards">
      <IOSCard variant="glass" class="overview-card income">
        <template #content>
          <div class="card-content">
            <div class="card-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M12 2v20M5 9l7-7 7 7" stroke="currentColor" stroke-width="2"/>
              </svg>
            </div>
            <div class="card-info">
              <span class="card-label">Income</span>
              <span class="card-value">{{ formatAmount(periodData.income) }}</span>
              <span class="card-change" :class="{ positive: periodData.incomeChange >= 0 }">
                {{ periodData.incomeChange >= 0 ? '+' : '' }}{{ periodData.incomeChange.toFixed(1) }}%
              </span>
            </div>
          </div>
        </template>
      </IOSCard>

      <IOSCard variant="glass" class="overview-card expense">
        <template #content>
          <div class="card-content">
            <div class="card-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M12 22V2M19 15l-7 7-7-7" stroke="currentColor" stroke-width="2"/>
              </svg>
            </div>
            <div class="card-info">
              <span class="card-label">Expenses</span>
              <span class="card-value">{{ formatAmount(periodData.expenses) }}</span>
              <span class="card-change" :class="{ positive: periodData.expenseChange <= 0 }">
                {{ periodData.expenseChange >= 0 ? '+' : '' }}{{ periodData.expenseChange.toFixed(1) }}%
              </span>
            </div>
          </div>
        </template>
      </IOSCard>

      <IOSCard variant="glass" class="overview-card savings">
        <template #content>
          <div class="card-content">
            <div class="card-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
                <path d="m9 12 2 2 4-4" stroke="currentColor" stroke-width="2"/>
              </svg>
            </div>
            <div class="card-info">
              <span class="card-label">Net Savings</span>
              <span class="card-value">{{ formatAmount(periodData.savings) }}</span>
              <span class="card-change" :class="{ positive: periodData.savingsChange >= 0 }">
                {{ periodData.savingsChange >= 0 ? '+' : '' }}{{ periodData.savingsChange.toFixed(1) }}%
              </span>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Spending Chart -->
    <div class="chart-section">
      <IOSCard variant="glass">
        <template #header>
          <div class="chart-header">
            <h3>Spending Trends</h3>
            <div class="chart-controls">
              <button
                v-for="chartType in chartTypes"
                :key="chartType.value"
                @click="selectedChartType = chartType.value"
                class="chart-type-btn"
                :class="{ active: selectedChartType === chartType.value }"
              >
                {{ chartType.label }}
              </button>
            </div>
          </div>
        </template>
        
        <template #content>
          <AnalyticsChart
            :data="chartData"
            :type="selectedChartType"
            :period="selectedPeriod"
            class="spending-chart"
          />
        </template>
      </IOSCard>
    </div>

    <!-- Category Breakdown -->
    <div class="category-section">
      <IOSCard variant="glass">
        <template #header>
          <div class="section-header">
            <h3>Spending by Category</h3>
            <span class="period-label">{{ getPeriodLabel() }}</span>
          </div>
        </template>
        
        <template #content>
          <div class="category-list">
            <div
              v-for="category in categoryData"
              :key="category.name"
              class="category-item"
              @click="viewCategoryDetails(category)"
            >
              <div class="category-info">
                <div class="category-icon" :style="{ background: category.color }">
                  <component :is="category.icon" :size="20" />
                </div>
                <div class="category-details">
                  <span class="category-name">{{ category.name }}</span>
                  <span class="category-transactions">{{ category.transactions }} transactions</span>
                </div>
              </div>
              <div class="category-amount">
                <span class="amount">{{ formatAmount(category.amount) }}</span>
                <span class="percentage">{{ category.percentage.toFixed(1) }}%</span>
              </div>
              <div class="category-bar">
                <div 
                  class="bar-fill" 
                  :style="{ 
                    width: `${category.percentage}%`, 
                    background: category.color 
                  }"
                ></div>
              </div>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Budget Overview -->
    <div class="budget-section">
      <IOSCard variant="glass">
        <template #header>
          <div class="section-header">
            <h3>Budget Overview</h3>
            <button @click="manageBudgets" class="manage-btn">
              Manage
            </button>
          </div>
        </template>
        
        <template #content>
          <div v-if="budgets.length === 0" class="empty-budgets">
            <div class="empty-icon">
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
                <line x1="12" y1="8" x2="12" y2="12" stroke="currentColor" stroke-width="2"/>
                <line x1="12" y1="16" x2="12.01" y2="16" stroke="currentColor" stroke-width="2"/>
              </svg>
            </div>
            <h4>No budgets set</h4>
            <p>Create budgets to track your spending goals</p>
            <IOSButton variant="primary" @click="createBudget">
              Create Budget
            </IOSButton>
          </div>
          
          <div v-else class="budget-list">
            <div
              v-for="budget in budgets"
              :key="budget.id"
              class="budget-item"
              @click="viewBudgetDetails(budget)"
            >
              <div class="budget-info">
                <span class="budget-name">{{ budget.name }}</span>
                <span class="budget-period">{{ budget.period }}</span>
              </div>
              <div class="budget-progress">
                <div class="progress-info">
                  <span class="spent">{{ formatAmount(budget.spent) }}</span>
                  <span class="total">/ {{ formatAmount(budget.limit) }}</span>
                </div>
                <div class="progress-bar">
                  <div 
                    class="progress-fill" 
                    :class="{ 
                      warning: budget.percentage >= 80,
                      danger: budget.percentage >= 100 
                    }"
                    :style="{ width: `${Math.min(budget.percentage, 100)}%` }"
                  ></div>
                </div>
                <span class="progress-percentage">{{ budget.percentage.toFixed(0) }}%</span>
              </div>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Financial Goals -->
    <div class="goals-section">
      <IOSCard variant="glass">
        <template #header>
          <div class="section-header">
            <h3>Financial Goals</h3>
            <button @click="addGoal" class="add-btn">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <line x1="12" y1="5" x2="12" y2="19" stroke="currentColor" stroke-width="2"/>
                <line x1="5" y1="12" x2="19" y2="12" stroke="currentColor" stroke-width="2"/>
              </svg>
              Add Goal
            </button>
          </div>
        </template>
        
        <template #content>
          <div v-if="goals.length === 0" class="empty-goals">
            <div class="empty-icon">
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none">
                <path d="M22 12h-4l-3 9L9 3l-3 9H2" stroke="currentColor" stroke-width="2"/>
              </svg>
            </div>
            <h4>No goals set</h4>
            <p>Set financial goals to track your progress</p>
          </div>
          
          <div v-else class="goals-list">
            <div
              v-for="goal in goals"
              :key="goal.id"
              class="goal-item"
              @click="viewGoalDetails(goal)"
            >
              <div class="goal-info">
                <span class="goal-name">{{ goal.name }}</span>
                <span class="goal-target">Target: {{ formatAmount(goal.target) }}</span>
              </div>
              <div class="goal-progress">
                <div class="progress-circle" :style="{ background: `conic-gradient(${goal.color} ${goal.percentage * 3.6}deg, rgba(0,0,0,0.1) 0deg)` }">
                  <div class="progress-inner">
                    <span class="progress-text">{{ goal.percentage.toFixed(0) }}%</span>
                  </div>
                </div>
                <div class="goal-amount">
                  <span class="current">{{ formatAmount(goal.current) }}</span>
                  <span class="remaining">{{ formatAmount(goal.target - goal.current) }} to go</span>
                </div>
              </div>
            </div>
          </div>
        </template>
      </IOSCard>
    </div>

    <!-- Category Details Modal -->
    <IOSModal
      v-model="showCategoryDetails"
      :title="selectedCategory?.name || 'Category Details'"
      size="medium"
    >
      <div v-if="selectedCategory" class="category-details">
        <div class="detail-header">
          <div class="detail-icon" :style="{ background: selectedCategory.color }">
            <component :is="selectedCategory.icon" :size="32" />
          </div>
          <div class="detail-info">
            <h3>{{ formatAmount(selectedCategory.amount) }}</h3>
            <p>{{ selectedCategory.transactions }} transactions this {{ selectedPeriod }}</p>
          </div>
        </div>
        
        <div class="detail-transactions">
          <h4>Recent Transactions</h4>
          <div class="transaction-list">
            <TransactionItem
              v-for="transaction in selectedCategory.recentTransactions"
              :key="transaction.id"
              :transaction="transaction"
            />
          </div>
        </div>
      </div>
    </IOSModal>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, h } from 'vue'
import { useStore } from 'vuex'
import { formatCurrency } from '../../../utils/currency'

// SVG Icons
const ShoppingCart = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('circle', { cx: '8', cy: '21', r: '1' }),
  h('circle', { cx: '19', cy: '21', r: '1' }),
  h('path', { d: 'M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12' })
])

const Car = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9L18.4 9H5.6L3.5 11.1C2.7 11.3 2 12.1 2 13v3c0 .6.4 1 1 1h2' }),
  h('circle', { cx: '7', cy: '17', r: '2' }),
  h('path', { d: 'M9 17h6' }),
  h('circle', { cx: '17', cy: '17', r: '2' })
])

const Home = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z' }),
  h('polyline', { points: '9,22 9,12 15,12 15,22' })
])

const Utensils = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2' }),
  h('path', { d: 'M7 2v20' }),
  h('path', { d: 'M21 15V2v0a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7' })
])

const Coffee = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M17 8h1a4 4 0 1 1 0 8h-1' }),
  h('path', { d: 'M3 8h14v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4Z' }),
  h('line', { x1: '6', x2: '6', y1: '2', y2: '4' }),
  h('line', { x1: '10', x2: '10', y1: '2', y2: '4' }),
  h('line', { x1: '14', x2: '14', y1: '2', y2: '4' })
])

const Gamepad2 = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('line', { x1: '6', x2: '10', y1: '12', y2: '12' }),
  h('line', { x1: '8', x2: '8', y1: '10', y2: '14' }),
  h('line', { x1: '15', x2: '15.01', y1: '13', y2: '13' }),
  h('line', { x1: '18', x2: '18.01', y1: '11', y2: '11' }),
  h('rect', { width: '20', height: '12', x: '2', y: '6', rx: '2' })
])

const Heart = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.29 1.51 4.04 3 5.5l7 7Z' })
])

const GraduationCap = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M21.42 10.922a1 1 0 0 0-.019-1.838L12.83 5.18a2 2 0 0 0-1.66 0L2.6 9.08a1 1 0 0 0 0 1.832l8.57 3.908a2 2 0 0 0 1.66 0z' }),
  h('path', { d: 'M22 10v6' }),
  h('path', { d: 'M6 12.5V16a6 3 0 0 0 12 0v-3.5' })
])

const Plane = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('path', { d: 'M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z' })
])

const Gift = () => h('svg', { width: '24', height: '24', viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': '2' }, [
  h('rect', { x: '3', y: '8', width: '18', height: '4', rx: '1' }),
  h('rect', { x: '12', y: '8', width: '0', height: '13' }),
  h('path', { d: 'M19 12v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7' }),
  h('path', { d: 'M7.5 8a2.5 2.5 0 0 1 0-5A4.9 4.9 0 0 1 12 7.5a4.9 4.9 0 0 1 4.5-4.5 2.5 2.5 0 0 1 0 5' })
])

// Components
import IOSCard from '../../ios/IOSCard.vue'
import IOSModal from '../../ios/IOSModal.vue'
import IOSButton from '../../ios/IOSButton.vue'
import AnalyticsChart from '../AnalyticsChart.vue'
import TransactionItem from '../TransactionItem.vue'

const store = useStore()

// State
const selectedPeriod = ref('month')
const selectedChartType = ref('line')
const showCategoryDetails = ref(false)
const selectedCategory = ref(null)

// Period options
const periods = [
  { label: 'Week', value: 'week' },
  { label: 'Month', value: 'month' },
  { label: 'Quarter', value: 'quarter' },
  { label: 'Year', value: 'year' }
]

// Chart type options
const chartTypes = [
  { label: 'Line', value: 'line' },
  { label: 'Area', value: 'area' },
  { label: 'Bar', value: 'bar' }
]

// Category icons mapping
const categoryIcons = {
  'Shopping': ShoppingCart,
  'Transportation': Car,
  'Housing': Home,
  'Food & Dining': Utensils,
  'Coffee & Drinks': Coffee,
  'Entertainment': Gamepad2,
  'Healthcare': Heart,
  'Education': GraduationCap,
  'Travel': Plane,
  'Gifts': Gift
}

// Computed properties
const transactions = computed(() => store.state.wallet.transactions)
const analytics = computed(() => store.state.wallet.analytics)
const budgets = computed(() => store.state.wallet.budgets || [])
const goals = computed(() => store.state.wallet.goals || [])

const periodData = computed(() => {
  const now = new Date()
  let startDate

  switch (selectedPeriod.value) {
    case 'week':
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7)
      break
    case 'month':
      startDate = new Date(now.getFullYear(), now.getMonth(), 1)
      break
    case 'quarter':
      startDate = new Date(now.getFullYear(), Math.floor(now.getMonth() / 3) * 3, 1)
      break
    case 'year':
      startDate = new Date(now.getFullYear(), 0, 1)
      break
    default:
      startDate = new Date(now.getFullYear(), now.getMonth(), 1)
  }

  const periodTransactions = transactions.value.filter(t => 
    new Date(t.date) >= startDate
  )

  const income = periodTransactions
    .filter(t => t.amount > 0)
    .reduce((sum, t) => sum + t.amount, 0)

  const expenses = Math.abs(periodTransactions
    .filter(t => t.amount < 0)
    .reduce((sum, t) => sum + t.amount, 0))

  const savings = income - expenses

  // Calculate changes (mock data for demo)
  return {
    income,
    expenses,
    savings,
    incomeChange: 12.5,
    expenseChange: -8.3,
    savingsChange: 25.7
  }
})

const categoryData = computed(() => {
  const now = new Date()
  let startDate

  switch (selectedPeriod.value) {
    case 'week':
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7)
      break
    case 'month':
      startDate = new Date(now.getFullYear(), now.getMonth(), 1)
      break
    case 'quarter':
      startDate = new Date(now.getFullYear(), Math.floor(now.getMonth() / 3) * 3, 1)
      break
    case 'year':
      startDate = new Date(now.getFullYear(), 0, 1)
      break
    default:
      startDate = new Date(now.getFullYear(), now.getMonth(), 1)
  }

  const periodTransactions = transactions.value.filter(t => 
    new Date(t.date) >= startDate && t.amount < 0
  )

  const categories = {}
  const totalExpenses = Math.abs(periodTransactions.reduce((sum, t) => sum + t.amount, 0))

  periodTransactions.forEach(transaction => {
    const category = transaction.category || 'Other'
    if (!categories[category]) {
      categories[category] = {
        name: category,
        amount: 0,
        transactions: 0,
        recentTransactions: []
      }
    }
    categories[category].amount += Math.abs(transaction.amount)
    categories[category].transactions += 1
    categories[category].recentTransactions.push(transaction)
  })

  const categoryColors = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
    '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
  ]

  return Object.values(categories)
    .map((category, index) => ({
      ...category,
      percentage: totalExpenses > 0 ? (category.amount / totalExpenses) * 100 : 0,
      color: categoryColors[index % categoryColors.length],
      icon: categoryIcons[category.name] || ShoppingCart,
      recentTransactions: category.recentTransactions.slice(0, 5)
    }))
    .sort((a, b) => b.amount - a.amount)
    .slice(0, 8)
})

const chartData = computed(() => {
  // Generate chart data based on selected period
  const now = new Date()
  const data = []

  for (let i = 6; i >= 0; i--) {
    let date
    let label

    switch (selectedPeriod.value) {
      case 'week':
        date = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i)
        label = date.toLocaleDateString('en-US', { weekday: 'short' })
        break
      case 'month':
        date = new Date(now.getFullYear(), now.getMonth() - i, 1)
        label = date.toLocaleDateString('en-US', { month: 'short' })
        break
      case 'quarter':
        date = new Date(now.getFullYear(), now.getMonth() - (i * 3), 1)
        label = `Q${Math.floor(date.getMonth() / 3) + 1}`
        break
      case 'year':
        date = new Date(now.getFullYear() - i, 0, 1)
        label = date.getFullYear().toString()
        break
      default:
        date = new Date(now.getFullYear(), now.getMonth() - i, 1)
        label = date.toLocaleDateString('en-US', { month: 'short' })
    }

    const dayTransactions = transactions.value.filter(t => {
      const transactionDate = new Date(t.date)
      return transactionDate >= date && transactionDate < new Date(date.getTime() + (selectedPeriod.value === 'week' ? 86400000 : 2592000000))
    })

    const income = dayTransactions
      .filter(t => t.amount > 0)
      .reduce((sum, t) => sum + t.amount, 0)

    const expenses = Math.abs(dayTransactions
      .filter(t => t.amount < 0)
      .reduce((sum, t) => sum + t.amount, 0))

    data.push({
      label,
      income,
      expenses,
      net: income - expenses
    })
  }

  return data
})

// Methods
const formatAmount = (amount) => {
  return formatCurrency(amount)
}

const getPeriodLabel = () => {
  const now = new Date()
  switch (selectedPeriod.value) {
    case 'week':
      return 'This Week'
    case 'month':
      return now.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
    case 'quarter':
      return `Q${Math.floor(now.getMonth() / 3) + 1} ${now.getFullYear()}`
    case 'year':
      return now.getFullYear().toString()
    default:
      return 'This Month'
  }
}

const viewCategoryDetails = (category) => {
  selectedCategory.value = category
  showCategoryDetails.value = true
}

const manageBudgets = () => {
  // Navigate to budget management
  console.log('Manage budgets')
}

const createBudget = () => {
  // Create new budget
  console.log('Create budget')
}

const viewBudgetDetails = (budget) => {
  // View budget details
  console.log('View budget:', budget)
}

const addGoal = () => {
  // Add new financial goal
  console.log('Add goal')
}

const viewGoalDetails = (goal) => {
  // View goal details
  console.log('View goal:', goal)
}

// Initialize data
onMounted(() => {
  store.dispatch('wallet/fetchTransactions')
  store.dispatch('wallet/fetchAnalytics')
  store.dispatch('wallet/fetchBudgets')
  store.dispatch('wallet/fetchGoals')
})
</script>

<style scoped>
.analytics-page {
  display: flex;
  flex-direction: column;
  gap: 24px;
  padding-bottom: 20px;
}

/* Period Selector */
.period-selector {
  display: flex;
  gap: 8px;
  padding: 4px;
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(20px);
  border-radius: 12px;
  border: 1px solid rgba(0, 0, 0, 0.1);
}

.period-btn {
  flex: 1;
  padding: 8px 16px;
  border: none;
  border-radius: 8px;
  background: transparent;
  color: #8e8e93;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.period-btn:hover {
  color: #1d1d1f;
}

.period-btn.active {
  background: #007AFF;
  color: white;
}

/* Overview Cards */
.overview-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 16px;
}

.overview-card {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(20px);
}

.card-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.card-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.overview-card.income .card-icon {
  background: linear-gradient(135deg, #34C759, #30D158);
}

.overview-card.expense .card-icon {
  background: linear-gradient(135deg, #FF3B30, #FF453A);
}

.overview-card.savings .card-icon {
  background: linear-gradient(135deg, #007AFF, #0A84FF);
}

.card-info {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.card-label {
  font-size: 14px;
  color: #8e8e93;
  font-weight: 500;
}

.card-value {
  font-size: 24px;
  font-weight: 700;
  color: #1d1d1f;
  margin: 4px 0;
}

.card-change {
  font-size: 12px;
  font-weight: 600;
  color: #FF3B30;
}

.card-change.positive {
  color: #34C759;
}

/* Chart Section */
.chart-section {
  margin-top: 8px;
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
}

.chart-header h3 {
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.chart-controls {
  display: flex;
  gap: 4px;
  padding: 2px;
  background: rgba(0, 0, 0, 0.05);
  border-radius: 8px;
}

.chart-type-btn {
  padding: 6px 12px;
  border: none;
  border-radius: 6px;
  background: transparent;
  color: #8e8e93;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.chart-type-btn:hover {
  color: #1d1d1f;
}

.chart-type-btn.active {
  background: white;
  color: #007AFF;
}

.spending-chart {
  margin-top: 16px;
  height: 300px;
}

/* Category Section */
.category-section {
  margin-top: 8px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.section-header h3 {
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.period-label {
  font-size: 14px;
  color: #8e8e93;
  font-weight: 500;
}

.manage-btn,
.add-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  background: none;
  border: none;
  color: #007AFF;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s ease;
}

.manage-btn:hover,
.add-btn:hover {
  opacity: 0.7;
}

.category-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 16px;
}

.category-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  border: 1px solid rgba(0, 0, 0, 0.05);
  cursor: pointer;
  transition: all 0.2s ease;
}

.category-item:hover {
  background: rgba(255, 255, 255, 0.8);
  transform: translateY(-1px);
}

.category-info {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}

.category-icon {
  width: 40px;
  height: 40px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.category-details {
  display: flex;
  flex-direction: column;
}

.category-name {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
}

.category-transactions {
  font-size: 12px;
  color: #8e8e93;
}

.category-amount {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  margin-right: 12px;
}

.amount {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
}

.percentage {
  font-size: 12px;
  color: #8e8e93;
}

.category-bar {
  width: 60px;
  height: 4px;
  background: rgba(0, 0, 0, 0.1);
  border-radius: 2px;
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  border-radius: 2px;
  transition: width 0.3s ease;
}

/* Budget Section */
.budget-section {
  margin-top: 8px;
}

.empty-budgets,
.empty-goals {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 40px 20px;
  text-align: center;
}

.empty-icon {
  color: #8e8e93;
  opacity: 0.6;
}

.empty-budgets h4,
.empty-goals h4 {
  font-size: 18px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0;
}

.empty-budgets p,
.empty-goals p {
  font-size: 14px;
  color: #8e8e93;
  margin: 0;
}

.budget-list,
.goals-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 16px;
}

.budget-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  border: 1px solid rgba(0, 0, 0, 0.05);
  cursor: pointer;
  transition: all 0.2s ease;
}

.budget-item:hover {
  background: rgba(255, 255, 255, 0.8);
}

.budget-info {
  display: flex;
  flex-direction: column;
}

.budget-name {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
}

.budget-period {
  font-size: 12px;
  color: #8e8e93;
  text-transform: capitalize;
}

.budget-progress {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
  min-width: 120px;
}

.progress-info {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 14px;
}

.spent {
  font-weight: 600;
  color: #1d1d1f;
}

.total {
  color: #8e8e93;
}

.progress-bar {
  width: 100%;
  height: 6px;
  background: rgba(0, 0, 0, 0.1);
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: #34C759;
  border-radius: 3px;
  transition: all 0.3s ease;
}

.progress-fill.warning {
  background: #FF9500;
}

.progress-fill.danger {
  background: #FF3B30;
}

.progress-percentage {
  font-size: 12px;
  font-weight: 600;
  color: #8e8e93;
}

/* Goals Section */
.goals-section {
  margin-top: 8px;
}

.goal-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  background: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  border: 1px solid rgba(0, 0, 0, 0.05);
  cursor: pointer;
  transition: all 0.2s ease;
}

.goal-item:hover {
  background: rgba(255, 255, 255, 0.8);
}

.goal-info {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.goal-name {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
}

.goal-target {
  font-size: 12px;
  color: #8e8e93;
}

.goal-progress {
  display: flex;
  align-items: center;
  gap: 16px;
}

.progress-circle {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.progress-inner {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background: white;
  display: flex;
  align-items: center;
  justify-content: center;
}

.progress-text {
  font-size: 12px;
  font-weight: 700;
  color: #1d1d1f;
}

.goal-amount {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.current {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
}

.remaining {
  font-size: 12px;
  color: #8e8e93;
}

/* Category Details Modal */
.category-details {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.detail-header {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px 0;
}

.detail-icon {
  width: 60px;
  height: 60px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.detail-info h3 {
  font-size: 24px;
  font-weight: 700;
  color: #1d1d1f;
  margin: 0 0 4px 0;
}

.detail-info p {
  font-size: 14px;
  color: #8e8e93;
  margin: 0;
}

.detail-transactions h4 {
  font-size: 16px;
  font-weight: 600;
  color: #1d1d1f;
  margin: 0 0 16px 0;
}

.transaction-list {
  background: rgba(255, 255, 255, 0.5);
  border-radius: 12px;
  overflow: hidden;
  border: 1px solid rgba(0, 0, 0, 0.05);
}

/* Responsive Design */
@media (max-width: 768px) {
  .overview-cards {
    grid-template-columns: 1fr;
  }

  .chart-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .category-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .category-amount {
    align-items: flex-start;
    margin-right: 0;
  }

  .category-bar {
    width: 100%;
  }

  .budget-item,
  .goal-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .budget-progress,
  .goal-progress {
    width: 100%;
    align-items: flex-start;
  }

  .goal-progress {
    flex-direction: row;
    justify-content: space-between;
  }
}

@media (max-width: 375px) {
  .period-selector {
    flex-direction: column;
    gap: 4px;
  }

  .card-content {
    flex-direction: column;
    text-align: center;
  }

  .spending-chart {
    height: 250px;
  }
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  .period-selector {
    background: rgba(28, 28, 30, 0.8);
    border-color: rgba(255, 255, 255, 0.1);
  }

  .period-btn {
    color: #8e8e93;
  }

  .period-btn:hover {
    color: #f2f2f7;
  }

  .period-btn.active {
    background: #0A84FF;
  }

  .overview-card {
    background: rgba(28, 28, 30, 0.8);
  }

  .card-value {
    color: #f2f2f7;
  }

  .chart-header h3,
  .section-header h3 {
    color: #f2f2f7;
  }

  .chart-controls {
    background: rgba(255, 255, 255, 0.05);
  }

  .chart-type-btn {
    color: #8e8e93;
  }

  .chart-type-btn:hover {
    color: #f2f2f7;
  }

  .chart-type-btn.active {
    background: rgba(44, 44, 46, 1);
    color: #0A84FF;
  }

  .category-item,
  .budget-item,
  .goal-item {
    background: rgba(44, 44, 46, 0.5);
    border-color: rgba(255, 255, 255, 0.05);
  }

  .category-item:hover,
  .budget-item:hover,
  .goal-item:hover {
    background: rgba(44, 44, 46, 0.8);
  }

  .category-name,
  .budget-name,
  .goal-name {
    color: #f2f2f7;
  }

  .amount,
  .spent,
  .current {
    color: #f2f2f7;
  }

  .empty-budgets h4,
  .empty-goals h4 {
    color: #f2f2f7;
  }

  .progress-bar {
    background: rgba(255, 255, 255, 0.1);
  }

  .progress-inner {
    background: rgba(28, 28, 30, 1);
  }

  .progress-text {
    color: #f2f2f7;
  }

  .detail-info h3 {
    color: #f2f2f7;
  }

  .detail-transactions h4 {
    color: #f2f2f7;
  }

  .transaction-list {
    background: rgba(44, 44, 46, 0.5);
    border-color: rgba(255, 255, 255, 0.05);
  }
}
</style>