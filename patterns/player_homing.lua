local sm = require("states/statemanager")

return {
    update = function(bullet, dt)
        local gameState = sm.current
        local target = nil
        local bulletSpeed = bullet.weaponData.bulletSpeed or 400
        local turnRate = 3 -- Radians per second

        -- Initialize velocity if not present
        if not bullet.vx or not bullet.vy then
            local angle = -math.pi / 2 -- Default: straight up
            bullet.vx = math.cos(angle) * bulletSpeed
            bullet.vy = math.sin(angle) * bulletSpeed
        end

        -- Try to find a target if game state is available
        if gameState and gameState.enemySpawner then
            local enemies = gameState.enemySpawner:getEnemies()
            local boss = gameState.boss
            
            local minDistSq = math.huge
            
            -- Check enemies
            for _, e in ipairs(enemies) do
                if not e.isDead then
                    local distSq = (bullet.x - e.x)^2 + (bullet.y - e.y)^2
                    if distSq < minDistSq then
                        minDistSq = distSq
                        target = e
                    end
                end
            end
            
            -- Check boss
            if boss and not boss.isDead then
                local distSq = (bullet.x - boss.x)^2 + (bullet.y - boss.y)^2
                if distSq < minDistSq then
                    minDistSq = distSq
                    target = boss
                end
            end
        end

        if target then
            -- Calculate desired angle to target
            local targetAngle = math.atan2(target.y - bullet.y, target.x - bullet.x)
            local currentAngle = math.atan2(bullet.vy, bullet.vx)
            
            -- Calculate angle difference and normalize to [-PI, PI]
            local angleDiff = targetAngle - currentAngle
            while angleDiff > math.pi do angleDiff = angleDiff - 2 * math.pi end
            while angleDiff < -math.pi do angleDiff = angleDiff + 2 * math.pi end
            
            -- Gradually turn towards target
            local maxTurn = turnRate * dt
            local change = math.max(-maxTurn, math.min(maxTurn, angleDiff))
            local newAngle = currentAngle + change
            
            -- Update velocity
            bullet.vx = math.cos(newAngle) * bulletSpeed
            bullet.vy = math.sin(newAngle) * bulletSpeed
        else
            -- If no enemies nearby, gradually return to moving straight up
            -- or move straight up if requested by "default direction"
            local targetAngle = -math.pi / 2
            local currentAngle = math.atan2(bullet.vy, bullet.vx)
            
            local angleDiff = targetAngle - currentAngle
            while angleDiff > math.pi do angleDiff = angleDiff - 2 * math.pi end
            while angleDiff < -math.pi do angleDiff = angleDiff + 2 * math.pi end
            
            local maxTurn = turnRate * dt
            local change = math.max(-maxTurn, math.min(maxTurn, angleDiff))
            local newAngle = currentAngle + change
            
            bullet.vx = math.cos(newAngle) * bulletSpeed
            bullet.vy = math.sin(newAngle) * bulletSpeed
        end

        -- Update position
        bullet.x = bullet.x + bullet.vx * dt
        bullet.y = bullet.y + bullet.vy * dt
    end
}
