local WS = require "systems/weapon_system"
local Player = {}
Player.__index = Player

function Player.new(shipData)
    local self = setmetatable({}, Player)
    self.x = love.graphics.getWidth() / 2
    self.y = love.graphics.getHeight() - 50
    
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
    
    -- Bounds
    self.x = math.max(self.radius, math.min(love.graphics.getWidth() - self.radius, self.x))
    
    -- Recovery
    if self.hp < self.maxHp then
        self.hp = math.min(self.maxHp, self.hp + self.recovery * dt)
    end
    
    -- Weapon System
    self.ws:update(dt, self.x, self.y, self.might, self.cooldown, self.area, self.amount)
end

function Player:draw()
    local r = self.radius
    local time = love.timer.getTime()
    
    if self.shipId == "vanguard" then
        -- White triangle (balanced)
        love.graphics.setColor(1, 1, 1)
        love.graphics.polygon("fill", self.x, self.y - r, self.x - r, self.y + r, self.x + r, self.y + r)
    elseif self.shipId == "interceptor" then
        -- Yellow narrow triangle (fast)
        love.graphics.setColor(1, 1, 0)
        love.graphics.polygon("fill", self.x, self.y - r * 1.2, self.x - r * 0.6, self.y + r * 0.8, self.x + r * 0.6, self.y + r * 0.8)
    elseif self.shipId == "fortress" then
        -- Gray wide hexagon (tanky)
        love.graphics.setColor(0.6, 0.6, 0.6)
        local w, h = r * 1.2, r * 0.8
        love.graphics.polygon("fill", 
            self.x, self.y - h, 
            self.x + w, self.y - h/2, 
            self.x + w, self.y + h/2, 
            self.x, self.y + h, 
            self.x - w, self.y + h/2, 
            self.x - w, self.y - h/2
        )
    elseif self.shipId == "swarm_commander" then
        -- Cyan triangle with small dots around it (drones)
        love.graphics.setColor(0, 1, 1)
        love.graphics.polygon("fill", self.x, self.y - r, self.x - r, self.y + r, self.x + r, self.y + r)
        -- Mini drones
        for i = 1, 3 do
            local angle = time * 3 + (i * (math.pi * 2 / 3))
            local dx = self.x + math.cos(angle) * 25
            local dy = self.y + math.sin(angle) * 25
            love.graphics.circle("fill", dx, dy, 2)
        end
    elseif self.shipId == "storm_caller" then
        -- Purple triangle with lightning effect (AoE)
        love.graphics.setColor(0.7, 0.3, 1)
        love.graphics.polygon("fill", self.x, self.y - r, self.x - r, self.y + r, self.x + r, self.y + r)
        -- Electric sparks
        love.graphics.setLineWidth(1)
        for i = 1, 2 do
            local angle = (time * 10 + i) % (math.pi * 2)
            local dist = 15 + math.random() * 10
            love.graphics.line(self.x, self.y, self.x + math.cos(angle) * dist, self.y + math.sin(angle) * dist)
        end
    else
        -- Default fallback
        love.graphics.setColor(1, 1, 1)
        love.graphics.polygon("fill", self.x, self.y - r, self.x - r, self.y + r, self.x + r, self.y + r)
    end
    
    self.ws:draw()
end

function Player:getBullets() return self.ws:getBullets() end
function Player:addWeapon(id) self.ws:equipWeapon(id) end

return Player
