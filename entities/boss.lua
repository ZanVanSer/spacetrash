local Screen = require('systems.screen')
local EnemyBullet = require('entities.enemy_bullet')
local Particles = require('systems.particles')
local BossVisuals = require('entities.boss_visuals')
local Colors = require('ui/colors')
local SpecialAttacks = require('systems/special_attacks')
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
    self.flashTimer = 0
    self.rotation = 0
    self.isTransitioning = false
    self.transitionTimer = 0
    self.pulseTimer = 0
    self.aimAngle = math.pi / 2
    self.chargeLevel = 0
    self.isCharging = false
    self.chargeTimer = 0
    self.chargeDuration = 0.3
    self.pendingShot = nil
    self.shootDelay = 0
    self.specialAttackUsed = {}
    self.specialAttackTimer = 0
    self.specialCooldownTimer = 0
    self.activeSpecial = nil
    self.isExecutingSpecial = false
    self.isSpecialAttacking = false
    self.prevHpPercent = 1.0
    
    self.invulnerableTimer = 0
    self.phaseText = ""
    self.phaseTextTimer = 0
    
    return self
end

local function normalizePatternName(patternName)
    local name = patternName or ""
    return name:gsub("^attack_", "")
end

local function isAimedPattern(patternName)
    return normalizePatternName(patternName) == "aimed"
end

local function isBurstPattern(patternName)
    return normalizePatternName(patternName) == "burst"
end

local function firePattern(self, currentPattern, playerX, playerY, targetX, targetY, originX, originY)
    local normalizedPattern = normalizePatternName(currentPattern)
    local fileName = currentPattern
    if not fileName:find("^attack_") then
        fileName = "attack_" .. fileName
    end

    local pattern = require("patterns/" .. fileName)
    local bulletData = {
        pattern = normalizedPattern,
        speed = self.bossData.bulletSpeed or 200,
        damage = self.bossData.bulletDamage or 10
    }

    -- Burst telegraph shots should originate from the boss but travel toward the telegraphed point.
    if normalizedPattern == "burst" and targetX and targetY then
        local ox = originX or self.x
        local oy = originY or self.y
        local count = bulletData.count or 3
        local speed = bulletData.speed * 1.3
        local angle = math.atan2(targetY - oy, targetX - ox)
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed

        for i = 1, count do
            local bData = {}
            for k, v in pairs(bulletData) do bData[k] = v end
            bData.x = ox
            bData.y = oy
            bData.vx = vx
            bData.vy = vy
            bData.delay = (i - 1) * 0.1
            bData.isDead = false
            bData.radius = 6
            table.insert(self.bullets, EnemyBullet.new(bData.x, bData.y, bData))
        end
        return
    end

    if pattern.createBullets then
        local ox = originX or self.x
        local oy = originY or self.y
        local px = targetX or playerX or self.x
        local py = targetY or playerY or (self.y + 100)
        local newBulletsData = pattern.createBullets(ox, oy, bulletData, px, py)
        for _, bData in ipairs(newBulletsData) do
            table.insert(self.bullets, EnemyBullet.new(bData.x, bData.y, bData))
        end
    else
        local ox = originX or self.x
        local oy = originY or self.y
        table.insert(self.bullets, EnemyBullet.new(ox, oy, bulletData))
    end
end

function Boss:executeSpecialAttack(specialData, telegraph, playerX, playerY, usedKey)
    if not specialData then return end

    local specialType = specialData.type or "screen_clear"
    local state = SpecialAttacks.execute(specialType, specialData, self, telegraph)
    
    if state then
        state.usedKey = usedKey
        self.activeSpecial = state
        self.isExecutingSpecial = true
        self.isCharging = false
        self.chargeTimer = 0
        self.chargeLevel = 0
        self.pendingShot = nil
        self.shootDelay = 0
        self.shootTimer = 0
        self.isSpecialAttacking = true
    end
end

function Boss:checkSpecialAttack(dt, telegraph, playerX, playerY)
    local phase = self.currentPhaseData
    if not phase or not phase.specialAttack or self.isExecutingSpecial then return false end

    local specialData = phase.specialAttack
    local trigger = specialData.trigger
    local hpPercent = self.health / self.maxHealth

    if trigger == "once" then
        local threshold = specialData.healthPercent or 0
        local key = tostring(self.currentPhaseIndex) .. ":" .. (specialData.type or "special")
        if self.prevHpPercent > threshold and hpPercent <= threshold and not self.specialAttackUsed[key] then
            self:executeSpecialAttack(specialData, telegraph, playerX, playerY, key)
            return true
        end
    elseif trigger == "repeat" then
        local interval = specialData.interval or 10.0
        if self.specialCooldownTimer <= 0 then
            self:executeSpecialAttack(specialData, telegraph, playerX, playerY, nil)
            self.specialCooldownTimer = interval
            return true
        end
    end

    return false
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
    self.pendingShot = nil
    self.shootDelay = 0
    self.isCharging = false
    self.chargeTimer = 0
    self.chargeLevel = 0
    self.specialAttackTimer = 0
    self.specialCooldownTimer = 0
    self.activeSpecial = nil
    self.isExecutingSpecial = false
    self.isSpecialAttacking = false
    self.isTransitioning = true
    self.transitionTimer = 1.0
    return true
