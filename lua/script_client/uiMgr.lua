local uiMgr = {}
local mainWnd
local rankWnd

local bindableEvent = Event:GetEvent("OnClientInitDone")
bindableEvent:Bind(function()
    mainWnd = uiMgr.OpenWindow("Gui/mainWnd")
    rankWnd = uiMgr.OpenWindow("Gui/rankWnd")
    rankWnd:Hide()
end)

function uiMgr.OpenWindow(name)
    local wnd = UI:CreateGUIWindow(name)
    UI.Root:AddChild(wnd)
    return wnd
end

function uiMgr.ShowGameProcessUI(packet)
    mainWnd:ShowTimer()
    mainWnd:SetTime(packet.Time)
    mainWnd:ShowWinProgress()
    mainWnd:SetWinProgress(packet.WinSum, packet.WinTotalSum)
end

function uiMgr.HideGameProcessUI()
    mainWnd:HideTimer()
    mainWnd:HideWinProgress()
    mainWnd:HideProgress()
end

function uiMgr.HideResultUI()
    mainWnd:HideWinUI()
    rankWnd:Hide()
end

function uiMgr.SetMapTip(packet)
    mainWnd:OpenMapTip(packet.Name, packet.Tip)
    local timer = Timer.new(3 * 20, function()
        mainWnd:HideMapTip()
    end)
    timer:Start()
end

function uiMgr.HandlerGameOver(packet)
    uiMgr.HideGameProcessUI()
    --The winning player will open the leaderboard directly, and the losing player will display the failure page first, and then open the leaderboard after 2 seconds
    if packet.winIndex then
        rankWnd:SetRank(packet)
    else
        mainWnd:ShowFailUI()
        local timer = Timer.new(2 * 20, function()
            mainWnd:HideFailUI()
            rankWnd:SetRank(packet)
        end)
        timer:Start()
    end
end

function uiMgr.HandlerMidwayJoin(packet)
    uiMgr.SetMapTip(packet.MapLangKeyData)
    mainWnd:ShowGoTip()
end

PackageHandlers:Receive("HandlerGameOverCountdown", function(player, packet)
    mainWnd:HandlerGameOverCountdown(packet.Time)
    rankWnd:SetCountdown(packet.Time)
end)

return uiMgr