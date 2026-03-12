local dataloader = require "systems/dataloader"
local stateManager = require "states/statemanager"
local ShipVisuals = require "entities/ship_visuals"
local Screen = require('systems.screen')
local Fonts = require('ui/fonts')
local AudioManager = require('systems/audio_manager')

local state = {}

local function getUnlockHint(condition)
    if not condition or condition == "default" then return "" end
    if condition == "level_10" then return "Reach Level 10" end
    local stageNum = condition:match("beat_stage_(%d+)")
    if stageNum then
        return "Complete Stage " .. stageNum
    end
    return "Locked"
end

function state:isShipUnlocked(ship)
    if not ship then return false end
    if ship.unlockCondition == "default" then return true end
    if not self.saveData or not self.saveData.unlockedShips then return false end
    for _, unlockedId in ipairs(self.saveData.unlockedShips) do
        if unlockedId == ship.id then
            return true
        end
    end
    return false
end

function state:enter(saveData, stageData)
    self.saveData = saveData
    self.stageData = stageData
    self.allShips = dataloader.getShips()
    self.selectedIndex = 1
    
    -- Animation State
    self.animTimer = 0
    self.transitionTimer = 0
    self.transitionDuration = 0.25
    self.lastSelectedIndex = 1
    self.slideDir = 0
end

function state:update(dt)
    self.animTimer = self.animTimer + dt
    if self.transitionTimer > 0 then
        self.transitionTimer = math.max(0, self.transitionTimer - dt)
    end
end