end

function Boss:update(dt, playerX, playerY, telegraph)
    if self.isDead then return end

    self.pulseTimer = self.pulseTimer + dt
    if self.specialCooldownTimer > 0 then
        self.specialCooldownTimer = math.max(0, self.specialCooldownTimer - dt)
    end

    if playerX and playerY then
        self.aimAngle = math.atan2(playerY - self.y, playerX - self.x)
    end
    
    if self.flashTimer > 0 then
        self.flashTimer = math.max(0, self.flashTimer - dt)
    end
    
    if self.isTransitioning then
        self.rotation = self.rotation + 3 * dt
        self.transitionTimer = self.transitionTimer - dt
        if self.transitionTimer <= 0 then
            self.isTransitioning = false
            self.transitionTimer = 0
            self.rotation = 0
        end
    end

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
    if behaviorName and not (self.activeSpecial and self.activeSpecial.lockMovement) then
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

    self:checkSpecialAttack(dt, telegraph, playerX, playerY)

    if self.activeSpecial then
        local complete = self.activeSpecial.update(dt, self, playerX, playerY)
        if complete then
            if self.activeSpecial.usedKey then
                self.specialAttackUsed[self.activeSpecial.usedKey] = true
            end
            self.activeSpecial = nil
            self.isExecutingSpecial = false
            self.isSpecialAttacking = false
            self.shootTimer = -0.5
        end
    end

    -- Resolve delayed aimed shot after telegraph phase.
    if self.pendingShot and not self.isExecutingSpecial then
        self.shootDelay = self.shootDelay - dt
        if self.shootDelay <= 0 then
            firePattern(
                self,
                self.pendingShot.pattern,
                playerX,
                playerY,
                self.pendingShot.targetX,
                self.pendingShot.targetY,
                self.pendingShot.originX,
                self.pendingShot.originY
            )
            self.pendingShot = nil
            self.shootDelay = 0
            self.shootTimer = 0
        end
    end

    -- Shooting logic with pre-fire charge-up.
    if not self.isCharging and not self.pendingShot and not self.isExecutingSpecial then
        self.shootTimer = self.shootTimer + dt
    end

    local shootInterval = phase.shootInterval or 2.0

    if not self.isCharging and not self.pendingShot and not self.isExecutingSpecial and self.shootTimer >= shootInterval then
        self.isCharging = true
        self.chargeTimer = 0
        self.chargeLevel = 0
    end

    if self.isCharging then
        self.chargeTimer = self.chargeTimer + dt
        self.chargeLevel = math.min(1, self.chargeTimer / self.chargeDuration)

        if self.chargeLevel >= 1.0 then
            local patterns = phase.patterns or {}
            local currentPattern = patterns[self.patternIndex] or "spread"

            self.isCharging = false
            self.chargeTimer = 0
            self.chargeLevel = 0

            if isAimedPattern(currentPattern) then
                local px = playerX or self.x
                local py = playerY or (self.y + 100)
                if telegraph and telegraph.createLineTelegraph then
                    telegraph:createLineTelegraph(self.x, self.y, px, py, 0.5, Colors.COLORS.danger)
                end
                self.pendingShot = {
                    pattern = currentPattern,
                    targetX = px,
                    targetY = py
                }
                self.shootDelay = 0.5
            elseif isBurstPattern(currentPattern) then
                local px = playerX or self.x
                local py = playerY or (self.y + 100)
                if telegraph and telegraph.createAreaTelegraph then
                    telegraph:createAreaTelegraph(px, py, 30, 0.8, Colors.COLORS.danger)
                end
                self.pendingShot = {
                    pattern = currentPattern,
                    targetX = px,
                    targetY = py
                }
                self.shootDelay = 0.8
            else
                firePattern(self, currentPattern, playerX, playerY)
                self.shootTimer = 0
            end
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

    self.prevHpPercent = self.health / self.maxHealth
    self.isSpecialAttacking = self.isExecutingSpecial and self.activeSpecial ~= nil
end

function Boss:getContactDamage()
    return self.bossData.bulletDamage or 10
end

function Boss:takeDamage(amount)
    self.health = self.health - amount
    self.flashTimer = 0.1
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

    local pulseSpeed = self.isSpecialAttacking and 5 or 2
    local pulseAmp = self.isSpecialAttacking and 0.1 or 0.05
    local scale = 1.0 + math.sin(self.pulseTimer * pulseSpeed) * pulseAmp
    BossVisuals.drawBoss(
        self.bossData.id,
        self.x,
        self.y,
        scale,
        self.rotation,
        self.flashTimer,
        self.aimAngle,
        self.chargeLevel,
        self.health / self.maxHealth,
        self.isSpecialAttacking
    )

    -- Draw Bullets
    for _, b in ipairs(self.bullets) do
        b:draw()
    end
end

return Boss
