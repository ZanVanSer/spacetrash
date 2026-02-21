local behavior = {}

function behavior.update(boss, dt)
    local screenWidth = love.graphics.getWidth()
    
    -- Move boss based on speed and current direction
    boss.x = boss.x + (boss.speed * boss.direction * dt)
    
    -- Reverse direction at screen boundaries (buffer of 40 pixels)
    if boss.x > screenWidth - 40 then
        boss.x = screenWidth - 40
        boss.direction = -1
    elseif boss.x < 40 then
        boss.x = 40
        boss.direction = 1
    end
end

return behavior
