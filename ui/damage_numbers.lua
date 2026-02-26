local Fonts = require('ui/fonts')
local Colors = require('ui/colors')

local DamageNumbers = {
    list = {}
}

function DamageNumbers.spawn(x, y, damage, isCrit)
    table.insert(DamageNumbers.list, {
        x = x + (math.random() * 20 - 10),
        y = y - 10,
        value = math.floor(damage),
        isCrit = isCrit,
        life = 0.5,
        maxLife = 0.5
    })
end

function DamageNumbers.update(dt)
    for i = #DamageNumbers.list, 1, -1 do
        local n = DamageNumbers.list[i]
        n.y = n.y - 50 * dt
        n.life = n.life - dt
        if n.life <= 0 then
            table.remove(DamageNumbers.list, i)
        end
    end
end

function DamageNumbers.draw()
    local oldFont = love.graphics.getFont()
    
    for _, n in ipairs(DamageNumbers.list) do
        local alpha = n.life / n.maxLife
        local colorKey = n.isCrit and "danger" or "accent"
        local fontSize = n.isCrit and "large" or "normal"
        
        Colors.setColor(colorKey, alpha)
        love.graphics.setFont(Fonts.getFont(fontSize))
        
        love.graphics.print(tostring(n.value), n.x, n.y)
    end
    
    love.graphics.setFont(oldFont)
end

return DamageNumbers
