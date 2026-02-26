return {
    update = function(enemy, dt)
        -- Initialize swarm-specific properties if they don't exist
        if not enemy.swarmOffset then
            enemy.swarmOffset = math.random() * math.pi * 2
        end

        local time = love.timer.getTime()
        
        -- Orbit movement
        local angle = (time * 2) + enemy.swarmOffset
        
        -- Move down slowly
        enemy.y = enemy.y + (enemy.speed * 0.3 * dt)
        
        -- Move in a circle relative to current position
        enemy.x = enemy.x + math.cos(angle) * 30 * dt
        enemy.y = enemy.y + math.sin(angle) * 30 * dt
    end
}
