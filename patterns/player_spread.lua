return {
    update = function(bullet, dt)
        local speed = bullet.weaponData.bulletSpeed or 400
        -- Use bullet.angle if set, otherwise default to straight up (-PI/2)
        local angle = bullet.angle or -math.pi / 2
        
        bullet.x = bullet.x + math.cos(angle) * speed * dt
        bullet.y = bullet.y + math.sin(angle) * speed * dt
    end
}
