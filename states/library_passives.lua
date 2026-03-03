local sm = require "states/statemanager"
local DataLoader = require "systems/dataloader"
local Colors = require "ui/colors"
local Fonts = require "ui/fonts"
local Screen = require "systems/screen"

local state = {}

function state:isPassiveUnlocked(passive)
    if not passive then return false end
    if not self.saveData or not self.saveData.unlockedPassives then return true end
    if #self.saveData.unlockedPassives == 0 then return true end
    
    for _, unlockedId in ipairs(self.saveData.unlockedPassives) do
        if unlockedId == passive.id then
            return true
        end
    end
    return false
end

function state:applyFilter()
    local filtered = {}
    for _, passive in ipairs(self.allPassives) do
        local unlocked = self:isPassiveUnlocked(passive)
        if self.filterIndex == 1 then -- All
            table.insert(filtered, passive)
        elseif self.filterIndex == 2 and unlocked then -- Unlocked
            table.insert(filtered, passive)
        elseif self.filterIndex == 3 and not unlocked then -- Locked
            table.insert(filtered, passive)
        end
    end
    self.passives = filtered
    self.selectedIndex = 1
end

function state:enter(saveData)
    self.saveData = saveData or {
        unlockedPassives = {}
    }
    
    self.allPassives = DataLoader.getUpgrades()
    self.filterIndex = 1 -- 1: All, 2: Unlocked, 3: Locked
    self.filters = {"All", "Unlocked", "Locked"}
    
    -- Filter and Sort initial list
    local unlocked = {}
    local locked = {}
    for _, passive in ipairs(self.allPassives) do
        if self:isPassiveUnlocked(passive) then
            table.insert(unlocked, passive)
        else
            table.insert(locked, passive)
        end
    end
    
    self.allPassives = {}
    for _, p in ipairs(unlocked) do table.insert(self.allPassives, p) end
    for _, p in ipairs(locked) do table.insert(self.allPassives, p) end
    
    self:applyFilter()
    self.animTimer = 0
end

function state:update(dt)
    self.animTimer = self.animTimer + dt
end

function state:keypressed(key)
    if key == "tab" then
        self.filterIndex = self.filterIndex + 1
        if self.filterIndex > #self.filters then
            self.filterIndex = 1
        end
        self:applyFilter()
    elseif key == "left" then
        if #self.passives > 0 then
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then
                self.selectedIndex = #self.passives
            end
        end
    elseif key == "right" then
        if #self.passives > 0 then
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > #self.passives then
                self.selectedIndex = 1
            end
        end
    elseif key == "x" or key == "escape" then
        sm.switch("library", self.saveData)
    end
end

