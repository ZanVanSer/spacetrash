local WS = require "systems/weapon_system"
local Player = {}
Player.__index = Player

function Player.new(shipData)
    local self = setmetatable({}, Player)
    self.x = love.graphics.getWidth() / 2
    self.y = love.graphics.getHeight() - 50
    self.hp = shipData.hp
    self.maxHp = shipData.hp
    self.speed = shipData.speed
    self.radius = 15
    self.ws = WS.new()
    self.ws:equipWeapon(shipData.startWeapon)
    return self
end

function Player:update(dt)
    if love.keyboard.isDown("left") then
        self.x = self.x - self.speed * dt
    elseif love.keyboard.isDown("right") then
        self.x = self.x + self.speed * dt
    end
    
    self.x = math.max(self.radius, math.min(love.graphics.getWidth() - self.radius, self.x))
    self.ws:update(dt, self.x, self.y)
end

function Player:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("fill", 
        self.x, self.y - self.radius,
        self.x - self.radius, self.y + self.radius,
        self.x + self.radius, self.y + self.radius
    )
    self.ws:draw()
end

function Player:getBullets() return self.ws:getBullets() end
function Player:addWeapon(id) self.ws:equipWeapon(id) end

return Player
