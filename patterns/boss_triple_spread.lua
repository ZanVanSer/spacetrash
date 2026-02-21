local pattern = {}

function pattern.createBullets(x, y, bossData)
    local bullets = {}
    local speed = bossData.bulletSpeed or 200
    local damage = bossData.bulletDamage or 10
    local radius = 8
    
    -- Angles in radians (15 degrees = pi/12)
    local angles = { -math.pi/12, 0, math.pi/12 }
    
    for _, angle in ipairs(angles) do
        -- Calculate velocity: 
        -- vx = speed * sin(angle) 
        -- vy = speed * cos(angle)
        -- Since y increases downwards, cos(0) gives 1 (downwards)
        table.insert(bullets, {
            x = x,
            y = y,
            vx = speed * math.sin(angle),
            vy = speed * math.cos(angle),
            damage = damage,
            radius = radius,
            isDead = false
        })
    end
    
    return bullets
end

return pattern
