local recordPartMgr = require "script_server.Organ.recordPart"
local toxicRiverMgr = require "script_server.Organ.toxicRiver"
local turnTableMgr = require "script_server.Organ.turnTable"
local liftingPlatformMgr = require "script_server.Organ.liftingPlatform"
local winPartMgr = require "script_server.Organ.winPart"
local spotlightMgr = require "script_server.Organ.spotlight"
local obstaclesFactoryMgr = require "script_server.Organ.obstaclesFactory"

local mapMgr = {}
mapMgr.CurMap = nil   --   Current map instance

local mapNameTb = {
    'map001',
    'map002',
    'map003',
}

-- random spawn area
local randomBirthRegion = {
    [mapNameTb[1]] = { min = Vector3.new(-16, 65, -19), max = Vector3.new(17, 66, 2) },
    [mapNameTb[2]] = { min = Vector3.new(7, 18, -15), max = Vector3.new(17, 21, 16) },
    [mapNameTb[3]] = { min = Vector3.new(-8, 30, -15), max = Vector3.new(3, 31, 14) },
}

local watchingPos = {
    [mapNameTb[1]] = Vector3.new(50, 64, 133),
    [mapNameTb[2]] = Vector3.new(25, 8, -11),
    [mapNameTb[3]] = Vector3.new(-42, 40, 0),
}

local mapUILangKey = {
    [mapNameTb[1]] = { Name =  'LangKey_map1Name', Tip = 'LangKey_map1Info' },
    [mapNameTb[2]] = { Name =  'LangKey_map2Name', Tip = 'LangKey_map2Info' },
    [mapNameTb[3]] = { Name =  'LangKey_map3Name', Tip = 'LangKey_map3Info' }
}

local curMapName = ''

--Set player location
function mapMgr.BornPlayer(player)
    local pos = Lib.randPosInRegion(randomBirthRegion[curMapName])
    player:setMapPos(mapMgr.CurMap, pos)
    player:setRebirthPos(pos, mapMgr.CurMap)
end

--Set player to spectator coordinates
function mapMgr.SetPlayerWatching(player)
    player:setPos(watchingPos[curMapName])
end

--Get the current map name
function mapMgr.GetCurMapName()
   return curMapName
end

--Get the multilingual key of the current map
function mapMgr.GetCurMapLangKeyData()
    return mapUILangKey[curMapName]
end

function mapMgr.GetRandomMap()
    local nextMapTb = {}
    --Exclude the current map, this time a random map will not be selected
    if mapMgr.CurMap then
        for i, mapName in ipairs(mapNameTb) do
            if mapName ~= mapMgr.CurMap.Name then
                table.insert(nextMapTb, mapName)
            end
        end
    else
        nextMapTb = mapNameTb
    end
    math.randomseed(os.time())

    local random = math.random(#nextMapTb)
    curMapName = nextMapTb[random]
    return World:CreateDynamicMap(curMapName, true)   --Generate a new map
end

--Receive game start trigger and disable the air wall
function mapMgr.HandlerGameStart()
    mapMgr.InitMapData()
    local part = mapMgr.CurMap.Root:FindFirstChild('AirWall')
    part.WorldPosition = Vector3.new(500, 0, 0)                       --Remove the air wall
end

function mapMgr.HandlerGamePrepare(playerTb)
    mapMgr.CurMap = mapMgr.GetRandomMap()

    for i, player in pairs(playerTb) do
        mapMgr.BornPlayer(player)
        player:setData('recordPoint',player:getPosition())
    end
end

function mapMgr.HandlerGameOver(playerTb)
    for i, player in pairs(playerTb) do
        mapMgr.SetPlayerWatching(player)
    end
    mapMgr.ClearOrgan()
end

function mapMgr.SetPlayersToHall(playerTb)
    for i, player in pairs(playerTb) do
        player:setMapPos(World.DefaultMap,Vector3.new(0,5,0))
    end
end

--Initialize map data and generate mechanisms
function mapMgr.InitMapData()
    recordPartMgr:StartOrgan(mapMgr.CurMap)
    toxicRiverMgr:StartOrgan(mapMgr.CurMap)
    turnTableMgr:StartOrgan(mapMgr.CurMap)
    liftingPlatformMgr:StartOrgan(mapMgr.CurMap)
    winPartMgr:StartOrgan(mapMgr.CurMap)
    spotlightMgr:StartOrgan(mapMgr.CurMap)
    obstaclesFactoryMgr:StartOrgan(mapMgr.CurMap)
end

function mapMgr.ClearOrgan()
    recordPartMgr:ClearOrgan()
    toxicRiverMgr:ClearOrgan()
    turnTableMgr:ClearOrgan()
    liftingPlatformMgr:ClearOrgan()
    winPartMgr:ClearOrgan()
    spotlightMgr:ClearOrgan()
    obstaclesFactoryMgr:ClearOrgan()
end

function mapMgr.ShowMapUI(player)
    if spotlightMgr.HasOrgan then
        PackageHandlers:SendToClient(player, 'ShowProgress')
    end
end


return mapMgr

