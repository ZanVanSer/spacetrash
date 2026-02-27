local AttackSpread = {}

function AttackSpread.createBullets(x, y, patternData, playerX, playerY)
    local bullets = {}
    local speed = patternData.speed or 200
    local angleToPlayer = math.atan2(playerY - y, playerX - x)
    local spread = math.rad(20)
    
    local angles = {
        angleToPlayer - spread, -- Left bullet
        angleToPlayer,          -- Center bullet
        angleToPlayer + spread  -- Right bullet
    }
    
    for _, angle in ipairs(angles) do
        table.insert(bullets, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            patternData = patternData,
            isDead = false,
            radius = 6
        })
    end
    
    return bullets
end

function AttackSpread.update(bullet, dt)
    -- Same as aimed pattern (moves in assigned direction)
    -- Ensure vx/vy are initialized if not already set (fallback to aimed logic)
    if not bullet.vx or not bullet.vy then
        local sm = require('states/statemanager')
        local player = sm.current and sm.current.player
        local px, py = bullet.x, bullet.y + 100
        if player then px, py = player.x, player.y end
        
        local angle = math.atan2(py - bullet.y, px - bullet.x)
        local speed = bullet.patternData.speed or 200
        bullet.vx = math.cos(angle) * speed
        bullet.vy = math.sin(angle) * speed
    end

    bullet.x = bullet.x + bullet.vx * dt
    bullet.y = bullet.y + bullet.vy * dt
end

return AttackSpread
