local Colors = require('ui.colors')

local PassiveIcons = {}

-- energy_matrix: 3x3 grid of small dots
function PassiveIcons.energy_matrix()
    local draw = function()
        for x = -1, 1 do
            for y = -1, 1 do
                love.graphics.circle("fill", x * 4, y * 4, 1)
            end
        end
    end
    Colors.drawGlow("dim", draw)
end

-- targeting_ai: Crosshair with corner brackets
function PassiveIcons.targeting_ai()
    local draw = function()
        -- Crosshair
        love.graphics.line(-4, 0, 4, 0)
        love.graphics.line(0, -4, 0, 4)
        -- Brackets
        local s = 6
        local b = 2
        -- TL
        love.graphics.line(-s, -s+b, -s, -s, -s+b, -s)
        -- TR
        love.graphics.line(s-b, -s, s, -s, s, -s+b)
        -- BL
        love.graphics.line(-s, s-b, -s, s, -s+b, s)
        -- BR
        love.graphics.line(s-b, s, s, s, s, s-b)
    end
    Colors.drawGlow("accent", draw)
end

-- capacitor_core: Battery symbol (parallel lines + terminals)
function PassiveIcons.capacitor_core()
    local draw = function()
        -- Main body lines
        love.graphics.line(-3, -5, -3, 5)
        love.graphics.line(3, -5, 3, 5)
        -- Terminals
        love.graphics.circle("fill", -3, -6, 1.2)
        love.graphics.circle("fill", 3, 6, 1.2)
    end
    Colors.drawGlow("accent", draw)
end

-- fragmenter: Triangle breaking into pieces
function PassiveIcons.fragmenter()
    local draw = function()
        love.graphics.polygon("line", 0, -7, -6, 5, 6, 5)
        love.graphics.line(-2, -3, 2, 1)
        love.graphics.line(0, 5, 1, 0)
        love.graphics.line(-6, 5, -2, 2)
    end
    Colors.drawGlow("danger", draw)
end

-- drone_bay: Rectangle outline with 3 dots inside
function PassiveIcons.drone_bay()
    local draw = function()
        love.graphics.rectangle("line", -6, -4, 12, 8)
        love.graphics.circle("fill", -3, 0, 1)
        love.graphics.circle("fill", 0, 0, 1)
        love.graphics.circle("fill", 3, 0, 1)
    end
    Colors.drawGlow("dim", draw)
end

-- dark_matter_core: Circle with darker inner circle
function PassiveIcons.dark_matter_core()
    local draw = function()
        love.graphics.circle("fill", 0, 0, 7)
        Colors.setColor("bg", 1)
        love.graphics.circle("fill", 0, 0, 3)
    end
    -- Special glow for dark core
    Colors.drawGlow("dim", draw)
end

-- overcharge_unit: Lightning bolt in circle
function PassiveIcons.overcharge_unit()
    local draw = function()
        love.graphics.circle("line", 0, 0, 7)
        love.graphics.line(-2, -4, 2, -1, -2, 1, 2, 4)
    end
    Colors.drawGlow("xp", draw)
end

-- replicator: Overlapping squares
function PassiveIcons.replicator()
    local draw = function()
        love.graphics.rectangle("line", -5, -5, 7, 7)
        love.graphics.rectangle("line", -2, -2, 7, 7)
    end
    Colors.drawGlow("health", draw)
end

-- fusion_core: Star burst pattern
function PassiveIcons.fusion_core()
    local draw = function()
        for i = 1, 8 do
            local ang = (i / 8) * math.pi * 2
            love.graphics.line(0, 0, math.cos(ang) * 7, math.sin(ang) * 7)
        end
    end
    Colors.drawGlow("xp", draw)
end

-- amplifier_array: Triangle waves
function PassiveIcons.amplifier_array()
    local draw = function()
        love.graphics.line(-7, 2, -4, -4, -1, 2, 2, -4, 5, 2)
    end
    Colors.drawGlow("accent", draw)
end

