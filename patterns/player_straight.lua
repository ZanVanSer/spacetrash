return {
    update = function(bullet, dt)
        bullet.y = bullet.y - bullet.weaponData.bulletSpeed * dt
    end
}
