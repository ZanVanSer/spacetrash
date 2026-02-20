local sm = require "states/statemanager"
local dl = require "systems/dataloader"

function love.load()
    local weapons = dl.getWeapons()
    local ships = dl.getShips()

    sm.register("test1", require "states/test1")
    sm.register("test2", require "states/test2")
    sm.switch("test1")
end

function love.update(dt)
    sm.update(dt)
end

function love.draw()
    sm.draw()
end

function love.keypressed(key)
    sm.keypressed(key)
end
