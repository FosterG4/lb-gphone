-- Weather App Server Handler
-- Handles weather data synchronization and forecast generation

local QBCore = nil
local ESX = nil

-- Initialize framework
if Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.Framework == 'qbox' then
    QBCore = exports.qbx_core
end

-- Weather data cache
local currentWeather = {
    type = 'CLEAR',
    temperature = 72,
    windSpeed = 5,
    humidity = 45,
    precipitation = 0,
    sunrise = '06:00',
    sunset = '18:00'
}

local weatherForecast = {}

-- Weather types available in GTA V
local weatherTypes = {
    'CLEAR', 'EXTRASUNNY', 'CLOUDS', 'OVERCAST', 'RAIN', 
    'CLEARING', 'THUNDER', 'SMOG', 'FOGGY', 'XMAS', 
    'SNOWLIGHT', 'BLIZZARD', 'SNOW', 'HALLOWEEN', 'NEUTRAL'
}

-- Temperature ranges for different weather types (Fahrenheit)
local weatherTemperatures = {
    CLEAR = {min = 70, max = 85},
    EXTRASUNNY = {min = 80, max = 95},
    CLOUDS = {min = 65, max = 75},
    OVERCAST = {min = 60, max = 70},
    RAIN = {min = 55, max = 65},
    CLEARING = {min = 65, max = 75},
    THUNDER = {min = 55, max = 70},
    SMOG = {min = 70, max = 80},
    FOGGY = {min = 60, max = 70},
    XMAS = {min = 30, max = 40},
    SNOWLIGHT = {min = 32, max = 40},
    BLIZZARD = {min = 20, max = 35},
    SNOW = {min = 25, max = 38},
    HALLOWEEN = {min = 55, max = 65},
    NEUTRAL = {min = 65, max = 75}
}

-- Precipitation chances for different weather types
local weatherPrecipitation = {
    CLEAR = 0,
    EXTRASUNNY = 0,
    CLOUDS = 10,
    OVERCAST = 30,
    RAIN = 80,
    CLEARING = 20,
    THUNDER = 90,
    SMOG = 0,
    FOGGY = 5,
    XMAS = 60,
    SNOWLIGHT = 50,
    BLIZZARD = 95,
    SNOW = 70,
    HALLOWEEN = 15,
    NEUTRAL = 10
}

-- Helper function to get current game weather
local function GetCurrentGameWeather()
    -- Try to get weather from common weather resources
    local weather = nil
    
    -- Try qb-weathersync (check for correct export name)
    if GetResourceState('qb-weathersync') == 'started' then
        -- Try different export names that qb-weathersync might use
        local success, result = pcall(function()
            return exports['qb-weathersync']:getWeather()
        end)
        if not success then
            -- Try alternative export name
            success, result = pcall(function()
                return exports['qb-weathersync']:getCurrentWeather()
            end)
        end
        if success and result then
            weather = result
        end
    -- Try cd_easytime
    elseif GetResourceState('cd_easytime') == 'started' then
        local success, result = pcall(function()
            return exports['cd_easytime']:GetWeather()
        end)
        if success and result then
            weather = result
        end
    -- Try vSync
    elseif GetResourceState('vSync') == 'started' then
        local success, result = pcall(function()
            return exports['vSync']:getCurrentWeather()
        end)
        if success and result then
            weather = result
        end
    end
    
    -- If we got weather data, use it
    if weather and type(weather) == 'string' then
        return weather
    end
    
    -- Default fallback
    return 'CLEAR'
end

-- Helper function to get current game time
local function GetCurrentGameTime()
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    
    return {
        hour = hour,
        minute = minute,
        formatted = string.format('%02d:%02d', hour, minute)
    }
end

-- Generate temperature based on weather type
local function GenerateTemperature(weatherType)
    local range = weatherTemperatures[weatherType] or weatherTemperatures.NEUTRAL
    return math.random(range.min, range.max)
end

