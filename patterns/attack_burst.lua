local AttackBurst = {}

-- System compatibility alias
function AttackBurst.createBullets(x, y, patternData, playerX, playerY)
    local count = patternData.count or 3
    return AttackBurst.burstFire(x, y, count, patternData, playerX, playerY)
end

function AttackBurst.burstFire(x, y, count, patternData, playerX, playerY)
    local bullets = {}
    local speed = (patternData.speed or 200) * 1.3 -- High speed for bursts
    
    -- Shoot straight down
    local vx, vy = 0, speed

    for i = 1, count do
        -- Clone patternData and add specific burst properties
        local b = {}
        for k, v in pairs(patternData) do b[k] = v end
        
        b.x = x
        b.y = y
        b.vx = vx
        b.vy = vy
        b.delay = (i - 1) * 0.1 -- Bullets spawn 0.1 seconds apart
        b.isDead = false
        b.radius = 6
        
        table.insert(bullets, b)
    end
    
    return bullets
end

function AttackBurst.update(bullet, dt)
    -- Handle spawn delay
    if not bullet._timer then
        bullet._timer = bullet.patternData.delay or 0
    end

    if bullet._timer > 0 then
        bullet._timer = bullet._timer - dt
        return
    end

    -- Move bullet using pre-calculated velocities
    bullet.x = bullet.x + (bullet.vx or 0) * dt
    bullet.y = bullet.y + (bullet.vy or 0) * dt
end

return AttackBurst
