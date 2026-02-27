local AttackSpread = {}

function AttackSpread.createBullets(x, y, patternData, playerX, playerY)
    local bullets = {}
    local speed = patternData.speed or 200
    -- Shoot straight down (angle = pi/2)
    local baseAngle = math.pi / 2
    local spread = math.rad(20)
    
    local angles = {
        baseAngle - spread, -- Left bullet
        baseAngle,          -- Center bullet
        baseAngle + spread  -- Right bullet
    }
    
    for _, angle in ipairs(angles) do
        -- Merge patternData into the bullet table
        local b = {}
        for k, v in pairs(patternData) do b[k] = v end
        
        b.x = x
        b.y = y
        b.vx = math.cos(angle) * speed
        b.vy = math.sin(angle) * speed
        b.isDead = false
        b.radius = 6
        
        table.insert(bullets, b)
    end
    
    return bullets
end

function AttackSpread.update(bullet, dt)
    -- Ensure vx/vy are initialized if not already set (fallback to straight down logic)
    if not bullet.vx or not bullet.vy then
        local speed = bullet.patternData.speed or 200
        bullet.vx = 0
        bullet.vy = speed
    end

    bullet.x = bullet.x + bullet.vx * dt
    bullet.y = bullet.y + bullet.vy * dt
end

return AttackSpread
