local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y, enemyData)
    local self = setmetatable({}, Enemy)
    self.x, self.y = x, y
    self.enemyData = enemyData
    self.hp = enemyData.hp
    self.speed = enemyData.speed
    self.behavior = enemyData.behavior
    self.xpValue = enemyData.xp
    self.isDead = false
    self.radius = 15
    return self
end

function Enemy:update(dt)
    local behavior = require("behaviors/" .. self.behavior)
    behavior.update(self, dt)
    -- Simple off-screen check (leaving the screen from the bottom or sides)
    if self.y > love.graphics.getHeight() + 50 or 
       self.x < -50 or self.x > love.graphics.getWidth() + 50 then
        self.isDead = true
    end
end

function Enemy:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

function Enemy:takeDamage(amount)
    self.hp = self.hp - amount
    if self.hp <= 0 then self.isDead = true end
end

return Enemy