-- reinforced_hull: Shield shape
function PassiveIcons.reinforced_hull()
    local draw = function()
        love.graphics.polygon("line", 0, 7, -6, 2, -6, -6, 6, -6, 6, 2)
    end
    Colors.drawGlow("dim", draw)
end

-- nano_repair: Plus symbol with circle
function PassiveIcons.nano_repair()
    local draw = function()
        love.graphics.circle("line", 0, 0, 7)
        love.graphics.rectangle("fill", -1, -4, 2, 8)
        love.graphics.rectangle("fill", -4, -1, 8, 2)
    end
    Colors.drawGlow("health", draw)
end

-- ablative_plating: Layered rectangles
function PassiveIcons.ablative_plating()
    local draw = function()
        love.graphics.rectangle("line", -6, -5, 12, 3)
        love.graphics.rectangle("line", -6, -1, 12, 3)
        love.graphics.rectangle("line", -6, 3, 12, 3)
    end
    Colors.drawGlow("dim", draw)
end

-- overclocked_thrusters: Double chevron
function PassiveIcons.overclocked_thrusters()
    local draw = function()
        -- First chevron
        love.graphics.line(-5, -5, -1, 0, -5, 5)
        -- Second chevron
        love.graphics.line(1, -5, 5, 0, 1, 5)
    end
    Colors.drawGlow("xp", draw)
end

-- extended_magazines: 3 vertical rectangles side by side
function PassiveIcons.extended_magazines()
    local draw = function()
        love.graphics.rectangle("line", -5, -5, 2, 10)
        love.graphics.rectangle("line", -1, -5, 2, 10)
        love.graphics.rectangle("line", 3, -5, 2, 10)
    end
    Colors.drawGlow("dim", draw)
end

-- auxiliary_reactor: Hexagon + center dot
function PassiveIcons.auxiliary_reactor()
    local draw = function()
        local pts = {}
        for i = 1, 6 do
            local ang = (i / 6) * math.pi * 2
            table.insert(pts, math.cos(ang) * 6)
            table.insert(pts, math.sin(ang) * 6)
        end
        love.graphics.polygon("line", pts)
        love.graphics.circle("fill", 0, 0, 1.5)
    end
    Colors.drawGlow("accent", draw)
end

-- field_expander: Expanding squares
function PassiveIcons.field_expander()
    local draw = function()
        love.graphics.rectangle("line", -2, -2, 4, 4)
        love.graphics.rectangle("line", -4, -4, 8, 8)
        love.graphics.rectangle("line", -6, -6, 12, 12)
    end
    Colors.drawGlow("accent", draw)
end

-- critical_enhancer: Bullseye
function PassiveIcons.critical_enhancer()
    local draw = function()
        love.graphics.circle("line", 0, 0, 2)
        love.graphics.circle("line", 0, 0, 5)
        love.graphics.circle("line", 0, 0, 8)
    end
    Colors.drawGlow("danger", draw)
end

-- piercing_module: Arrow piercing through circle
function PassiveIcons.piercing_module()
    local draw = function()
        love.graphics.circle("line", 0, 0, 5)
        -- Arrow
        love.graphics.line(-8, 0, 8, 0)
        love.graphics.polygon("fill", 5, -3, 8, 0, 5, 3)
    end
    Colors.drawGlow("accent", draw)
end

-- temporal_accelerator: Circular arrow
function PassiveIcons.temporal_accelerator()
    local draw = function()
        love.graphics.arc("line", "open", 0, 0, 6, 0, math.pi * 1.6)
        -- Arrowhead
        love.graphics.polygon("fill", 6, -1, 9, 2, 6, 2)
    end
    Colors.drawGlow("dim", draw)
end

function PassiveIcons.drawPassiveIcon(passiveId, x, y, scale)
    local s = scale or 1.0
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(s, s)
    
    local iconFunc = PassiveIcons[passiveId]
    if iconFunc then
        iconFunc()
    else
        -- Fallback placeholder
        Colors.setColor("dim", 0.4)
        love.graphics.circle("line", 0, 0, 6)
        love.graphics.line(-4, -4, 4, 4)
    end
    
    love.graphics.pop()
end

return PassiveIcons
