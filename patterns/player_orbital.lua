local sm = require("states/statemanager")

return {
    update = function(bullet, dt)
        local gameState = sm.current
        if not gameState or not gameState.player then return end
        
        local player = gameState.player
        
        -- Initialize orbit properties on first update
        if not bullet.orbitAngle then
            -- Randomize start angle to spread out multiple drones if not set by WS
            bullet.orbitAngle = (love.math.random() * math.pi * 2)
        end
        if not bullet.orbitRadius then
            -- Base radius of 80, modified by weapon area stat
            bullet.orbitRadius = 80 * (bullet.weaponData.area or 1.0)
        end
        
        -- Update orbit angle (2 radians per second)
        bullet.orbitAngle = bullet.orbitAngle + 2 * dt
        
        -- Position bullet around player
        bullet.x = player.x + math.cos(bullet.orbitAngle) * bullet.orbitRadius
        bullet.y = player.y + math.sin(bullet.orbitAngle) * bullet.orbitRadius
        
        -- Auto-fire at nearby enemies when facing them
        bullet.fireTimer = (bullet.fireTimer or 0) - dt
        if bullet.fireTimer <= 0 then
            -- Gather potential targets
            local targets = {}
            if gameState.enemySpawner then
                for _, e in ipairs(gameState.enemySpawner:getEnemies()) do
                    if not e.isDead then table.insert(targets, e) end
                end
            end
            if gameState.boss and not gameState.boss.isDead then
                table.insert(targets, gameState.boss)
            end
            
            -- "Facing" is the tangent direction of the orbit
            local facingAngle = bullet.orbitAngle + math.pi/2
            
            local bestTarget = nil
            local bestAngleDiff = 0.5 -- Max tolerance
            
            for _, target in ipairs(targets) do
                local dx = target.x - bullet.x
                local dy = target.y - bullet.y
                local distSq = dx*dx + dy*dy
                
                -- Check if target is within range (e.g., 300 units)
                if distSq < 300*300 then
                    local angleToTarget = math.atan2(dy, dx)
                    local angleDiff = (angleToTarget - facingAngle + math.pi) % (math.pi * 2) - math.pi
                    
                    if math.abs(angleDiff) < bestAngleDiff then
                        bestAngleDiff = math.abs(angleDiff)
                        bestTarget = target
                    end
                end
            end
            
            if bestTarget then
                local BulletClass = require("entities/bullet")
                -- Use weapon's fireRate if available, otherwise default
                local cooldown = bullet.weaponData.fireRate or 0.5
                
                local shootData = {
                    damage = bullet.weaponData.damage,
                    bulletSpeed = bullet.weaponData.bulletSpeed or 400,
                    pattern = "spread" -- Uses bullet.angle for direction
                }
                local b = BulletClass.new(bullet.x, bullet.y, shootData)
                b.angle = facingAngle
                table.insert(player.ws.bullets, b)
                
                -- Play weapon sound
                local soundName, soundVol = player.ws:getWeaponSound(bullet.weaponData.id)
                if soundName and player.ws.audioManager then
                    player.ws.audioManager.playSound(soundName, soundVol)
                end
                
                bullet.fireTimer = cooldown
            end
        end
    end
}
