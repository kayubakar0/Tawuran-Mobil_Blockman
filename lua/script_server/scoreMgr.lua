local awardScoreTb = {
    [1] = 4,
    [2] = 3,
    [3] = 2
}

local scoreMgr = {}

--Get bonus points based on ranking, default is 1
function scoreMgr.GetAddScore(index)
    return awardScoreTb[index] or 1
end

function scoreMgr.AddScore(winTb)
    for i, player in ipairs(winTb or {}) do
        player:setValue('score', player:getValue('score') + scoreMgr.GetAddScore(i))
        PackageHandlers:SendToClient(player, 'SetScore', { score = player:getValue('score') })
    end
end

--Get a list of player points
function scoreMgr.GetPlayersScoreTb(playerTb,winTb)
    scoreMgr.AddScore(winTb)
    local scoreTb = {}
    for i, player in pairs(playerTb) do
        table.insert(scoreTb, { Name = player.name, ObjID = player.objID,
                                Score = player:getValue('score'),UserID = player.platformUserId  })
    end
    --Arrange the score table, the higher score is in the front, if the scores are the same, the smaller objID is in the front
    table.sort(scoreTb, function(data1, data2)
        if data1.Score > data2.Score or data1.Score == data2.Score and data1.ObjID < data2.ObjID then
            return true
        end
    end)
    return scoreTb
end

return scoreMgr
