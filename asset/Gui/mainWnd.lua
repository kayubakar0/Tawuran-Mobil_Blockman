print("startup ui")
local audioMgr = require "script_client.audioMgr"
local Txt_score = self:GetChildByName('Txt_score')

local Img_winProgressBg = self:GetChildByName('Img_winProgressBg')
local Txt_progressTitle = Img_winProgressBg:GetChildByName('Txt_progressTitle')
local Txt_winProgress = Img_winProgressBg:GetChildByName('Txt_winProgress')

local Img_timerBg = self:GetChildByName('Img_timerBg')
local Txt_timer = Img_timerBg:GetChildByName('Txt_timer')

local Img_progressBg = self:GetChildByName('Img_progressBg')
local Txt_progress = Img_progressBg:GetChildByName('Txt_progress')

local Img_tipBg = self:GetChildByName('Img_tipBg')

local Img_mapTipBg = self:GetChildByName('Img_mapTipBg')

local DW_tip = self:GetChildByName('DW_tip')
local Img_countDown = DW_tip:GetChildByName('Img_countDown')
local Img_go = DW_tip:GetChildByName('Img_go')
local countdownImgPath = "gameres|asset/GameUI/Main/Countdown/%d.png"

local Img_winBg = DW_tip:GetChildByName('Img_winBg')
local Img_medal = Img_winBg:GetChildByName('Img_medal')
local Btn_confirm = Img_winBg:GetChildByName('Btn_confirm')
local Img_failBg = DW_tip:GetChildByName('Img_failBg')
local medalImgPath = "gameres|asset/GameUI/Result/icon_%d.png"

local Img_rank = self:GetChildByName('Img_rank')

function self:Init()
    Txt_progressTitle.Text = Lang:toText('LangKey_progressTitle')
    Img_winBg:GetChildByName('Txt_winTitle').Text = Lang:toText('LangKey_winTitle')
    Img_failBg:GetChildByName('Txt_failTitle').Text = Lang:toText('LangKey_failTitle')
    Btn_confirm:GetChildByName('Txt_confirm').Text = Lang:toText('LangKey_confirm')
end

function self:ShowWinProgress()
    Img_winProgressBg.Visible = true
end

function self:HideWinProgress()
    Img_winProgressBg.Visible = false
end

function self:SetWinProgress(winSum, totalSum)
    self:ShowWinProgress()
    Txt_winProgress.Text = winSum .. '/' .. totalSum
end

function self:ShowTimer()
    Img_timerBg.Visible = true
end

function self:HideTimer()
    Img_timerBg.Visible = false
end

function self:SetTime(time)
    self:ShowTimer()
    Txt_timer.Text = time
end

function self:SetScore(score)
    Txt_score.Text = score
end

function self:HandlerPrepareCountdown(time)
    if time <= 3 then
        self:HideTip()
        if time == 0 then
            Img_countDown.Visible = false
            self:ShowGoTip()
        else
            Img_countDown.Visible = true
            Img_countDown.Image = string.format(countdownImgPath,time)
            if time == 3 then
                audioMgr.PlaySound('countdown')
            end
        end

    else
        self:OpenTip({ 'LangKey_gamePrepareCountdownTip',time })
    end
end

function self:ShowGoTip()
    Img_go.Visible = true
    audioMgr.PlaySound('go')
    local timer = Timer.new(20, function()
        Img_go.Visible = false
    end)
    timer:Start()
end

function self:HandlerGameOverCountdown(time)
    self:OpenTip({ 'LangKey_gameOverCountdownTip',time })
    if time == 0 then
        self:HideTip()
    end
end

function self:ShowWinUI(rank)
    Img_winBg.Visible = true
    audioMgr.PlaySound('win')
    if rank <= 3 then
        Img_medal.Visible = true
        Img_medal.Image = string.format(medalImgPath,rank)
    end
end

function self:HideWinUI()
    Img_winBg.Visible = false
end

function self:ShowFailUI()
    audioMgr.PlaySound('fail')
    Img_failBg.Visible = true
end

function self:HideFailUI()
    Img_failBg.Visible = false
end

function self:ShowProgress()
    Img_progressBg.Visible = true
end

function self:HideProgress()
    self:SetProgress(0)
    Img_progressBg.Visible = false
end

function self:SetProgress(progress)
    Txt_progress.Text = progress..'%'
end

function self:OpenTip(langKey)
    Img_tipBg.Visible = true
    Img_tipBg.Txt_tip.Text = Lang:toText(langKey)
end

function self:HideTip()
    Img_tipBg.Visible = false
end

function self:OpenMapTip(name,tip)
    Img_mapTipBg.Visible = true
    Img_mapTipBg.Txt_mapName.Text = Lang:toText(name)
    Img_mapTipBg.Txt_mapTip.Text = Lang:toText(tip)
end

function self:HideMapTip()
    Img_mapTipBg.Visible = false
end

local event = Btn_confirm:GetEvent("OnClick")
event:Bind(function()
    audioMgr.PlaySound('click')
    self:HideWinUI()
end)

local event = Img_rank:GetEvent("OnClick")
event:Bind(function()
    audioMgr.PlaySound('click')
    PackageHandlers:SendToServer("RequestRankData")
end)

PackageHandlers:Receive("SetScore", function(player, packet)
    self:SetScore(packet.score)
end)

PackageHandlers:Receive("SetTime", function(player, packet)
    self:SetTime(packet.Time)
end)

PackageHandlers:Receive("SetWinProgress", function(player, packet)
    self:SetWinProgress(packet.WinSum, packet.WinTotalSum)
end)

PackageHandlers:Receive("HandlerPrepareCountdown", function(player, packet)
    self:HandlerPrepareCountdown(packet.Time)
end)

PackageHandlers:Receive("ShowProgress", function(player, packet)
    self:ShowProgress()
end)

PackageHandlers:Receive("SetProgress", function(player, packet)
    self:SetProgress(packet.Progress)
end)

PackageHandlers:Receive("ShowWinUI", function(player, packet)
    self:ShowWinUI(packet.Rank)
end)

PackageHandlers:Receive("OpenTip", function(player, packet)
    self:OpenTip(packet.Tip)
end)

self:Init()