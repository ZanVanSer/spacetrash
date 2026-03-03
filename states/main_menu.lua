local sm = require "states/statemanager"
local Menu = require "ui/menu"
local Screen = require('systems.screen')
local Fonts = require('ui/fonts')
local savemanager = require "systems/savemanager"
local state = {}

function state:enter()
    self.menu = Menu.new({"Start Game", "Settings", "Library", "Exit"})
end

function state:keypressed(key)
    local selection = self.menu:keypressed(key)
    if selection == 1 then
        sm.switch("save_select")
    elseif selection == 2 then
        sm.switch("settings_menu")
    elseif selection == 3 then
        -- Get current save data (or slot 1 as default for meta-progression view)
        local saveData = _G.currentSaveData or savemanager.loadSave(1)
        sm.switch("library", saveData)
    elseif selection == 4 then
        love.event.quit()
    end
end

function state:draw()
    Screen.applyScale()
    local oldFont = love.graphics.getFont()
    -- Dark background
    love.graphics.clear(0.05, 0.05, 0.1)
    
    local screenWidth = Screen.getVirtualWidth()
    local screenHeight = Screen.getVirtualHeight()
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("SPACE TRASH", 0, screenHeight * 0.2, screenWidth, "center")
    
    -- Subtitle
    love.graphics.setFont(Fonts.getFont("large"))
    love.graphics.printf("A Bullet Hell Trash Roguelike", 0, screenHeight * 0.3, screenWidth, "center")
    
    -- Menu
    love.graphics.setFont(Fonts.getFont("normal"))
    self.menu:draw(screenWidth / 2, screenHeight / 2 + 50)
    
    -- Controls Hint
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("Arrow Keys: Move | Z: Select | X: Back", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
