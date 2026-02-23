local sm = require "states/statemanager"
local dataloader = require "systems/dataloader"
local Menu = require "ui/menu"

local state = {}

function state:enter(saveData)
    self.saveData = saveData or { completedStages = {} }
    local allStages = dataloader.getStages()
    self.unlockedStages = {}
    
    local completedMap = {}
    for _, id in ipairs(self.saveData.completedStages or {}) do
        completedMap[id] = true
    end
    
    for _, stage in ipairs(allStages) do
        local isUnlocked = false
        if stage.unlockCondition == "default" then
            isUnlocked = true
        elseif completedMap[stage.unlockCondition] then
            isUnlocked = true
        end
        
        if isUnlocked then
            table.insert(self.unlockedStages, stage)
        end
    end
    
    self.selectedIndex = 1
    
    -- Create menu names for the component (used differently than usual)
    local stageNames = {}
    for _, stage in ipairs(self.unlockedStages) do
        table.insert(stageNames, stage.name)
    end
    self.menu = Menu.new(stageNames)
end

function state:keypressed(key)
    if key == "left" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.unlockedStages
        end
        self.menu.selectedIndex = self.selectedIndex
    elseif key == "right" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.unlockedStages then
            self.selectedIndex = 1
        end
        self.menu.selectedIndex = self.selectedIndex
    elseif key == "z" then
        local selectedStage = self.unlockedStages[self.selectedIndex]
        if selectedStage then
            sm.switch("ship_select", selectedStage, self.saveData)
        end
    elseif key == "x" then
        sm.switch("save_select")
    end
end

function state:draw()
    love.graphics.clear(0.05, 0.05, 0.1)
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    local titleFont = love.graphics.newFont(48)
    local originalFont = love.graphics.getFont()
    love.graphics.setFont(titleFont)
    love.graphics.printf("SELECT STAGE", 0, screenHeight * 0.1, screenWidth, "center")
    
    -- Current Stage Info
    local stage = self.unlockedStages[self.selectedIndex]
    if stage then
        -- Stage Name
        love.graphics.setFont(love.graphics.newFont(36))
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(stage.name, 0, screenHeight * 0.3, screenWidth, "center")
        
        -- Difficulty
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.printf("Difficulty: " .. stage.difficulty, 0, screenHeight * 0.38, screenWidth, "center")
        
        -- Description
        love.graphics.setFont(love.graphics.newFont(22))
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf(stage.description, screenWidth * 0.2, screenHeight * 0.45, screenWidth * 0.6, "center")
        
        -- Navigation Arrows
        if #self.unlockedStages > 1 then
            love.graphics.setFont(love.graphics.newFont(48))
            love.graphics.setColor(1, 1, 1, math.abs(math.sin(love.timer.getTime() * 4)))
            love.graphics.print("<", screenWidth * 0.15, screenHeight * 0.3)
            love.graphics.print(">", screenWidth * 0.85 - 30, screenHeight * 0.3)
        end
    end
    
    -- Stage progress dots
    local dotCount = #self.unlockedStages
    local dotSpacing = 30
    local totalWidth = (dotCount - 1) * dotSpacing
    local startX = (screenWidth - totalWidth) / 2
    local dotY = screenHeight * 0.7
    
    for i = 1, dotCount do
        if i == self.selectedIndex then
            love.graphics.setColor(1, 1, 1)
            love.graphics.circle("fill", startX + (i-1) * dotSpacing, dotY, 8)
        else
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.circle("line", startX + (i-1) * dotSpacing, dotY, 6)
        end
    end
    
    -- Controls Hint
    love.graphics.setFont(originalFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Left/Right: Change Stage | Z: Select | X: Back", 0, screenHeight - 50, screenWidth, "center")
end

return state
