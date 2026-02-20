local Player = require "entities/player"
local dl = require "systems/dataloader"
local state = {}

function state:enter()
    local shipData = dl.getShips()[1]
    self.player = Player.new(shipData)
end

function state:update(dt)
    self.player:update(dt)
end

function state:draw()
    love.graphics.clear(0.05, 0.05, 0.1)
    self.player:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. self.player.hp, 10, 10)
end

return state
