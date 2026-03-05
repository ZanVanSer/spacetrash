local sm = require("states/statemanager")

return {
    update = function(bullet, dt)
        local gameState = sm.current
        if not gameState or not gameState.player then return end
        
        local player = gameState.player
        
        -- Base rotation speed 1.0, scales with weapon bulletSpeed (which is affected by passives)
        local rotationSpeed = bullet.weaponData.bulletSpeed or 1.0
        bullet.orbitAngle = (bullet.orbitAngle or 0) + rotationSpeed * dt
        
        -- Whip length increased to 60 units
        local baseRadius = 60 
        local whipPulse = math.sin(love.timer.getTime() * 8) * 5
        bullet.orbitRadius = baseRadius + whipPulse
        
        bullet.x = player.x + math.cos(bullet.orbitAngle) * bullet.orbitRadius
        bullet.y = player.y + math.sin(bullet.orbitAngle) * bullet.orbitRadius
    end
}
