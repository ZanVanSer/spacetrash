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
    
    local titleFont = love.graphics.newFont(36)
    local mainFont = love.graphics.newFont(18)
    local smallFont = love.graphics.newFont(14)
    local boldFont = love.graphics.newFont(22)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SELECT SHIP", 0, 40, screenWidth, "center")
    
    if self.unlockedShips and #self.unlockedShips > 0 then
        local ship = self.unlockedShips[self.selectedIndex]
        
        -- Left Side: Selection Display
        love.graphics.setFont(boldFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("< " .. ship.name .. " >", 0, screenHeight / 2 - 20, screenWidth * 0.45, "center")
        
        -- Right Side: Stats Panel
        local panelX = screenWidth * 0.45
        local panelY = 100
        local panelWidth = screenWidth * 0.5
        local panelHeight = screenHeight - 160
        
        love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 12)
        love.graphics.setColor(0.4, 0.4, 0.6, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 12)
        
        local contentX = panelX + 30
        local currY = panelY + 30
        
        -- Ship Name and Class
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(titleFont)
        love.graphics.printf(ship.name:upper(), contentX, currY, panelWidth - 60, "center")
        currY = currY + 50
        
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.setFont(boldFont)
        love.graphics.printf(ship.class or "Unknown Class", contentX, currY, panelWidth - 60, "center")
        currY = currY + 45
        
        -- Description
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.setFont(mainFont)
        love.graphics.printf(ship.description or "", contentX, currY, panelWidth - 60, "left")
        currY = currY + 80
        
        -- Divider
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.line(contentX, currY, panelX + panelWidth - 30, currY)
        currY = currY + 20
        
        -- Stats Table
        local function drawStat(label, value, color)
            love.graphics.setFont(smallFont)
            love.graphics.setColor(0.6, 0.6, 0.7)
            love.graphics.print(label .. ":", contentX, currY)
            love.graphics.setFont(mainFont)
            love.graphics.setColor(unpack(color or {1, 1, 1}))
            love.graphics.print(tostring(value), contentX + 160, currY - 3)
            currY = currY + 26
        end
        
        drawStat("Max Health", ship.maxHealth, {1, 0.4, 0.4})
        drawStat("Recovery", (ship.recovery or 0) .. " HP/s", {0.4, 1, 0.4})
        drawStat("Armor", ship.armor, {0.6, 0.6, 1})
        drawStat("Might", math.floor((ship.might or 1) * 100) .. "%", {1, 0.6, 0.2})
        drawStat("Speed", ship.speed, {1, 1, 1})
        drawStat("Duration", math.floor((ship.duration or 1) * 100) .. "%", {0.8, 0.6, 1})
        drawStat("Cooldown", math.floor((ship.cooldown or 1) * 100) .. "%", {0.6, 1, 1})
        drawStat("Area", math.floor((ship.area or 1) * 100) .. "%", {1, 0.9, 0.5})
        drawStat("Amount", "+" .. (ship.amount or 0), {0.5, 1, 0.5})
        
        currY = currY + 10
        drawStat("Starting Weapon", (ship.startWeapon or "Unknown"):gsub("_", " "):gsub("^%l", string.upper), {1, 1, 0.6})
        
    else
        love.graphics.setFont(mainFont)
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf("No ships available", 0, screenHeight / 2, screenWidth, "center")
    end
    
    -- Controls hint
    love.graphics.setFont(mainFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("LEFT/RIGHT: Navigate | Z: Confirm | X: Back", 0, screenHeight - 50, screenWidth, "center")
end

return state
