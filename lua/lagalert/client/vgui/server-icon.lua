local PANEL = {}
PANEL.statusImages = {
    good = "materials/vgui/lagalert/server-stack-good.png",
    warn = "materials/vgui/lagalert/server-stack-okay.png",
    bad = "materials/vgui/lagalert/server-stack-bad.png"
}

function PANEL:SetStatusIcon( status )
    if IsValid( self.StatusIcon ) then
        self.StatusIcon:Remove()
    end

    self.StatusIcon = vgui.Create( "LagAlert_StatusIcon", self )
    self.StatusIcon:SetStatus( status )
end

function PANEL:SetType( status )
    self:SetImage( self.statusImages[status] )

    self:SetStatusIcon( status )
    self:SetVisible( true )
end

function PANEL:Init()
    self:SetVisible( false )
    self:SetSize( 100, 100 )
    self:Dock( TOP )
end

vgui.Register( "LagAlert_ServerIcon", PANEL, "DImage" )
