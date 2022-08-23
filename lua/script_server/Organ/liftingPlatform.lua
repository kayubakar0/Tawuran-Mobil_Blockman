local liftingPlatform = {}

liftingPlatform.MaxDetailY = 3.5                    --Highest Y-axis coordinates based on initial position offset
liftingPlatform.MinDetailY = -10                   --Lowest Y-axis coordinates based on initial position offset

liftingPlatform.Speed = 0.05                       --Moving speed
liftingPlatform.MaxPosStayTime = 5 * 20           --Highest point stay duration
liftingPlatform.MinPosStayTime = 1 * 20            --Lowest point stay duration

liftingPlatform.NextPos = nil             --Next target point
liftingPlatform.CurDir = nil               --Current interpolation vector
liftingPlatform.StopTime = 0               --Duration of stay
liftingPlatform.Part = nil                 --Bound main part
liftingPlatform.Map = nil                  --Corresponding map

function liftingPlatform:CalcNextDir()
    local dir = (self.NextPos - self.Part.WorldPosition)
    self.CurDir = dir.Normalized * self.Speed
end

--Lift table moves down
function liftingPlatform:DownMove()
    self.NextPos = self.MinPos
    self:CalcNextDir()
end

function liftingPlatform:ChangeNextPos()
    local isMin = self.NextPos == self.MinPos
    self.NextPos = isMin and self.MaxPos or self.MinPos
    self:CalcNextDir()
    self.StopTime = isMin and self.MinPosStayTime or self.MaxPosStayTime
end

function liftingPlatform:RegisterTouchBeginEvent(myPart)
    local this = self
    self.TouchBeginCancelFunc = Trigger.addHandler(Entity.GetCfg("myplugin/player1"), "ENTITY_TOUCH_PART_BEGIN", function(context)
        local part = context.part

        if part ~= myPart then
            return
        end
        this:DownMove()
    end)
end

function liftingPlatform:Init(packet, map)
    local part = map.Root:FindFirstChild(packet.PartName,true)

    for i, v in pairs(packet) do
        self[i] = v
    end

    self.Part = part
    local pos = part.WorldPosition
    self.MaxPos = pos + Vector3.new(0, self.MaxDetailY, 0)
    self.MinPos = pos + Vector3.new(0, self.MinDetailY, 0)
    self.Map = map
    self:RegisterTouchBeginEvent(part)
    self.NextPos = self.MinPos
    self:ChangeNextPos()

    self.Timer = Timer.new(1, self.Tick,self)
    self.Timer.Loop = true
    self.Timer:Start()
end

function liftingPlatform:Destroy()
    self.TouchBeginCancelFunc()
    self.Timer:Stop()
end

function liftingPlatform:Tick()
    --Ensure that the map is valid before operating the mechanism
    if not self.Map:IsValid() then
        self.Timer:Destroy()
        return
    end
    local part = self.Part
    local pos = part.WorldPosition
    local distance = Vector3.Distance(self.Part.WorldPosition, self.NextPos)

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
        { PartName = 'LiftingPlatform_1' },
        { PartName = 'LiftingPlatform_2' }
    }
}
local organTb = {}

local liftingPlatformMgr = {}
function liftingPlatformMgr:StartOrgan(map)
     local mapOrganData = mapOrganDataTb[map.Name]
    for i, organData in ipairs(mapOrganData or {}) do
        local liftingPlatformInstance = {}
        Lib.derive(liftingPlatform, liftingPlatformInstance)
        liftingPlatformInstance:Init(organData, map)
       table.insert(organTb,liftingPlatformInstance)
    end
end

function liftingPlatformMgr:ClearOrgan()
    for i, organ in ipairs(organTb or {}) do
        organ:Destroy()
    end
    organTb = {}
end

return liftingPlatformMgr