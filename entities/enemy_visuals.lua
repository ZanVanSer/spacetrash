local Colors = require('ui/colors')

local EnemyVisuals = {}

local function setEnemyColor(colorName, alpha, isElite)
    if isElite and colorName == "danger" then
        -- Brighter, more saturated red for elites
        love.graphics.setColor(1, 0.1, 0.1, alpha or 1)
    else
        Colors.setColor(colorName, alpha)
    end
end

function EnemyVisuals.drawCrown(radius)
    local t = love.timer.getTime()
    local bounce = math.sin(t * 4) * 3
    love.graphics.push()
    -- Position above the enemy
    love.graphics.translate(0, -radius - 12 + bounce)
    
    local pts = {
        -7, 0,
        -9, -7,
        -4, -3,
        0, -10,
        4, -3,
        9, -7,
        7, 0
    }
    
    -- Gold fill
    Colors.setColor("xp", 1)
    love.graphics.polygon("fill", pts)
    
    -- White shine/border
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.polygon("line", pts)
    
    love.graphics.pop()
end

function EnemyVisuals.basic_drone(isElite)
    local t = love.timer.getTime()
    local points = {0, 10, -10, -8, 10, -8}
    
    setEnemyColor("danger", 0.7, isElite)
    love.graphics.polygon("fill", points)
    
    love.graphics.setLineWidth(1)
    setEnemyColor("danger", 1, isElite)
    love.graphics.polygon("line", points)
    
    local pulse = (math.sin(t * (isElite and 12 or 8)) + 1) / 2
    setEnemyColor("danger", 0.2 + pulse * 0.3, isElite)
    love.graphics.circle("fill", 0, -2, 6)
    setEnemyColor("danger", 1, isElite)
    love.graphics.circle("fill", 0, -2, 3)
end

function EnemyVisuals.zigzag_fighter(isElite)
    local points = {0, -14, -10, 0, 0, 14, 10, 0}
    
    setEnemyColor("danger", 0.75, isElite)
    love.graphics.polygon("fill", points)
    
    love.graphics.setLineWidth(1)
    setEnemyColor("danger", 1, isElite)
    love.graphics.polygon("line", points)
    
    love.graphics.line(-6, 0, 6, 0)
    love.graphics.line(0, -6, 0, 6)
    
    love.graphics.setColor(1, 0.5, 0, 1)
    love.graphics.circle("fill", -4, 8, 2)
    love.graphics.circle("fill", 4, 8, 2)
end

function EnemyVisuals.bomber(isElite)
    local t = love.timer.getTime()
    local points = {0, 14, -14, 6, -18, -8, -10, -14, 10, -14, 18, -8, 14, 6}
    
    if isElite then
        love.graphics.setColor(0.4, 0, 0, 0.9)
    else
        love.graphics.setColor(0.2, 0, 0, 0.9)
    end
    love.graphics.polygon("fill", points)
    
    love.graphics.setLineWidth(2)
    setEnemyColor("danger", 1, isElite)
    love.graphics.polygon("line", points)
    
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", -6, -4, 12, 8)
    
    local pulse = (math.sin(t * 4) + 1) / 2
    love.graphics.setColor(1, 0.1, 0.1, 0.4 + pulse * 0.6)
    love.graphics.circle("fill", 0, 0, 5)
end

function EnemyVisuals.swarm_bee(isElite)
    local points = {0, 6, -6, -5, 6, -5}
    love.graphics.setLineWidth(1)
    
    for i = 1, 3 do
        local alpha = 0.5 - (i * 0.15)
        local offset = i * 5
        setEnemyColor("danger", alpha, isElite)
        love.graphics.push()
        love.graphics.translate(0, -offset)
        love.graphics.polygon("line", points)
        love.graphics.pop()
    end
    
    setEnemyColor("danger", 1, isElite)
    love.graphics.polygon("line", points)
end

function EnemyVisuals.heavy_assault(isElite)
    local t = love.timer.getTime()
    
    if isElite then
        love.graphics.setColor(0.4, 0, 0, 0.9)
    else
        love.graphics.setColor(0.25, 0, 0, 0.9)
    end
    love.graphics.rectangle("fill", -20, -15, 40, 30)
    
    love.graphics.setLineWidth(2)
    setEnemyColor("danger", 1, isElite)
    love.graphics.rectangle("line", -20, -15, 40, 30)
    
    love.graphics.setLineWidth(1)
    love.graphics.line(-10, -15, -10, 15)
    love.graphics.line(10, -15, 10, 15)
    love.graphics.line(-20, 0, 20, 0)
    
    setEnemyColor("danger", 1, isElite)
    love.graphics.circle("fill", -10, 5, 4)
    love.graphics.circle("fill", 10, 5, 4)
    
    local pulse = (math.sin(t * 12) + 1) / 2
    love.graphics.setColor(1, 0.4, 0, 0.4 + pulse * 0.6)
    love.graphics.circle("fill", -12, -15, 5)
    love.graphics.circle("fill", 12, -15, 5)
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.circle("fill", -12, -15, 2)
    love.graphics.circle("fill", 12, -15, 2)
