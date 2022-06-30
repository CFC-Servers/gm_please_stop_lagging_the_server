if SERVER then
    AddCSLuaFile( "lagalert/client/init.lua" )

    local vguiElements = file.Find( "lagalert/client/vgui/*.lua", "LUA" )
    for _, element in ipairs( vguiElements ) do
        AddCSLuaFile( "lagalert/client/vgui/" .. element )
    end

    local materials = file.Find( "materials/vgui/lagalert/*.png", "GAME" )
    for _, material in ipairs( materials ) do
        resource.AddSingleFile( "materials/vgui/lagalert/" .. material )
    end
end

if CLIENT then
    hook.Add( "InitPostEntity", "LagAlert_Enable", function()
        include( "lagalert/client/init.lua" )
    end )
end
