local Screen = require('systems.screen')
local EnemyVisuals = require('entities.enemy_visuals')
local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y, enemyData)
    local self = setmetatable({}, Enemy)
    self.x, self.y = x, y
    self.enemyData = enemyData
    self.hp = enemyData.hp
    self.maxHp = enemyData.hp
    self.speed = enemyData.speed
    self.behavior = enemyData.behavior
    self.xpValue = enemyData.xp
    self.isDead = false
    self.radius = enemyData.radius or 15
    return self
end

function Enemy:update(dt)
    local behavior = require("behaviors/" .. self.behavior)
    behavior.update(self, dt)
    -- Simple off-screen check (leaving the screen from the bottom or sides)
    if self.y > Screen.getVirtualHeight() + 50 or 
       self.x < -50 or self.x > Screen.getVirtualWidth() + 50 then
        self.isDead = true
    end
end

function Enemy:draw()
    EnemyVisuals.drawEnemy(self.enemyData.id, self.x, self.y, 1.0, 0)
    
    -- HP Bar if damaged
    if self.hp < self.maxHp then
        local barWidth = self.radius * 2
        local barHeight = 4
        local bx = self.x - self.radius
        local by = self.y - self.radius - 10
        
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", bx, by, barWidth, barHeight)
        
        local hpPercent = math.max(0, self.hp / self.maxHp)
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", bx, by, barWidth * hpPercent, barHeight)
    end
end

function Enemy:takeDamage(amount)
    self.hp = self.hp - amount
    if self.hp <= 0 then self.isDead = true end
end

return Enemy
