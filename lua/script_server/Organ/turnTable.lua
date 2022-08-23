local turnTable = {}

turnTable.Pivot = nil                   --Rotating center part
turnTable.Pointer = nil                 --Spinning wheel pointer
turnTable.Map = nil                     --Corresponding map
turnTable.AngleVelocity = Vector3.new(0,50,0)

function turnTable:RegisterTouchBeginEvent(myPart)
    self.TouchBeginCancelFunc = Trigger.addHandler(Entity.GetCfg("myplugin/player1"), "ENTITY_TOUCH_PART_BEGIN", function(context)
        local entity = context.obj1
        local part = context.part

        if part ~= myPart then
            return
        end

        entity:setPos(entity:data('recordPoint'))
        PackageHandlers:SendToClient(entity, 'PlaySound', { SoundName = 'die' })
    end)
end

function turnTable:Init(packet, map)
    local pivot = map.Root:FindFirstChild(packet.PivotName,true)
    local pointer = map.Root:FindFirstChild(packet.PointerName,true)

    for i, v in pairs(packet) do
        self[i] = v
    end

    self.Pivot = pivot                 --Rotating center part
    self.Pointer = pointer
    self.Map = map
    self:RegisterTouchBeginEvent(pointer)

    self.Timer = Timer.new(1, self.Tick,self)
    self.Timer.Loop = true
    self.Timer:Start()
end

function turnTable:Destroy()
    self.TouchBeginCancelFunc()
    self.Timer:Stop()
end

function turnTable:Tick()
    --Ensure that the map is valid before operating the mechanism
    if not self.Map:IsValid() then
        self:Destroy()
    end
    local part = self.Pivot
    part.AngularVelocity = self.AngleVelocity
end

local mapOrganDataTb = {
    map001 = {
        { PivotName = 'TurntablePivot_1', PointerName = 'TurntablePointer_1' },
        { PivotName = 'TurntablePivot_2', PointerName = 'TurntablePointer_2' },
    },
}
local organTb = {}

local turnTableMgr = {}
function turnTableMgr:StartOrgan(map)
    local mapOrganData = mapOrganDataTb[map.Name]

    for i, organData in ipairs(mapOrganData or {}) do
        local turnTableInstance = {}
        Lib.derive(turnTable, turnTableInstance)
        turnTableInstance:Init(organData, map)
        table.insert(organTb, turnTableInstance)
    end
end

function turnTableMgr:ClearOrgan()
    for i, organ in ipairs(organTb or {}) do
        organ:Destroy()
    end
    organTb = {}
end

return turnTableMgr