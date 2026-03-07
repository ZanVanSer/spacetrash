local Colors = require('ui/colors')

local EnemyVisuals = {}

function EnemyVisuals.basic_drone()
    local t = love.timer.getTime()
    -- Triangle pointing down: {0,10, -10,-8, 10,-8}
    local points = {0, 10, -10, -8, 10, -8}
    
    -- Fill: danger red, alpha 0.7
    Colors.setColor("danger", 0.7)
    love.graphics.polygon("fill", points)
    
    -- Border: 1px danger red
    love.graphics.setLineWidth(1)
    Colors.setColor("danger", 1)
    love.graphics.polygon("line", points)
    
    -- Eye: small circle at center, radius 3, pulsing glow
    local pulse = (math.sin(t * 8) + 1) / 2
    -- Glow
    Colors.setColor("danger", 0.2 + pulse * 0.3)
    love.graphics.circle("fill", 0, -2, 6)
    -- Eye
    Colors.setColor("danger", 1)
    love.graphics.circle("fill", 0, -2, 3)
end

function EnemyVisuals.zigzag_fighter()
    -- Diamond: {0,-14, -10,0, 0,14, 10,0}
    local points = {0, -14, -10, 0, 0, 14, 10, 0}
    
    -- Fill: danger red, alpha 0.75
    Colors.setColor("danger", 0.75)
    love.graphics.polygon("fill", points)
    
    -- Border: 1px red
    love.graphics.setLineWidth(1)
    Colors.setColor("danger", 1)
    love.graphics.polygon("line", points)
    
    -- Crosshair detail: horizontal and vertical lines through center
    love.graphics.line(-6, 0, 6, 0)
    love.graphics.line(0, -6, 0, 6)
    
    -- Engine dots: two orange circles at bottom
    love.graphics.setColor(1, 0.5, 0, 1)
    love.graphics.circle("fill", -4, 8, 2)
    love.graphics.circle("fill", 4, 8, 2)
end

function EnemyVisuals.bomber()
    local t = love.timer.getTime()
    -- Large hexagon: {0,14, -14,6, -18,-8, -10,-14, 10,-14, 18,-8, 14,6}
    local points = {0, 14, -14, 6, -18, -8, -10, -14, 10, -14, 18, -8, 14, 6}
    
    -- Fill: dark red (0.2, 0, 0, 0.9)
    love.graphics.setColor(0.2, 0, 0, 0.9)
    love.graphics.polygon("fill", points)
    
    -- Border: 2px bright red
    love.graphics.setLineWidth(2)
    Colors.setColor("danger", 1)
    love.graphics.polygon("line", points)
    
    -- Bomb bay: rectangle outline on underside
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", -6, -4, 12, 8)
    
    -- Payload circle: pulsing red at center
    local pulse = (math.sin(t * 4) + 1) / 2
    love.graphics.setColor(1, 0, 0, 0.4 + pulse * 0.6)
    love.graphics.circle("fill", 0, 0, 5)
end

function EnemyVisuals.swarm_bee()
    -- Small triangle: {0,6, -6,-5, 6,-5}
    local points = {0, 6, -6, -5, 6, -5}
    
    -- NO fill, outline only
    -- 1px red line
    love.graphics.setLineWidth(1)
    
    -- Draw 3 ghost trails behind (fade effect)
    for i = 1, 3 do
        local alpha = 0.5 - (i * 0.15)
        local offset = i * 5
        Colors.setColor("danger", alpha)
        love.graphics.push()
        love.graphics.translate(0, -offset)
        love.graphics.polygon("line", points)
        love.graphics.pop()
    end
    
    -- Main outline
    Colors.setColor("danger", 1)
    love.graphics.polygon("line", points)
end

