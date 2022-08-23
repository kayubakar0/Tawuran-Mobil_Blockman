local obstaclesFactory = {}

obstaclesFactory.StartPos = Vector3.new(30, 22.75, 0)     --Obstacle starting position
obstaclesFactory.EndPos = Vector3.new(-9, 22.75, 0)       --Obstacle disappearing position
obstaclesFactory.Speed = 0.2

obstaclesFactory.CurDir = Vector3.new(-1, 0, 0) * obstaclesFactory.Speed
obstaclesFactory.Map = nil                               --Corresponding map
obstaclesFactory.ObstaclesRoot = nil                     --Obstacle root node
obstaclesFactory.ObstaclesTb = nil                       --Obstacle list
obstaclesFactory.CreateDetailTime = 3.5 * 20                  --Create obstacle interval


function obstaclesFactory:RegisterTouchBeginEvent()
    local this = self
    self.TouchBeginCancelFunc = Trigger.addHandler(Entity.GetCfg("myplugin/player1"), "ENTITY_TOUCH_PART_BEGIN", function(context)
        local entity = context.obj1
        local part = context.part

        if part.Name ~= 'Obstacle' then
            return
        end

        entity:setForceMoveToAll(entity:getPosition() +( this.CurDir * 25),5)
    end)
end

function obstaclesFactory:CreateObstacles()
    if not self.Map:IsValid() then
        return
    end

    local children = self.ObstaclesRoot:GetChildren()

    local randomsSeed  = tostring(os.time()):reverse():sub(1, 7)
    math.randomseed(randomsSeed)
    local random = math.random(#children)
    local part = children[random]

    local newPart = part:Clone()
    newPart.WorldPosition = self.StartPos
    newPart.Parent = self.Map.Root
    newPart.Name = 'Obstacle'
    self.ObstaclesTb[newPart.ID] = newPart

    --Generate obstacle based on interval
    self.CreateObstaclesTimer = Timer.new(self.CreateDetailTime, self.CreateObstacles, self)
    self.CreateObstaclesTimer:Start()
end

function obstaclesFactory:Init(packet, map)
    self.ObstaclesRoot = map.Root:FindFirstChild(packet.PathName, true)

    for i, v in pairs(packet) do
        self[i] = v
    end
    self.ObstaclesTb = {}
    self.Map = map
    self:CreateObstacles()

    self:RegisterTouchBeginEvent(self.ObstaclesRoot)

    self.Timer = Timer.new(1, self.Tick,self)
    self.Timer.Loop = true
    self.Timer:Start()
end

function obstaclesFactory:Destroy()
    self.TouchBeginCancelFunc()
    self.Timer:Stop()
    self.CreateObstaclesTimer:Stop()
end

function obstaclesFactory:Tick()
    --Ensure that the map is valid before operating the mechanism
    if not self.Map:IsValid() then
        self:Destroy()
        return
    end
    for id, part in pairs(self.ObstaclesTb) do
        local pos = part.WorldPosition
        local distance = Vector3.Distance(pos, self.EndPos)

        if distance < 0.5 then
            self.ObstaclesTb[id] = nil
            part:Destroy()
        else
            part.WorldPosition = pos + self.CurDir
        end
    end
end

local mapOrganDataTb = {
    map003 = {
        {PathName = 'Obstacle'}
    }
}
local organTb = {}

local obstaclesFactoryMgr = {}
function obstaclesFactoryMgr:StartOrgan(map)
    local mapOrganData = mapOrganDataTb[map.Name]
    for i, organData in ipairs(mapOrganData or {}) do
        local obstaclesFactoryInstance = {}
        Lib.derive(obstaclesFactory, obstaclesFactoryInstance)
        obstaclesFactoryInstance:Init(organData, map)
        table.insert(organTb,obstaclesFactoryInstance)
    end
end

function obstaclesFactoryMgr:ClearOrgan()
    for i, organ in ipairs(organTb or {}) do
        organ:Destroy()
    end
    organTb = {}
end

return obstaclesFactoryMgr