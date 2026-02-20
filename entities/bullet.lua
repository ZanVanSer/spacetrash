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
    local pattern = require("patterns/" .. self.weaponData.pattern)
    pattern.update(self, dt)
    if self.y < -50 then self.isDead = true end
end

function Bullet:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", self.x, self.y, 4, 10)
end

return Bullet
