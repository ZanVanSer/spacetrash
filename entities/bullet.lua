local Colors = require('ui/colors')
local Screen = require('systems.screen')

local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(x, y, weaponData)
    local self = setmetatable({}, Bullet)
    self.x, self.y = x, y
    self.weaponData = weaponData
    self.isDead = false
    self.lifeTimer = weaponData.duration or nil
    return self
end

function Bullet:update(dt)
    local pattern = require("patterns/player_" .. self.weaponData.pattern)
    pattern.update(self, dt)
    
    if self.lifeTimer then
        self.lifeTimer = self.lifeTimer - dt
        if self.lifeTimer <= 0 then self.isDead = true end
    end
    
    -- Bounds check: Don't kill orbital drones for being off-screen
    if self.weaponData.pattern ~= "orbital" then
        local margin = 100
        if self.y < -margin or self.y > Screen.getVirtualHeight() + margin or
           self.x < -margin or self.x > Screen.getVirtualWidth() + margin then
            self.isDead = true
        end
    end
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
