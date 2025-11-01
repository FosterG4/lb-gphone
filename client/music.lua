-- Music Player Module
-- Handles audio streaming integration with xsound for Musicly app

local Music = {}
local currentTrack = nil
local currentStation = nil
local isPlaying = false
local volume = 50
local soundId = nil
local isBackgroundPlay = true
local repeatMode = 'off' -- 'off', 'all', 'one'
local isShuffled = false
local playlist = {}
local playlistIndex = 1

-- Configuration
local audioResource = Config.MusiclyApp and Config.MusiclyApp.audioResource or 'xsound'
local defaultVolume = Config.MusiclyApp and Config.MusiclyApp.defaultVolume or 50
local enableBackgroundPlay = Config.MusiclyApp and Config.MusiclyApp.enableBackgroundPlay or true

-- Initialize music module
function Music.Initialize()
    volume = defaultVolume
    isBackgroundPlay = enableBackgroundPlay
    
    if Config.DebugMode then
        print('[Phone Music] Music module initialized')
        print('[Phone Music] Audio resource: ' .. audioResource)
        print('[Phone Music] Background play: ' .. tostring(isBackgroundPlay))
    end
end

-- Check if xsound is available
function Music.IsXSoundAvailable()
    return GetResourceState('xsound') == 'started'
end

-- Play a track
function Music.PlayTrack(track)
    if not track or not track.stream_url then
        if Config.DebugMode then
            print('[Phone Music] Invalid track data')
        end
        return false
    end
    
    -- Stop current playback
    Music.Stop()
    
    currentTrack = track
    currentStation = nil
    
    if audioResource == 'xsound' and Music.IsXSoundAvailable() then
        -- Use xsound for playback
        local soundName = 'phone_music_' .. GetPlayerServerId(PlayerId())
        
        exports.xsound:PlayUrl(soundName, track.stream_url, volume / 100, false, {
            onPlayStart = function()
                isPlaying = true
                soundId = soundName
                
                -- Notify NUI
                SendNUIMessage({
                    action = 'musicPlaybackStarted',
                    data = {
                        track = track,
                        isPlaying = true
                    }
                })
                
                if Config.DebugMode then
                    print('[Phone Music] Started playing: ' .. track.title)
                end
            end,
            onPlayEnd = function()
                isPlaying = false
                
                -- Handle repeat and next track
                if repeatMode == 'one' then
                    Music.PlayTrack(track)
                elseif repeatMode == 'all' or #playlist > 0 then
                    Music.NextTrack()
                else
                    Music.Stop()
                end
                
                -- Notify NUI
                SendNUIMessage({
                    action = 'musicPlaybackEnded',
                    data = {
                        track = track
                    }
                })
            end
        })
        
        -- Log play to server for analytics
        TriggerServerEvent('phone:server:playTrack', track)
        
        return true
    else
        -- Fallback: notify NUI to handle playback
        SendNUIMessage({
            action = 'musicPlayTrack',
            data = {
                track = track,
                volume = volume
            }
        })
        
        isPlaying = true
        
        -- Log play to server
        TriggerServerEvent('phone:server:playTrack', track)
        
        return true
    end
end

-- Play a radio station
function Music.PlayStation(station)
    if not station or not station.stream_url then
        if Config.DebugMode then
            print('[Phone Music] Invalid station data')
        end
        return false
    end
    
    -- Stop current playback
    Music.Stop()
    
    currentStation = station
    currentTrack = nil
    
    if audioResource == 'xsound' and Music.IsXSoundAvailable() then
        -- Use xsound for radio streaming
        local soundName = 'phone_radio_' .. GetPlayerServerId(PlayerId())
        
        exports.xsound:PlayUrl(soundName, station.stream_url, volume / 100, true, {
            onPlayStart = function()
                isPlaying = true
                soundId = soundName
                
                -- Notify NUI
                SendNUIMessage({
                    action = 'radioPlaybackStarted',
                    data = {
                        station = station,
                        isPlaying = true
                    }
                })
                
                if Config.DebugMode then
                    print('[Phone Music] Started radio: ' .. station.name)
                end
            end
        })
        
        -- Log radio play to server
        TriggerServerEvent('phone:server:playRadioStation', station)
        
        return true
    else
        -- Fallback: notify NUI to handle playback
        SendNUIMessage({
            action = 'radioPlayStation',
            data = {
                station = station,
                volume = volume
            }
        })
        
        isPlaying = true
        
        -- Log to server
        TriggerServerEvent('phone:server:playRadioStation', station)
        
        return true
    end
