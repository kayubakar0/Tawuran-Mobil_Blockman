local toxicRiver = {}

toxicRiver.MaxDetailY = 0.24                    --Highest Y-axis coordinates based on initial position offset
toxicRiver.MinDetailY = -6                   --Lowest Y-axis coordinates based on initial position offset
toxicRiver.Speed = 0.08                       --Ascending speed
toxicRiver.MaxPosStayTime = 3 * 20           --Stay duration at maximum height
toxicRiver.MinPosStayTime = 4 * 20           --Stay duration at minimum height
toxicRiver.CanMove = true


toxicRiver.NextPos = nil                     --Next target point
toxicRiver.CurDir = nil                      --Current interpolation vector
toxicRiver.StopTime = 0                      --Duration of stay
toxicRiver.Part = nil                        --Bound main part
toxicRiver.Map = nil                         --Corresponding map

function toxicRiver:CalcNextDir()
    local dir = (self.NextPos - self.Part.WorldPosition)
    self.CurDir = dir.Normalized * self.Speed
end

function toxicRiver:ChangeNextPos()
    local isMin = self.NextPos == self.MinPos
    self.NextPos = isMin and self.MaxPos or self.MinPos
    self:CalcNextDir()
    self.StopTime = isMin and self.MinPosStayTime or self.MaxPosStayTime
end

function toxicRiver:RegisterTouchBeginEvent(myPart)
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

function toxicRiver:Init(packet, map)
    local part = map.Root:FindFirstChild(packet.PartName,true)
    local checkPlatformPart = part:FindFirstChild(packet.CheckPartName)

    for i, v in pairs(packet) do
        self[i] = v
    end
    local pos = part.WorldPosition
    self.MaxPos = pos + Vector3.new(0, self.MaxDetailY, 0)
    self.MinPos = pos + Vector3.new(0, self.MinDetailY, 0)
    self.Part = part
    self.Map = map
    self:RegisterTouchBeginEvent(checkPlatformPart)

    if not self.CanMove then
        return
    end

    self:ChangeNextPos()

    self.Timer = Timer.new(1, self.Tick,self)
    self.Timer.Loop = true
    self.Timer:Start()
end

function toxicRiver:Destroy()
    self.TouchBeginCancelFunc()
    if self.Timer then
        self.Timer:Stop()
    end
end

function toxicRiver:Tick()
    --Ensure that the map is valid before operating the mechanism
    if not self.Map:IsValid() then
        self:Destroy()
        return
    end
    local part = self.Part
    local pos = part.WorldPosition
    local distance = Vector3.Distance(pos, self.NextPos)

    if distance < 0.5 then
        self:ChangeNextPos()
        self.Timer.Delay = self.StopTime
    else
        part.WorldPosition = pos + self.CurDir
        self.Timer.Delay = 1
    end
end

local mapOrganDataTb = {
    map001 = {
        { PartName = 'ToxicRiver_1',CheckPartName = 'CheckPlatform' ,CanMove = false},
        { PartName = 'ToxicRiver_2',CheckPartName = 'CheckPlatform' }
    }
}
local organTb = {}

local toxicRiverMgr = {}
function toxicRiverMgr:StartOrgan(map)
    local mapOrganData = mapOrganDataTb[map.Name]

    for i, organData in ipairs(mapOrganData or {}) do
        local toxicRiverInstance = {}
        Lib.derive(toxicRiver, toxicRiverInstance)
        toxicRiverInstance:Init(organData, map)
        table.insert(organTb, toxicRiverInstance)
    end
end

function toxicRiverMgr:ClearOrgan()
    for i, organ in ipairs(organTb or {}) do
        organ:Destroy()
    end
    organTb = {}
end

return toxicRiverMgr