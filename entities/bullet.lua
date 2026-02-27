local Colors = require('ui/colors')

local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(x, y, weaponData)
    local self = setmetatable({}, Bullet)
    self.x, self.y = x, y
    self.weaponData = weaponData
    self.isDead = false
    return self
end

function Bullet:update(dt)
    local pattern = require("patterns/player_" .. self.weaponData.pattern)
    pattern.update(self, dt)
    if self.y < -50 then self.isDead = true end
end

function Bullet:draw()
    local drawShape = function()
        -- Diamond/Rectangle shape
        love.graphics.polygon("fill", 0, -5, -2, 0, 0, 5, 2, 0)
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    
    -- 3-pass glow effect
    -- Outer glow
    love.graphics.push()
    love.graphics.scale(1.3, 1.3)
    Colors.setColor("accent", 0.1)
    drawShape()
    love.graphics.pop()
    
    -- Mid glow
    love.graphics.push()
    love.graphics.scale(1.15, 1.15)
    Colors.setColor("accent", 0.2)
    drawShape()
    love.graphics.pop()
    
    -- Main bullet
    Colors.setColor("accent", 0.9)
    drawShape()
    
    love.graphics.pop()
end

return Bullet
