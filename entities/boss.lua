local Screen = require('systems.screen')
local EnemyBullet = require('entities.enemy_bullet')
local Particles = require('systems.particles')
local Boss = {}
Boss.__index = Boss

function Boss.new(x, y, bossData)
    local self = setmetatable({}, Boss)
    self.bossData = bossData or {
        id = "unknown",
        name = "Unknown Entity",
        maxHealth = 500,
        radius = 40,
        baseSpeed = 80,
        bulletSpeed = 200,
        bulletDamage = 10
    }
    self.x = x or Screen.getVirtualWidth() / 2
    self.y = y or 100
    
    -- Stats from bossData
    self.maxHealth = self.bossData.maxHealth or 500
    self.health = self.maxHealth
    self.radius = self.bossData.radius or 40
    
    -- Validation: Phases
    if not self.bossData.phases or #self.bossData.phases == 0 then
        print("ERROR: Boss '" .. (self.bossData.id or "unknown") .. "' has no phases! Falling back to default phase.")
        self.bossData.phases = {
            {
                healthPercent = 1.0,
                behavior = "side_to_side",
                movementSpeed = 80,
                patterns = {"spread"},
                shootInterval = 2.0,
                patternDuration = 5.0
            }
        }
    end

    -- Validation: Behaviors and Patterns in each phase
    for i, phase in ipairs(self.bossData.phases) do
        -- Behavior existence check
        local behaviorName = phase.behavior or "side_to_side"
        local behaviorPath = "behaviors/" .. behaviorName .. ".lua"
        if not love.filesystem.getInfo(behaviorPath) then
            print("WARNING: Behavior '" .. behaviorName .. "' not found for boss '" .. self.bossData.id .. "' phase " .. i .. ". Defaulting to side_to_side.")
            phase.behavior = "side_to_side"
        end

        -- Patterns existence check
        if not phase.patterns or #phase.patterns == 0 then
            phase.patterns = {"spread"}
        else
            for j, patternName in ipairs(phase.patterns) do
                local fullPatternName = patternName
                if not patternName:find("^attack_") then
                    fullPatternName = "attack_" .. patternName
                end
                local patternPath = "patterns/" .. fullPatternName .. ".lua"
                if not love.filesystem.getInfo(patternPath) then
                    print("WARNING: Pattern '" .. patternName .. "' not found for boss '" .. self.bossData.id .. "' phase " .. i .. ". Defaulting to spread.")
                    phase.patterns[j] = "spread"
                end
            end
        end
    end

    -- Phase system initialization
    self.phases = self.bossData.phases
    self.currentPhaseIndex = 1
    self.currentPhaseData = self.phases[1]
    
    self.patternIndex = 1
    self.patternTimer = 0
    self.shootTimer = 0
    
    self.direction = 1
    self.isDead = false
    self.bullets = {}
    
    return self
end

function Boss:getCurrentPhase()
    if not self.phases or #self.phases == 0 then return nil, 1 end
    
    local hpPercent = self.health / self.maxHealth
    
    -- Loop through phases array (sorted by healthPercent descending)
    for i, phase in ipairs(self.phases) do
        if hpPercent >= phase.healthPercent then
            return phase, i
        end
    end
    
    return self.phases[#self.phases], #self.phases
end

function Boss:onPhaseChange(oldPhaseIndex, newPhaseIndex)
    self.patternIndex = 1
    self.patternTimer = 0
    self.shootTimer = -1.0 -- Stop shooting briefly (1 second pause)
    return true
end

function Boss:update(dt, playerX, playerY)
    if self.isDead then return end

    -- Phase Management
    local newPhase, newIndex = self:getCurrentPhase()
    if newPhase and newIndex ~= self.currentPhaseIndex then
        self:onPhaseChange(self.currentPhaseIndex, newIndex)
        self.currentPhaseIndex = newIndex
        self.currentPhaseData = newPhase
        
        -- Optional: visual effect for phase change
        Particles.bossHit(self.x, self.y)
    end

    -- Use currentPhaseData for behavior and stats
    local phase = self.currentPhaseData
    
    -- Movement Behavior
    local speed = phase.movementSpeed or self.bossData.baseSpeed or 80
    local behaviorName = phase.behavior or self.bossData.behavior
    if behaviorName then
        local behavior = require("behaviors/" .. behaviorName)
        if behavior and behavior.update then
            -- Store speed on self for behaviors that read boss.speed directly
            self.speed = speed
            behavior.update(self, dt, speed)
        end
    end

    -- Boundary enforcement
    local hudW = 220
    if self.x < hudW + self.radius then
        self.x = hudW + self.radius
        self.direction = 1
    elseif self.x > Screen.getVirtualWidth() - self.radius then
        self.x = Screen.getVirtualWidth() - self.radius
        self.direction = -1
    end

    -- Pattern rotation logic
    if phase.patterns and #phase.patterns > 1 then
        self.patternTimer = self.patternTimer + dt
        local patternDuration = phase.patternDuration or 5.0
        if self.patternTimer >= patternDuration then
            self.patternIndex = (self.patternIndex % #phase.patterns) + 1
            self.patternTimer = 0
            -- Brief visual effect for pattern change
            Particles.bossHit(self.x, self.y)
        end
    end

    -- Shooting logic (using shootTimer logic)
    self.shootTimer = self.shootTimer + dt
    local shootInterval = phase.shootInterval or 2.0
    
    if self.shootTimer >= shootInterval then
        local patterns = phase.patterns or {}
        local currentPattern = patterns[self.patternIndex] or "spread"
        
        -- Add attack_ prefix if missing for file require
        local fileName = currentPattern
        if not fileName:find("^attack_") then
            fileName = "attack_" .. fileName
        end
        
        local pattern = require("patterns/" .. fileName)
        
        local bulletData = {
            pattern = currentPattern,
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

    -- Visual feedback based on current phase
    local r, g, b = 1, 0, 0
    if self.currentPhaseIndex >= 4 then
        r, g, b = 1, 0.2, 0.2
    elseif self.currentPhaseIndex == 3 then
        r, g, b = 1, 0.5, 0
    elseif self.currentPhaseIndex == 2 then
        r, g, b = 1, 0.8, 0
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
