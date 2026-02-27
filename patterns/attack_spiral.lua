local AttackSpiral = {}

function AttackSpiral.update(bullet, dt)
    -- Move downward: bullet.y = bullet.y + bullet.patternData.speed * dt
    local speed = bullet.patternData.speed or 200
    bullet.y = bullet.y + speed * dt
    
    -- Rotate around center (corkscrew/spiral effect)
    -- bullet.spiralAngle = (bullet.spiralAngle or 0) + 3 * dt
    -- bullet.x = bullet.x + math.cos(bullet.spiralAngle) * 50 * dt
    bullet.spiralAngle = (bullet.spiralAngle or 0) + 5 * dt -- Increased rotation speed slightly for better visual spiral
    bullet.x = bullet.x + math.cos(bullet.spiralAngle) * 150 * dt -- Increased width to make spiral visible
end

return AttackSpiral
