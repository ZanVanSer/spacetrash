local sm = require "states/statemanager"
local DataLoader = require "systems/dataloader"
local ShipVisuals = require "entities/ship_visuals"
local Colors = require "ui/colors"
local Fonts = require "ui/fonts"
local Screen = require "systems/screen"
local Scanlines = require "ui/scanlines"

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

function state:applyFilter()
    local filtered = {}
    for _, ship in ipairs(self.allShips) do
        local unlocked = self:isShipUnlocked(ship)
        if self.filterIndex == 1 then -- All
            table.insert(filtered, ship)
        elseif self.filterIndex == 2 and unlocked then -- Unlocked
            table.insert(filtered, ship)
        elseif self.filterIndex == 3 and not unlocked then -- Locked
            table.insert(filtered, ship)
        end
    end
    self.ships = filtered
    self.selectedIndex = 1
    self.transitionAlpha = 0
    self.slideOffset = 20
end

function state:enter(saveData)
    self.saveData = saveData or {
        unlockedShips = {"vanguard"}
    }
    
    self.allShips = DataLoader.getShips()
    self.filterIndex = 1
    self.filters = {"All", "Unlocked", "Locked"}
    
    local unlocked = {}
    local locked = {}
    for _, ship in ipairs(self.allShips) do
        if self:isShipUnlocked(ship) then
            table.insert(unlocked, ship)
        else
            table.insert(locked, ship)
        end
    end
    
    self.allShips = {}
    for _, s in ipairs(unlocked) do table.insert(self.allShips, s) end
    for _, s in ipairs(locked) do table.insert(self.allShips, s) end
    
    self:applyFilter()
    self.animTimer = 0
    self.transitionAlpha = 1
    self.slideOffset = 0
    
    -- Background particles
    self.particles = {}
    for i = 1, 25 do
        table.insert(self.particles, {
            x = math.random(Screen.getVirtualWidth()),
            y = math.random(Screen.getVirtualHeight()),
            speed = math.random(15, 45),
            size = math.random(1, 2),
            alpha = math.random() * 0.3
        })
    end
end

function state:update(dt)
    self.animTimer = self.animTimer + dt
    self.transitionAlpha = math.min(1, self.transitionAlpha + dt * 5)
    self.slideOffset = self.slideOffset * math.exp(-12 * dt)
    
    for _, p in ipairs(self.particles) do
        p.y = p.y + p.speed * dt
        if p.y > Screen.getVirtualHeight() then p.y = -10 end
    end
end

function state:keypressed(key)
    if key == "tab" then
        self.filterIndex = self.filterIndex + 1
        if self.filterIndex > #self.filters then self.filterIndex = 1 end
        self:applyFilter()
    elseif key == "left" or key == "right" then
        if #self.ships > 0 then
            self.selectedIndex = (key == "left") and (self.selectedIndex - 1) or (self.selectedIndex + 1)
            if self.selectedIndex < 1 then self.selectedIndex = #self.ships end
            if self.selectedIndex > #self.ships then self.selectedIndex = 1 end
            self.transitionAlpha = 0
            self.slideOffset = (key == "left") and -40 or 40
        end
    elseif key == "x" or key == "escape" then
        sm.switch("library", self.saveData)
    end
end

function state:drawCornerBrackets(x, y, w, h, size)
    local s = size or 15
    love.graphics.line(x, y + s, x, y, x + s, y)
    love.graphics.line(x + w - s, y, x + w, y, x + w, y + s)
    love.graphics.line(x, y + h - s, x, y + h, x + s, y + h)
    love.graphics.line(x + w - s, y + h, x + w, y + h, x + w, y + h - s)
end

