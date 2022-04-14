-- Load vgui elements
do
    local vguiBase = "lagalert/client/vgui"

    local elements = file.Find( vguiBase .. "/*.lua", "LUA" )
    for _, fileName in ipairs( elements ) do
        print( "Loading: " .. vguiBase .. "/" .. fileName )
        include( vguiBase .. "/" .. fileName )
    end
end

LagAlert = {}

LagAlert.statusPanel = nil
LagAlert.displayingStatus = false
LagAlert.currentStatus = "good"

local function setStatus( status )
    if LagAlert.currentStatus == status then return end
    timer.Remove( "LagAlert_GoodCooldown" )

    if not LagAlert.displayingStatus then
        LagAlert.statusPanel = vgui.Create( "LagAlert_StatusPanel" )
        LagAlert.displayingStatus = true
    end

    if status == "good" then
        LagAlert.statusPanel:AlphaTo( 0, 4, 1 )
        timer.Create( "LagAlert_GoodCooldown", 5, 1, function()
            LagAlert.statusPanel:Clear()
            LagAlert.statusPanel:Remove()
            LagAlert.statusPanel = nil
            LagAlert.displayingStatus = false
        end )
    else
        LagAlert.statusPanel:Stop()
        LagAlert.statusPanel:SetAlpha( 255 )
    end

    LagAlert.currentStatus = status
    if LagAlert.statusPanel then LagAlert.statusPanel:SetType( status ) end
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
        LagAlert.average = LagAlert.total / sampleSize
        table_insert( samples, 1, newSample )

        -- A number from 0-1 indicating the current performance deficit
        -- i.e. if the server was running at 22/66 tps, this number would be 0.66
        LagAlert.performanceLoss = 1 - ( Clamp( tickInterval / newSample, 0, 1 ) )
        local performanceLoss = LagAlert.performanceLoss

        if LagAlert.displayingStatus then
            LagAlert.statusPanel.PerformanceLoss = math_floor( performanceLoss * 100 )
        end

        if performanceLoss >= 0.8 then
            return setStatus( "bad" )
        end

        if performanceLoss >= 0.5 then
            return setStatus( "okay" )
        end

        -- If we were showing an alert but things went back to normal, show a good alert
        if LagAlert.displayingStatus and performanceLoss <= 0 then
            setStatus( "good" )
        end
    end )
end

hook.Add( "Think", "LagAlert_Init", function()
    hook.Remove( "Think", "LagAlert_Init" )
    timer.Simple( 10, init )
end )

hook.Remove( "Think", "LagAlert_Measure" )
