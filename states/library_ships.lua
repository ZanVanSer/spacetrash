local sm = require "states/statemanager"
local DataLoader = require "systems/dataloader"
local ShipVisuals = require "entities/ship_visuals"
local Colors = require "ui/colors"
local Fonts = require "ui/fonts"
local Screen = require "systems/screen"

local state = {}

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

function state:enter(saveData)
    self.saveData = saveData or {
        unlockedShips = {"vanguard"} -- Fallback
    }
    
    local allShips = DataLoader.getShips()
    
    -- Filter and Sort: Unlocked ships first, locked after
    self.ships = {}
    local unlocked = {}
    local locked = {}
    
    for _, ship in ipairs(allShips) do
        if self:isShipUnlocked(ship) then
            table.insert(unlocked, ship)
        else
            table.insert(locked, ship)
        end
    end
    
    for _, s in ipairs(unlocked) do table.insert(self.ships, s) end
    for _, s in ipairs(locked) do table.insert(self.ships, s) end
    
    self.selectedIndex = 1
    self.animTimer = 0
end

function state:update(dt)
    self.animTimer = self.animTimer + dt
end

function state:keypressed(key)
    if key == "left" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.ships
        end
    elseif key == "right" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.ships then
            self.selectedIndex = 1
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
    
    if #self.ships == 0 then
        Colors.setColor("accent")
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.printf("No ship data found.", 0, screenHeight/2, screenWidth, "center")
        Screen.removeScale()
        return
    end
    
    local ship = self.ships[self.selectedIndex]
    local unlocked = self:isShipUnlocked(ship)
    
    -- Title
    Colors.setColor("accent")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("SHIP ARCHIVES", 0, 40, screenWidth, "center")
    
    -- Left Side: Ship Visual Preview
    local previewX = screenWidth * 0.25
    local previewY = screenHeight * 0.5
    local bob = math.sin(self.animTimer * 2) * 10
    local rotation = math.sin(self.animTimer * 1.5) * 0.1
    
    if unlocked then
        ShipVisuals.drawShip(ship.id, previewX, previewY + bob, 3.0, rotation)
    else
        -- Draw as silhouette / grayed out
        love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
        ShipVisuals.drawShip(ship.id, previewX, previewY + bob, 3.0, rotation)
        
        -- LOCKED Overlay
        love.graphics.setFont(Fonts.getFont("large"))
        love.graphics.setColor(1, 0, 0, 0.8 + math.sin(self.animTimer * 5) * 0.2)
        love.graphics.printf("LOCKED", previewX - 100, previewY + 100, 200, "center")
    end
    
    -- Right Side: Information Panel
    local panelX = screenWidth * 0.5
    local panelY = 100
    local panelW = screenWidth * 0.45
    local panelH = screenHeight - 160
    
    love.graphics.setColor(0.05, 0.1, 0.12, 0.8)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12)
    love.graphics.setColor(Colors.getColor("accent", 0.2))
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 12)
    
    local contentX = panelX + 30
    local currY = panelY + 30
    
    -- Ship Name and Class
    love.graphics.setFont(Fonts.getFont("large"))
    if unlocked then
        Colors.setColor("accent")
        love.graphics.print(ship.name:upper(), contentX, currY)
        currY = currY + 30
        Colors.setColor("dim")
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.print(ship.class or "Standard Class", contentX, currY)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.print("UNKNOWN VESSEL", contentX, currY)
        currY = currY + 30
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.print("Class: Redacted", contentX, currY)
    end
    currY = currY + 50
    
    -- Description
    love.graphics.setFont(Fonts.getFont("small"))
    if unlocked then
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.printf(ship.description or "No data available.", contentX, currY, panelW - 60, "left")
    else
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.printf("Scanning... Ship signature recognized. Access denied. Please unlock this ship in the hangar to view technical specifications.", contentX, currY, panelW - 60, "left")
    end
    currY = currY + 80
    
    -- Stats
    local function drawStat(label, value, color)
        love.graphics.setFont(Fonts.getFont("small"))
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(label .. ":", contentX, currY)
        
        love.graphics.setFont(Fonts.getFont("normal"))
        if unlocked then
            love.graphics.setColor(unpack(color or {1, 1, 1}))
            love.graphics.print(tostring(value), contentX + 150, currY - 2)
        else
            love.graphics.setColor(0.15, 0.15, 0.15)
            love.graphics.print("???", contentX + 150, currY - 2)
        end
        currY = currY + 28
    end
    
    drawStat("Max Health", ship.maxHealth, {1, 0.3, 0.3})
    drawStat("Armor", ship.armor, {0.5, 0.5, 1})
    drawStat("Might", math.floor((ship.might or 1) * 100) .. "%", {1, 0.7, 0.2})
    drawStat("Speed", ship.speed, {1, 1, 1})
    drawStat("Area", math.floor((ship.area or 1) * 100) .. "%", {1, 0.9, 0.4})
    
    currY = currY + 10
    local weaponName = (ship.startWeapon or "Unknown"):gsub("_", " "):gsub("^%l", string.upper)
    drawStat("Starting Weapon", weaponName, {1, 1, 0.6})
    
    -- Unlock Condition if locked
    if not unlocked then
        currY = currY + 20
        Colors.setColor("xp")
        love.graphics.setFont(Fonts.getFont("normal"))
        local hint = "Unlock: "
        if ship.unlockCondition == "default" then hint = hint .. "Starter Ship"
        elseif ship.unlockCondition == "stage_1" then hint = hint .. "Complete Stage 1"
        elseif ship.unlockCondition == "level_10" then hint = hint .. "Reach Level 10"
        else hint = hint .. (ship.unlockCondition or "Locked")
        end
        love.graphics.print(hint, contentX, currY)
    end
    
    -- Navigation Bottom Info
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(string.format("Ship %d of %d", self.selectedIndex, #self.ships), 0, screenHeight - 110, screenWidth, "center")
    
    -- Controls Hint
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("LEFT/RIGHT: Browse Ships | X: Back to Library", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
