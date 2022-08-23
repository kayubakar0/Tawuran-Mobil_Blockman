local mapMgr = require "script_server.mapMgr"
local scoreMgr = require "script_server.scoreMgr"

local STATE = {
    PREPARE = 1,
    START = 2,
    GAMEOVER = 3
}

local prepareTime = 10                   --Game preparation time
local gameTotalTime = 200                --Total game time
local gameOverWaitTime = 10              --Wait time after the game ends

local playerTb = {}                    --Player list
local playerSum = 0                      --Number of players
local playerWinSumRatio = 0.7            --The percentage of players who have passed the game, which is used to calculate the total number of players who have passed the game
local winTotalSum = 0                  --The total number of players who have passed the game and won; if the number exceeds this, the game is over
local winPlayerTb = {}                 -- List of the players who have passed the game
local playerCfg = Entity.GetCfg('myplugin/player1')
local minPlayerSum = 2                 --Minimum number of players to start the game

local gameStageMgr = {}
gameStageMgr.Timer = nil                 --Game stage loop timer function
gameStageMgr.CurStage = nil              --Current game stage

--Send server-side protocols to players in the game list,func modifies the data
function gameStageMgr.BroadcastServerHandler(name, packet, func)
    for i, player in pairs(playerTb) do
        if func then
            func(player, packet)
        end
        PackageHandlers:SendToClient(player, name, packet)
    end
end

