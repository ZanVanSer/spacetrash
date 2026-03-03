local sm = require "states/statemanager"
local DataLoader = require "systems/dataloader"
local Colors = require "ui/colors"
local Fonts = require "ui/fonts"
local Screen = require "systems/screen"
local Scanlines = require "ui/scanlines"

local state = {}

-- Define weapon evolutions mapping
local evolutions = {
    basic_laser = {
        name = "Hyper Beam",
        requiredPassiveId = "damage_boost",
        requiredPassiveName = "Damage +10%",
        changes = "Increases damage by 100%, gains piercing and increased beam width.",
        evolvedStats = {
            damage = 20,
            fireRate = 0.25,
            bulletSpeed = 600,
            pattern = "Pulse",
            area = 1.5
        }
    }
}

function state:isWeaponUnlocked(weapon)
    if not weapon then return false end
    if weapon.id == "basic_laser" then return true end
    if not self.saveData or not self.saveData.unlockedWeapons then return false end
    for _, unlockedId in ipairs(self.saveData.unlockedWeapons) do
        if unlockedId == weapon.id then return true end
    end
    return false
end

function state:isPassiveUnlocked(passiveId)
    if not self.saveData or not self.saveData.unlockedPassives then return false end
    for _, id in ipairs(self.saveData.unlockedPassives) do
        if id == passiveId then return true end
    end
    return false
end

function state:applyFilter()
    local filtered = {}
    for _, weapon in ipairs(self.allWeapons) do
        local unlocked = self:isWeaponUnlocked(weapon)
        if self.filterIndex == 1 then table.insert(filtered, weapon)
        elseif self.filterIndex == 2 and unlocked then table.insert(filtered, weapon)
        elseif self.filterIndex == 3 and not unlocked then table.insert(filtered, weapon)
        end
    end
    self.weapons = filtered
    self.selectedIndex = 1
    self.bullets = {}
    self.transitionAlpha = 0
    self.slideOffset = 20
end

