local WS = require "systems/weapon_system"
local ShipVisuals = require "entities/ship_visuals"
local Screen = require('systems.screen')
local dl = require "systems/dataloader"
local Fonts = require "ui/fonts"
local ScreenShake = require "systems/screenshake"
local Particles = require "systems/particles"

local Player = {}
Player.__index = Player

function Player.new(shipData)
    local self = setmetatable({}, Player)
    self.x = (Screen.getVirtualWidth() + 220) / 2
    self.y = Screen.getVirtualHeight() / 2
    
    -- Store Ship ID for drawing
    self.shipId = shipData.id
    
    -- Base Stats (Backup for recalculation)
    self.baseStats = {
        maxHealth = shipData.maxHealth or 100,
        recovery = shipData.recovery or 0,
        armor = shipData.armor or 0,
        speed = shipData.speed or 200,
        might = shipData.might or 1.0,
        duration = shipData.duration or 1.0,
        cooldown = shipData.cooldown or 1.0,
        area = shipData.area or 1.0,
        amount = shipData.amount or 0,
        pierce = shipData.pierce or 0,
        critMult = shipData.critMult or 2.0
    }
    
    -- Passive Modifiers (1.0 for multipliers, 0 for additions)
    self.passiveModifiers = {
        might = 1.0,
        speed = 1.0,
        area = 1.0,
        cooldown = 1.0,
        duration = 1.0,
        critMult = 1.0,
        maxHealth = 0,
        recovery = 0,
        armor = 0,
        amount = 0,
        pierce = 0
    }
    
    self.passives = {} -- { [id] = level }
    
    -- Current Active Stats
    self.maxHp = self.baseStats.maxHealth
    self.hp = self.maxHp
    self.recovery = self.baseStats.recovery
    self.armor = self.baseStats.armor
    self.speed = self.baseStats.speed
    self.might = self.baseStats.might
    self.duration = self.baseStats.duration
    self.cooldown = self.baseStats.cooldown
    self.area = self.baseStats.area
    self.amount = self.baseStats.amount
    self.pierce = self.baseStats.pierce
    self.critMult = self.baseStats.critMult
    
    self.radius = 15
    self.ws = WS.new()
    self.ws:equipWeapon(shipData.startWeapon)
    
    self.weaponLevels = { [shipData.startWeapon] = 1 }
    self.passives = {} -- { [id] = level }

    -- Handle Starting Passive
    if shipData.startingPassive then
        self:addPassive(shipData.startingPassive)
    end
    
    self.xp = 0
    self.level = 1
    self.xpToNext = 10

    -- Evolution State
    self.pendingEvolution = nil
    self.evolutionAvailable = false
    self.evoEffectTimer = 0
    self.isEvolving = false

    -- Damage Feedback & Invulnerability
    self.invulnTimer = 0
    self.damageFlashTimer = 0

    return self
end

function Player:addPassive(id)
    self.passives[id] = math.min(5, (self.passives[id] or 0) + 1)
    self:recalculateStats()
end

function Player:upgradeWeapon(id)
    if self.weaponLevels[id] then
        self.weaponLevels[id] = math.min(5, self.weaponLevels[id] + 1)
        
        -- Check for evolution trigger when reaching max level (5)
        if self.weaponLevels[id] == 5 then
            local pList = {}
            for pId, _ in pairs(self.passives) do table.insert(pList, pId) end
            
            local evolvedId = self.ws:checkEvolution(id, pList, 5)
            if evolvedId then
                self.pendingEvolution = { baseId = id, evolvedId = evolvedId }
                self.evolutionAvailable = true
            end
        end
    else
        -- Equip new weapon
        self.ws:equipWeapon(id)
        self.weaponLevels[id] = 1
    end
end

