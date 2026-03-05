return {
    update = function(bullet, dt)
        -- Mines move slowly forward and then stop or just keep moving slowly
        -- Let's have them move and slowly decelerate
        bullet.velocity = bullet.velocity or bullet.weaponData.bulletSpeed or 200
        bullet.y = bullet.y - bullet.velocity * dt
        
        -- Decelerate
        bullet.velocity = math.max(20, bullet.velocity - 100 * dt)
    end
}
