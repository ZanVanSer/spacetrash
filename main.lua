local sm = require "states/statemanager"
local dl = require "systems/dataloader"
local Settings = require "systems/settings"

function love.load()
    -- Load and Apply Settings
    local currentSettings = Settings.load()
    -- On first run, ensure settings file exists
    if not love.filesystem.getInfo("settings.json") then
        Settings.save(currentSettings)
    end
    Settings.apply(currentSettings)

    -- Register all states
    sm.register("main_menu", require "states/main_menu")
    sm.register("save_select", require "states/save_select")
    sm.register("stage_select", require "states/stage_select")
    sm.register("ship_select", require "states/ship_select")
    sm.register("settings_menu", require "states/settings_menu")
    sm.register("game", require "states/game_state")
    sm.register("gameover", require "states/gameover_state")
    sm.register("library", require "states/library")
    sm.register("library_ships", require "states/library_ships")
    sm.register("library_weapons", require "states/library_weapons")
    sm.register("library_passives", require "states/library_passives")
    sm.register("library_enemies", require "states/library_enemies")
    sm.register("library_bosses", require "states/library_bosses")
    sm.register("library_stats", require "states/library_stats")
    sm.register("library_save_select", require "states/library_save_select")
    
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
