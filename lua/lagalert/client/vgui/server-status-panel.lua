local PANEL = {}

function PANEL:SetType( status )
    if self.Status == status then return end

    self.ServerIcon:SetType( status )
    self.Status = status
end

function PANEL:Init()
    self:SetSize( 100, 200 )
    self:SetPos( 150, 100 )
    self.PerformanceLoss = 0
    self.Status = nil

    self.ServerIcon = vgui.Create( "LagAlert_ServerIcon", self )
    self.LagMeter = vgui.Create( "LagAlert_Meter", self )
end

function PANEL:Paint()
end

vgui.Register( "LagAlert_StatusPanel", PANEL, "DPanel" )
