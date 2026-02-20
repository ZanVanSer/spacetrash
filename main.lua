local sm = require "states/statemanager"
local dl = require "systems/dataloader"

function love.load()
    local weapons = dl.getWeapons()
    local ships = dl.getShips()

    sm.register("game", require "states/game_state")
    sm.switch("game")
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
