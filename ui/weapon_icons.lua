local Colors = require('ui/colors')

local WeaponIcons = {}

-- Plasma Lance: Vertical line with arrow tip
function WeaponIcons.plasma_lance()
    local draw = function()
        -- Shaft
        love.graphics.rectangle("fill", -1, -2, 2, 8)
        -- Tip
        love.graphics.polygon("fill", -3, -2, 3, -2, 0, -8)
    end
    Colors.drawGlow("accent", draw)
end

-- Missile Swarm: Four small triangles in diamond formation
function WeaponIcons.missile_swarm()
    local draw = function()
        local s = 3
        -- Top
        love.graphics.polygon("fill", 0, -7, -s, -4, s, -4)
        -- Bottom
        love.graphics.polygon("fill", 0, 7, -s, 4, s, 4)
        -- Left
        love.graphics.polygon("fill", -7, 0, -4, -s, -4, s)
        -- Right
        love.graphics.polygon("fill", 7, 0, 4, -s, 4, s)
    end
    Colors.drawGlow("danger", draw)
end

-- Arc Conductor: Lightning bolt zigzag
function WeaponIcons.arc_conductor()
    local draw = function()
        love.graphics.setLineWidth(2)
        love.graphics.line(-4, -7, 2, -2, -2, 0, 4, 7)
        love.graphics.setLineWidth(1)
    end
    Colors.drawGlow("accent", draw)
end

-- Scatter Blaster: Multiple dots in spread pattern
function WeaponIcons.scatter_blaster()
    local draw = function()
        love.graphics.circle("fill", 0, -6, 1.5)
        love.graphics.circle("fill", -5, -3, 1.5)
        love.graphics.circle("fill", 5, -3, 1.5)
        love.graphics.circle("fill", -3, 4, 1.5)
        love.graphics.circle("fill", 3, 4, 1.5)
    end
    Colors.drawGlow("xp", draw)
end

-- Orbital Drones: Circle with 3 small circles around it
function WeaponIcons.orbital_drones()
    local draw = function()
        -- Center
        love.graphics.circle("line", 0, 0, 4)
        -- Orbiters
        local t = love.timer.getTime() * 2
        for i = 1, 3 do
            local ang = (i / 3) * math.pi * 2 + t
            love.graphics.circle("fill", math.cos(ang) * 7, math.sin(ang) * 7, 1.5)
        end
    end
    Colors.drawGlow("accent", draw)
end

-- Gravity Mines: Hexagon with radiating lines
function WeaponIcons.gravity_mines()
    local draw = function()
        -- Hexagon
        local pts = {}
        for i = 1, 6 do
            local ang = (i / 6) * math.pi * 2
            table.insert(pts, math.cos(ang) * 5)
            table.insert(pts, math.sin(ang) * 5)
        end
        love.graphics.polygon("line", pts)
        
        -- Radiating lines
        for i = 1, 6 do
            local ang = (i / 6) * math.pi * 2
            love.graphics.line(math.cos(ang) * 5, math.sin(ang) * 5, math.cos(ang) * 8, math.sin(ang) * 8)
        end
    end
    Colors.drawGlow("dim", draw)
end

-- Railgun: Long horizontal line with crosshair
function WeaponIcons.railgun()
    local draw = function()
        -- Beam
        love.graphics.rectangle("fill", -8, -1, 16, 2)
        -- Crosshair
        love.graphics.circle("line", 0, 0, 5)
        love.graphics.line(-7, 0, -3, 0)
        love.graphics.line(3, 0, 7, 0)
        love.graphics.line(0, -7, 0, -3)
        love.graphics.line(0, 3, 0, 7)
    end
    Colors.drawGlow("danger", draw)
end

-- Nanite Swarm: Cluster of tiny squares
function WeaponIcons.nanite_swarm()
    local draw = function()
        local grid = 3
        for x = -1, 1 do
            for y = -1, 1 do
                if (x + y) % 2 == 0 then
                    love.graphics.rectangle("fill", x * grid - 1, y * grid - 1, 2, 2)
                end
            end
        end
        -- Random scatter
        love.graphics.rectangle("fill", -6, 2, 1.5, 1.5)
        love.graphics.rectangle("fill", 5, -4, 1.5, 1.5)
        love.graphics.rectangle("fill", 2, 6, 1.5, 1.5)
    end
    Colors.drawGlow("health", draw)
end

-- Photon Whip: Curved arc/crescent
function WeaponIcons.photon_whip()
    local draw = function()
        love.graphics.setLineWidth(2)
        love.graphics.arc("line", "open", 0, 0, 7, -math.pi * 0.8, math.pi * 0.8)
        love.graphics.circle("fill", math.cos(math.pi * 0.8) * 7, math.sin(math.pi * 0.8) * 7, 2)
        love.graphics.setLineWidth(1)
    end
    Colors.drawGlow("xp", draw)
end

-- Pulse Wave: Concentric circles
function WeaponIcons.pulse_wave()
    local draw = function()
        love.graphics.circle("line", 0, 0, 3)
        love.graphics.circle("line", 0, 0, 5.5)
        love.graphics.circle("line", 0, 0, 8)
    end
    Colors.drawGlow("accent", draw)
end

function WeaponIcons.drawWeaponIcon(weaponId, x, y, scale)
    local s = scale or 1.0
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(s, s)
    
    local iconFunc = WeaponIcons[weaponId]
    if iconFunc then
        iconFunc()
    else
        -- Fallback placeholder
        Colors.setColor("dim", 0.5)
        love.graphics.rectangle("line", -8, -8, 16, 16)
        love.graphics.line(-8, -8, 8, 8)
    end
    
    love.graphics.pop()
end

return WeaponIcons
