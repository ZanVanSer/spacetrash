local Colors = require('ui/colors')
local EnemyBullet = require('entities/enemy_bullet')
local Screen = require('systems/screen')

local ScreenClear = {}

--- Handler for the screen clear special attack.
--- @param attackData table Parameters: directions, pattern, telegraphDuration, bulletSpeed, bulletDamage
--- @param source table The boss or enemy entity performing the attack
--- @param telegraph table Reference to the telegraph system for visual cues
--- @return table An attack state object with an update(dt, source) function
function ScreenClear.execute(attackData, source, telegraph)
    local directions = attackData.directions or 8
    local patternName = attackData.pattern or "aimed" -- Usually aimed or straight
    local telegraphDuration = attackData.telegraphDuration or 1.0
    local bulletSpeed = attackData.bulletSpeed or ((source.bossData and source.bossData.bulletSpeed or 200) * 1.5)
    local bulletDamage = attackData.bulletDamage or (source.bossData and source.bossData.bulletDamage or 10)

    -- Create line telegraphs radiating from source
    if telegraph and telegraph.createLineTelegraph then
        local telegraphLength = math.max(Screen.getVirtualWidth(), Screen.getVirtualHeight())
        for i = 1, directions do
            local angle = (i - 1) * ((math.pi * 2) / directions)
            local tx = source.x + math.cos(angle) * telegraphLength
            local ty = source.y + math.sin(angle) * telegraphLength
            telegraph:createLineTelegraph(source.x, source.y, tx, ty, telegraphDuration, Colors.COLORS.danger)
        end
    end

    local state = {
        directions = directions,
        telegraphTimer = 0,
        telegraphDuration = telegraphDuration,
        fired = false,
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
        if state.fired then return true end

        state.telegraphTimer = state.telegraphTimer + dt
        
        -- Fire bullets in all directions after telegraph duration
        if state.telegraphTimer >= state.telegraphDuration then
            local dirs = math.max(1, state.directions)
            
            -- Prepare pattern name
            local fileName = state.patternName
            if not fileName:find("^attack_") then
                fileName = "attack_" .. fileName
            end
            local normalizedPattern = state.patternName:gsub("^attack_", "")

            for i = 1, dirs do
                local angle = (i - 1) * ((math.pi * 2) / dirs)
                
                -- Force 'aimed' pattern for the individual bullets because 
                -- attack_straight.lua is hardcoded to only move DOWN.
                -- attack_aimed.lua respects vx and vy which we calculate here.
                local bulletPattern = normalizedPattern
                if bulletPattern == "straight" then
                    bulletPattern = "aimed"
                end

                local bData = {
                    pattern = bulletPattern,
                    speed = state.bulletSpeed,
                    damage = state.bulletDamage,
                    vx = math.cos(angle) * state.bulletSpeed,
                    vy = math.sin(angle) * state.bulletSpeed,
                    isDead = false,
                    radius = 6
                }
                
                if source.bullets then
                    table.insert(source.bullets, EnemyBullet.new(source.x, source.y, bData))
                end
            end
            
            state.fired = true
            return true
        end

        return false
    end

    return state
end

return ScreenClear
