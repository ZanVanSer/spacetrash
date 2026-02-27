local AttackStraight = {}

function AttackStraight.update(bullet, dt)
    -- Move bullet straight down: bullet.y = bullet.y + bullet.patternData.speed * dt
    bullet.y = bullet.y + bullet.patternData.speed * dt
end

return AttackStraight