function state:enter(saveData)
    self.saveData = saveData or {
        unlockedWeapons = {"basic_laser"},
        unlockedPassives = {}
    }
    
    self.allWeapons = DataLoader.getWeapons()
    self.filterIndex = 1
    self.filters = {"All", "Unlocked", "Locked"}
    
    local unlocked = {}
    local locked = {}
    for _, weapon in ipairs(self.allWeapons) do
        if self:isWeaponUnlocked(weapon) then table.insert(unlocked, weapon)
        else table.insert(locked, weapon) end
    end
    
    self.allWeapons = {}
    for _, w in ipairs(unlocked) do table.insert(self.allWeapons, w) end
    for _, w in ipairs(locked) do table.insert(self.allWeapons, w) end
    
    self:applyFilter()
    self.animTimer = 0
    self.transitionAlpha = 1
    self.slideOffset = 0
    
    self.particles = {}
    for i = 1, 20 do
        table.insert(self.particles, {
            x = math.random(Screen.getVirtualWidth()),
            y = math.random(Screen.getVirtualHeight()),
            speed = math.random(20, 50),
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
    
    -- Update preview bullets
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b.y = b.y - b.speed * dt
        b.life = b.life - dt
        if b.life <= 0 then table.remove(self.bullets, i) end
    end
    
    -- Spawn preview bullet
    if #self.weapons > 0 and self.selectedIndex <= #self.weapons then
        local weapon = self.weapons[self.selectedIndex]
        if self:isWeaponUnlocked(weapon) then
            local fireRate = weapon.fireRate or 0.5
            if self.animTimer % fireRate < dt then
                table.insert(self.bullets, {
                    x = Screen.getVirtualWidth() * 0.25,
                    y = Screen.getVirtualHeight() * 0.5,
                    speed = weapon.bulletSpeed or 300,
                    life = 1.2
                })
            end
        end
    end
end

function state:keypressed(key)
    if key == "tab" then
        self.filterIndex = self.filterIndex + 1
        if self.filterIndex > #self.filters then self.filterIndex = 1 end
        self:applyFilter()
    elseif key == "left" or key == "right" then
        if #self.weapons > 0 then
            self.selectedIndex = (key == "left") and (self.selectedIndex - 1) or (self.selectedIndex + 1)
            if self.selectedIndex < 1 then self.selectedIndex = #self.weapons end
            if self.selectedIndex > #self.weapons then self.selectedIndex = 1 end
            self.bullets = {}
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
    
    -- Particles
    for _, p in ipairs(self.particles) do
        Colors.setColor("accent", p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    
    -- Title
    Colors.setColor("accent")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("WEAPON ARCHIVES", 0, 40, screenWidth, "center")
    
    -- Filter
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
    
    if #self.weapons > 0 then
        local weapon = self.weapons[self.selectedIndex]
        local unlocked = self:isWeaponUnlocked(weapon)
        local evo = evolutions[weapon.id]
        local accentColor = (weapon.rarity and weapon.rarity < 50) and "xp" or "accent" -- Gold for rare, cyan for common
        
        love.graphics.push()
        love.graphics.translate(self.slideOffset, 0)
        
        -- Visual Preview
        local previewX, previewY = screenWidth * 0.25, screenHeight * 0.55
        if unlocked then
            Colors.setColor(accentColor, 0.15 * self.transitionAlpha)
            love.graphics.circle("fill", previewX, previewY, 40 + math.sin(self.animTimer * 4) * 8)
            Colors.setColor(accentColor, 0.4 * self.transitionAlpha)
            love.graphics.circle("line", previewX, previewY, 30 + math.sin(self.animTimer * 4) * 5)
            Colors.setColor(accentColor, 0.8 * self.transitionAlpha)
            love.graphics.polygon("fill", previewX, previewY - 20, previewX - 15, previewY + 10, previewX + 15, previewY + 10)
            
            for _, b in ipairs(self.bullets) do
                Colors.setColor(accentColor, b.life * self.transitionAlpha)
                love.graphics.rectangle("fill", b.x - 2, b.y - 5, 4, 10)
            end
        else
            love.graphics.setColor(0.02, 0.05, 0.05, self.transitionAlpha)
            love.graphics.polygon("fill", previewX, previewY - 20, previewX - 15, previewY + 10, previewX + 15, previewY + 10)
            Colors.setColor("danger", 0.5 * self.transitionAlpha)
            love.graphics.setFont(Fonts.getFont("large"))
            love.graphics.printf("LOCKED", previewX - 100, previewY + 100, 200, "center")
        end
        
        -- Info Panel
        local panelX, panelY = screenWidth * 0.5, 115
        local panelW, panelH = screenWidth * 0.45, screenHeight - 180
        love.graphics.setColor(0.05, 0.1, 0.12, 0.85 * self.transitionAlpha)
        love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12)
        Colors.setColor(accentColor, 0.3 * self.transitionAlpha)
        self:drawCornerBrackets(panelX, panelY, panelW, panelH, 25)
        
        local contentX, currY = panelX + 30, panelY + 25
        love.graphics.setFont(Fonts.getFont("large"))
        if unlocked then
            Colors.setColor(accentColor, self.transitionAlpha)
            love.graphics.print(weapon.name:upper(), contentX, currY)
        else
            Colors.setColor("dim", 0.3 * self.transitionAlpha)
            love.graphics.print("UNKNOWN ARMAMENT", contentX, currY)
        end
        currY = currY + 40
        
        local function drawStat(label, value, color)
            love.graphics.setFont(Fonts.getFont("tiny"))
            Colors.setColor("dim", 0.6 * self.transitionAlpha)
            love.graphics.print(label .. ":", contentX, currY)
            love.graphics.setFont(Fonts.getFont("small"))
            Colors.setColor(color[1], color[2], color[3], (unlocked and 1 or 0.15) * self.transitionAlpha)
            love.graphics.print(unlocked and tostring(value) or "???", contentX + 100, currY - 1)
            currY = currY + 20
        end
        drawStat("Damage", weapon.damage, {1, 0.3, 0.3})
        drawStat("Fire Rate", weapon.fireRate .. "s", {0.6, 1, 0.6})
        drawStat("Bullet Speed", weapon.bulletSpeed, {1, 1, 1})
        drawStat("Pattern", (weapon.pattern or "Straight"):gsub("^%l", string.upper), {0.6, 0.6, 1})
        
        if evo then
            currY = currY + 15
            love.graphics.setColor(1, 1, 1, 0.1 * self.transitionAlpha)
            love.graphics.line(contentX, currY, panelX + panelW - 30, currY)
            currY = currY + 15
            love.graphics.setFont(Fonts.getFont("normal"))
            Colors.setColor("xp", self.transitionAlpha)
            love.graphics.print("EVOLUTION: " .. evo.name, contentX, currY)
            currY = currY + 25
            
            local passiveUnlocked = self:isPassiveUnlocked(evo.requiredPassiveId)
            love.graphics.setFont(Fonts.getFont("small"))
            Colors.setColor("dim", self.transitionAlpha)
            love.graphics.print("Requires: ", contentX, currY)
            if passiveUnlocked then
                Colors.setColor("health", self.transitionAlpha)
                love.graphics.print(evo.requiredPassiveName, contentX + 80, currY)
            else
                Colors.setColor("danger", self.transitionAlpha)
                love.graphics.print(evo.requiredPassiveName .. " (Locked)", contentX + 80, currY)
            end
            currY = currY + 30
            
            love.graphics.setFont(Fonts.getFont("tiny"))
            if unlocked and passiveUnlocked then
                Colors.setColor("health", self.transitionAlpha)
                love.graphics.printf("Evolution Available! " .. evo.changes, contentX, currY, panelW - 60, "left")
            else
                Colors.setColor(0.4, 0.4, 0.4, self.transitionAlpha)
                love.graphics.printf("Evolution potential detected. Master base armament and catalyst to transcend.", contentX, currY, panelW - 60, "left")
            end
        end
        love.graphics.pop()
    end
    
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(string.format("Entry %d / %d", self.selectedIndex, #self.weapons), 0, screenHeight - 110, screenWidth, "center")
    
    Scanlines.drawScanlines()
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("TAB: Filter | LEFT/RIGHT: Browse | X: Back", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