-- Generate wind speed (mph)
local function GenerateWindSpeed(weatherType)
    if weatherType == 'BLIZZARD' or weatherType == 'THUNDER' then
        return math.random(20, 40)
    elseif weatherType == 'RAIN' or weatherType == 'SNOW' then
        return math.random(10, 25)
    else
        return math.random(3, 15)
    end
end

-- Generate humidity percentage
local function GenerateHumidity(weatherType)
    if weatherType == 'RAIN' or weatherType == 'THUNDER' or weatherType == 'FOGGY' then
        return math.random(70, 95)
    elseif weatherType == 'EXTRASUNNY' or weatherType == 'CLEAR' then
        return math.random(30, 50)
    else
        return math.random(45, 70)
    end
end

-- Update current weather data
local function UpdateCurrentWeather()
    local gameWeather = GetCurrentGameWeather()
    local gameTime = GetCurrentGameTime()
    
    currentWeather = {
        type = gameWeather,
        temperature = GenerateTemperature(gameWeather),
        windSpeed = GenerateWindSpeed(gameWeather),
        humidity = GenerateHumidity(gameWeather),
        precipitation = weatherPrecipitation[gameWeather] or 0,
        sunrise = '06:00',
        sunset = '18:00',
        time = gameTime.formatted
    }
    
    if Config.Debug then
        print('^3[PHONE] Weather updated: ' .. gameWeather .. ' at ' .. gameTime.formatted .. '^0')
    end
end

-- Generate 24-hour forecast
local function GenerateForecast()
    local forecast = {}
    local currentTime = GetCurrentGameTime()
    local currentHour = currentTime.hour
    
    -- Generate forecast for next 24 hours
    for i = 1, 24 do
        local forecastHour = (currentHour + i) % 24
        local timeString = string.format('%02d:00', forecastHour)
        
        -- Randomly select weather type with some logic
        local weatherType = currentWeather.type
        
        -- Add some variation to forecast
        if math.random(1, 100) > 70 then
            -- 30% chance of weather change
            local changeIndex = math.random(1, #weatherTypes)
            weatherType = weatherTypes[changeIndex]
        end
        
        table.insert(forecast, {
            time = timeString,
            type = weatherType,
            temperature = GenerateTemperature(weatherType),
            precipitation = weatherPrecipitation[weatherType] or 0,
            windSpeed = GenerateWindSpeed(weatherType)
        })
    end
    
    weatherForecast = forecast
end

-- Initialize weather system
local function InitializeWeather()
    UpdateCurrentWeather()
    
    if Config.WeatherApp.showForecast then
        GenerateForecast()
    end
    
    print('^2[Phone] Weather system initialized^7')
end

-- Update weather data periodically
CreateThread(function()
    -- Initialize on start
    InitializeWeather()
    
    -- Update every 5 minutes (or configured interval)
    while true do
        Wait(Config.WeatherApp.updateInterval or 300000)
        
        if Config.WeatherApp.syncWithServer then
            UpdateCurrentWeather()
            
            if Config.WeatherApp.showForecast then
                GenerateForecast()
            end
            
            -- Broadcast update to all players with weather app open
            TriggerClientEvent('phone:client:weatherUpdated', -1, {
                current = currentWeather,
                forecast = weatherForecast
            })
        end
    end
end)

-- Get weather data
RegisterNetEvent('phone:server:getWeatherData', function()
    local src = source
    
    -- Update weather if sync is enabled
    if Config.WeatherApp.syncWithServer then
        UpdateCurrentWeather()
    end
    
    TriggerClientEvent('phone:client:receiveWeatherData', src, {
        success = true,
        current = currentWeather,
        forecast = Config.WeatherApp.showForecast and weatherForecast or {}
    })
end)

-- Export for other resources
exports('GetCurrentWeather', function()
    return currentWeather
end)

exports('GetWeatherForecast', function()
    return weatherForecast
end)

print('^2[Phone] Weather app loaded successfully^7')
