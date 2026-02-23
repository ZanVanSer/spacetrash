local sm = require "states/statemanager"
local dl = require "systems/dataloader"

function love.load()
    -- Register all states
    sm.register("main_menu", require "states/main_menu")
    sm.register("save_select", require "states/save_select")
    sm.register("stage_select", require "states/stage_select")
    sm.register("game", require "states/game_state")
    sm.register("gameover", require "states/gameover_state")
    
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
