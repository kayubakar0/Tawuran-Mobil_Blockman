local gameStageMgr

local winPart = {}

winPart.Part = nil                 --Bound main part
winPart.Map = nil                  --Corresponding map
winPart.ObjIDTb = nil             --Record if the player passed the endpoint

function winPart:RegisterTouchBeginEvent(myPart)
    local this = self
    self.TouchBeginCancelFunc = Trigger.addHandler(Entity.GetCfg("myplugin/player1"), "ENTITY_TOUCH_PART_BEGIN", function(context)
        local entity = context.obj1
        local part = context.part

        if part ~= myPart or this.ObjIDTb[entity.objID] then
            return
        end

        this.ObjIDTb[entity.objID] = true
        gameStageMgr.HandlerPlayerWin(entity)
    end)
end

function winPart:Init(packet, map)
    local part = map.Root:FindFirstChild(packet.PartName,true)

    self.ObjIDTb = {}
    self.Pos = part.WorldPosition
    for i, v in pairs(packet) do
        self[i] = v
    end

    self.Part = part
    self.Map = map
    self:RegisterTouchBeginEvent(part)
end

function winPart:Destroy()
    self.TouchBeginCancelFunc()
end

local mapOrganDataTb = {
    map001 = {
        { PartName = 'WinPart' },
    },
}
local organTb = {}

local winPartMgr = {}
function winPartMgr:StartOrgan(map)
    local mapOrganData = mapOrganDataTb[map.Name]
    gameStageMgr = require "script_server.gameStageMgr"
    for i, organData in ipairs(mapOrganData or {}) do
        local winPartInstance = {}
        Lib.derive(winPart, winPartInstance)
        winPartInstance:Init(organData, map)
        table.insert(organTb, winPartInstance)
    end
end

function winPartMgr:ClearOrgan()
    for i, organ in ipairs(organTb or {}) do
        organ:Destroy()
    end
    organTb = {}
end

return winPartMgr