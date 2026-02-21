local sm = require "states/statemanager"
local dl = require "systems/dataloader"

function love.load()
    -- Register all states
    sm.register("main_menu", require "states/main_menu")
    sm.register("game", require "states/game_state")
    
    -- Start with main menu
    sm.switch("main_menu")
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