function state:draw()
    Screen.applyScale()
    local oldFont = love.graphics.getFont()
    local screenWidth = Screen.getVirtualWidth()
    local screenHeight = Screen.getVirtualHeight()
    
    Colors.setColor("bg")
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Background Particles
    for _, p in ipairs(self.particles) do
        Colors.setColor("accent", p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    
    -- Title
    Colors.setColor("accent")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("SHIP ARCHIVES", 0, 40, screenWidth, "center")
    
    -- Filter
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
    
    if #self.ships > 0 then
        local ship = self.ships[self.selectedIndex]
        local unlocked = self:isShipUnlocked(ship)
        
        love.graphics.push()
        love.graphics.translate(self.slideOffset, 0)
        
        -- Preview
        local previewX, previewY = screenWidth * 0.25, screenHeight * 0.5
        local bob = math.sin(self.animTimer * 2) * 10
        
        if unlocked then
            Colors.setColor("accent", 0.1 * self.transitionAlpha)
            love.graphics.circle("fill", previewX, previewY + bob, 70 + math.sin(self.animTimer * 4) * 15)
            ShipVisuals.drawShip(ship.id, previewX, previewY + bob, 3.0, math.sin(self.animTimer * 1.5) * 0.1)
        else
            love.graphics.setColor(0.02, 0.05, 0.05, self.transitionAlpha)
            ShipVisuals.drawShip(ship.id, previewX, previewY + bob, 3.0, 0)
            Colors.setColor("danger", 0.5 * self.transitionAlpha)
            love.graphics.setFont(Fonts.getFont("large"))
            love.graphics.printf("LOCKED", previewX - 100, previewY + 100, 200, "center")
        end
        
        -- Info Panel
        local panelX, panelY = screenWidth * 0.5, 115
        local panelW, panelH = screenWidth * 0.45, screenHeight - 180
        
        love.graphics.setColor(0.05, 0.1, 0.12, 0.85 * self.transitionAlpha)
        love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12)
        Colors.setColor("accent", 0.3 * self.transitionAlpha)
        love.graphics.setLineWidth(2)
        self:drawCornerBrackets(panelX, panelY, panelW, panelH, 25)
        
        local contentX, currY = panelX + 30, panelY + 30
        love.graphics.setFont(Fonts.getFont("large"))
        if unlocked then
            Colors.setColor("accent", self.transitionAlpha)
            love.graphics.print(ship.name:upper(), contentX, currY)
            currY = currY + 30
            Colors.setColor("dim", self.transitionAlpha)
            love.graphics.setFont(Fonts.getFont("normal"))
            love.graphics.print(ship.class or "Standard Class", contentX, currY)
        else
            Colors.setColor("dim", 0.3 * self.transitionAlpha)
            love.graphics.print("UNKNOWN VESSEL", contentX, currY)
            currY = currY + 30
            love.graphics.setFont(Fonts.getFont("normal"))
            love.graphics.print("Class: [REDACTED]", contentX, currY)
        end
        currY = currY + 50
        
        love.graphics.setFont(Fonts.getFont("small"))
        Colors.setColor("white", (unlocked and 0.9 or 0.2) * self.transitionAlpha)
        local desc = unlocked and (ship.description or "") or "Technical data restricted. Please secure pilot clearance."
        love.graphics.printf(desc, contentX, currY, panelW - 60, "left")
        currY = currY + 80
        
        local function drawStat(label, value, color)
            Colors.setColor("dim", 0.6 * self.transitionAlpha)
            love.graphics.print(label .. ":", contentX, currY)
            Colors.setColor(color[1], color[2], color[3], (unlocked and 1 or 0.15) * self.transitionAlpha)
            love.graphics.print(unlocked and tostring(value) or "???", contentX + 150, currY)
            currY = currY + 28
        end
        drawStat("Max Health", ship.maxHealth, {1, 0.3, 0.3})
        drawStat("Armor", ship.armor, {0.5, 0.5, 1})
        drawStat("Might", math.floor((ship.might or 1) * 100) .. "%", {1, 0.7, 0.2})
        drawStat("Speed", ship.speed, {1, 1, 1})
        
        if not unlocked then
            currY = currY + 20
            Colors.setColor("xp", self.transitionAlpha)
            love.graphics.print("Unlock: " .. (ship.unlockCondition or "Locked"), contentX, currY)
        end
        love.graphics.pop()
    end
    
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(string.format("Entry %d / %d", self.selectedIndex, #self.ships), 0, screenHeight - 110, screenWidth, "center")
    
    Scanlines.drawScanlines()
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("TAB: Filter | LEFT/RIGHT: Browse | X: Back", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
