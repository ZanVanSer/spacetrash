local sm = require "states/statemanager"
local dataloader = require "systems/dataloader"
local savemanager = require "systems/savemanager"
local Menu = require "ui/menu"
local Screen = require('systems.screen')
local Fonts = require('ui/fonts')

local state = {}

function state:isUnlocked(stage)
    if not stage then return false end
    if stage.unlockCondition == "default" then
        return true
    end
    return self.completedMap[stage.unlockCondition] or false
end

function state:enter(saveData)
    self.saveData = saveData or { completedStages = {}, seenStages = {} }
    self.stages = dataloader.getStages()
    
    local completedMap = {}
    for _, id in ipairs(self.saveData.completedStages or {}) do
        completedMap[id] = true
    end
    self.completedMap = completedMap
    
    -- Track "NEW!" stages
    self.saveData.seenStages = self.saveData.seenStages or {}
    local seenMap = {}
    for _, id in ipairs(self.saveData.seenStages) do
        seenMap[id] = true
    end
    
    self.newStages = {}
    local anyNew = false
    
    for _, stage in ipairs(self.stages) do
        if self:isUnlocked(stage) and not seenMap[stage.id] then
            self.newStages[stage.id] = true
            table.insert(self.saveData.seenStages, stage.id)
            anyNew = true
        end
    end
    
    -- Save if we updated seen status
    if anyNew then
        local slot = _G.currentSaveSlot
        if slot then
            savemanager.createSave(slot, self.saveData)
        end
    end
    
    self.cols = 3
    self.rows = math.ceil(#self.stages / self.cols)
    self.gridX = 1
    self.gridY = 1
    self.selectedIndex = 1
end

function state:keypressed(key)
    local oldX, oldY = self.gridX, self.gridY
    
    if key == "left" then
        self.gridX = self.gridX - 1
        if self.gridX < 1 then self.gridX = self.cols end
    elseif key == "right" then
        self.gridX = self.gridX + 1
        if self.gridX > self.cols then self.gridX = 1 end
    elseif key == "up" then
        self.gridY = self.gridY - 1
        if self.gridY < 1 then self.gridY = self.rows end
    elseif key == "down" then
        self.gridY = self.gridY + 1
        if self.gridY > self.rows then self.gridY = 1 end
    elseif key == "z" then
        local selectedStage = self.stages[self.selectedIndex]
        if selectedStage and self:isUnlocked(selectedStage) then
            print("Selected Stage: " .. selectedStage.name)
            sm.switch("ship_select", self.saveData, selectedStage)
        end
        return
    elseif key == "x" then
        sm.switch("save_select")
        return
    else
        return
    end
    
    -- Update selected index and handle empty grid spots
    self.selectedIndex = (self.gridY - 1) * self.cols + self.gridX
    
    if self.selectedIndex > #self.stages then
        if key == "down" or key == "up" then
            -- Jump to last available stage
            self.selectedIndex = #self.stages
            self.gridX = ((self.selectedIndex - 1) % self.cols) + 1
            self.gridY = math.floor((self.selectedIndex - 1) / self.cols) + 1
        elseif key == "right" then
            -- Wrap to start of row
            self.gridX = 1
            self.selectedIndex = (self.gridY - 1) * self.cols + self.gridX
        elseif key == "left" then
            -- Wrap to end of previous valid stage in same row
            self.selectedIndex = #self.stages
            self.gridX = ((self.selectedIndex - 1) % self.cols) + 1
        end
    end
end

function state:draw()
    Screen.applyScale()
    local oldFont = love.graphics.getFont()
    love.graphics.clear(0.05, 0.05, 0.1)
    
    local screenWidth = Screen.getVirtualWidth()
    local screenHeight = Screen.getVirtualHeight()
    local time = love.timer.getTime()
    
    -- Fonts
    local titleFont = Fonts.getFont("huge")
    local mainFont = Fonts.getFont("large")
    local smallFont = Fonts.getFont("small")
    local boldFont = Fonts.getFont("large") -- Using large as bold since we don't have separate bold variants
    
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SELECT STAGE", 20, 20, screenWidth, "left")
    
    -- Grid Settings
    local padding = 20
    local gridAreaWidth = screenWidth * 0.6
    local cardWidth = (gridAreaWidth - (self.cols + 1) * padding) / self.cols
    local cardHeight = cardWidth * 0.85
    local startX = padding
    local startY = 80
    
    -- Draw Stage Cards
    for i, stage in ipairs(self.stages) do
        local col = (i - 1) % self.cols
        local row = math.floor((i - 1) / self.cols)
        
        local x = startX + col * (cardWidth + padding)
        local y = startY + row * (cardHeight + padding)
        
        local isSelected = (i == self.selectedIndex)
        local isUnlocked = self:isUnlocked(stage)
        local isCompleted = self.completedMap[stage.id]
        local isNew = self.newStages[stage.id]
        
        -- Card Background
        if isUnlocked then
            if isCompleted then
                love.graphics.setColor(0.1, 0.2, 0.1, 0.9) -- Subtle green for completed
            else
                love.graphics.setColor(0.15, 0.15, 0.25, 0.9) -- Default blue
            end
        else
            love.graphics.setColor(0.1, 0.1, 0.1, 0.9) -- Dark for locked
        end
        
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 8)
        
        -- Border and Selection Glow
        if isSelected then
            local glow = (math.sin(time * 6) + 1) / 2
            love.graphics.setColor(1, 0.8, 0.2, 0.5 + 0.5 * glow)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", x, y, cardWidth, cardHeight, 8)
            
            -- Outer glow
            love.graphics.setColor(1, 0.8, 0.2, 0.2 * glow)
            love.graphics.rectangle("line", x - 2, y - 2, cardWidth + 4, cardHeight + 4, 10)
        else
            love.graphics.setColor(0.3, 0.3, 0.5, 0.5)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", x, y, cardWidth, cardHeight, 8)
        end
        
        -- Thumbnail Placeholder
        local thumbY = y + 10
        local thumbH = cardHeight * 0.45
        if isUnlocked then
            love.graphics.setColor(0.2, 0.3, 0.5)
            love.graphics.rectangle("fill", x + 10, thumbY, cardWidth - 20, thumbH, 4)
        else
            love.graphics.setColor(0.05, 0.05, 0.05)
            love.graphics.rectangle("fill", x + 10, thumbY, cardWidth - 20, thumbH, 4)
            
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            love.graphics.setFont(smallFont)
            love.graphics.printf("LOCKED", x, thumbY + thumbH/2 - 7, cardWidth, "center")
        end
        
        -- NEW! Badge
        if isNew then
            local badgePulse = math.abs(math.sin(time * 8))
            love.graphics.setColor(1, 0.2, 0.2, 0.8 + 0.2 * badgePulse)
            love.graphics.rectangle("fill", x - 5, y - 5, 50, 20, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(smallFont)
            love.graphics.print("NEW!", x, y - 2)
        end
        
        -- Stage Name
        love.graphics.setFont(mainFont)
        if isUnlocked then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.4, 0.4, 0.4)
        end
        -- Start name slightly higher and ensure it has room to wrap
        love.graphics.printf(stage.name, x + 5, y + cardHeight * 0.5, cardWidth - 10, "center")
        
        -- Difficulty Stars
        local stars = ""
        for s = 1, (stage.difficulty or 1) do stars = stars .. "*" end
        love.graphics.setFont(smallFont)
        if isUnlocked then
            love.graphics.setColor(1, 0.8, 0.2)
        else
            love.graphics.setColor(0.3, 0.3, 0.3)
        end
        -- Move stars to the very bottom of the card
        love.graphics.printf(stars, x + 5, y + cardHeight - 18, cardWidth - 10, "center")
        
        -- Completion Status
        if isCompleted then
            love.graphics.setColor(0.4, 1, 0.4)
            love.graphics.setFont(smallFont)
            love.graphics.print("[OK]", x + cardWidth - 35, y + 5)
        end
    end
    
    -- Detailed Info Panel
    local infoX = gridAreaWidth + 20
    local infoY = 80
    local infoWidth = screenWidth - infoX - 40
    local infoHeight = screenHeight - 150
    
    local selectedStage = self.stages[self.selectedIndex]
    if selectedStage then
        -- Panel Background
        love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
        love.graphics.rectangle("fill", infoX, infoY, infoWidth, infoHeight, 12)
        love.graphics.setColor(0.4, 0.4, 0.6, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", infoX, infoY, infoWidth, infoHeight, 12)
        
        local contentX = infoX + 25
        local currY = infoY + 25
        
        -- Stage Name (Large)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(titleFont)
        love.graphics.printf(selectedStage.name:upper(), contentX, currY, infoWidth - 50, "left")
        local _, lines = titleFont:getWrap(selectedStage.name:upper(), infoWidth - 50)
        currY = currY + titleFont:getHeight() * #lines + 15
        
        -- Description
        love.graphics.setFont(mainFont)
        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.printf(selectedStage.description, contentX, currY, infoWidth - 50, "left")
        currY = currY + 70
        
        -- Stats Section
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.line(contentX, currY, infoX + infoWidth - 25, currY)
        currY = currY + 15
        
        local function drawStat(label, value, color)
            love.graphics.setFont(smallFont)
            love.graphics.setColor(0.6, 0.6, 0.7)
            love.graphics.print(label .. ":", contentX, currY)
            love.graphics.setFont(mainFont)
            love.graphics.setColor(unpack(color or {1, 1, 1}))
            love.graphics.print(value, contentX + 110, currY - 3)
            currY = currY + 30
        end
        
        -- Difficulty
        local stars = ""
        for s = 1, (selectedStage.difficulty or 1) do stars = stars .. "*" end
        drawStat("DIFFICULTY", stars, {1, 0.8, 0.2})
        
        -- Enemies
        local enemyList = table.concat(selectedStage.enemies or {}, ", ")
        if enemyList == "" then enemyList = "None" end
        drawStat("ENEMIES", enemyList:gsub("^%l", string.upper), {0.8, 0.8, 1})
        
        -- Boss
        local bossName = selectedStage.boss or "None"
        drawStat("BOSS", bossName:gsub("_", " "):gsub("^%l", string.upper), {1, 0.4, 0.4})
        
        -- Survival Time
        local st = selectedStage.survivalTime or 0
        local minutes = math.floor(st / 60)
        local seconds = st % 60
        drawStat("SURVIVAL", string.format("%d:%02d", minutes, seconds), {0.4, 1, 0.4})
        
        currY = currY + 10
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.line(contentX, currY, infoX + infoWidth - 25, currY)
        currY = currY + 20
        
        -- Rewards Section
        love.graphics.setFont(boldFont)
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.print("REWARDS", contentX, currY)
        currY = currY + 30
        
        love.graphics.setFont(smallFont)
        love.graphics.setColor(0.7, 0.7, 0.7)
        local rewards = selectedStage.rewards or {}
        local hasRewards = false
        
        if rewards.unlockStage then
            love.graphics.print("• Next Stage: " .. rewards.unlockStage:gsub("_", " "):gsub("^%l", string.upper), contentX + 10, currY)
            currY = currY + 20
            hasRewards = true
        end
        if rewards.unlockShip then
            love.graphics.print("• New Ship: " .. rewards.unlockShip:gsub("_", " "):gsub("^%l", string.upper), contentX + 10, currY)
            currY = currY + 20
            hasRewards = true
        end
        if rewards.unlockWeapon then
            love.graphics.print("• New Weapon: " .. rewards.unlockWeapon:gsub("_", " "):gsub("^%l", string.upper), contentX + 10, currY)
            currY = currY + 20
            hasRewards = true
        end
        
        if not hasRewards then
            love.graphics.print("• No immediate rewards", contentX + 10, currY)
        end
        
        -- Status Footer
        currY = infoY + infoHeight - 40
        if not self:isUnlocked(selectedStage) then
            love.graphics.setColor(1, 0.2, 0.2)
            love.graphics.setFont(boldFont)
            love.graphics.printf("LOCKED", infoX, currY, infoWidth, "center")
            love.graphics.setFont(smallFont)
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.printf("REQ: Complete " .. (selectedStage.unlockCondition or "???"), infoX, currY + 25, infoWidth, "center")
        elseif self.completedMap[selectedStage.id] then
            love.graphics.setColor(0.4, 1, 0.4)
            love.graphics.setFont(boldFont)
            love.graphics.printf("STAY CLEAR [OK]", infoX, currY, infoWidth, "center")
        else
            love.graphics.setColor(1, 1, 1, math.abs(math.sin(time * 4)))
            love.graphics.setFont(boldFont)
            love.graphics.printf("READY TO LAUNCH", infoX, currY, infoWidth, "center")
        end
    end
    
    -- Controls Hint
    love.graphics.setFont(mainFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("ARROWS: Navigate | Z: Select | X: Back", 0, screenHeight - 40, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
