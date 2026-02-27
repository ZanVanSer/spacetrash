local WS = require "systems/weapon_system"
local ShipVisuals = require "entities/ship_visuals"
local Screen = require('systems.screen')

local Player = {}
Player.__index = Player

function Player.new(shipData)
    local self = setmetatable({}, Player)
    self.x = Screen.getVirtualWidth() / 2
    self.y = Screen.getVirtualHeight() - 50
    
    -- Store Ship ID for drawing
    self.shipId = shipData.id
    
    -- Ship Stats
    self.maxHp = shipData.maxHealth or 100
    self.hp = self.maxHp
    self.recovery = shipData.recovery or 0
    self.armor = shipData.armor or 0
    self.speed = shipData.speed or 200
    self.might = shipData.might or 1.0
    self.duration = shipData.duration or 1.0
    self.cooldown = shipData.cooldown or 1.0
    self.area = shipData.area or 1.0
    self.amount = shipData.amount or 0
    
    self.radius = 15
    self.ws = WS.new()
    self.ws:equipWeapon(shipData.startWeapon)
    
    self.xp = 0
    self.level = 1
    self.xpToNext = 10
    return self
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
    -- Movement
    local moveX = 0
    if love.keyboard.isDown("left") then
        moveX = -1
    elseif love.keyboard.isDown("right") then
        moveX = 1
    end
    self.x = self.x + moveX * self.speed * dt
    
    -- Bounds (Keep player in game viewport: 220 to virtual width)
    if self.x < 220 + self.radius then
        self.x = 220 + self.radius
    end
    if self.x > Screen.getVirtualWidth() - self.radius then
        self.x = Screen.getVirtualWidth() - self.radius
    end
    
    -- Recovery
    if self.hp < self.maxHp then
        self.hp = math.min(self.maxHp, self.hp + self.recovery * dt)
    end
    
    -- Weapon System
    self.ws:update(dt, self.x, self.y, self.might, self.cooldown, self.area, self.amount)
end

function Player:draw()
    -- Draw ship using visual system
    ShipVisuals.drawShip(self.shipId, self.x, self.y, 1.0, 0)
    
    -- Draw weapons
    self.ws:draw()
end

function Player:getBullets() return self.ws:getBullets() end
function Player:addWeapon(id) self.ws:equipWeapon(id) end

function Player:takeDamage(amount)
    -- Apply armor reduction (simple reduction, minimum 1 damage)
    local actualDamage = math.max(1, amount - (self.armor or 0))
    self.hp = self.hp - actualDamage
end

return Player
