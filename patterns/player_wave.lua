local sm = require("states/statemanager")

return {
    update = function(bullet, dt)
        local gameState = sm.current
        if not gameState or not gameState.player then return end
        
        local player = gameState.player
        
        -- Pulse Wave expands from the player
        bullet.x = player.x
        bullet.y = player.y
        
        -- Expansion speed scales with area stat
        local expansionSpeed = (bullet.weaponData.bulletSpeed or 300) * (bullet.weaponData.area or 1.0)
        bullet.waveRadius = (bullet.waveRadius or 0) + expansionSpeed * dt
        
        -- Collision radius is its current visual radius
        bullet.radius = bullet.waveRadius
    end
}
