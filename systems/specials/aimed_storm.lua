local Colors = require('ui/colors')
local EnemyBullet = require('entities/enemy_bullet')

local AimedStorm = {}

--- Handler for the aimed storm special attack.
--- @param attackData table Parameters: shotCount, pattern, telegraphDuration, bulletSpeed, bulletDamage
--- @param source table The boss or enemy entity performing the attack
--- @param telegraph table Reference to the telegraph system for visual cues
--- @return table An attack state object with an update(dt, source, playerX, playerY) function
function AimedStorm.execute(attackData, source, telegraph)
    local shotCount = attackData.shotCount or 8
    local patternName = attackData.pattern or "aimed"
    local telegraphDuration = attackData.telegraphDuration or 1.0
    local bulletSpeed = attackData.bulletSpeed or (source.bossData and source.bossData.bulletSpeed) or 200
    local bulletDamage = attackData.bulletDamage or (source.bossData and source.bossData.bulletDamage) or 10

    local state = {
        targetPositions = {},
        phase = "telegraph", -- "telegraph" or "execute"
        shotsFired = 0,
        timer = 0,
        trackTimer = 0,
        trackInterval = telegraphDuration / shotCount,
        shotTimer = 0,
        shotInterval = 0.2, -- Standard delay between shots in the storm
        telegraphDuration = telegraphDuration,
        shotCount = shotCount,
        patternName = patternName,
        bulletSpeed = bulletSpeed,
        bulletDamage = bulletDamage,
        lockMovement = true,
        telegraph = telegraph
    }

    --- Updates the attack state.
    --- @param dt number Delta time
    --- @param source table The boss or enemy entity
    --- @param playerX number Current player X coordinate
    --- @param playerY number Current player Y coordinate
    --- @return boolean True if the attack is complete
    function state.update(dt, source, playerX, playerY)
        state.timer = state.timer + dt

        -- PHASE 1: Tracking and Telegraphing
        if state.phase == "telegraph" then
            state.trackTimer = state.trackTimer + dt
            
            -- Track player position at intervals
            if state.trackTimer >= state.trackInterval and #state.targetPositions < state.shotCount then
                state.trackTimer = state.trackTimer - state.trackInterval
                
                local target = {
                    x = playerX or source.x,
                    y = playerY or (source.y + 100)
                }
                table.insert(state.targetPositions, target)
                
                -- Create area telegraph at the tracked position
                if state.telegraph and state.telegraph.createAreaTelegraph then
                    -- Telegraph lasts until slightly after the storm starts
                    local remainingDuration = (state.telegraphDuration - state.timer) + 0.5
                    state.telegraph:createAreaTelegraph(
                        target.x, 
                        target.y, 
                        30, 
                        math.max(0.2, remainingDuration), 
                        Colors.COLORS.danger
                    )
                end
            end

            -- Switch to execution phase when telegraph duration is over
            if state.timer >= state.telegraphDuration then
                state.phase = "execute"
                state.timer = 0
                state.shotTimer = 0.2 -- Small initial delay before first shot
            end
            return false
        end

        -- PHASE 2: Shooting at Recorded Positions
        if state.phase == "execute" then
            state.shotTimer = state.shotTimer + dt
            
            while state.shotsFired < state.shotCount and state.shotTimer >= state.shotInterval do
                state.shotTimer = state.shotTimer - state.shotInterval
                state.shotsFired = state.shotsFired + 1
                
                local target = state.targetPositions[state.shotsFired]
                if target then
                    -- Fire pattern at the stored target position
                    local fileName = state.patternName
                    if not fileName:find("^attack_") then
                        fileName = "attack_" .. fileName
                    end
                    
                    local normalizedPattern = state.patternName:gsub("^attack_", "")
                    local pattern = require("patterns/" .. fileName)
                    local bulletData = {
                        pattern = normalizedPattern,
                        speed = state.bulletSpeed,
                        damage = state.bulletDamage
                    }

                    -- Create the bullet(s) aimed at the recorded target
                    if pattern.createBullets then
                        local bullets = pattern.createBullets(source.x, source.y, bulletData, target.x, target.y)
                        for _, bData in ipairs(bullets) do
                            if source.bullets then
                                table.insert(source.bullets, EnemyBullet.new(bData.x, bData.y, bData))
                            end
                        end
                    else
                        -- Fallback for simple patterns: calculate direct velocity
                        local angle = math.atan2(target.y - source.y, target.x - source.x)
                        bulletData.vx = math.cos(angle) * state.bulletSpeed
                        bulletData.vy = math.sin(angle) * state.bulletSpeed
                        if source.bullets then
                            table.insert(source.bullets, EnemyBullet.new(source.x, source.y, bulletData))
                        end
                    end
                end
            end
            
            -- Return true when all shots are fired
            return state.shotsFired >= state.shotCount
        end

        return false
    end

    return state
end

return AimedStorm
