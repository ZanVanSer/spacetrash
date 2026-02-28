local behavior = {}

function behavior.update(boss, dt, speed)
    local Screen = require('systems.screen')
    local vw = Screen.getVirtualWidth()
    local hudW = 220
    
    -- Faster side-to-side movement
    boss.x = boss.x + (boss.direction * (speed or 150) * dt)
    
    -- Boundary reversal
    if boss.x > vw - boss.radius then
        boss.x = vw - boss.radius
        boss.direction = -1
    elseif boss.x < hudW + boss.radius then
        boss.x = hudW + boss.radius
        boss.direction = 1
    end
    
    -- Aggressive vertical oscillation
    boss.y = 100 + math.sin(love.timer.getTime() * 5) * 50
end

return behavior
