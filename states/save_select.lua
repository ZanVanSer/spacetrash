local sm = require "states/statemanager"
local savemanager = require "systems/savemanager"
local Menu = require "ui/menu"

local state = {}

function state:enter()
    self.saves = {}
    local options = {}
    
    for i = 1, 3 do
        local data = savemanager.loadSave(i)
        self.saves[i] = data
        
        local label = "Slot " .. i .. ": "
        if data then
            local mins = math.floor(data.totalPlayTime / 60)
            local secs = data.totalPlayTime % 60
            label = label .. "Level " .. data.level .. " - " .. string.format("%02d:%02d", mins, secs)
        else
            label = label .. "Empty"
        end
        table.insert(options, label)
    end
    table.insert(options, "Back")
    
    self.menu = Menu.new(options)
end

function state:keypressed(key)
    local selection = self.menu:keypressed(key)
    
    if selection == -1 then
        sm.switch("main_menu")
    elseif selection == 4 then
        sm.switch("main_menu")
    elseif selection and selection >= 1 and selection <= 3 then
        local data = self.saves[selection]
        if not data then
            data = savemanager.getDefaultSave()
            savemanager.createSave(selection, data)
        end
        
        -- Store the save data globally for game_state/ship_select to use
        _G.currentSaveSlot = selection
        _G.currentSaveData = data
        
        -- Note: ship_select state will be created in Phase 10
        sm.switch("ship_select")
    end
end

function state:draw()
    -- Visual style consistent with main_menu.lua
    love.graphics.clear(0.05, 0.05, 0.1)
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    local titleFont = love.graphics.newFont(48)
    local oldFont = love.graphics.getFont()
    love.graphics.setFont(titleFont)
    love.graphics.printf("SELECT SAVE SLOT", 0, screenHeight * 0.15, screenWidth, "center")
    
    -- Menu
    love.graphics.setFont(oldFont)
    self.menu:draw(screenWidth / 2, screenHeight / 2)
    
    -- Additional info for highlighted slot
    local idx = self.menu.selectedIndex
    if idx <= 3 then
        local data = self.saves[idx]
        local infoY = screenHeight * 0.7
        if data then
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.printf("XP: " .. data.xp, 0, infoY, screenWidth, "center")
            love.graphics.printf("Ships Unlocked: " .. #data.unlockedShips, 0, infoY + 25, screenWidth, "center")
            love.graphics.printf("Weapons Unlocked: " .. #data.unlockedWeapons, 0, infoY + 50, screenWidth, "center")
            love.graphics.printf("Stages Completed: " .. #data.completedStages, 0, infoY + 75, screenWidth, "center")
        else
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.printf("Create New Save", 0, infoY, screenWidth, "center")
        end
    end
    
    -- Controls Hint
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Arrow Keys: Move | Z: Select | X: Back", 0, screenHeight - 50, screenWidth, "center")
end

return state
