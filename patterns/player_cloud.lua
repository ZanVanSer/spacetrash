return {
    update = function(bullet, dt)
        -- Clouds move very slowly forward and expand slightly
        bullet.velocity = bullet.velocity or bullet.weaponData.bulletSpeed or 100
        bullet.y = bullet.y - bullet.velocity * dt
        
        -- Decelerate to almost zero
        bullet.velocity = math.max(10, bullet.velocity - 50 * dt)
    end
}
