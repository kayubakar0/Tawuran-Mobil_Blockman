local uiMgr = require "script_client.uiMgr"
local audioMgr = require "script_client.audioMgr"
local gameStageMgr = {}

PackageHandlers:Receive("HandlerGameStart", function(player, packet)
    uiMgr.ShowGameProcessUI(packet)
    audioMgr.PlayGlobalSound(packet.SoundName)
end)

PackageHandlers:Receive("HandlerGamePrepare", function(player, packet)
    uiMgr.HideResultUI()
    uiMgr.SetMapTip(packet.MapLangKeyData)
    audioMgr.PlayGlobalSound('prepareBgm')
end)

PackageHandlers:Receive("HandlerGameOver", function(player, packet)
    uiMgr.HandlerGameOver(packet)
end)

PackageHandlers:Receive("HandlerMidwayJoin", function(player, packet)
    uiMgr.HandlerMidwayJoin(packet)
    audioMgr.PlayGlobalSound(packet.MapName..'Bgm')
end)

return gameStageMgr