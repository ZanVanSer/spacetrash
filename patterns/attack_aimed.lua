local AttackAimed = {}

function AttackAimed.createBullets(x, y, patternData, playerX, playerY)
    local bullets = {}
    local speed = patternData.speed or 200
    
    -- Calculate angle to player: angle = math.atan2(playerY - y, playerX - x)
    local angle = math.atan2(playerY - y, playerX - x)
    
    local b = {}
    -- Copy patternData properties
    for k, v in pairs(patternData) do b[k] = v end
    
    b.x = x
    b.y = y
    b.vx = math.cos(angle) * speed
    b.vy = math.sin(angle) * speed
    b.isDead = false
    b.radius = 6
    
    table.insert(bullets, b)
    return bullets
end

function AttackAimed.update(bullet, dt)
    -- Move bullet
    bullet.x = bullet.x + (bullet.vx or 0) * dt
    bullet.y = bullet.y + (bullet.vy or 0) * dt
end

return AttackAimed
