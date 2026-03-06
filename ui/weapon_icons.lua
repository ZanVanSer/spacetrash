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

-- EVOLVED WEAPONS

-- Quantum Splitter (Evolved Plasma Lance)
function WeaponIcons.quantum_splitter()
    local draw = function()
        for i = -1, 1 do
            local x = i * 4
            -- Shaft
            love.graphics.rectangle("fill", x - 0.5, -1, 1, 7)
            -- Tip
            love.graphics.polygon("fill", x - 2, -1, x + 2, -1, x, -6)
        end
    end
    Colors.drawGlow("accent", draw, 1.6, 1.3)
end

-- Apocalypse Barrage (Evolved Missile Swarm)
function WeaponIcons.apocalypse_barrage()
    local draw = function()
        -- Main cluster
        local s = 4
        love.graphics.polygon("fill", 0, -8, -s, -4, s, -4)
        love.graphics.polygon("fill", 0, 8, -s, 4, s, 4)
        love.graphics.polygon("fill", -8, 0, -4, -s, -4, s)
        love.graphics.polygon("fill", 8, 0, 4, -s, 4, s)
        
        -- Mini missiles
        local ms = 2
        love.graphics.polygon("fill", -5, -5, -7, -7, -7, -5)
        love.graphics.polygon("fill", 5, -5, 7, -7, 7, -5)
        love.graphics.polygon("fill", -5, 5, -7, 7, -7, 5)
        love.graphics.polygon("fill", 5, 5, 7, 7, 7, 5)
    end
    Colors.drawGlow("danger", draw, 1.5, 1.25)
end

-- Tesla Storm (Evolved Arc Conductor)
function WeaponIcons.tesla_storm()
    local draw = function()
        love.graphics.setLineWidth(3)
        love.graphics.line(-5, -8, 3, -2, -3, 0, 5, 8)
        love.graphics.setLineWidth(1)
        -- Energy circles
        love.graphics.circle("line", -1, -4, 3)
        love.graphics.circle("line", 1, 4, 3)
    end
    Colors.drawGlow("accent", draw, 1.7, 1.35)
end

-- Shrapnel Cannon (Evolved Scatter Blaster)
function WeaponIcons.shrapnel_cannon()
    local draw = function()
        -- Main dots
        love.graphics.circle("fill", 0, -6, 2)
        love.graphics.circle("fill", -5, -3, 2)
        love.graphics.circle("fill", 5, -3, 2)
        love.graphics.circle("fill", -3, 4, 2)
        love.graphics.circle("fill", 3, 4, 2)
        -- Shrapnel lines
        for i = 1, 8 do
            local ang = (i / 8) * math.pi * 2
            love.graphics.line(math.cos(ang) * 4, math.sin(ang) * 4, math.cos(ang) * 9, math.sin(ang) * 9)
        end
    end
    Colors.drawGlow("xp", draw, 1.6, 1.3)
end

-- Sentinel Network (Evolved Orbital Drones)
function WeaponIcons.sentinel_network()
    local draw = function()
        -- Center node
        love.graphics.circle("fill", 0, 0, 3)
        -- 6 orbital drones in hexagon
        local t = love.timer.getTime() * 1.5
        local pts = {}
        for i = 1, 6 do
            local ang = (i / 6) * math.pi * 2 + t
            local dx = math.cos(ang) * 8
            local dy = math.sin(ang) * 8
            love.graphics.circle("fill", dx, dy, 2)
            table.insert(pts, dx)
            table.insert(pts, dy)
        end
        -- Connecting lines
        love.graphics.polygon("line", pts)
    end
    Colors.drawGlow("accent", draw, 1.5, 1.25)
end

-- Singularity Engine (Evolved Gravity Mines)
function WeaponIcons.singularity_engine()
    local draw = function()
        local t = love.timer.getTime() * 4
        for i = 1, 3 do
            local r = 9 - (i * 2.5)
            love.graphics.arc("line", "open", 0, 0, r, t + i, t + i + math.pi * 1.2)
        end
        love.graphics.circle("fill", 0, 0, 2)
    end
    Colors.drawGlow("dim", draw, 1.8, 1.4)
end

-- Annihilator Cannon (Evolved Railgun)
function WeaponIcons.annihilator_cannon()
    local draw = function()
        -- 3 parallel beams
        for i = -1, 1 do
            local y = i * 3
            love.graphics.rectangle("fill", -9, y - 0.5, 18, 1)
        end
        -- Larger Crosshair
        love.graphics.circle("line", 0, 0, 7)
        love.graphics.line(-9, 0, -4, 0)
        love.graphics.line(4, 0, 9, 0)
        love.graphics.line(0, -9, 0, -4)
        love.graphics.line(0, 4, 0, 9)
    end
    Colors.drawGlow("danger", draw, 1.5, 1.25)
end

-- Grey Goo Protocol (Evolved Nanite Swarm)
function WeaponIcons.grey_goo_protocol()
    local draw = function()
        local pts = {
            {-5, -5}, {5, -5}, {5, 5}, {-5, 5},
            {0, -8}, {8, 0}, {0, 8}, {-8, 0}
        }
        -- Dots
        for _, p in ipairs(pts) do
            love.graphics.rectangle("fill", p[1] - 1, p[2] - 1, 2, 2)
        end
        -- Connecting lines (web)
        love.graphics.setLineWidth(0.5)
        for i = 1, #pts do
            for j = i + 1, #pts do
                local d2 = (pts[i][1]-pts[j][1])^2 + (pts[i][2]-pts[j][2])^2
                if d2 < 70 then
                    love.graphics.line(pts[i][1], pts[i][2], pts[j][1], pts[j][2])
                end
            end
        end
        love.graphics.setLineWidth(1)
    end
    Colors.drawGlow("health", draw, 1.6, 1.3)
end

-- Solar Flare (Evolved Photon Whip)
function WeaponIcons.solar_flare()
    local draw = function()
        love.graphics.setLineWidth(2.5)
        love.graphics.arc("line", "open", 0, 0, 8, -math.pi * 0.9, math.pi * 0.9)
        love.graphics.setLineWidth(1)
        -- Flame/Wavy trail
        local t = love.timer.getTime() * 5
        for i = 1, 5 do
            local ang = -math.pi * 0.8 + (i * 0.4)
            local r = 8 + math.sin(t + i) * 2
            love.graphics.circle("fill", math.cos(ang) * r, math.sin(ang) * r, 1.5)
        end
    end
    Colors.drawGlow("xp", draw, 1.7, 1.35)
end

-- Electromagnetic Cataclysm (Evolved Pulse Wave)
function WeaponIcons.electromagnetic_cataclysm()
    local draw = function()
        love.graphics.circle("line", 0, 0, 4)
        love.graphics.circle("line", 0, 0, 7)
        love.graphics.circle("line", 0, 0, 9)
        -- Lightning between circles
        for i = 1, 4 do
            local ang = (i / 4) * math.pi * 2
            love.graphics.line(math.cos(ang) * 4, math.sin(ang) * 4, math.cos(ang+0.2) * 6, math.sin(ang+0.2) * 6)
            love.graphics.line(math.cos(ang+0.2) * 6, math.sin(ang+0.2) * 6, math.cos(ang) * 7, math.sin(ang) * 7)
        end
    end
    Colors.drawGlow("accent", draw, 1.6, 1.3)
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