function EnemyVisuals.heavy_assault()
    local t = love.timer.getTime()
    
    -- Body: 40x30 rectangle (centered)
    -- Darker fill
    love.graphics.setColor(0.25, 0, 0, 0.9)
    love.graphics.rectangle("fill", -20, -15, 40, 30)
    
    -- Border: 2px thick danger red
    love.graphics.setLineWidth(2)
    Colors.setColor("danger", 1)
    love.graphics.rectangle("line", -20, -15, 40, 30)
    
    -- Armor plating details (panel lines)
    love.graphics.setLineWidth(1)
    love.graphics.line(-10, -15, -10, 15)
    love.graphics.line(10, -15, 10, 15)
    love.graphics.line(-20, 0, 20, 0)
    
    -- Twin gun turrets on top (two small circles)
    love.graphics.circle("fill", -10, 5, 4)
    love.graphics.circle("fill", 10, 5, 4)
    -- Turret outlines
    Colors.setColor("danger", 1)
    love.graphics.circle("line", -10, 5, 4)
    love.graphics.circle("line", 10, 5, 4)
    
    -- Engine exhausts at back (glowing)
    local pulse = (math.sin(t * 12) + 1) / 2
    love.graphics.setColor(1, 0.4, 0, 0.4 + pulse * 0.6)
    love.graphics.circle("fill", -12, -15, 5)
    love.graphics.circle("fill", 12, -15, 5)
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.circle("fill", -12, -15, 2)
    love.graphics.circle("fill", 12, -15, 2)
end

function EnemyVisuals.elite_fighter(shieldHealth, shootTimer, shootInterval)
    local t = love.timer.getTime()
    
    -- 6-pointed star shape
    local outerRadius = 16
    local innerRadius = 8
    local points = {}
    for i = 0, 11 do
        local ang = (i * math.pi / 6) - math.pi/2 -- pointing up
        local r = (i % 2 == 0) and outerRadius or innerRadius
        table.insert(points, math.cos(ang) * r)
        table.insert(points, math.sin(ang) * r)
    end
    
    -- Fill: danger red
    Colors.setColor("danger", 0.7)
    love.graphics.polygon("fill", points)
    
    -- Border: bright red
    love.graphics.setLineWidth(2)
    Colors.setColor("danger", 1)
    love.graphics.polygon("line", points)
    
    -- Yellow/gold accent on star tips
    Colors.setColor("xp", 1)
    for i = 0, 5 do
        local ang = (i * math.pi / 3) - math.pi/2
        love.graphics.circle("fill", math.cos(ang) * outerRadius, math.sin(ang) * outerRadius, 2)
    end
    
    -- Energy core at center
    local pulse = (math.sin(t * 12) + 1) / 2
    -- Brighten core when shooting
    if shootTimer and shootInterval then
        local timeRemaining = shootInterval - shootTimer
        if timeRemaining < 0.5 and timeRemaining > 0 then
            pulse = 0.5 + (0.5 - timeRemaining) / 0.5 * 0.5
        end
    end
    Colors.setColor("danger", 0.3 + pulse * 0.4)
    love.graphics.circle("fill", 0, 0, 8) -- Outer core glow
    Colors.setColor("danger", 1)
    love.graphics.circle("fill", 0, 0, 4) -- Main core
    
    -- Shield visual: Cyan/blue rotating ring (if shieldActive)
    if shieldHealth and shieldHealth > 0 then
        love.graphics.setLineWidth(2)
        Colors.setColor("accent", 0.6)
        local rot = t * 4
        love.graphics.arc("line", "open", 0, 0, 22, rot, rot + math.pi * 0.8)
        love.graphics.arc("line", "open", 0, 0, 22, rot + math.pi, rot + math.pi * 1.8)
    end
end

function EnemyVisuals.drawEnemy(enemyId, x, y, scale, rotation, shieldHealth, shootTimer, shootInterval)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(rotation or 0)
    love.graphics.scale(scale or 1, scale or 1)
    
    if enemyId == "basic_drone" then
        EnemyVisuals.basic_drone()
    elseif enemyId == "zigzag_fighter" then
        EnemyVisuals.zigzag_fighter()
    elseif enemyId == "bomber" then
        EnemyVisuals.bomber()
    elseif enemyId == "swarm_bee" then
        EnemyVisuals.swarm_bee()
    elseif enemyId == "heavy_assault" then
        EnemyVisuals.heavy_assault()
    elseif enemyId == "elite_fighter" then
        EnemyVisuals.elite_fighter(shieldHealth, shootTimer, shootInterval)
    else
        -- Default fallback
        Colors.setColor("danger", 1)
        love.graphics.circle("line", 0, 0, 10)
    end
    
    love.graphics.pop()
end

return EnemyVisuals
