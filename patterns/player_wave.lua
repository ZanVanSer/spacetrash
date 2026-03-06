local sm = require("states/statemanager")

return {
    update = function(bullet, dt)
        if bullet.followPlayer ~= false then
            local gameState = sm.current
            if gameState and gameState.player then
                bullet.x = gameState.player.x
                bullet.y = gameState.player.y
            end
        end
        
        -- Expansion speed
        local expansionSpeed = (bullet.weaponData.bulletSpeed or 300)
        if expansionSpeed == 0 then expansionSpeed = 400 end -- Default for stationary waves
        
        expansionSpeed = expansionSpeed * (bullet.weaponData.area or 1.0)
        bullet.waveRadius = (bullet.waveRadius or 0) + expansionSpeed * dt
        
        -- Collision radius is its current visual radius
        bullet.radius = bullet.waveRadius
    end
}
