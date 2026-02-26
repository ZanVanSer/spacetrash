local Colors = require('ui.colors')

local Particles = {
    list = {}
}

function Particles.spawn(x, y, count, colorKey, speed, size)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local s = speed * (0.5 + math.random())
        local life = 0.3 + math.random() * 0.3
        
        table.insert(Particles.list, {
            x = x,
            y = y,
            vx = math.cos(angle) * s,
            vy = math.sin(angle) * s,
            life = life,
            maxLife = life,
            colorKey = colorKey,
            size = size
        })
    end
end

-- Presets
function Particles.enemyDeath(x, y)
    Particles.spawn(x, y, 8, "danger", 150, 2)
end

function Particles.playerHit(x, y)
    Particles.spawn(x, y, 5, "accent", 100, 1.5)
end

function Particles.xpPickup(x, y)
    Particles.spawn(x, y, 4, "xp", 80, 1)
end

function Particles.bossHit(x, y)
    Particles.spawn(x, y, 12, "danger", 200, 3)
end

function Particles.update(dt)
    for i = #Particles.list, 1, -1 do
        local p = Particles.list[i]
        
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        
        -- Apply gravity
        p.vy = p.vy + 50 * dt
        
        p.life = p.life - dt
        
        if p.life <= 0 then
            table.remove(Particles.list, i)
        end
    end
end

function Particles.draw()
    for _, p in ipairs(Particles.list) do
        local alpha = p.life / p.maxLife
        local drawSize = p.size * alpha
        
        Colors.setColor(p.colorKey, alpha)
        love.graphics.circle("fill", p.x, p.y, drawSize)
    end
end

return Particles
