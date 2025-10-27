<template>
  <div class="clock-app">
    <div class="clock-header">
      <h1>Clock</h1>
    </div>

    <div class="clock-tabs">
      <button 
        v-for="tab in tabs" 
        :key="tab.id"
        :class="['tab-button', { active: activeTab === tab.id }]"
        @click="activeTab = tab.id"
      >
        {{ tab.label }}
      </button>
    </div>

    <div class="clock-content">
      <!-- Clock Tab -->
      <div v-if="activeTab === 'clock'" class="tab-panel clock-panel">
        <div class="current-time">
          <div class="time-display">{{ currentTime }}</div>
          <div class="date-display">{{ currentDate }}</div>
        </div>
      </div>

      <!-- Alarm Tab -->
      <div v-if="activeTab === 'alarm'" class="tab-panel alarm-panel">
        <div class="alarm-list">
          <div v-if="alarms.length === 0" class="empty-state">
            <p>No alarms set</p>
          </div>
          <div 
            v-for="alarm in alarms" 
            :key="alarm.id"
            class="alarm-item"
          >
            <div class="alarm-info">
              <div class="alarm-time">{{ formatAlarmTime(alarm.alarm_time) }}</div>
              <div class="alarm-label">{{ alarm.label || 'Alarm' }}</div>
              <div v-if="alarm.alarm_days" class="alarm-days">{{ formatAlarmDays(alarm.alarm_days) }}</div>
            </div>
            <div class="alarm-actions">
              <button 
                :class="['toggle-button', { active: alarm.enabled }]"
                @click="toggleAlarm(alarm.id)"
              >
                {{ alarm.enabled ? 'ON' : 'OFF' }}
              </button>
              <button class="edit-button" @click="editAlarm(alarm)">Edit</button>
              <button class="delete-button" @click="deleteAlarm(alarm.id)">Delete</button>
            </div>
          </div>
        </div>
        <button class="add-alarm-button" @click="showAlarmForm = true">
          + Add Alarm
        </button>
      </div>

      <!-- Timer Tab -->
      <div v-if="activeTab === 'timer'" class="tab-panel timer-panel">
        <div class="timer-display">
          <div class="timer-time">{{ formatTimerDisplay }}</div>
        </div>
        <div v-if="!timerRunning && !timerPaused" class="timer-input">
          <input 
            type="number" 
            v-model.number="timerHours" 
            min="0" 
            max="23"
            placeholder="HH"
          />
          <span>:</span>
          <input 
            type="number" 
            v-model.number="timerMinutes" 
            min="0" 
            max="59"
            placeholder="MM"
          />
          <span>:</span>
          <input 
            type="number" 
            v-model.number="timerSeconds" 
            min="0" 
            max="59"
            placeholder="SS"
          />
        </div>
        <div class="timer-controls">
          <button 
            v-if="!timerRunning && !timerPaused" 
            class="start-button"
            @click="startTimer"
            :disabled="timerTotalSeconds === 0"
          >
            Start
          </button>
          <button 
            v-if="timerRunning" 
            class="pause-button"
            @click="pauseTimer"
          >
            Pause
          </button>
          <button 
            v-if="timerPaused" 
            class="resume-button"
            @click="resumeTimer"
          >
            Resume
          </button>
          <button 
            v-if="timerRunning || timerPaused" 
            class="reset-button"
            @click="resetTimer"
          >
            Reset
          </button>
        </div>
      </div>

      <!-- Stopwatch Tab -->
      <div v-if="activeTab === 'stopwatch'" class="tab-panel stopwatch-panel">
        <div class="stopwatch-display">
          <div class="stopwatch-time">{{ formatStopwatchDisplay }}</div>
        </div>
        <div class="stopwatch-controls">
          <button 
            v-if="!stopwatchRunning" 
            class="start-button"
            @click="startStopwatch"
          >
            Start
          </button>
          <button 
            v-if="stopwatchRunning" 
            class="stop-button"
            @click="stopStopwatch"
          >
            Stop
          </button>
          <button 
            v-if="stopwatchRunning" 
            class="lap-button"
            @click="recordLap"
          >
            Lap
          </button>
          <button 
            v-if="!stopwatchRunning && stopwatchTime > 0" 
            class="reset-button"
            @click="resetStopwatch"
          >
            Reset
          </button>
        </div>
        <div v-if="laps.length > 0" class="lap-list">
          <div class="lap-header">Laps</div>
          <div 
            v-for="(lap, index) in laps" 
            :key="index"
            class="lap-item"
          >
            <span class="lap-number">Lap {{ laps.length - index }}</span>
            <span class="lap-time">{{ formatTime(lap) }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Alarm Form Modal -->
    <div v-if="showAlarmForm" class="modal-overlay" @click="closeAlarmForm">
      <div class="modal-content" @click.stop>
        <h2>{{ editingAlarm ? 'Edit Alarm' : 'Add Alarm' }}</h2>
        <div class="form-group">
          <label>Time</label>
          <input 
            type="time" 
            v-model="alarmForm.time"
            required
          />
        </div>
        <div class="form-group">
          <label>Label</label>
          <input 
            type="text" 
            v-model="alarmForm.label"
            placeholder="Wake up"
            maxlength="100"
          />
        </div>
        <div class="form-group">
          <label>Repeat</label>
          <div class="days-selector">
            <button 
              v-for="day in daysOfWeek" 
              :key="day.value"
              :class="['day-button', { active: alarmForm.days.includes(day.value) }]"
              @click="toggleDay(day.value)"
            >
              {{ day.label }}
            </button>
          </div>
        </div>
        <div class="form-group">
          <label>Sound</label>
          <select v-model="alarmForm.sound">
            <option value="default">Default</option>
            <option value="gentle">Gentle</option>
            <option value="loud">Loud</option>
            <option value="custom">Custom</option>
          </select>
        </div>
        <div class="form-actions">
          <button class="cancel-button" @click="closeAlarmForm">Cancel</button>
          <button class="save-button" @click="saveAlarm">Save</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { fetchNui } from '../utils/nui';

export default {
  name: 'Clock',
  data() {
    return {
      activeTab: 'clock',
      tabs: [
        { id: 'clock', label: 'Clock' },
        { id: 'alarm', label: 'Alarm' },
        { id: 'timer', label: 'Timer' },
        { id: 'stopwatch', label: 'Stopwatch' }
      ],
      currentTime: '',
      currentDate: '',
      timeInterval: null,
      
      // Alarms
      alarms: [],
      showAlarmForm: false,
      editingAlarm: null,
      alarmForm: {
        time: '',
        label: '',
        days: [],
        sound: 'default'
      },
      daysOfWeek: [
        { value: 'mon', label: 'M' },
        { value: 'tue', label: 'T' },
        { value: 'wed', label: 'W' },
        { value: 'thu', label: 'T' },
        { value: 'fri', label: 'F' },
        { value: 'sat', label: 'S' },
        { value: 'sun', label: 'S' }
      ],
      
      // Timer
      timerHours: 0,
      timerMinutes: 0,
      timerSeconds: 0,
      timerRemaining: 0,
      timerRunning: false,
      timerPaused: false,
      timerInterval: null,
      
      // Stopwatch
      stopwatchTime: 0,
      stopwatchRunning: false,
      stopwatchInterval: null,
      laps: []
    };
  },
  computed: {
    timerTotalSeconds() {
      return (this.timerHours * 3600) + (this.timerMinutes * 60) + this.timerSeconds;
    },
    formatTimerDisplay() {
      return this.formatTime(this.timerRemaining);
    },
    formatStopwatchDisplay() {
      return this.formatTime(this.stopwatchTime);
    }
  },
  mounted() {
    this.updateTime();
    this.timeInterval = setInterval(this.updateTime, 1000);
    this.loadAlarms();
  },
  beforeUnmount() {
    if (this.timeInterval) {
      clearInterval(this.timeInterval);
    }
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
    }
    if (this.stopwatchInterval) {
      clearInterval(this.stopwatchInterval);
    }
  },
  methods: {
    updateTime() {
      const now = new Date();
      this.currentTime = now.toLocaleTimeString('en-US', { 
        hour: '2-digit', 
        minute: '2-digit',
        second: '2-digit',
        hour12: false
      });
      this.currentDate = now.toLocaleDateString('en-US', { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
      });
    },
    
    // Alarm methods
    async loadAlarms() {
      try {
        const response = await fetchNui('getAlarms');
        if (response.success) {
          this.alarms = response.alarms || [];
        }
      } catch (error) {
        console.error('Failed to load alarms:', error);
      }
    },
    async toggleAlarm(alarmId) {
      try {
        const alarm = this.alarms.find(a => a.id === alarmId);
        const response = await fetchNui('toggleAlarm', { 
          alarmId, 
          enabled: !alarm.enabled 
        });
        if (response.success) {
          alarm.enabled = !alarm.enabled;
        }
      } catch (error) {
        console.error('Failed to toggle alarm:', error);
      }
    },
    editAlarm(alarm) {
      this.editingAlarm = alarm;
      this.alarmForm = {
        time: alarm.alarm_time,
        label: alarm.label || '',
        days: alarm.alarm_days ? alarm.alarm_days.split(',') : [],
        sound: alarm.sound || 'default'
      };
      this.showAlarmForm = true;
    },
    async deleteAlarm(alarmId) {
      if (!confirm('Are you sure you want to delete this alarm?')) {
        return;
      }
      try {
        const response = await fetchNui('deleteAlarm', { alarmId });
        if (response.success) {
          this.alarms = this.alarms.filter(a => a.id !== alarmId);
        }
      } catch (error) {
        console.error('Failed to delete alarm:', error);
      }
    },
    async saveAlarm() {
      if (!this.alarmForm.time) {
        alert('Please set a time for the alarm');
        return;
      }
      
      try {
        const alarmData = {
          time: this.alarmForm.time,
          label: this.alarmForm.label,
          days: this.alarmForm.days.join(','),
          sound: this.alarmForm.sound
        };
        
        if (this.editingAlarm) {
          const response = await fetchNui('updateAlarm', {
            alarmId: this.editingAlarm.id,
            ...alarmData
          });
          if (response.success) {
            const index = this.alarms.findIndex(a => a.id === this.editingAlarm.id);
            if (index !== -1) {
              this.alarms[index] = { ...this.alarms[index], ...response.alarm };
            }
          }
        } else {
          const response = await fetchNui('createAlarm', alarmData);
          if (response.success) {
            this.alarms.push(response.alarm);
          }
        }
        
        this.closeAlarmForm();
      } catch (error) {
        console.error('Failed to save alarm:', error);
      }
    },
    closeAlarmForm() {
      this.showAlarmForm = false;
      this.editingAlarm = null;
      this.alarmForm = {
        time: '',
        label: '',
        days: [],
        sound: 'default'
      };
    },
    toggleDay(day) {
      const index = this.alarmForm.days.indexOf(day);
      if (index > -1) {
        this.alarmForm.days.splice(index, 1);
      } else {
        this.alarmForm.days.push(day);
      }
    },
    formatAlarmTime(time) {
      return time;
    },
    formatAlarmDays(days) {
      if (!days) return 'Once';
      const dayArray = days.split(',');
      if (dayArray.length === 7) return 'Every day';
      const dayLabels = {
        mon: 'Mon', tue: 'Tue', wed: 'Wed', thu: 'Thu',
        fri: 'Fri', sat: 'Sat', sun: 'Sun'
      };
      return dayArray.map(d => dayLabels[d]).join(', ');
    },
    
    // Timer methods
    startTimer() {
      if (this.timerTotalSeconds === 0) return;
      
      this.timerRemaining = this.timerTotalSeconds;
      this.timerRunning = true;
      this.timerPaused = false;
      
      this.timerInterval = setInterval(() => {
        this.timerRemaining--;
        
        if (this.timerRemaining <= 0) {
          this.timerComplete();
        }
      }, 1000);
    },
    pauseTimer() {
      this.timerRunning = false;
      this.timerPaused = true;
      if (this.timerInterval) {
        clearInterval(this.timerInterval);
      }
    },
    resumeTimer() {
      this.timerRunning = true;
      this.timerPaused = false;
      
      this.timerInterval = setInterval(() => {
        this.timerRemaining--;
        
        if (this.timerRemaining <= 0) {
          this.timerComplete();
        }
      }, 1000);
    },
    resetTimer() {
      this.timerRunning = false;
      this.timerPaused = false;
      this.timerRemaining = 0;
      if (this.timerInterval) {
        clearInterval(this.timerInterval);
      }
    },
    async timerComplete() {
      this.resetTimer();
      
      // Send notification
      try {
        await fetchNui('timerComplete');
      } catch (error) {
        console.error('Failed to send timer notification:', error);
      }
      
      alert('Timer complete!');
    },
    
    // Stopwatch methods
    startStopwatch() {
      this.stopwatchRunning = true;
      const startTime = Date.now() - this.stopwatchTime;
      
      this.stopwatchInterval = setInterval(() => {
        this.stopwatchTime = Date.now() - startTime;
      }, 10);
    },
    stopStopwatch() {
      this.stopwatchRunning = false;
      if (this.stopwatchInterval) {
        clearInterval(this.stopwatchInterval);
      }
    },
    resetStopwatch() {
      this.stopwatchTime = 0;
      this.laps = [];
    },
    recordLap() {
      this.laps.unshift(this.stopwatchTime);
    },
    
    // Utility methods
    formatTime(milliseconds) {
      const totalSeconds = Math.floor(milliseconds / 1000);
      const hours = Math.floor(totalSeconds / 3600);
      const minutes = Math.floor((totalSeconds % 3600) / 60);
      const seconds = totalSeconds % 60;
      const ms = Math.floor((milliseconds % 1000) / 10);
      
      if (hours > 0) {
        return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
      }
      return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}.${String(ms).padStart(2, '0')}`;
    }
  }
};
</script>

<style scoped>
.clock-app {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: var(--background-color);
  color: var(--text-color);
}

.clock-header {
  padding: 20px;
  border-bottom: 1px solid var(--border-color);
}

.clock-header h1 {
  margin: 0;
  font-size: 24px;
  font-weight: 600;
}

.clock-tabs {
  display: flex;
  border-bottom: 1px solid var(--border-color);
  background: var(--card-background);
}

.tab-button {
  flex: 1;
  padding: 15px;
  background: none;
  border: none;
  color: var(--text-color);
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s;
  border-bottom: 2px solid transparent;
}

.tab-button.active {
  color: var(--primary-color);
  border-bottom-color: var(--primary-color);
}

.clock-content {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
}

/* Clock Panel */
.clock-panel {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.current-time {
  text-align: center;
}

.time-display {
  font-size: 64px;
  font-weight: 300;
  margin-bottom: 10px;
}

.date-display {
  font-size: 18px;
  color: var(--text-color);
  opacity: 0.7;
}

/* Alarm Panel */
.alarm-list {
  margin-bottom: 20px;
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: var(--text-color);
  opacity: 0.5;
}

.alarm-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  background: var(--card-background);
  border-radius: 8px;
  margin-bottom: 10px;
}

.alarm-info {
  flex: 1;
}

.alarm-time {
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 5px;
}

.alarm-label {
  font-size: 14px;
  opacity: 0.7;
}

.alarm-days {
  font-size: 12px;
  margin-top: 5px;
  opacity: 0.6;
}

.alarm-actions {
  display: flex;
  gap: 10px;
}

.toggle-button {
  padding: 8px 16px;
  border: 1px solid var(--border-color);
  background: var(--background-color);
  color: var(--text-color);
  border-radius: 20px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 600;
}

.toggle-button.active {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.edit-button, .delete-button {
  padding: 8px 12px;
  border: none;
  background: var(--card-background);
  color: var(--text-color);
  border-radius: 6px;
  cursor: pointer;
  font-size: 12px;
}

.delete-button {
  color: var(--accent-color);
}

.add-alarm-button {
  width: 100%;
  padding: 15px;
  background: var(--primary-color);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
}

/* Timer Panel */
.timer-panel {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.timer-display {
  margin-bottom: 30px;
}

.timer-time {
  font-size: 64px;
  font-weight: 300;
}

.timer-input {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 30px;
}

.timer-input input {
  width: 80px;
  padding: 15px;
  font-size: 32px;
  text-align: center;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  color: var(--text-color);
}

.timer-input span {
  font-size: 32px;
  font-weight: 300;
}

.timer-controls {
  display: flex;
  gap: 15px;
}

.timer-controls button {
  padding: 15px 30px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
}

.start-button, .resume-button {
  background: var(--primary-color);
  color: white;
}

.pause-button {
  background: #FFA500;
  color: white;
}

.reset-button {
  background: var(--card-background);
  color: var(--text-color);
}

.start-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Stopwatch Panel */
.stopwatch-panel {
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 100%;
}

.stopwatch-display {
  margin: 40px 0;
}

.stopwatch-time {
  font-size: 64px;
  font-weight: 300;
}

.stopwatch-controls {
  display: flex;
  gap: 15px;
  margin-bottom: 30px;
}

.stopwatch-controls button {
  padding: 15px 30px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
}

.stop-button {
  background: var(--accent-color);
  color: white;
}

.lap-button {
  background: var(--card-background);
  color: var(--text-color);
}

.lap-list {
  width: 100%;
  max-width: 400px;
  max-height: 300px;
  overflow-y: auto;
}

.lap-header {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 15px;
  padding-bottom: 10px;
  border-bottom: 1px solid var(--border-color);
}

.lap-item {
  display: flex;
  justify-content: space-between;
  padding: 10px;
  background: var(--card-background);
  border-radius: 6px;
  margin-bottom: 8px;
}

.lap-number {
  font-weight: 600;
}

.lap-time {
  font-family: monospace;
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: var(--background-color);
  padding: 30px;
  border-radius: 12px;
  width: 90%;
  max-width: 400px;
  max-height: 80vh;
  overflow-y: auto;
}

.modal-content h2 {
  margin: 0 0 20px 0;
  font-size: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  font-size: 14px;
}

.form-group input[type="time"],
.form-group input[type="text"],
.form-group select {
  width: 100%;
  padding: 12px;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  color: var(--text-color);
  font-size: 16px;
}

.days-selector {
  display: flex;
  gap: 8px;
}

.day-button {
  flex: 1;
  padding: 12px;
  background: var(--card-background);
  border: 1px solid var(--border-color);
  border-radius: 50%;
  color: var(--text-color);
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
}

.day-button.active {
  background: var(--primary-color);
  color: white;
  border-color: var(--primary-color);
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 30px;
}

.form-actions button {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
}

.cancel-button {
  background: var(--card-background);
  color: var(--text-color);
}

.save-button {
  background: var(--primary-color);
  color: white;
}
</style>
