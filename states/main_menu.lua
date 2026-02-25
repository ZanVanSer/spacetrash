local sm = require "states/statemanager"
local Menu = require "ui/menu"
local Screen = require('systems.screen')
local state = {}

function state:enter()
    self.menu = Menu.new({"Start Game", "Settings", "Library", "Exit"})
end

function state:keypressed(key)
    local selection = self.menu:keypressed(key)
    if selection == 1 then
        sm.switch("save_select")
    elseif selection == 2 then
        print("Settings - coming soon")
    elseif selection == 3 then
        print("Library - coming soon")
    elseif selection == 4 then
        love.event.quit()
    end
end

function state:draw()
    Screen.applyScale()
    -- Dark background
    love.graphics.clear(0.05, 0.05, 0.1)
    
    local screenWidth = Screen.getVirtualWidth()
    local screenHeight = Screen.getVirtualHeight()
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    local titleFont = love.graphics.newFont(48)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(titleFont)
    love.graphics.printf("SPACE TRASH", 0, screenHeight * 0.2, screenWidth, "center")
    
    -- Subtitle
    local subtitleFont = love.graphics.newFont(24)
    love.graphics.setFont(subtitleFont)
    love.graphics.printf("A Bullet Hell Trash Roguelike", 0, screenHeight * 0.3, screenWidth, "center")
    
    -- Menu
    love.graphics.setFont(oldFont)
    self.menu:draw(screenWidth / 2, screenHeight / 2 + 50)
    
    -- Controls Hint
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Arrow Keys: Move | Z: Select | X: Back", 0, screenHeight - 50, screenWidth, "center")
    Screen.removeScale()
end

return state
