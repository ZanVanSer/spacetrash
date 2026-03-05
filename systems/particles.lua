local Colors = require('ui.colors')

local Particles = {
    list = {},
    chains = {}, -- New list for persistent line effects
    rings = {},  -- New list for expanding circle effects
    beams = {},  -- New list for lingering railgun beams
    enabled = true
}

function Particles.spawn(x, y, count, colorKey, speed, size)
    if not Particles.enabled then return end
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

-- New function for lightning visual effect
function Particles.lightningChain(x1, y1, x2, y2, colorKey)
    if not Particles.enabled then return end
    local life = 0.15
    local points = {}
    local segments = 5
    local dx, dy = x2 - x1, y2 - y1
    local dist = math.sqrt(dx*dx + dy*dy)
    
    table.insert(points, x1)
    table.insert(points, y1)
    
    for i = 1, segments - 1 do
        local t = i / segments
        local px = x1 + dx * t
        local py = y1 + dy * t
        
        -- Offset perpendicular to the line for "jagged" look
        local offset = (math.random() - 0.5) * 20 * (dist/100)
        local nx, ny = -dy/dist, dx/dist
        px = px + nx * offset
        py = py + ny * offset
        
        table.insert(points, px)
        table.insert(points, py)
    end
    
    table.insert(points, x2)
    table.insert(points, y2)
    
    table.insert(Particles.chains, {
        points = points,
        life = life,
        maxLife = life,
        colorKey = colorKey or "accent"
    })
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

function Particles.explosion(x, y, area)
    local count = 20 * (area or 1.0)
    local speed = 100 * (area or 1.0)
    Particles.spawn(x, y, count, "accent", speed, 3)
    Particles.spawn(x, y, count/2, "danger", speed * 0.7, 4)
    Particles.spawn(x, y, count/4, "bg", speed * 0.5, 2)
    
    -- Add expanding ring
    table.insert(Particles.rings, {
        x = x,
        y = y,
        radius = 0,
        maxRadius = 60 * (area or 1.0),
        life = 0.4,
        maxLife = 0.4,
        colorKey = "accent"
    })
end

function Particles.railgunBeam(x, y, width)
    table.insert(Particles.beams, {
        x = x,
        y = y,
        width = width or 4,
        life = 0.6,
        maxLife = 0.6,
        colorKey = "accent"
    })
end

function Particles.update(dt)
    -- Update standard particles
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
    
    -- Update chain effects
    for i = #Particles.chains, 1, -1 do
        local c = Particles.chains[i]
        c.life = c.life - dt
        if c.life <= 0 then
            table.remove(Particles.chains, i)
        end
    end

    -- Update ring effects
    for i = #Particles.rings, 1, -1 do
        local r = Particles.rings[i]
        r.life = r.life - dt
        r.radius = r.maxRadius * (1 - (r.life / r.maxLife))
        if r.life <= 0 then
            table.remove(Particles.rings, i)
        end
    end

    -- Update beam effects
    for i = #Particles.beams, 1, -1 do
        local b = Particles.beams[i]
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(Particles.beams, i)
        end
    end
end

function Particles.draw()
    -- Draw chains (lightning lines)
    for _, c in ipairs(Particles.chains) do
        local alpha = (c.life / c.maxLife) * 0.8
        Colors.setColor(c.colorKey, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.line(c.points)
        
        -- Inner bright core
        Colors.setColor("bg", alpha * 1.5)
        love.graphics.setLineWidth(1)
        love.graphics.line(c.points)
    end
    love.graphics.setLineWidth(1)

    -- Draw rings
    for _, r in ipairs(Particles.rings) do
        local alpha = (r.life / r.maxLife) * 0.6
        Colors.setColor(r.colorKey, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", r.x, r.y, r.radius)
    end
    love.graphics.setLineWidth(1)

    -- Draw beams
    for _, b in ipairs(Particles.beams) do
        local alpha = (b.life / b.maxLife)
        local flicker = (math.floor(love.timer.getTime() * 30) % 2 == 0) and 1.0 or 0.7
        
        -- Outer glow
        Colors.setColor(b.colorKey, alpha * 0.2 * flicker)
        love.graphics.setLineWidth(b.width * 2)
        love.graphics.line(b.x, b.y, b.x, -100)
        
        -- Main beam
        Colors.setColor(b.colorKey, alpha * 0.8 * flicker)
        love.graphics.setLineWidth(b.width)
        love.graphics.line(b.x, b.y, b.x, -100)
        
        -- Core
        Colors.setColor("bg", alpha * flicker)
        love.graphics.setLineWidth(b.width * 0.4)
        love.graphics.line(b.x, b.y, b.x, -100)
    end
    love.graphics.setLineWidth(1)

    -- Draw particles
    for _, p in ipairs(Particles.list) do
        local alpha = p.life / p.maxLife
        local drawSize = p.size * alpha
        
        Colors.setColor(p.colorKey, alpha)
        love.graphics.circle("fill", p.x, p.y, drawSize)
    end
end

return Particles
