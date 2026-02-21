local sm = require "states/statemanager"
local Menu = require "ui/menu"
local state = {}

function state:enter(stats)
    self.stats = stats or { timeSurvived = 0, level = 1, enemiesKilled = 0 }
    self.menu = Menu.new({"Retry", "Main Menu"})
end

function state:keypressed(key)
    local selection = self.menu:keypressed(key)
    if selection == 1 then
        sm.switch("game")
    elseif selection == 2 then
        sm.switch("main_menu")
    end
end

function state:draw()
    -- Dark background
    love.graphics.clear(0.05, 0.0, 0.0) -- Slightly red tint for game over
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Game Over Title
    love.graphics.setColor(1, 0, 0)
    local titleFont = love.graphics.newFont(64)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(titleFont)
    love.graphics.printf("GAME OVER", 0, screenHeight * 0.15, screenWidth, "center")
    
    -- Stats
    love.graphics.setColor(1, 1, 1)
    local statsFont = love.graphics.newFont(24)
    love.graphics.setFont(statsFont)
    
    local minutes = math.floor(self.stats.timeSurvived / 60)
    local seconds = math.floor(self.stats.timeSurvived % 60)
    local timeStr = string.format("Time Survived: %02d:%02d", minutes, seconds)
    
    local statsY = screenHeight * 0.35
    love.graphics.printf(timeStr, 0, statsY, screenWidth, "center")
    love.graphics.printf("Level Reached: " .. self.stats.level, 0, statsY + 35, screenWidth, "center")
    love.graphics.printf("Enemies Killed: " .. self.stats.enemiesKilled, 0, statsY + 70, screenWidth, "center")
    
    -- Menu
    love.graphics.setFont(oldFont)
    self.menu:draw(screenWidth / 2, screenHeight * 0.65)
    
    -- Controls Hint
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Arrow Keys: Move | Z: Select", 0, screenHeight - 50, screenWidth, "center")
end

return state
