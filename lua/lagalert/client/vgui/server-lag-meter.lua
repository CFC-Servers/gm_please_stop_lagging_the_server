local PANEL = {}
local OUTLINE_COLOR = Color( 25, 25, 25, 255 )
local DRAW_COLOR = Color( 245, 100, 100, 255 )

local SimpleTextOutlined = draw.SimpleTextOutlined
local math_floor = math.floor

function PANEL:Init()
    self:SetSize( 100, 100 )
    self:Dock( TOP )

    self.Parent = self:GetParent()
end

-- TODO: Add dynamic draw colors

function PANEL:Paint()
    local loss = math_floor( self.Parent.PerformanceLoss or 0 )
    local text = "-" .. loss .. "%"

    SimpleTextOutlined(
        text, "CloseCaption_Bold",
        50, 0,
        DRAW_COLOR,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_TOP,
        2,
        OUTLINE_COLOR
    )
end

vgui.Register( "LagAlert_Meter", PANEL, "DPanel" )
