-- Load vgui elements
do
    local vguiBase = "lagalert/client/vgui"

    local elements = file.Find( vguiBase .. "/*.lua", "LUA" )
    for _, fileName in ipairs( elements ) do
        include( vguiBase .. "/" .. fileName )
    end
end

LagAlert = LagAlert or {}

LagAlert.statusPanel = nil
LagAlert.displayingStatus = false
LagAlert.currentStatus = "good"

local GREY = Color( 170, 170, 170 )
local RED = Color( 225, 0, 0 )
local GREEN = Color( 0, 225, 0 )
local YELLOW = Color( 225, 225, 0 )
local WHITE = Color( 225, 225, 225 )

local statusChanges = {
    good = {
        warn = {
            GREY, "[Server] ",
            WHITE, "Performance is ",
            YELLOW, "DEGRADED"
        }
    },
    warn = {
        good = {
            GREY, "[Server] ",
            WHITE, "Performance has ",
            GREEN, "RECOVERED"
        },
        bad = {
            GREY, "[Server] ",
            WHITE, "Performance is ",
            RED, "CRITICAL"
        }
    },
    bad = {
        warn = {
            GREY, "[Server] ",
            WHITE, "Performance is ",
            YELLOW, "RECOVERING"
        }
    }
}

local function makeAttentionSound()
    LagAlert.attention = CreateSound( LocalPlayer(), "npc/overwatch/cityvoice/f_evasionbehavior_2_spkr.wav" )
    LagAlert.attention:Stop()
end

local function attentionPlease()
    if not LagAlert.attention then
        makeAttentionSound()
    end

    LagAlert.attention:PlayEx( 75, 100 )

    timer.Simple( 1.2, function()
        if LagAlert.attention:IsPlaying() then
            LagAlert.attention:Stop()
        end
    end )
end

local function resolvedSound()
    surface.PlaySound("garrysmod/save_load4.wav")
end

local lastAlert = 0
local alertTimer = "LagAlert_StatusChange"
local function _alertChange( old, new )
    lastAlert = CurTime()
    chat.AddText( unpack( statusChanges[old][new] ) )

    if new == "bad" then attentionPlease() end
    if new == "good" then resolvedSound() end
end

local function alertChange( old, new )
    local now = CurTime()

    if lastAlert < now - 5 then
        return _alertChange( old, new )
    end

    if timer.Exists( alertTimer ) then return end

    local delay = ( lastAlert + 5 ) - now
    timer.Create( alertTimer, delay, 1, function()
        _alertChange( LagAlert.lastStatus, LagAlert.currentStatus )
        timer.Remove( alertTimer )
    end )
end

local function setStatus( newStatus )
    local lastStatus = LagAlert.currentStatus

    if lastStatus == newStatus then return end
    timer.Remove( "LagAlert_GoodCooldown" )

    if not LagAlert.displayingStatus then
        LagAlert.statusPanel = vgui.Create( "LagAlert_StatusPanel" )
        LagAlert.displayingStatus = true
    end

    if newStatus == "good" then
        -- Hide the numbers
        LagAlert.statusPanel.LagMeter:SetVisible( false )

        -- Start fade out
        LagAlert.statusPanel:AlphaTo( 0, 4, 1 )

        timer.Create( "LagAlert_GoodCooldown", 5, 1, function()
            LagAlert.statusPanel:Clear()
            LagAlert.statusPanel:Remove()
            LagAlert.statusPanel = nil
            LagAlert.displayingStatus = false

            LagAlert.attention:Stop()
        end )
    end

    if newStatus == "warn" then
        LagAlert.statusPanel:Stop()
        LagAlert.statusPanel:SetAlpha( 255 )
    end

    if newStatus == "bad" then
        LagAlert.statusPanel:Stop()
        LagAlert.statusPanel:SetAlpha( 255 )
    end

    alertChange( lastStatus, newStatus )

    LagAlert.lastStatus = lastStatus
    LagAlert.currentStatus = newStatus
    if LagAlert.statusPanel then LagAlert.statusPanel:SetType( newStatus ) end
end

local function init()
    local Clamp = math.Clamp
    local table_remove = table.remove
    local table_insert = table.insert
    local math_floor = math.floor
    local ServerFrameTime = engine.ServerFrameTime

    local averageTime = 8 -- How many seconds to calculate a rolling average server FPS

    local tickInterval = engine.TickInterval()
    local targetTPS = 1 / tickInterval
    local sampleSize = math_floor( targetTPS * averageTime )

    LagAlert.samples = {}
    local samples = LagAlert.samples

    LagAlert.total = tickInterval * sampleSize
    LagAlert.average = tickInterval

    for i = 1, sampleSize do samples[i] = tickInterval end

    hook.Add( "Think", "LagAlert_Measure", function()
        local newSample = ServerFrameTime()
        local removed = table_remove( samples )

        LagAlert.total = LagAlert.total - removed + newSample

        local average = LagAlert.total / sampleSize
        LagAlert.average = average

        table_insert( samples, 1, newSample )

        -- A number from 0-1 indicating the current performance deficit
        -- i.e. if the server was running at 22/66 tps, this number would be 0.66
        local performanceLoss = 1 - ( Clamp( tickInterval / average, 0, 1 ) )
        LagAlert.performanceLoss = performanceLoss

        if LagAlert.displayingStatus then
            LagAlert.statusPanel.PerformanceLoss = math_floor( performanceLoss * 100 )
        end

        if performanceLoss >= 0.85 then
            return setStatus( "bad" )
        end

        if performanceLoss >= 0.8 then
            return setStatus( "warn" )
        end

        -- If we were showing an alert but things went back to normal, show a good alert
        if LagAlert.displayingStatus and performanceLoss <= 0 then
            return setStatus( "good" )
        end
    end )
end

hook.Add( "InitPostEntity", "LagAlert_SoundInit", function()
    makeAttentionSound()
end )

hook.Add( "Think", "LagAlert_Init", function()
    hook.Remove( "Think", "LagAlert_Init" )
    timer.Simple( 60, init )
end )