end

function EnemyVisuals.elite_fighter(shieldHealth, shootTimer, shootInterval, isElite)
    local t = love.timer.getTime()
    local outerRadius = 16
    local innerRadius = 8
    local points = {}
    for i = 0, 11 do
        local ang = (i * math.pi / 6) - math.pi/2
        local r = (i % 2 == 0) and outerRadius or innerRadius
        table.insert(points, math.cos(ang) * r)
        table.insert(points, math.sin(ang) * r)
    end
    
    setEnemyColor("danger", 0.7, isElite)
    love.graphics.polygon("fill", points)
    
    love.graphics.setLineWidth(2)
    setEnemyColor("danger", 1, isElite)
    love.graphics.polygon("line", points)
    
    Colors.setColor("xp", 1)
    for i = 0, 5 do
        local ang = (i * math.pi / 3) - math.pi/2
        love.graphics.circle("fill", math.cos(ang) * outerRadius, math.sin(ang) * outerRadius, 2)
    end
    
    local pulse = (math.sin(t * 12) + 1) / 2
    if shootTimer and shootInterval then
        local timeRemaining = shootInterval - shootTimer
        if timeRemaining < 0.5 and timeRemaining > 0 then
            pulse = 0.5 + (0.5 - timeRemaining) / 0.5 * 0.5
        end
    end
    setEnemyColor("danger", 0.3 + pulse * 0.4, isElite)
    love.graphics.circle("fill", 0, 0, 8)
    setEnemyColor("danger", 1, isElite)
    love.graphics.circle("fill", 0, 0, 4)
    
    if shieldHealth and shieldHealth > 0 then
        love.graphics.setLineWidth(2)
        Colors.setColor("accent", 0.6)
        local rot = t * 4
        love.graphics.arc("line", "open", 0, 0, 22, rot, rot + math.pi * 0.8)
        love.graphics.arc("line", "open", 0, 0, 22, rot + math.pi, rot + math.pi * 1.8)
    end
end

function EnemyVisuals.drawEnemy(enemyId, x, y, scale, rotation, shieldHealth, shootTimer, shootInterval, isElite)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(rotation or 0)
    
    local finalScale = scale or 1
    if isElite then finalScale = finalScale * 1.15 end
    love.graphics.scale(finalScale, finalScale)
    
    local function drawShape()
        if enemyId == "basic_drone" then
            EnemyVisuals.basic_drone(isElite)
        elseif enemyId == "zigzag_fighter" then
            EnemyVisuals.zigzag_fighter(isElite)
        elseif enemyId == "bomber" then
            EnemyVisuals.bomber(isElite)
        elseif enemyId == "swarm_bee" then
            EnemyVisuals.swarm_bee(isElite)
        elseif enemyId == "heavy_assault" then
            EnemyVisuals.heavy_assault(isElite)
        elseif enemyId == "elite_fighter" then
            EnemyVisuals.elite_fighter(shieldHealth, shootTimer, shootInterval, isElite)
        else
            setEnemyColor("danger", 1, isElite)
            love.graphics.circle("line", 0, 0, 10)
        end
    end
    
    if isElite then
        -- Particle trail (simulated with fading shapes)
        local t = love.timer.getTime()
        for i = 1, 2 do
            local alpha = 0.2 / i
            local offset = i * 8 + math.sin(t * 10 + i) * 2
            love.graphics.push()
            love.graphics.translate(0, offset)
            love.graphics.scale(0.95, 0.95)
            setEnemyColor("danger", alpha, true)
            drawShape()
            love.graphics.pop()
        end
        
        -- Crown
        EnemyVisuals.drawCrown(15)
        
        -- Enhanced Glow
        local pulse = (math.sin(t * 15) + 1) / 2
        Colors.drawGlow("danger", drawShape, 1.6 + pulse * 0.3, 1.2 + pulse * 0.1)
    else
        drawShape()
    end
    
    love.graphics.pop()
end

return EnemyVisuals
