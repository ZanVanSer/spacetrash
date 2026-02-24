local dataloader = require "systems/dataloader"
local stateManager = require "states/statemanager"

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
end

function state:keypressed(key)
    if not self.allShips or #self.allShips == 0 then
        if key == "x" then
            stateManager.switch('stage_select', self.saveData)
        end
        return
    end

    if key == "left" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.allShips
        end
    elseif key == "right" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.allShips then
            self.selectedIndex = 1
        end
    elseif key == "z" then
        local selectedShip = self.allShips[self.selectedIndex]
        if self:isShipUnlocked(selectedShip) then
            stateManager.switch('game', self.saveData, self.stageData, selectedShip)
        end
    elseif key == "x" then
        stateManager.switch('stage_select', self.saveData)
    end
end

function state:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local time = love.timer.getTime()
    
    love.graphics.clear(0.05, 0.05, 0.1)
    
    local titleFont = love.graphics.newFont(36)
    local mainFont = love.graphics.newFont(18)
    local smallFont = love.graphics.newFont(14)
    local boldFont = love.graphics.newFont(22)

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
        
        -- Draw Ship Preview (3x Scale)
        love.graphics.push()
        love.graphics.translate(leftCenterX, leftCenterY - 40)
        love.graphics.scale(3, 3)
        
        local function drawShipIcon(sid, isSilho)
            if isSilho then
                love.graphics.setColor(0.1, 0.1, 0.1, 0.7)
            end
            
            if sid == "vanguard" then
                if not isSilho then love.graphics.setColor(1, 1, 1) end
                love.graphics.polygon("fill", 0, -10, -8, 8, 8, 8)
            elseif sid == "interceptor" then
                if not isSilho then love.graphics.setColor(1, 1, 0) end
                love.graphics.polygon("fill", 0, -12, -5, 8, 5, 8)
            elseif sid == "fortress" then
                if not isSilho then love.graphics.setColor(0.6, 0.6, 0.6) end
                love.graphics.polygon("fill", 0, -10, 8, -4, 8, 4, 0, 10, -8, 4, -8, -4)
            elseif sid == "swarm_commander" then
                if not isSilho then love.graphics.setColor(0, 1, 1) end
                love.graphics.polygon("fill", 0, -10, -8, 8, 8, 8)
                if not isSilho then
                    for i = 1, 4 do
                        local angle = time * 2 + (i * math.pi / 2)
                        local dx = math.cos(angle) * 15
                        local dy = math.sin(angle) * 15
                        love.graphics.circle("fill", dx, dy, 2)
                    end
                end
            elseif sid == "storm_caller" then
                if not isSilho then love.graphics.setColor(0.7, 0.3, 1) end
                love.graphics.polygon("fill", 0, -10, -8, 8, 8, 8)
                if not isSilho then
                    love.graphics.setLineWidth(1)
                    for i = 1, 3 do
                        local angle = (time * 5 + i) % (math.pi * 2)
                        local dist = 12 + math.random() * 8
                        love.graphics.line(0, 0, math.cos(angle) * dist, math.sin(angle) * dist)
                    end
                end
            else
                if not isSilho then love.graphics.setColor(0.5, 0.5, 0.5) end
                love.graphics.polygon("fill", 0, -10, -8, 8, 8, 8)
            end
        end
        
        drawShipIcon(ship.id, not unlocked)
        love.graphics.pop()
        
        -- Locked Overlay
        if not unlocked then
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
            
            love.graphics.push()
            love.graphics.translate(x, bottomY)
            love.graphics.scale(1.5, 1.5)
            drawShipIcon(s.id, not isUnlocked)
            love.graphics.pop()
            
            if not isUnlocked then
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
        
        -- Description
        love.graphics.setColor(unlocked and {0.8, 0.8, 0.9} or {0.3, 0.3, 0.3})
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
            love.graphics.setColor(unlocked and {0.6, 0.6, 0.7} or {0.3, 0.3, 0.3})
            love.graphics.print(label .. ":", contentX, currY)
            love.graphics.setFont(mainFont)
            if unlocked then
                love.graphics.setColor(unpack(color or {1, 1, 1}))
            else
                love.graphics.setColor(0.3, 0.3, 0.3)
            end
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
