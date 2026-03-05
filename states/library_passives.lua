local sm = require "states/statemanager"
local DataLoader = require "systems/dataloader"
local Colors = require "ui.colors"
local Fonts = require "ui.fonts"
local Screen = require "systems.screen"
local Scanlines = require "ui.scanlines"
local PassiveIcons = require "ui.passive_icons"

local state = {}

function state:isPassiveUnlocked(passive)
    if not passive then return false end
    if not self.saveData or not self.saveData.unlockedPassives then return true end
    if #self.saveData.unlockedPassives == 0 then return true end
    for _, unlockedId in ipairs(self.saveData.unlockedPassives) do
        if unlockedId == passive.id then return true end
    end
    return false
end

function state:applyFilter()
    local filtered = {}
    for _, passive in ipairs(self.allPassives) do
        local unlocked = self:isPassiveUnlocked(passive)
        if self.filterIndex == 1 then table.insert(filtered, passive)
        elseif self.filterIndex == 2 and unlocked then table.insert(filtered, passive)
        elseif self.filterIndex == 3 and not unlocked then table.insert(filtered, passive)
        end
    end
    self.passives = filtered
    self.selectedIndex = 1
    self.transitionAlpha = 0
    self.slideOffset = 20
end

function state:enter(saveData)
    self.saveData = saveData or { unlockedPassives = {} }
    self.allPassives = DataLoader.getPassives()
    self.filterIndex = 1
    self.filters = {"All", "Unlocked", "Locked"}
    
    local unlocked, locked = {}, {}
    for _, passive in ipairs(self.allPassives) do
        if self:isPassiveUnlocked(passive) then table.insert(unlocked, passive)
        else table.insert(locked, passive) end
    end
    self.allPassives = {}
    for _, p in ipairs(unlocked) do table.insert(self.allPassives, p) end
    for _, p in ipairs(locked) do table.insert(self.allPassives, p) end
    
    self:applyFilter()
    self.animTimer = 0
    self.transitionAlpha = 1
    self.slideOffset = 0
    
    self.particles = {}
    for i = 1, 20 do
        table.insert(self.particles, {
            x = math.random(Screen.getVirtualWidth()),
            y = math.random(Screen.getVirtualHeight()),
            speed = math.random(10, 30),
            size = math.random(1, 2),
            alpha = math.random() * 0.2
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
        if #self.passives > 0 then
            self.selectedIndex = (key == "left") and (self.selectedIndex - 1) or (self.selectedIndex + 1)
            if self.selectedIndex < 1 then self.selectedIndex = #self.passives end
            if self.selectedIndex > #self.passives then self.selectedIndex = 1 end
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
    local screenWidth, screenHeight = Screen.getVirtualWidth(), Screen.getVirtualHeight()
    
    Colors.setColor("bg")
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    for _, p in ipairs(self.particles) do
        Colors.setColor("accent", p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    
    Colors.setColor("accent")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("PASSIVE ARCHIVES", 0, 40, screenWidth, "center")
    
    love.graphics.setFont(Fonts.getFont("small"))
    local filterX, filterY = screenWidth / 2 - 120, 85
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
    
    if #self.passives > 0 then
        local passive = self.passives[self.selectedIndex]
        local unlocked = self:isPassiveUnlocked(passive)
        
        love.graphics.push()
        love.graphics.translate(self.slideOffset, 0)
        
        local iconX, iconY = screenWidth * 0.25, screenHeight * 0.5
        local iconScale = 3.5
        
        if unlocked then
            -- Pulsing background glow
            local pulse = math.sin(self.animTimer * 2.5) * 0.1
            Colors.setColor("accent", 0.1 * self.transitionAlpha)
            love.graphics.circle("fill", iconX, iconY, 70 + pulse * 100)
            
            -- Draw large passive icon
            PassiveIcons.drawPassiveIcon(passive.id, iconX, iconY, iconScale * (1.0 + pulse))
        else
            -- Locked: Draw icon grayed out
            love.graphics.push("all")
            PassiveIcons.drawPassiveIcon(passive.id, iconX, iconY, iconScale)
            -- Dimming overlay
            love.graphics.setColor(0, 0, 0, 0.7 * self.transitionAlpha)
            love.graphics.circle("fill", iconX, iconY, 60)
            love.graphics.pop()
            
            Colors.setColor("danger", 0.5 * self.transitionAlpha)
            love.graphics.setFont(Fonts.getFont("large"))
            love.graphics.printf("LOCKED", iconX - 100, iconY + 100, 200, "center")
        end
        
        local panelX, panelY = screenWidth * 0.5, 115
        local panelW, panelH = screenWidth * 0.45, screenHeight - 180
        love.graphics.setColor(0.05, 0.1, 0.12, 0.85 * self.transitionAlpha)
        love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12)
        Colors.setColor("accent", 0.3 * self.transitionAlpha)
        self:drawCornerBrackets(panelX, panelY, panelW, panelH, 25)
        
        local contentX, currY = panelX + 30, panelY + 30
        love.graphics.setFont(Fonts.getFont("large"))
        if unlocked then
            Colors.setColor("accent", self.transitionAlpha)
            love.graphics.print(passive.name:upper(), contentX, currY)
            currY = currY + 30
            Colors.setColor("xp", self.transitionAlpha)
            love.graphics.setFont(Fonts.getFont("normal"))
            love.graphics.print("Rarity: " .. (passive.rarity or 100), contentX, currY)
        else
            Colors.setColor("dim", 0.3 * self.transitionAlpha)
            love.graphics.print("UNKNOWN MODULE", contentX, currY)
            currY = currY + 30
            love.graphics.setFont(Fonts.getFont("normal"))
            love.graphics.print("Rarity: ???", contentX, currY)
        end
        currY = currY + 50
        
        love.graphics.setFont(Fonts.getFont("small"))
        Colors.setColor("white", (unlocked and 0.9 or 0.2) * self.transitionAlpha)
        local desc = unlocked and (passive.description or "") or "Encrypted augment data. Field retrieval required for analysis."
        love.graphics.printf(desc, contentX, currY, panelW - 60, "left")
        currY = currY + 65
        
        if unlocked then
            Colors.setColor("accent", self.transitionAlpha)
            love.graphics.setFont(Fonts.getFont("normal"))
            love.graphics.print("MODULE PROGRESSION", contentX, currY)
            currY = currY + 30
            love.graphics.setFont(Fonts.getFont("small"))
            Colors.setColor("dim", self.transitionAlpha)
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
            Colors.setColor("dim", 0.3 * self.transitionAlpha)
            love.graphics.print("PROGRESSION: ENCRYPTED", contentX, currY)
        end
        love.graphics.pop()
    end
    
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(string.format("Entry %d / %d", self.selectedIndex, #self.passives), 0, screenHeight - 110, screenWidth, "center")
    Scanlines.drawScanlines()
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("TAB: Filter | LEFT/RIGHT: Browse | X: Back", 0, screenHeight - 50, screenWidth, "center")
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
