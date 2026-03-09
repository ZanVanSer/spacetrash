local Colors = require('ui.colors')
local Particles = require('systems.particles')

local XPOrb = {}
XPOrb.__index = XPOrb

local MAGNET_RADIUS = 150
local COLLECTION_RADIUS = 30
local MAGNET_SPEED = 300
local MAX_LIFETIME = 10.0

---Create a new XP Orb
---@param x number X position
---@param y number Y position
---@param xpValue number XP amount
function XPOrb.new(x, y, xpValue)
    local self = setmetatable({}, XPOrb)
    self.x = x
    self.y = y
    self.baseY = y
    self.xpValue = xpValue or 1
    self.lifetime = MAX_LIFETIME
    self.bobTimer = math.random() * math.pi * 2
    self.isCollected = false
    self.isMagnetized = false
    
    -- Visual properties
    self.pulseTimer = math.random() * math.pi * 2
    self.size = 3 + math.min(self.xpValue, 10) * 0.5
    
    return self
end

---Update the XP Orb logic
---@param dt number Delta time
---@param playerX number Player's X position
---@param playerY number Player's Y position
function XPOrb:update(dt, playerX, playerY)
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.isCollected = true -- Effectively remove it
        return
    end

    self.bobTimer = self.bobTimer + dt
    self.pulseTimer = self.pulseTimer + dt

    -- Distance check for magnet/collection
    local dx = playerX - self.x
    local dy = playerY - self.y
    local distSq = dx * dx + dy * dy
    local dist = math.sqrt(distSq)

    if dist < COLLECTION_RADIUS then
        self.isCollected = true
        return
    elseif dist < MAGNET_RADIUS or self.isMagnetized then
        self.isMagnetized = true -- Once magnetized, stay magnetized
        
        -- Move toward player
        local angle = math.atan2(dy, dx)
        local speed = MAGNET_SPEED * (1 + (MAGNET_RADIUS - dist) / MAGNET_RADIUS)
        self.x = self.x + math.cos(angle) * speed * dt
        self.y = self.y + math.sin(angle) * speed * dt
        self.baseY = self.y -- Update baseY so bobbing doesn't fight movement
    else
        -- Bobbing animation when not magnetized
        local bobOffset = math.sin(self.bobTimer * 3) * 5
        self.y = self.baseY + bobOffset
    end

    -- Occasional sparkle particles
    if math.random() < 5 * dt then
        Particles.spawn(self.x, self.y, 1, "xp", 20, 1)
    end
end

---Draw the XP Orb
function XPOrb:draw()
    local alpha = 1.0
    if self.lifetime < 2.0 then
        alpha = self.lifetime / 2.0
    end

    local pulse = 1.0 + math.sin(self.pulseTimer * 5) * 0.2
    local drawSize = self.size * pulse

    -- Draw outer glow
    Colors.setColor("xp", alpha * 0.3)
    love.graphics.circle("fill", self.x, self.y, drawSize * 1.5)

    -- Draw core
    Colors.setColor("xp", alpha * 0.9)
    love.graphics.circle("fill", self.x, self.y, drawSize)

    -- Draw bright center
    love.graphics.setColor(1, 1, 1, alpha * 0.8)
    love.graphics.circle("fill", self.x, self.y, drawSize * 0.4)
end

---Check if the orb has been collected or expired
---@return boolean
function XPOrb:getIsCollected()
    return self.isCollected
end

return XPOrb
