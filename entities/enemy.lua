local Screen = require('systems.screen')
local EnemyVisuals = require('entities.enemy_visuals')
local EnemyBullet = require('entities.enemy_bullet')
local Particles = require('systems.particles')
local Colors = require('ui/colors')
local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y, enemyData, scaler)
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
    self.scaler = scaler
    
    -- Shield System
    self.hasShield = enemyData.hasShield or false
    self.shieldHealth = enemyData.shieldHealth or 0
    self.maxShieldHealth = enemyData.shieldHealth or 0
    self.shieldFlash = 0

    -- Burning State
    self.burnStacks = {}
    self.isBurning = false

    -- Pull State
    self.pullX = 0
    self.pullY = 0
    self.totalPull = 0

    -- Shooting Capability
    self.shootTimer = 0
    self.shootInterval = enemyData.shootInterval or 3
    self.shootPattern = enemyData.shootPattern
    self.bullets = {}
    
    return self
end

function Enemy:applyBurn(damage, duration)
    table.insert(self.burnStacks, {
        damage = damage,
        duration = duration,
        timer = 0
    })
end

function Enemy:update(dt, playerX, playerY)
    local behavior = require("behaviors/" .. self.behavior)
    behavior.update(self, dt)

    -- Update shield flash
    if self.shieldFlash and self.shieldFlash > 0 then
        self.shieldFlash = self.shieldFlash - dt
    end

    -- Apply Pull Force
    if self.pullX ~= 0 or self.pullY ~= 0 then
        self.x = self.x + self.pullX * dt
        self.y = self.y + self.pullY * dt
        
        -- Store magnitude for visual distortion then reset
        self.totalPull = math.sqrt(self.pullX^2 + self.pullY^2)
        self.pullX = 0
        self.pullY = 0
    else
        self.totalPull = 0
    end

    -- Burn processing
    self.isBurning = #self.burnStacks > 0
    if self.isBurning then
        for i = #self.burnStacks, 1, -1 do
            local stack = self.burnStacks[i]
            stack.duration = stack.duration - dt
            
            -- continuous burn damage
            self:takeDamage(stack.damage * dt)
            
            if stack.duration <= 0 then
                table.remove(self.burnStacks, i)
            end
        end
    end

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
            
            -- Apply damage scaling
            local baseDamage = self.enemyData.bulletDamage or 10
            local scaledDamage = baseDamage
            if self.scaler and self.scaler.getDamageMultiplier then
                scaledDamage = baseDamage * self.scaler.getDamageMultiplier()
            end
            
            local bulletData = {
                pattern = self.shootPattern,
                speed = speed,
                damage = scaledDamage
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

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    
    -- Visual Bending towards gravity source
    if self.totalPull > 0 then
        local stretch = math.min(0.3, self.totalPull / 1000)
        love.graphics.scale(1 + stretch, 1 - stretch)
        -- Rotation handled by visuals usually, but we can add a slight skew here
    end
    
    EnemyVisuals.drawEnemy(self.enemyData.id, 0, 0, 1.0, 0, self.shieldHealth, self.shootTimer, self.shootInterval, self.isElite)
    
    -- Shield Flash
    if self.shieldFlash and self.shieldFlash > 0 then
        Colors.setColor("accent", self.shieldFlash * 0.5)
        love.graphics.circle("fill", 0, 0, self.radius + 5)
    end
    
    love.graphics.pop()
    
    -- Burn Visuals
    if self.isBurning then
        local flash = math.abs(math.sin(love.timer.getTime() * 10)) * 0.3
        love.graphics.setColor(1, 0.5, 0, flash)
        love.graphics.circle("fill", self.x, self.y, self.radius * 1.2)
        
        if math.random() > 0.8 then
            Particles.spawn(self.x, self.y, 2, "danger", 50, 1)
        end
    end

    -- Bars
    local barWidth = self.radius * 2
    local barHeight = 4
    local bx = self.x - self.radius
    local by = self.y - self.radius - 10
    
    -- Shield Bar
    if self.hasShield and self.shieldHealth > 0 then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", bx, by - 6, barWidth, barHeight)
        
        local shieldPercent = math.max(0, self.shieldHealth / self.maxShieldHealth)
        Colors.setColor("accent", 1)
        love.graphics.rectangle("fill", bx, by - 6, barWidth * shieldPercent, barHeight)
    end

    -- HP Bar if damaged
    if self.hp < self.maxHp then
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

function Enemy:getContactDamage()
    return self.enemyData.bulletDamage or 5
end

function Enemy:takeDamage(amount)
    if self.hasShield and self.shieldHealth > 0 then
        self.shieldHealth = self.shieldHealth - amount
        self.shieldFlash = 0.2 -- Trigger flash
        if self.shieldHealth < 0 then
            local excess = math.abs(self.shieldHealth)
            self.shieldHealth = 0
            self.hp = self.hp - excess
        end
    else
        self.hp = self.hp - amount
    end
    
    if self.hp <= 0 then self.isDead = true end
end

return Enemy