function Player:evolveWeapon(baseId)
    if not self.pendingEvolution or self.pendingEvolution.baseId ~= baseId then return end
    
    local evolvedId = self.pendingEvolution.evolvedId
    
    -- Replace in Weapon System
    for i, id in ipairs(self.ws.equippedWeapons) do
        if id == baseId then
            self.ws.equippedWeapons[i] = evolvedId
            -- Transfer timer for smooth transition
            self.ws.shootTimers[evolvedId] = self.ws.shootTimers[baseId] or 0
            self.ws.shootTimers[baseId] = nil
            break
        end
    end
    
    -- Update level tracking
    self.weaponLevels[baseId] = nil
    self.weaponLevels[evolvedId] = 1 -- Evolved weapon starts at level 1
    
    -- Reset evolution trigger
    self.pendingEvolution = nil
    self.evolutionAvailable = false
    
    -- Trigger dramatic effects
    self.evoEffectTimer = 1.5
    self.isEvolving = true
    ScreenShake.trigger(10, 1.0)
    Particles.spawn(self.x, self.y, 40, "accent", 300, 4)
    
    -- Add expanding ring for emphasis
    table.insert(Particles.rings, {
        x = self.x,
        y = self.y,
        radius = 0,
        maxRadius = 150,
        life = 0.8,
        maxLife = 0.8,
        colorKey = "accent"
    })
end

function Player:upgradePassive(id)
    self:addPassive(id)
end

function Player:recalculateStats()
    -- Reset modifiers to default
    self.passiveModifiers.might = 1.0
    self.passiveModifiers.speed = 1.0
    self.passiveModifiers.area = 1.0
    self.passiveModifiers.cooldown = 1.0
    self.passiveModifiers.duration = 1.0
    self.passiveModifiers.critMult = 1.0
    
    self.passiveModifiers.maxHealth = 0
    self.passiveModifiers.recovery = 0
    self.passiveModifiers.armor = 0
    self.passiveModifiers.amount = 0
    self.passiveModifiers.pierce = 0
    
    -- Load passive data
    local allPassives = dl.loadJSON("passives")
    local lookup = dl.createLookup(allPassives, "id")
    
    for id, level in pairs(self.passives) do
        local data = lookup[id]
        if data and data.effects and data.effects[level] then
            for _, effect in ipairs(data.effects[level]) do
                local stat = effect.stat
                local val = effect.value
                
                if effect.type == "multiply" then
                    -- Multiplicative accumulation
                    if stat == "cooldown" then
                        -- Cooldown reduction: +10% cooldown means -10% fire delay
                        self.passiveModifiers.cooldown = self.passiveModifiers.cooldown * (1 - val)
                    else
                        self.passiveModifiers[stat] = (self.passiveModifiers[stat] or 1.0) * (1 + val)
                    end
                elseif effect.type == "add" then
                    -- Additive accumulation
                    self.passiveModifiers[stat] = (self.passiveModifiers[stat] or 0) + val
                end
            end
        end
    end
    
    -- Apply to active stats
    self.might = self.baseStats.might * self.passiveModifiers.might
    self.speed = self.baseStats.speed * self.passiveModifiers.speed
    self.area = self.baseStats.area * self.passiveModifiers.area
    self.duration = self.baseStats.duration * self.passiveModifiers.duration
    self.cooldown = self.baseStats.cooldown * self.passiveModifiers.cooldown
    -- critMult bonus is additive to base multiplier
    self.critMult = self.baseStats.critMult + (self.passiveModifiers.critMult - 1.0)
    
    local oldMax = self.maxHp
    self.maxHp = self.baseStats.maxHealth + self.passiveModifiers.maxHealth
    if self.maxHp > oldMax then
        self.hp = self.hp + (self.maxHp - oldMax)
    end
    
    self.recovery = self.baseStats.recovery + self.passiveModifiers.recovery
    self.armor = self.baseStats.armor + self.passiveModifiers.armor
    self.amount = self.baseStats.amount + self.passiveModifiers.amount
    self.pierce = self.baseStats.pierce + self.passiveModifiers.pierce
end

function Player:addXP(amount)
    self.xp = self.xp + amount
    if self.xp >= self.xpToNext then
        self:levelUp()
    end
end

function Player:levelUp()
    self.level = self.level + 1
    self.xp = self.xp - self.xpToNext
    self.xpToNext = math.floor(self.xpToNext * 1.5)
    return true
end