function state:keypressed(key)
    if not self.allShips or #self.allShips == 0 then
        if key == "x" then
            AudioManager.playSound("ui.back")
            stateManager.switch('stage_select', self.saveData)
        end
        return
    end

    if key == "left" then
        AudioManager.playSound("ui.navigate")
        self.lastSelectedIndex = self.selectedIndex
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.allShips
        end
        self.transitionTimer = self.transitionDuration
        self.slideDir = -1
    elseif key == "right" then
        AudioManager.playSound("ui.navigate")
        self.lastSelectedIndex = self.selectedIndex
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.allShips then
            self.selectedIndex = 1
        end
        self.transitionTimer = self.transitionDuration
        self.slideDir = 1
    elseif key == "z" then
        local selectedShip = self.allShips[self.selectedIndex]
        if self:isShipUnlocked(selectedShip) then
            AudioManager.playSound("ui.select")
            stateManager.switch('game', self.saveData, self.stageData, selectedShip)
        else
            AudioManager.playSound("ui.back") -- Feedback for locked
        end
    elseif key == "r" then
        local unlockedShips = {}
        for _, ship in ipairs(self.allShips) do
            if self:isShipUnlocked(ship) then
                table.insert(unlockedShips, ship)
            end
        end
        if #unlockedShips > 0 then
            AudioManager.playSound("ui.select")
            local randomShip = unlockedShips[love.math.random(#unlockedShips)]
            stateManager.switch('game', self.saveData, self.stageData, randomShip)
        end
    elseif key == "x" then
        AudioManager.playSound("ui.back")
        stateManager.switch('stage_select', self.saveData)
    end
end

function state:draw()
    Screen.applyScale()
    local oldFont = love.graphics.getFont()
    local screenWidth = Screen.getVirtualWidth()
    local screenHeight = Screen.getVirtualHeight()
    local time = self.animTimer
    
    love.graphics.clear(0.05, 0.05, 0.1)
    
    -- Fonts
    local titleFont = Fonts.getFont("huge")
    local mainFont = Fonts.getFont("large")
    local smallFont = Fonts.getFont("small")
    local boldFont = Fonts.getFont("large")

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SELECT SHIP", 0, 40, screenWidth, "center")
    
    if self.allShips and #self.allShips > 0 then
        local ship = self.allShips[self.selectedIndex]
        local unlocked = self:isShipUnlocked(ship)
        
        -- Left Side: Selection Display
        local leftCenterX = screenWidth * 0.225
        local leftCenterY = screenHeight * 0.45
        
        -- Navigation Arrows
        local arrowPulse = math.sin(time * 8) * 5
        love.graphics.setFont(titleFont)
        
        if #self.allShips > 1 then
            love.graphics.setColor(1, 1, 1, 0.8 + math.sin(time * 10) * 0.2)
            love.graphics.print("<-", leftCenterX - 110 - arrowPulse, leftCenterY - 60)
            love.graphics.print("->", leftCenterX + 60 + arrowPulse, leftCenterY - 60)
        end
        
        -- Animation values
        local bobY = math.sin(time * 2) * 10
        local rotation = math.sin(time * 1.5) * 0.1

        -- Handle Transitions
        if self.transitionTimer > 0 then
            local t = 1 - (self.transitionTimer / self.transitionDuration)
            -- Ease out quint
            t = 1 - math.pow(1 - t, 5)
            
            local lastShip = self.allShips[self.lastSelectedIndex]
            
            -- Draw previous ship sliding out
            local prevX = leftCenterX - t * 150 * self.slideDir
            ShipVisuals.drawShip(lastShip.id, prevX, leftCenterY - 40 + bobY, 3.0, rotation)
            
            -- Draw current ship sliding in
            local currX = leftCenterX + (1 - t) * 150 * self.slideDir
            ShipVisuals.drawShip(ship.id, currX, leftCenterY - 40 + bobY, 3.0, rotation)
        else
            ShipVisuals.drawShip(ship.id, leftCenterX, leftCenterY - 40 + bobY, 3.0, rotation)
        end
        
        -- Locked Overlay
        if not unlocked then
            -- Simple dark overlay for locked ship
            love.graphics.setColor(0, 0, 0, 0.4)
            love.graphics.circle("fill", leftCenterX, leftCenterY - 40, 60)
            
            love.graphics.setFont(boldFont)
            love.graphics.setColor(1, 0, 0, 0.8 + math.sin(time * 5) * 0.2)
            love.graphics.printf("LOCKED", 0, leftCenterY - 60, screenWidth * 0.45, "center")
        end
        
        -- Ship Name
        love.graphics.setFont(boldFont)
        love.graphics.setColor(unlocked and {1, 1, 1} or {0.5, 0.5, 0.5})
        love.graphics.printf(ship.name, 0, screenHeight * 0.45 + 50, screenWidth * 0.45, "center")
        
        -- Unlock Hint
        if not unlocked then
            love.graphics.setFont(mainFont)
            love.graphics.setColor(1, 0.8, 0.2)
            love.graphics.printf(getUnlockHint(ship.unlockCondition), 0, screenHeight * 0.45 + 85, screenWidth * 0.45, "center")
        else
            -- Ship Counter
            love.graphics.setFont(mainFont)
            love.graphics.setColor(0.6, 0.6, 0.7)
            love.graphics.printf(self.selectedIndex .. " / " .. #self.allShips, 0, screenHeight * 0.45 + 85, screenWidth * 0.45, "center")
        end
        
        -- Ship Row at Bottom
        local iconSize = 40
        local spacing = 20
        local totalWidth = (#self.allShips * iconSize) + ((#self.allShips - 1) * spacing)
        local startX = (screenWidth * 0.45 - totalWidth) / 2
        local bottomY = screenHeight - 120
        
        for i, s in ipairs(self.allShips) do
            local x = startX + (i - 1) * (iconSize + spacing) + iconSize/2
            local isUnlocked = self:isShipUnlocked(s)
            local isSelected = i == self.selectedIndex
            
            if isSelected then
                love.graphics.setColor(1, 1, 1, 0.2)
                love.graphics.circle("fill", x, bottomY, iconSize/2 + 5)
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.setLineWidth(2)
                love.graphics.circle("line", x, bottomY, iconSize/2 + 5)
            end
            
            ShipVisuals.drawShip(s.id, x, bottomY, 0.5, 0)
            
            if not isUnlocked then
                -- Darken locked thumbnails
                love.graphics.setColor(0, 0, 0, 0.6)
                love.graphics.circle("fill", x, bottomY, iconSize/2)
                
                love.graphics.setFont(smallFont)
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.print("?", x - 4, bottomY - 7)
            end
        end
        
        -- Right Side: Stats Panel
        local panelX = screenWidth * 0.45
        local panelY = 100
        local panelWidth = screenWidth * 0.5
        local panelHeight = screenHeight - 160
        
        love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 12)
        
        if unlocked then
            love.graphics.setColor(0.4, 0.4, 0.6, 0.5)
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
        end
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 12)
        
        local contentX = panelX + 30
        local currY = panelY + 30
        
        -- Ship Name and Class
        love.graphics.setColor(unlocked and {1, 1, 1} or {0.4, 0.4, 0.4})
        love.graphics.setFont(titleFont)
        love.graphics.printf(ship.name:upper(), contentX, currY, panelWidth - 60, "center")
        currY = currY + 50
        
        love.graphics.setColor(unlocked and {1, 0.8, 0.2} or {0.4, 0.3, 0.1})
        love.graphics.setFont(boldFont)
        love.graphics.printf(ship.class or "Unknown Class", contentX, currY, panelWidth - 60, "center")
        currY = currY + 45
        
        -- Description - wrap with max lines to prevent overflow
        love.graphics.setColor(unlocked and {0.8, 0.8, 0.9} or {0.3, 0.3, 0.3})
        love.graphics.setFont(mainFont)
        local descWidth = panelWidth - 60
        local descText = ship.description or ""
        local maxDescLines = 3
        local descHeight = mainFont:getHeight() * maxDescLines
        -- Use simple truncation if text is too long
        if mainFont:getWidth(descText) > descWidth * maxDescLines then
            -- Try wrapping first
            local wrapped = mainFont:getWrap(descText, descWidth)
            if type(wrapped) == "table" then
                descText = table.concat(wrapped, "\n", 1, maxDescLines)
            end
        end
        love.graphics.printf(descText, contentX, currY, descWidth, "left")
        currY = currY + descHeight + 15
        
        -- Divider
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.line(contentX, currY, panelX + panelWidth - 30, currY)
        currY = currY + 15
        
        -- Stats Table
        local function drawStat(label, value, color)
            love.graphics.setFont(smallFont)
            love.graphics.setColor(unlocked and {0.6, 0.6, 0.7} or {0.3, 0.3, 0.3})
            love.graphics.print(label .. ":", contentX, currY)
            love.graphics.setFont(mainFont)
            if unlocked then
                love.graphics.setColor(unpack(color or {1, 1, 1}))
            else
                love.graphics.setColor(0.3, 0.3, 0.3)
            end
            -- Truncate value if too wide for container
            local maxValueWidth = panelWidth - 220  -- Reserve space for label
            local valueStr = tostring(value)
            if mainFont:getWidth(valueStr) > maxValueWidth then
                valueStr = Fonts.truncateText(valueStr, maxValueWidth, mainFont)
            end
            love.graphics.print(valueStr, contentX + 160, currY - 3)
            currY = currY + 20
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
        
        currY = currY + 5
        drawStat("Starting Weapon", (ship.startWeapon or "Unknown"):gsub("_", " "):gsub("^%l", string.upper), {1, 1, 0.6})
        
    else
        love.graphics.setFont(mainFont)
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf("No ships available", 0, screenHeight / 2, screenWidth, "center")
    end
    
    -- Controls hint
    love.graphics.setFont(mainFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("LEFT/RIGHT: Navigate | Z: Confirm | R: Random | X: Back", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
