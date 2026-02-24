local dataloader = require "systems/dataloader"
local stateManager = require "states/statemanager"

local state = {}

function state:enter(saveData, stageData)
    self.saveData = saveData
    self.stageData = stageData
    
    local allShips = dataloader.getShips()
    self.unlockedShips = {}
    
    -- Helper to check if ship ID is in saveData.unlockedShips
    local function isUnlocked(id)
        if not self.saveData or not self.saveData.unlockedShips then return false end
        for _, unlockedId in ipairs(self.saveData.unlockedShips) do
            if unlockedId == id then
                return true
            end
        end
        return false
    end
    
    for _, ship in ipairs(allShips) do
        if ship.unlockCondition == "default" or isUnlocked(ship.id) then
            table.insert(self.unlockedShips, ship)
        end
    end
    
    self.selectedIndex = 1
end

function state:keypressed(key)
    if #self.unlockedShips == 0 then
        if key == "x" then
            stateManager.switch('stage_select', self.saveData)
        end
        return
    end

    if key == "left" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.unlockedShips
        end
    elseif key == "right" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.unlockedShips then
            self.selectedIndex = 1
        end
    elseif key == "z" then
        local selectedShip = self.unlockedShips[self.selectedIndex]
        stateManager.switch('game', self.saveData, self.stageData, selectedShip)
    elseif key == "x" then
        stateManager.switch('stage_select', self.saveData)
    end
end

function state:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    love.graphics.clear(0.05, 0.05, 0.1)
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Select Ship", 0, 50, screenWidth, "center")
    
    -- Selected Ship Name
    if self.unlockedShips and #self.unlockedShips > 0 then
        local ship = self.unlockedShips[self.selectedIndex]
        love.graphics.printf(ship.name or ship.id, 0, screenHeight / 2, screenWidth, "center")
    else
        love.graphics.printf("No ships available", 0, screenHeight / 2, screenWidth, "center")
    end
    
    -- Controls hint
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("LEFT/RIGHT: Navigate | Z: Confirm | X: Back", 0, screenHeight - 50, screenWidth, "center")
end

return state
