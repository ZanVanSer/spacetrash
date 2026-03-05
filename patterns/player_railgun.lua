local Particles = require('systems.particles')

return {
    update = function(bullet, dt)
        if not bullet.beamSpawned then
            Particles.railgunBeam(bullet.x, bullet.y, 6 * (bullet.weaponData.area or 1.0))
            bullet.beamSpawned = true
        end
        
        -- Move extremely fast
        bullet.y = bullet.y - bullet.weaponData.bulletSpeed * dt
    end
}
