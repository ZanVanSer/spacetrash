local Colors = require('ui/colors')
local Screen = require('systems/screen')

local EnemyBullet = {}
EnemyBullet.__index = EnemyBullet

function EnemyBullet.new(x, y, patternData)
    local self = setmetatable({}, EnemyBullet)
    self.x = x
    self.y = y
    self.patternData = patternData -- contains speed, angle, pattern, damage
    self.vx = patternData.vx
    self.vy = patternData.vy
    self.isDead = false
    self.radius = patternData.radius or 6
    return self
end

function EnemyBullet:update(dt)
    -- Load attack pattern from patterns/attack_[patternData.pattern].lua
    local pattern = require("patterns/attack_" .. self.patternData.pattern)
    pattern.update(self, dt)
    
    -- If bullet goes off-screen: isDead = true
    local margin = 50
    if self.x < -margin or self.x > Screen.getVirtualWidth() + margin or
       self.y < -margin or self.y > Screen.getVirtualHeight() + margin then
        self.isDead = true
    end
end

function EnemyBullet:draw()
    local drawShape = function()
        -- Diamond/Circle hybrid
        love.graphics.circle("fill", 0, 0, self.radius)
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    
    -- Apply 3-pass glow (outer, mid, main) using colors.lua utility
    Colors.drawGlow("danger", drawShape, 1.4, 1.15)
    
    love.graphics.pop()
end

return EnemyBullet
