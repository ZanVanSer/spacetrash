local Screen = require('systems.screen')
local EnemyVisuals = require('entities.enemy_visuals')
local EnemyBullet = require('entities.enemy_bullet')
local Particles = require('systems.particles')
local Colors = require('ui/colors')
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
    
    -- Shooting Capability
    self.shootTimer = 0
    self.shootInterval = enemyData.shootInterval or 3
    self.shootPattern = enemyData.shootPattern
    self.bullets = {}
    
    return self
end

function Enemy:update(dt, playerX, playerY)
    local behavior = require("behaviors/" .. self.behavior)
    behavior.update(self, dt)

    -- Store last player position for drawing telegraph
    self.lastPlayerX = playerX
    self.lastPlayerY = playerY

    -- Shooting logic
    if self.shootPattern then
        self.shootTimer = self.shootTimer + dt
        if self.shootTimer >= self.shootInterval then
            local pattern = require("patterns/attack_" .. self.shootPattern)
            
            -- Add slight random variation: speed = bulletSpeed * (0.9 + math.random() * 0.2)
            local baseSpeed = self.enemyData.bulletSpeed or 200
            local speed = baseSpeed * (0.9 + math.random() * 0.2)
            
            local bulletData = {
                pattern = self.shootPattern,
                speed = speed,
                damage = self.enemyData.bulletDamage or 10
            }

            if pattern.createBullets then
                -- Use passed player position or fallback
                local px, py = playerX or self.x, playerY or (self.y + 100)
                
                local newBulletsData = pattern.createBullets(self.x, self.y, bulletData, px, py)
                for _, bData in ipairs(newBulletsData) do
                    table.insert(self.bullets, EnemyBullet.new(bData.x, bData.y, bData))
                end
            else
                table.insert(self.bullets, EnemyBullet.new(self.x, self.y, bulletData))
            end
            
            -- Muzzle flash effect: Brief flash at enemy position when bullet spawns
            Particles.spawn(self.x, self.y, 6, "danger", 120, 2)
            
            self.shootTimer = 0
        end
    end

    -- Update bullets
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b:update(dt)
        if b.isDead then
            table.remove(self.bullets, i)
        end
    end

    -- Simple off-screen check (leaving the screen from the bottom or sides)
    if self.y > Screen.getVirtualHeight() + 50 or 
       self.x < -50 or self.x > Screen.getVirtualWidth() + 50 then
        self.isDead = true
    end
end

function Enemy:draw()
    -- Visual Warning (Telegraph)
    if self.shootPattern == "aimed" and self.lastPlayerX then
        local timeRemaining = self.shootInterval - self.shootTimer
        if timeRemaining <= 0.5 and timeRemaining > 0 then
            local alpha = (0.5 - timeRemaining) / 0.5
            local pulse = math.abs(math.sin(love.timer.getTime() * 20)) * 0.5 + 0.2
            Colors.setColor("danger", pulse * alpha)
            love.graphics.setLineWidth(1)
            love.graphics.line(self.x, self.y, self.lastPlayerX, self.lastPlayerY)
            love.graphics.setLineWidth(1)
        end
    end

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

    -- Draw all bullets
    for _, b in ipairs(self.bullets) do
        b:draw()
    end
end

function Enemy:getBullets()
    return self.bullets
end

function Enemy:takeDamage(amount)
    self.hp = self.hp - amount
    if self.hp <= 0 then self.isDead = true end
end

return Enemy