--Update the progress of the number of people who have passed the game
function gameStageMgr.UpdateWinProgress()
    gameStageMgr.BroadcastServerHandler(
            'SetWinProgress', { WinSum = #winPlayerTb, WinTotalSum = winTotalSum })
end

--Calculate the total number of players who have passed the game and won
function gameStageMgr.CalcWinTotalSum()
    winTotalSum = math.ceil(playerSum * playerWinSumRatio)
    --Need to dynamically change the UI at the start of the game
    if gameStageMgr.CurStage == STATE.START then
        gameStageMgr.UpdateWinProgress()
    end
end

--Handle switching game stages, start the timer for this stage, func is its own logic for each stage
function gameStageMgr.HandlerSwitchStage(stage, time, func)
    gameStageMgr.Time = time
    gameStageMgr.CurStage = stage

    gameStageMgr.Timer = Timer.new(20, function()
        gameStageMgr.Time = gameStageMgr.Time - 1
        gameStageMgr.Timer.Loop = func(gameStageMgr.Time)
    end)
    gameStageMgr.Timer.Loop = true
    gameStageMgr.Timer:Start()
end

--Processing game preparation to start
function gameStageMgr.GamePrepare()
    gameStageMgr.BroadcastServerHandler('HandlerPrepareCountdown', { Time = prepareTime })
    gameStageMgr.HandlerSwitchStage(STATE.PREPARE, prepareTime, function(time)
        gameStageMgr.BroadcastServerHandler('HandlerPrepareCountdown', { Time = time })
        if time == 0 then
            gameStageMgr.GameStart()
            return
        end
        return true
    end)

    mapMgr.HandlerGamePrepare(playerTb)

    gameStageMgr.BroadcastServerHandler('HandlerGamePrepare', { MapLangKeyData = mapMgr.GetCurMapLangKeyData() })
end

--Processing game start
function gameStageMgr.GameStart()
    gameStageMgr.HandlerSwitchStage(STATE.START, gameTotalTime, function(time)
        gameStageMgr.BroadcastServerHandler('SetTime', { Time = time })

        if time == 0 then
            gameStageMgr.GameOver(gameStageMgr.Time)
            return
        end
        return true
    end)

    mapMgr.HandlerGameStart()

    gameStageMgr.BroadcastServerHandler('HandlerGameStart',
            { Time = gameStageMgr.Time, WinSum = #winPlayerTb,
              WinTotalSum = winTotalSum, SoundName = mapMgr.GetCurMapName() .. 'Bgm' })
end

--Processing game end
function gameStageMgr.GameOver()
    --Before the time runs out, and the game ends, the timer needs to be switched off
    if  gameStageMgr.Timer then
        gameStageMgr.Timer:Stop()
        gameStageMgr.Timer = nil
    end

    mapMgr.HandlerGameOver(playerTb)

    gameStageMgr.HandlerSwitchStage(STATE.GAMEOVER, gameOverWaitTime, function(time)
        gameStageMgr.BroadcastServerHandler('HandlerGameOverCountdown', { Time = time })

        if playerSum < minPlayerSum then
            gameStageMgr.BroadcastServerHandler('OpenTip', { Tip = 'LangKey_waitPlayerTip' })
        end

        if time == 0 then
            if playerSum >= minPlayerSum then
                gameStageMgr.GamePrepare()    --Enter the game preparation stage
            else
                gameStageMgr.CurStage = nil
                mapMgr.SetPlayersToHall(playerTb)
                gameStageMgr.BroadcastServerHandler('PlayGlobalSound', { SoundName = 'prepareBgm' })
            end
            return
        end
        return true
    end)

    gameStageMgr.BroadcastServerHandler('HandlerGameOver',
            { Rank = scoreMgr.GetPlayersScoreTb(playerTb, winPlayerTb), Time = gameOverWaitTime }
    ,function(player, packet)
                packet.winIndex = gameStageMgr.GetPlayerWinIndex(player)
            end)

    winPlayerTb = {}--Clear the list of players who won
end

function gameStageMgr.CheckGameOver()
    if #winPlayerTb >= winTotalSum then
        gameStageMgr.GameOver(gameStageMgr.Time)
    end
end

--Handling player victory logic
function gameStageMgr.HandlerPlayerWin(player)
    if gameStageMgr.CurStage ~= STATE.START then
        return
    end
    table.insert(winPlayerTb, player)
    mapMgr.SetPlayerWatching(player)
    PackageHandlers:SendToClient(player, 'ShowWinUI', { Rank = #winPlayerTb })
    gameStageMgr.UpdateWinProgress()
    gameStageMgr.CheckGameOver()
end

--Get the player's index in the win list
function gameStageMgr.GetPlayerWinIndex(player)
    for i, _player in ipairs(winPlayerTb) do
        if player == _player then
            return i
        end
    end
end

--Receive player entry trigger and process them accordingly to the current game stage
function gameStageMgr.PlayerEnter(player)
    playerTb[player.objID] = player
    playerSum = playerSum + 1
    gameStageMgr.CalcWinTotalSum()

    if gameStageMgr.CurStage == STATE.PREPARE then
        mapMgr.BornPlayer(player)
        PackageHandlers:SendToClient(player, 'PlayGlobalSound', { SoundName = 'prepareBgm' })

    elseif gameStageMgr.CurStage == STATE.START then
        mapMgr.BornPlayer(player)
        mapMgr.ShowMapUI(player)
        PackageHandlers:SendToClient(player, 'HandlerMidwayJoin',
                { MapName = mapMgr.GetCurMapName(),MapLangKeyData = mapMgr.GetCurMapLangKeyData() })

    elseif gameStageMgr.CurStage == STATE.GAMEOVER then
        mapMgr.SetPlayerWatching(player)

    else
        if playerSum >= minPlayerSum then
            gameStageMgr.GamePrepare()    --Enter the game preparation stage
        else
            PackageHandlers:SendToClient(player, 'OpenTip', { Tip = 'LangKey_waitPlayerTip' })
        end
    end
end

Trigger.RegisterHandler(playerCfg, "ENTITY_ENTER", function(context)
    local player = context.obj1
    PackageHandlers:SendToClient(player, 'PlayGlobalSound', { SoundName = 'waitBgm' })
    local timer = Timer.new(160, function()
        if player and player:isValid() then
            gameStageMgr.PlayerEnter(player)
        end
    end)
    timer:Start()
end)

--Receive the player leaving event, and make corresponding processing according to the current game stage
function gameStageMgr.PlayerExit(player)
    playerTb[player.objID] = nil
    playerSum = playerSum - 1

    --If the player who left the game has already passed the game, then you need to remove his reference
    local index = gameStageMgr.GetPlayerWinIndex(player)
    if index then
        table.remove(winPlayerTb, index)
    end
    gameStageMgr.CalcWinTotalSum()
    gameStageMgr.CheckGameOver()

end

Trigger.RegisterHandler(playerCfg, "ENTITY_LEAVE", function(context)
    local player = context.obj1
    gameStageMgr.PlayerExit(player)
end)

PackageHandlers:Receive("RequestRankData", function(player, packet)
    PackageHandlers:SendToClient(player, 'SetRank', { Rank = scoreMgr.GetPlayersScoreTb(playerTb) })
end)

return gameStageMgr



