local PANEL = {}
PANEL.statusIcons = {
    good = "materials/vgui/lagalert/check.png",
    okay = "materials/vgui/lagalert/caution.png",
    bad = "materials/vgui/lagalert/fire.png"
}

function PANEL:SetStatus( status )
    timer.Remove( "LagAlert_StatusIconBlink" )
    self:SetImage( self.statusIcons[status] )
    self:SetVisible( true )

    if status ~= "good" then
        timer.Create( "LagAlert_StatusIconBlink", 0.7, 0, function()
            if not IsValid( self ) then
                return timer.Remove( "LagAlert_StatusIconBlink" )
            end

            self:ToggleVisible()
        end )
    end
end

function PANEL:Init()
    self:SetVisible( false )
    self:SetSize( 65, 65 )
    self:Center()
end

vgui.Register( "LagAlert_StatusIcon", PANEL, "DImage" )
