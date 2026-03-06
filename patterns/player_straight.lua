return {
    update = function(bullet, dt)
        local angle = bullet.angle or -math.pi/2
        local speed = bullet.weaponData.bulletSpeed
        bullet.x = bullet.x + math.cos(angle) * speed * dt
        bullet.y = bullet.y + math.sin(angle) * speed * dt
    end
}
