local gameStageMgr
local spotlight = {}

spotlight.RandomPosRegion = nil    --Used to select the region of random points
spotlight.CanMove = true
spotlight.Speed = 0.1                             --Light pillar movement speed
spotlight.DetailTime = 1 * 10                     --How long it takes in the light pillar to increase progress
spotlight.DetailProgress = 1                         --Progress increase per step
spotlight.TotalProgress = 100                         --Total progress
spotlight.TargetPos = nil
spotlight.Part = nil                              --Bound main part
spotlight.Map = nil                               --Corresponding map
spotlight.ProgressTb = nil                           --Player progress list
spotlight.TouchPlayerTb = nil                   --List of players who have touched

function spotlight:ChangeTargetPos()
    if not self.CanMove then
        return
    end
    local pos = Lib.randPosInRegion(self.RandomPosRegion)
    local dir = (pos - self.Part.WorldPosition).Normalized
    self.CurDir = dir * self.Speed
    self.TargetPos = pos
end

function spotlight:RegisterTouchBeginEvent(myPart)
    local this = self
    self.TouchBeginCancelFunc = Trigger.addHandler(Entity.GetCfg("myplugin/player1"), "ENTITY_TOUCH_PART_BEGIN", function(context)
        local entity = context.obj1
        local part = context.part

        if part ~= myPart or gameStageMgr.GetPlayerWinIndex(entity) then
            return
        end

        this.TouchPlayerTb[entity.objID] = Game.Time
    end)

    self.TouchEndCancelFunc = Trigger.addHandler(Entity.GetCfg("myplugin/player1"), "ENTITY_TOUCH_PART_END", function(context)
        local entity = context.obj1
        local part = context.part

        if part ~= myPart then
            return
        end
        this.TouchPlayerTb[entity.objID] = nil
    end)
end

function spotlight:CalcProgress()
    local now = Game.Time
    for objID, time in pairs(self.TouchPlayerTb) do
        if (now - time) > self.DetailTime then
            --When the stay duration is greater than the interval time, process progress calculation
            local curProgress = self.ProgressTb[objID]
            local entity = World.CurWorld:getObject(objID)
            if entity and entity:isValid() then
                self.ProgressTb[objID] = curProgress and curProgress + self.DetailProgress or self.DetailProgress
                self.TouchPlayerTb[objID] = now

                PackageHandlers:SendToClient(entity, 'SetProgress'
                , { Progress = (math.min(self.ProgressTb[objID],self.TotalProgress) / self.TotalProgress) * 100 })

                if self.ProgressTb[objID] >= self.TotalProgress then
                    --When greater than the total progress, the player wins
                    self.TouchPlayerTb[entity.objID] = nil
                    gameStageMgr.HandlerPlayerWin(entity)
                end
            else
                self.ProgressTb[objID] = nil
            end
        end
    end
end

function spotlight:Init(packet, map)
    local part = map.Root:FindFirstChild(packet.PartName, true)

    for i, v in pairs(packet) do
        self[i] = v
    end

    self.Part = part
    self.Map = map
    self.ProgressTb = {}
    self.TouchPlayerTb = {}

    self:RegisterTouchBeginEvent(part)
    self:ChangeTargetPos()

    self.Timer = Timer.new(1, self.Tick, self)
    self.Timer.Loop = true
    self.Timer:Start()
end

function spotlight:Destroy()
    self.TouchBeginCancelFunc()
    self.TouchEndCancelFunc()
    self.Timer:Stop()
end

function spotlight:Tick()
    --Ensure that the map is valid before operating the mechanism
    if not self.Map:IsValid() then
        self:Destroy()
        return
    end

    self:CalcProgress()

    if self.CanMove then
        local part = self.Part
        local pos = part.WorldPosition
        local distance = Vector3.Distance(pos, self.TargetPos)

        if distance < 0.5 then
            self:ChangeTargetPos()
        else
            part.WorldPosition = pos + self.CurDir
        end
    end
end

local mapOrganDataTb = {
    map002 = {
        { PartName = 'Spotlight', RandomPosRegion = { min = Vector3.new(-18, 7, -12), max = Vector3.new(18, 7, 12) } }
    },
    map003 = {
        {PartName = 'Spotlight',CanMove = false}
    }
}
local organTb = {}

local spotlightMgr = {}
function spotlightMgr:StartOrgan(map)
    local mapOrganData = mapOrganDataTb[map.Name]
    if mapOrganData then
        gameStageMgr = require "script_server.gameStageMgr"
        gameStageMgr.BroadcastServerHandler('ShowProgress')
        spotlightMgr.HasOrgan = true
    end

    for i, organData in ipairs(mapOrganData or {}) do
        local spotlightInstance = {}
        Lib.derive(spotlight, spotlightInstance)
        spotlightInstance:Init(organData, map)
        table.insert(organTb, spotlightInstance)
    end
end

function spotlightMgr:ClearOrgan()
    for i, organ in ipairs(organTb or {}) do
        organ:Destroy()
    end
    organTb = {}
    spotlightMgr.HasOrgan = false
end

return spotlightMgr