local audioData = {
    waitBgm = { SoundType = '2d', SoundPath = 'asset/Sound/BGM_Hall.mp3', Volume = 1, Time = -1 },
    prepareBgm = { SoundType = '2d', SoundPath = 'asset/Sound/BGM_Ready.mp3', Volume = 1, Time = -1 },
    map001Bgm = { SoundType = '2d', SoundPath = 'asset/Sound/BGM_Level_1.mp3', Volume = 1, Time = -1 },
    map002Bgm = { SoundType = '2d', SoundPath = 'asset/Sound/BGM_Level_2.mp3', Volume = 1, Time = -1 },
    map003Bgm = { SoundType = '2d', SoundPath = 'asset/Sound/BGM_Level_3.mp3', Volume = 1, Time = -1 },
    countdown = { SoundType = '2d', SoundPath = 'asset/Sound/SE_Countdown.mp3', Volume = 1, Time = 5 },
    go = { SoundType = '2d', SoundPath = 'asset/Sound/SE_Go.mp3', Volume = 1, Time = 2 },
    die = { SoundType = '2d', SoundPath = 'asset/Sound/SE_PlayerDie.mp3', Volume = 1, Time = 2 },
    click = { SoundType = '2d', SoundPath = 'asset/Sound/SE_Check.mp3', Volume = 1, Time = 2 },
    win = { SoundType = '2d', SoundPath = 'asset/Sound/SE_PlayerWin.mp3', Volume = 1, Time = 2 },
    fail = { SoundType = '2d', SoundPath = 'asset/Sound/SE_PlayerLose.mp3', Volume = 1, Time = 2 },
}
local function GetSoundCfg(soundName)
    return audioData[soundName]
end

local audioMgr = {}
local audioEngine = TdAudioEngine.Instance()

local soundList = {}
local soundIDTb = {}

local globalMusicID

function audioMgr.PlaySound(soundName, pos)
    local soundData = GetSoundCfg(soundName)
    print('play Sound----------------------',soundName)
    if not soundData then
        return
    end

    local soundID
    if soundData.SoundType == '3d' then
        soundID = audioEngine:play3dSound(soundData.SoundPath, pos)
    else
        soundID = audioEngine:play2dSound(soundData.SoundPath, soundData.Time == -1)
    end

    if soundID and soundID ~= 0 then
        audioEngine:setSoundsVolume(soundID, soundData.Volume)
        local stopTime = soundData.Time
        --If time is not equal to -1, start a timer to close
        if stopTime ~= -1 then
            soundList[soundID] = Timer.new(stopTime * 20, function()
                audioEngine:stopSound(soundID)
                soundList[soundID] = nil
            end)
            soundList[soundID]:Start()
        end
    end
    soundIDTb[soundName] = soundID
    return soundID
end

function audioMgr.StopSound(soundID)
    if soundList[soundID] then
        soundList[soundID]:Stop()
        soundList[soundID] = nil
    end
    audioEngine:stopSound(soundID)
end

function audioMgr.PlayGlobalSound(soundName)
    --If globalMusicID exists, stop playing this sound
    local useless = globalMusicID and audioMgr.StopSound(globalMusicID)
    globalMusicID = audioMgr.PlaySound(soundName)
end

PackageHandlers:Receive("PlaySound", function(player, packet)
    audioMgr.PlaySound(packet.SoundName, packet.Pos)
end)

PackageHandlers:Receive("PlayGlobalSound", function(player, packet)
    audioMgr.PlayGlobalSound(packet.SoundName, packet.Pos)
end)

return audioMgr

