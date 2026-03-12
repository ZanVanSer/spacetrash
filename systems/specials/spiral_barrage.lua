local Colors = require('ui/colors')
local EnemyBullet = require('entities/enemy_bullet')

local SpiralBarrage = {}

--- Handler for the spiral barrage special attack.
--- @param attackData table Parameters: duration, burstCount, pattern, bulletSpeed, bulletDamage
--- @param source table The boss or enemy entity performing the attack
--- @param telegraph table Reference to the telegraph system for visual cues
--- @return table An attack state object with an update(dt, source) function
function SpiralBarrage.execute(attackData, source, telegraph)
    local duration = attackData.duration or 3.0
    local burstCount = attackData.burstCount or 15
    local patternName = attackData.pattern or "spiral"
    local bulletSpeed = attackData.bulletSpeed or (source.bossData and source.bossData.bulletSpeed) or 200
    local bulletDamage = attackData.bulletDamage or (source.bossData and source.bossData.bulletDamage) or 10
    local warningDuration = 0.8

    -- Create telegraph warning (expanding rings)
    -- In ui/attack_telegraph.lua, 'area' telegraphs expand to fill their radius
    if telegraph and telegraph.createAreaTelegraph then
        local radius = source.radius or 40
        telegraph:createAreaTelegraph(source.x, source.y, radius + 20, warningDuration, Colors.COLORS.danger)
        telegraph:createAreaTelegraph(source.x, source.y, radius + 40, warningDuration, Colors.COLORS.danger)
        telegraph:createAreaTelegraph(source.x, source.y, radius + 60, warningDuration, Colors.COLORS.danger)
    end

    local state = {
        timer = 0,
        burstsFired = 0,
        burstCount = burstCount,
        burstInterval = duration / burstCount,
        shotTimer = 0,
        warningDuration = warningDuration,
        elapsed = 0,
        patternName = patternName,
        bulletSpeed = bulletSpeed,
        bulletDamage = bulletDamage,
        lockMovement = true
    }

    --- Updates the attack state.
    --- @param dt number Delta time
    --- @param source table The boss or enemy entity
    --- @return boolean True if the attack is complete
    function state.update(dt, source)
        state.elapsed = state.elapsed + dt
        
        -- Wait for the telegraph/warning period to finish
        if state.elapsed < state.warningDuration then
            return false
        end

        state.shotTimer = state.shotTimer + dt
        
        -- Fire bursts over time
        while state.burstsFired < state.burstCount and state.shotTimer >= state.burstInterval do
            state.shotTimer = state.shotTimer - state.burstInterval
            
            -- Prepare the pattern
            local fileName = state.patternName
            if not fileName:find("^attack_") then
                fileName = "attack_" .. fileName
            end
            
            -- Normalizing pattern name for bullet initialization (remove 'attack_' prefix)
            local normalizedPattern = state.patternName:gsub("^attack_", "")
            
            local pattern = require("patterns/" .. fileName)
            local bulletData = {
                pattern = normalizedPattern,
                speed = state.bulletSpeed,
                damage = state.bulletDamage
            }
            
            -- Fire the bullet(s)
            local ox = source.x
            local oy = source.y
            
            -- Default target (used if the pattern requires it, e.g., aimed)
            -- For a spiral barrage, we generally fire in a rotating or fixed pattern
            local tx = ox
            local ty = oy + 100

            if pattern.createBullets then
                local newBulletsData = pattern.createBullets(ox, oy, bulletData, tx, ty)
                for _, bData in ipairs(newBulletsData) do
                    -- source must have a 'enemyBullets' table to store active projectiles
                    if source.enemyBullets then
                        table.insert(source.enemyBullets, EnemyBullet.new(bData.x, bData.y, bData))
                    end
                end
            else
                if source.enemyBullets then
                    table.insert(source.enemyBullets, EnemyBullet.new(ox, oy, bulletData))
                end
            end

            state.burstsFired = state.burstsFired + 1
        end

        -- Return true when all bursts have been fired
        return state.burstsFired >= state.burstCount
    end

    return state
end

return SpiralBarrage