function Player:update(dt)
    -- Movement with Normalization
    local dx, dy = 0, 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        dx = dx - 1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        dx = dx + 1
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        dy = dy - 1
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        dy = dy + 1
    end

    if dx ~= 0 or dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx = dx / length
        dy = dy / length
        
        self.x = self.x + dx * self.speed * dt
        self.y = self.y + dy * self.speed * dt
    end
    
    -- Bounds (Keep player in game viewport: 220 to virtual width)
    if self.x < 220 + self.radius then
        self.x = 220 + self.radius
    end
    if self.x > Screen.getVirtualWidth() - self.radius then
        self.x = Screen.getVirtualWidth() - self.radius
    end

    -- Vertical Bounds
    if self.y < self.radius then
        self.y = self.radius
    end
    if self.y > Screen.getVirtualHeight() - self.radius then
        self.y = Screen.getVirtualHeight() - self.radius
    end
    
    -- Recovery
    if self.hp < self.maxHp then
        self.hp = math.min(self.maxHp, self.hp + self.recovery * dt)
    end
    
    -- Weapon System
    self.ws:update(dt, self.x, self.y, self.might, self.cooldown, self.area, self.amount, self.pierce)

    -- Evolution Effects
    if self.evoEffectTimer > 0 then
        self.evoEffectTimer = self.evoEffectTimer - dt
        if self.evoEffectTimer <= 0 then
            self.isEvolving = false
        end
    end

    -- Damage Feedback & Invulnerability Timers
    if self.invulnTimer > 0 then
        self.invulnTimer = self.invulnTimer - dt
    end
    if self.damageFlashTimer > 0 then
        self.damageFlashTimer = self.damageFlashTimer - dt
    end
end

function Player:draw()
    -- Draw ship using visual system
    local alpha = 1.0
    if self.invulnTimer > 0 then
        -- Blink on/off during invulnerability (10Hz)
        if math.floor(love.timer.getTime() * 20) % 2 == 0 then
            alpha = 0.3
        end
    end

    if self.isEvolving then
        local flashAlpha = math.min(1, self.evoEffectTimer / 0.5)
        love.graphics.setColor(0, 1, 1, flashAlpha)
    elseif self.damageFlashTimer > 0 then
        -- Flash red briefly
        love.graphics.setColor(1, 0, 0, alpha)
    else
        love.graphics.setColor(1, 1, 1, alpha)
    end
    
    ShipVisuals.drawShip(self.shipId, self.x, self.y, 1.0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw weapons
    self.ws:draw()

    -- Evolution Notification
    if self.evolutionAvailable then
        love.graphics.setColor(1, 0.8, 0.2, 0.8 + math.sin(love.timer.getTime() * 10) * 0.2)
        love.graphics.setFont(Fonts.getFont("small"))
        love.graphics.printf("EVOLUTION AVAILABLE!", self.x - 100, self.y - 45, 200, "center")
    end

    -- Evolution Effect (Flash & Whiteout)
    if self.evoEffectTimer > 0 then
        -- Whiteout flash at start
        if self.evoEffectTimer > 1.3 then
            love.graphics.setColor(1, 1, 1, (self.evoEffectTimer - 1.3) / 0.2)
            love.graphics.rectangle("fill", 0, 0, Screen.getVirtualWidth(), Screen.getVirtualHeight())
        end

        love.graphics.setColor(0, 1, 1, self.evoEffectTimer)
        love.graphics.circle("line", self.x, self.y, 100 * (1 - (self.evoEffectTimer/1.5)))
    end
end

function Player:getBullets() return self.ws:getBullets() end
function Player:addWeapon(id) self.ws:equipWeapon(id) end

function Player:takeDamage(amount)
    if self.isEvolving or self.invulnTimer > 0 then return end
    
    -- Apply armor reduction (simple reduction, minimum 1 damage)
    local actualDamage = math.max(1, amount - (self.armor or 0))
    self.hp = self.hp - actualDamage

    -- 1. Temporary Invulnerability (0.5 seconds)
    self.invulnTimer = 0.5
    self.damageFlashTimer = 0.2

    -- 2. Visual Feedback
    -- Screen shake
    ScreenShake.trigger(6, 0.3)
    
    -- Particle burst (red particles)
    Particles.spawn(self.x, self.y, 15, "danger", 150, 2)

    -- GameState interactions (if available)
    if self.gameState then
        -- Screen border flashes red
        if self.gameState.flashScreen then
            self.gameState:flashScreen("danger", 0.2, 0.4)
        end
        
        -- Floating damage number: "-10 HP"
        if self.gameState.damageNumbers and self.gameState.damageNumbers.spawn then
            self.gameState.damageNumbers:spawn(self.x, self.y - 30, "-" .. math.floor(actualDamage) .. " HP", false)
        end
    end

    -- 3. Sound trigger point (Sound.play("player_hit"))
end

return Player
