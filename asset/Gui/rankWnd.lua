print("startup ui")
local audioMgr = require "script_client.audioMgr"
local DW_time = self:GetChildByName('DW_time')
local Txt_rankTitle = self:GetChildByName('Txt_rankTitle')
local Txt_time = self:GetChildByName('Txt_time')
local Btn_return = self:GetChildByName('Btn_return')

local function ZeroFill(time)
      return  time > 9 and time or ("0" .. time)
end

function self:Init()
    Txt_rankTitle.Text = Lang:toText('LangKey_rankTitle')
end

function self:Hide()
    self.Visible = false
end

function self:Show()
    self.Visible = true
end

function self:SetRank(packet)
    self:Show()
    if packet.Time then
        self:SetCountdown(packet.Time)
    else
        DW_time.Visible = false
    end

    local userIDTb = {}
    for i = 1, 8 do
        local line = packet.Rank[i]
        local rankUI = self:GetChildByName('DW_rank' .. i)
        rankUI.GetChildByName = rankUI.child
        --Determine whether there is data, if not, set the corresponding ui to the default value
        if not line then
            line = { Name = '--------', Score = '---' }
            rankUI:GetChildByName('Img_head').Image = "asset/GameUI/Rank/default_icon.png"
        else
            table.insert(userIDTb,line.UserID)
        end
        rankUI:GetChildByName('Txt_name').Text = line.Name
        rankUI:GetChildByName('Txt_score').Text = line.Score
    end

    --Get user information and set avatar
    UserInfoCache.LoadCacheByUserIds(userIDTb,function()
        for i, userID in ipairs(userIDTb) do
            local info = UserInfoCache.GetCache(userID)
            local rankUI = self:GetChildByName('DW_rank' .. i)
            rankUI:GetChildByName('Img_head'):SetUrlImage(info.picUrl)
        end
    end)
end

function self:SetCountdown(time)
    DW_time.Visible = true
    Txt_time.Text = Lang:toText('LangKey_timeTitle') .. ' ' .. '00'.. ':'..ZeroFill(time)
    if time == 0 then
        self:Hide()
    end
end

local event = Btn_return:GetEvent("OnClick")
event:Bind(function()
    audioMgr.PlaySound('click')
    self:Hide()
end)

PackageHandlers:Receive("SetRank", function(player, packet)
    self:SetRank(packet)
end)



self:Init()