end

-- Pause playback
function Music.Pause()
    if not isPlaying then
        return false
    end
    
    if audioResource == 'xsound' and Music.IsXSoundAvailable() and soundId then
        exports.xsound:Pause(soundId)
    end
    
    isPlaying = false
    
    -- Notify NUI
    SendNUIMessage({
        action = 'musicPaused',
        data = {
            track = currentTrack,
            station = currentStation
        }
    })
    
    if Config.DebugMode then
        print('[Phone Music] Playback paused')
    end
    
    return true
end

-- Resume playback
function Music.Resume()
    if isPlaying then
        return false
    end
    
    if audioResource == 'xsound' and Music.IsXSoundAvailable() and soundId then
        exports.xsound:Resume(soundId)
    end
    
    isPlaying = true
    
    -- Notify NUI
    SendNUIMessage({
        action = 'musicResumed',
        data = {
            track = currentTrack,
            station = currentStation
        }
    })
    
    if Config.DebugMode then
        print('[Phone Music] Playback resumed')
    end
    
    return true
end

-- Toggle play/pause
function Music.TogglePlayPause()
    if isPlaying then
        return Music.Pause()
    else
        return Music.Resume()
    end
end

-- Stop playback
function Music.Stop()
    if audioResource == 'xsound' and Music.IsXSoundAvailable() and soundId then
        exports.xsound:Destroy(soundId)
    end
    
    isPlaying = false
    soundId = nil
    
    -- Notify NUI
    SendNUIMessage({
        action = 'musicStopped'
    })
    
    if Config.DebugMode then
        print('[Phone Music] Playback stopped')
    end
    
    return true
end

-- Set volume (0-100)
function Music.SetVolume(newVolume)
    if newVolume < 0 or newVolume > 100 then
        return false
    end
    
    volume = newVolume
    
    if audioResource == 'xsound' and Music.IsXSoundAvailable() and soundId then
        exports.xsound:setVolume(soundId, volume / 100)
    end
    
    -- Notify NUI
    SendNUIMessage({
        action = 'musicVolumeChanged',
        data = {
            volume = volume
        }
    })
    
    if Config.DebugMode then
        print('[Phone Music] Volume set to: ' .. volume)
    end
    
    return true
end

-- Get current volume
function Music.GetVolume()
    return volume
end

-- Set repeat mode
function Music.SetRepeatMode(mode)
    if mode ~= 'off' and mode ~= 'all' and mode ~= 'one' then
        return false
    end
    
    repeatMode = mode
    
    -- Notify NUI
    SendNUIMessage({
        action = 'musicRepeatModeChanged',
        data = {
            repeatMode = repeatMode
        }
    })
    
    if Config.DebugMode then
        print('[Phone Music] Repeat mode set to: ' .. repeatMode)
    end
    
    return true
end

-- Get repeat mode
function Music.GetRepeatMode()
    return repeatMode
end

-- Set shuffle mode
function Music.SetShuffle(enabled)
    isShuffled = enabled
    
    -- Notify NUI
    SendNUIMessage({
        action = 'musicShuffleChanged',
        data = {
            isShuffled = isShuffled
        }
    })
    
    if Config.DebugMode then
        print('[Phone Music] Shuffle set to: ' .. tostring(isShuffled))
    end
    
    return true
end

-- Get shuffle mode
function Music.IsShuffled()
    return isShuffled
end

