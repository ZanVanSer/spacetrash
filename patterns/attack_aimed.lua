local AttackAimed = {}

function AttackAimed.new(bullet)
    -- Calculate angle to player: angle = math.atan2(playerY - y, playerX - x)
    local sm = require('states/statemanager')
    local player = sm.current and sm.current.player
    
    local px, py = bullet.x, bullet.y + 100 -- Default to straight down if no player
    if player then
        px, py = player.x, player.y
    end
    
    local angle = math.atan2(py - bullet.y, px - bullet.x)
    local speed = bullet.patternData.speed or 200
    
    -- Store velocities
    bullet.vx = math.cos(angle) * speed
    bullet.vy = math.sin(angle) * speed
end

function AttackAimed.update(bullet, dt)
    -- Ensure vx and vy are initialized
    if not bullet.vx or not bullet.vy then
        AttackAimed.new(bullet)
    end
    
    -- Move bullet
    bullet.x = bullet.x + bullet.vx * dt
    bullet.y = bullet.y + bullet.vy * dt
end

return AttackAimed
