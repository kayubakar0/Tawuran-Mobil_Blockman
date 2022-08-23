local recordPart = {}

recordPart.Part = nil                 --Bound main part
recordPart.Map = nil                  --Corresponding map
recordPart.ObjIDTb = nil             --Record if a player have passed a save point
recordPart.Pos = nil                  --Save point

function recordPart:RegisterTouchBeginEvent(myPart)
    local this = self
    self.TouchBeginCancelFunc = Trigger.addHandler(Entity.GetCfg("myplugin/player1"), "ENTITY_TOUCH_PART_BEGIN", function(context)
        local entity = context.obj1
        local part = context.part

        if part ~= myPart or this.ObjIDTb[entity.objID] then
            return
        end
        this.ObjIDTb[entity.objID] = true
        entity:setData('recordPoint',this.Pos)
    end)
end

function recordPart:Init(packet, map)
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

function recordPart:Destroy()
    self.TouchBeginCancelFunc()
end

local mapOrganDataTb = {
    map001 = {
        { PartName = 'RecordPart_1' },
        { PartName = 'RecordPart_2' },
        { PartName = 'RecordPart_3' },
        { PartName = 'RecordPart_4' },
        { PartName = 'RecordPart_5' },
    }
}
local organTb = {}

local recordPartMgr = {}
function recordPartMgr:StartOrgan(map)
    local mapOrganData = mapOrganDataTb[map.Name]
    for i, organData in ipairs(mapOrganData or {}) do
        local recordPartInstance = {}
        Lib.derive(recordPart, recordPartInstance)
        recordPartInstance:Init(organData, map)
        table.insert(organTb,recordPartInstance)
    end
end

function recordPartMgr:ClearOrgan()
    for i, organ in ipairs(organTb or {}) do
        organ:Destroy()
    end
    organTb = {}
end

return recordPartMgr