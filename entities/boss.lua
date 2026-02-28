local Screen = require('systems.screen')
local EnemyBullet = require('entities.enemy_bullet')
local Boss = {}
Boss.__index = Boss

function Boss.new(x, y, bossData)
    local self = setmetatable({}, Boss)
    self.bossData = bossData
    self.x = x or Screen.getVirtualWidth() / 2
    self.y = y or 100
    
    -- Stats from bossData
    self.maxHealth = bossData.maxHealth or 500
    self.health = self.maxHealth
    self.radius = bossData.radius or 40
    
    -- Phase system initialization
    self.phases = bossData.phases or {}
    self.currentPhaseIndex = 1
    self.currentPhaseData = self.phases[1] or {}
    
    self.patternIndex = 1
    self.patternTimer = 0
    self.shootTimer = 0
    
    self.direction = 1
    self.isDead = false
    self.bullets = {}
    
    return self
end

function Boss:getCurrentPhase()
    if not self.phases or #self.phases == 0 then return nil end
    
    local hpPercent = self.health / self.maxHealth
    
    -- Find first phase where hpPercent >= phase.healthPercent
    for i, phase in ipairs(self.phases) do
        if hpPercent >= phase.healthPercent then
            return phase, i
        end
    end
    
    -- Fallback to last phase if none match (shouldn't happen with 0.25 as lowest)
    return self.phases[#self.phases], #self.phases
end

function Boss:update(dt, playerX, playerY)
    if self.isDead then return end

    -- Phase Management
    local newPhase, newIndex = self:getCurrentPhase()
    if newPhase and newIndex ~= self.currentPhaseIndex then
        self.currentPhaseData = newPhase
        self.currentPhaseIndex = newIndex
        self.patternIndex = 1
        self.patternTimer = 0
        self.shootTimer = 0
        -- Optional: Trigger visual effect or sound for phase change
    end

    local phase = self.currentPhaseData or self.bossData
    
    -- Movement Behavior
    self.speed = phase.movementSpeed or self.bossData.baseSpeed or 80
    local behaviorName = phase.behavior or self.bossData.behavior
    if behaviorName then
        local behavior = require("behaviors/" .. behaviorName)
        if behavior and behavior.update then
            behavior.update(self, dt)
        end
    end

    -- Boundary enforcement (Data-driven padding if needed, else standard)
    local hudW = 220
    if self.x < hudW + self.radius then
        self.x = hudW + self.radius
        self.direction = 1
    elseif self.x > Screen.getVirtualWidth() - self.radius then
        self.x = Screen.getVirtualWidth() - self.radius
        self.direction = -1
    end

    -- Shooting Logic
    self.shootTimer = self.shootTimer + dt
    local shootInterval = phase.shootInterval or self.bossData.shootInterval or 2.0
    
    if self.shootTimer >= shootInterval then
        local patterns = phase.patterns or {phase.shootPattern or "spread"}
        local patternName = patterns[self.patternIndex]
        
        -- Ensure pattern name has "attack_" prefix for require
        local fullPatternName = patternName
        if not patternName:find("^attack_") then
            fullPatternName = "attack_" .. patternName
        end
        
        local pattern = require("patterns/" .. fullPatternName)
        
        local bulletData = {
            pattern = patternName,
            speed = self.bossData.bulletSpeed or 200,
            damage = self.bossData.bulletDamage or 10
        }

        if pattern.createBullets then
            local px, py = playerX or self.x, playerY or (self.y + 100)
            local newBulletsData = pattern.createBullets(self.x, self.y, bulletData, px, py)
            for _, bData in ipairs(newBulletsData) do
                table.insert(self.bullets, EnemyBullet.new(bData.x, bData.y, bData))
            end
        else
            table.insert(self.bullets, EnemyBullet.new(self.x, self.y, bulletData))
        end
        
        self.shootTimer = 0
    end
    
    -- Pattern Rotation within Phase
    if phase.patterns and #phase.patterns > 1 then
        self.patternTimer = self.patternTimer + dt
        local patternDuration = phase.patternDuration or 5.0
        if self.patternTimer >= patternDuration then
            self.patternIndex = (self.patternIndex % #phase.patterns) + 1
            self.patternTimer = 0
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
end

function Boss:getContactDamage()
    return self.bossData.bulletDamage or 10
end

function Boss:takeDamage(amount)
    self.health = self.health - amount
    if self.health <= 0 then
        self.health = 0
        self.isDead = true
    end
end

function Boss:getBullets()
    return self.bullets
end

function Boss:draw()
    if self.isDead then return end

    -- Draw Boss: Visuals could vary by phase index
    local r, g, b = 1, 0, 0
    if self.currentPhaseIndex == 4 then
        r, g, b = 1, 0.2, 0.2 -- More intense
    elseif self.currentPhaseIndex == 3 then
        r, g, b = 1, 0.5, 0   -- Orange
    end
    
    love.graphics.setColor(r, g, b)
    love.graphics.polygon("fill", 
        self.x - self.radius, self.y - self.radius,
        self.x + self.radius, self.y - self.radius,
        self.x, self.y + self.radius
    )

    -- Draw Bullets
    for _, b in ipairs(self.bullets) do
        b:draw()
    end
end

return Boss