-- Set playlist
function Music.SetPlaylist(tracks, startIndex)
    playlist = tracks or {}
    playlistIndex = startIndex or 1
    
    if Config.DebugMode then
        print('[Phone Music] Playlist set with ' .. #playlist .. ' tracks')
    end
    
    return true
end

-- Next track
function Music.NextTrack()
    if #playlist == 0 then
        Music.Stop()
        return false
    end
    
    if isShuffled then
        -- Random track
        playlistIndex = math.random(1, #playlist)
    else
        -- Next track in order
        playlistIndex = playlistIndex + 1
        if playlistIndex > #playlist then
            if repeatMode == 'all' then
                playlistIndex = 1
            else
                Music.Stop()
                return false
            end
        end
    end
    
    local nextTrack = playlist[playlistIndex]
    if nextTrack then
        Music.PlayTrack(nextTrack)
        return true
    end
    
    return false
end

-- Previous track
function Music.PreviousTrack()
    if #playlist == 0 then
        return false
    end
    
    if isShuffled then
        -- Random track
        playlistIndex = math.random(1, #playlist)
    else
        -- Previous track in order
        playlistIndex = playlistIndex - 1
        if playlistIndex < 1 then
            playlistIndex = #playlist
        end
    end
    
    local prevTrack = playlist[playlistIndex]
    if prevTrack then
        Music.PlayTrack(prevTrack)
        return true
    end
    
    return false
end

-- Seek to position (seconds)
function Music.SeekTo(position)
    if audioResource == 'xsound' and Music.IsXSoundAvailable() and soundId then
        exports.xsound:setTimeStamp(soundId, position)
        
        if Config.DebugMode then
            print('[Phone Music] Seeked to: ' .. position .. 's')
        end
        
        return true
    end
    
    return false
end

-- Get current playback position
function Music.GetPosition()
    if audioResource == 'xsound' and Music.IsXSoundAvailable() and soundId then
        local info = exports.xsound:getInfo(soundId)
        if info then
            return info.currentTime or 0
        end
    end
    
    return 0
end

-- Get current track duration
function Music.GetDuration()
    if currentTrack and currentTrack.duration then
        return currentTrack.duration
    end
    
    if audioResource == 'xsound' and Music.IsXSoundAvailable() and soundId then
        local info = exports.xsound:getInfo(soundId)
        if info then
            return info.duration or 0
        end
    end
    
    return 0
end

-- Get playback status
function Music.GetStatus()
    return {
        isPlaying = isPlaying,
        currentTrack = currentTrack,
        currentStation = currentStation,
        volume = volume,
        repeatMode = repeatMode,
        isShuffled = isShuffled,
        position = Music.GetPosition(),
        duration = Music.GetDuration()
    }
end

-- Check if music should continue when phone is closed
function Music.ShouldContinueInBackground()
    return isBackgroundPlay
end

-- Register NUI callbacks
RegisterNUICallback('musicPlayTrack', function(data, cb)
    local success = Music.PlayTrack(data.track)
    cb({ success = success })
end)

RegisterNUICallback('musicPlayStation', function(data, cb)
    local success = Music.PlayStation(data.station)
    cb({ success = success })
end)

RegisterNUICallback('musicTogglePlayPause', function(data, cb)
    local success = Music.TogglePlayPause()
    cb({ success = success, isPlaying = isPlaying })
end)

RegisterNUICallback('musicPause', function(data, cb)
    local success = Music.Pause()
    cb({ success = success })
end)

RegisterNUICallback('musicResume', function(data, cb)
    local success = Music.Resume()
    cb({ success = success })
end)

RegisterNUICallback('musicStop', function(data, cb)
    local success = Music.Stop()
    cb({ success = success })
end)

RegisterNUICallback('musicSetVolume', function(data, cb)
    local success = Music.SetVolume(data.volume)
    cb({ success = success })
end)

RegisterNUICallback('musicSetRepeatMode', function(data, cb)
    local success = Music.SetRepeatMode(data.mode)
    cb({ success = success })
end)

RegisterNUICallback('musicSetShuffle', function(data, cb)
    local success = Music.SetShuffle(data.enabled)
    cb({ success = success })
end)

RegisterNUICallback('musicSetPlaylist', function(data, cb)
    local success = Music.SetPlaylist(data.tracks, data.startIndex)
    cb({ success = success })
end)

RegisterNUICallback('musicNextTrack', function(data, cb)
    local success = Music.NextTrack()
    cb({ success = success })
end)

RegisterNUICallback('musicPreviousTrack', function(data, cb)
    local success = Music.PreviousTrack()
    cb({ success = success })
end)

RegisterNUICallback('musicSeekTo', function(data, cb)
    local success = Music.SeekTo(data.position)
    cb({ success = success })
end)

RegisterNUICallback('musicGetStatus', function(data, cb)
    cb(Music.GetStatus())
end)

-- Client events
RegisterNetEvent('phone:client:startTrackPlayback', function(track)
    Music.PlayTrack(track)
end)

RegisterNetEvent('phone:client:startRadioPlayback', function(station)
    Music.PlayStation(station)
end)

RegisterNetEvent('phone:client:stopMusic', function()
    Music.Stop()
end)

-- Handle phone close - continue or stop music based on settings
AddEventHandler('phone:client:phoneClosed', function()
    if not Music.ShouldContinueInBackground() and isPlaying then
        Music.Stop()
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Music.Stop()
    end
end)

-- Initialize on resource start
CreateThread(function()
    Music.Initialize()
end)

-- Export functions
exports('GetMusicStatus', Music.GetStatus)
exports('IsPlaying', function() return isPlaying end)
exports('StopMusic', Music.Stop)

return Music