function state:draw()
    Screen.applyScale()
    local oldFont = love.graphics.getFont()
    local screenWidth = Screen.getVirtualWidth()
    local screenHeight = Screen.getVirtualHeight()
    
    -- Dark background
    Colors.setColor("bg")
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Title
    Colors.setColor("accent")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("PASSIVE ARCHIVES", 0, 40, screenWidth, "center")
    
    -- Filter Display
    love.graphics.setFont(Fonts.getFont("small"))
    local filterX = screenWidth / 2 - 120
    local filterY = 85
    Colors.setColor("dim")
    love.graphics.print("Filter [TAB]:", filterX, filterY)
    
    for i, f in ipairs(self.filters) do
        local x = filterX + 85 + (i-1) * 70
        if i == self.filterIndex then
            Colors.setColor("accent")
            love.graphics.print("[" .. f .. "]", x, filterY)
        else
            Colors.setColor("dim", 0.5)
            love.graphics.print(f, x + 5, filterY)
        end
    end
    
    if #self.passives == 0 then
        Colors.setColor("accent", 0.6)
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.printf("No modules match the current filter.", 0, screenHeight/2, screenWidth, "center")
        
        -- Controls Hint
        love.graphics.setFont(Fonts.getFont("small"))
        Colors.setColor("dim")
        love.graphics.printf("TAB: Change Filter | X: Back to Library", 0, screenHeight - 50, screenWidth, "center")
        
        Screen.removeScale()
        return
    end
    
    local passive = self.passives[self.selectedIndex]
    local unlocked = self:isPassiveUnlocked(passive)
    
    -- Left Side: Passive Item Icon
    local iconX = screenWidth * 0.25
    local iconY = screenHeight * 0.5
    local pulse = math.sin(self.animTimer * 2) * 5
    
    if unlocked then
        Colors.setColor("accent", 0.3)
        love.graphics.circle("fill", iconX, iconY, 50 + pulse)
        Colors.setColor("accent", 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", iconX, iconY, 55 + pulse)
        
        love.graphics.polygon("fill", iconX, iconY - 30, iconX - 30, iconY, iconX, iconY + 30, iconX + 30, iconY)
        Colors.setColor("white", 0.5)
        love.graphics.polygon("line", iconX, iconY - 30, iconX - 30, iconY, iconX, iconY + 30, iconX + 30, iconY)
    else
        Colors.setColor(0.1, 0.1, 0.1, 0.8)
        love.graphics.circle("fill", iconX, iconY, 50)
        love.graphics.polygon("fill", iconX, iconY - 30, iconX - 30, iconY, iconX, iconY + 30, iconX + 30, iconY)
        
        love.graphics.setFont(Fonts.getFont("large"))
        love.graphics.setColor(1, 0, 0, 0.8 + math.sin(self.animTimer * 5) * 0.2)
        love.graphics.printf("LOCKED", iconX - 100, iconY + 90, 200, "center")
    end
    
    -- Right Side: Information Panel
    local panelX = screenWidth * 0.5
    local panelY = 110
    local panelW = screenWidth * 0.45
    local panelH = screenHeight - 170
    
    love.graphics.setColor(0.05, 0.1, 0.12, 0.8)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12)
    love.graphics.setColor(Colors.getColor("accent", 0.2))
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 12)
    
    local contentX = panelX + 30
    local currY = panelY + 30
    
    -- Name and Rarity
    love.graphics.setFont(Fonts.getFont("large"))
    if unlocked then
        Colors.setColor("accent")
        love.graphics.print(passive.name:upper(), contentX, currY)
        currY = currY + 30
        Colors.setColor("xp")
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.print("Rarity: " .. (passive.rarity or 100), contentX, currY)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.print("UNKNOWN MODULE", contentX, currY)
        currY = currY + 30
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.print("Rarity: ???", contentX, currY)
    end
    currY = currY + 50
    
    -- Description
    love.graphics.setFont(Fonts.getFont("small"))
    if unlocked then
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf(passive.description or "No data available.", contentX, currY, panelW - 60, "left")
    else
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.printf("Scanning augment signature... Access denied. Passive module must be retrieved in-game to analyze technical properties.", contentX, currY, panelW - 60, "left")
    end
    currY = currY + 65
    
    -- Effects per Level
    love.graphics.setFont(Fonts.getFont("normal"))
    if unlocked then
        Colors.setColor("accent")
        love.graphics.print("MODULE PROGRESSION", contentX, currY)
        currY = currY + 30
        
        love.graphics.setFont(Fonts.getFont("small"))
        love.graphics.setColor(0.7, 0.7, 0.7)
        
        local baseVal = passive.effect and passive.effect.value or 1.1
        local isMult = passive.effect and passive.effect.type == "stat_mult"
        local step = isMult and 0.05 or 5
        
        for i = 1, 5 do
            local val = baseVal + (i-1) * step
            local valStr = isMult and string.format("+%d%%", (val-1)*100) or string.format("+%d", val)
            love.graphics.print(string.format("Lv%d: %s Potency", i, valStr), contentX + 10, currY)
            currY = currY + 22
        end
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.print("PROGRESSION: ENCRYPTED", contentX, currY)
    end
    
    -- Unlock Condition
    if not unlocked then
        currY = panelY + panelH - 60
        Colors.setColor("xp")
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.print("Unlock: " .. (passive.unlockCondition or "Common Droplet"), contentX, currY)
    end
    
    -- Navigation Bottom Info
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(string.format("Passive %d of %d", self.selectedIndex, #self.passives), 0, screenHeight - 110, screenWidth, "center")
    
    -- Controls Hint
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("TAB: Filter | LEFT/RIGHT: Browse | X: Back", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
