local sm = require "states/statemanager"
local DataLoader = require "systems/dataloader"
local Colors = require "ui/colors"
local Fonts = require "ui/fonts"
local Screen = require "systems/screen"

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
    -- Basic laser is always unlocked
    if weapon.id == "basic_laser" then return true end
    if not self.saveData or not self.saveData.unlockedWeapons then return false end
    for _, unlockedId in ipairs(self.saveData.unlockedWeapons) do
        if unlockedId == weapon.id then
            return true
        end
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
        if self.filterIndex == 1 then -- All
            table.insert(filtered, weapon)
        elseif self.filterIndex == 2 and unlocked then -- Unlocked
            table.insert(filtered, weapon)
        elseif self.filterIndex == 3 and not unlocked then -- Locked
            table.insert(filtered, weapon)
        end
    end
    self.weapons = filtered
    self.selectedIndex = 1
    self.bullets = {}
end

function state:enter(saveData)
    self.saveData = saveData or {
        unlockedWeapons = {"basic_laser"},
        unlockedPassives = {}
    }
    
    self.allWeapons = DataLoader.getWeapons()
    self.filterIndex = 1 -- 1: All, 2: Unlocked, 3: Locked
    self.filters = {"All", "Unlocked", "Locked"}
    
    -- Sort initial list: Unlocked first for "All" view
    local unlocked = {}
    local locked = {}
    for _, weapon in ipairs(self.allWeapons) do
        if self:isWeaponUnlocked(weapon) then
            table.insert(unlocked, weapon)
        else
            table.insert(locked, weapon)
        end
    end
    
    self.allWeapons = {}
    for _, w in ipairs(unlocked) do table.insert(self.allWeapons, w) end
    for _, w in ipairs(locked) do table.insert(self.allWeapons, w) end
    
    self:applyFilter()
    self.animTimer = 0
    self.bullets = {}
end

function state:update(dt)
    self.animTimer = self.animTimer + dt
    
    -- Update preview bullets
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b.y = b.y - b.speed * dt
        b.life = b.life - dt
        if b.life <= 0 then
            table.remove(self.bullets, i)
        end
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
                    life = 1.5
                })
            end
        end
    end
end

function state:keypressed(key)
    if key == "tab" then
        self.filterIndex = self.filterIndex + 1
        if self.filterIndex > #self.filters then
            self.filterIndex = 1
        end
        self:applyFilter()
    elseif key == "left" then
        if #self.weapons > 0 then
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then
                self.selectedIndex = #self.weapons
            end
            self.bullets = {}
        end
    elseif key == "right" then
        if #self.weapons > 0 then
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > #self.weapons then
                self.selectedIndex = 1
            end
            self.bullets = {}
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
    love.graphics.printf("WEAPON ARCHIVES", 0, 40, screenWidth, "center")
    
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
    
    if #self.weapons == 0 then
        Colors.setColor("accent", 0.6)
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.printf("No weapons match the current filter.", 0, screenHeight/2, screenWidth, "center")
        
        -- Controls Hint
        love.graphics.setFont(Fonts.getFont("small"))
        Colors.setColor("dim")
        love.graphics.printf("TAB: Change Filter | X: Back to Library", 0, screenHeight - 50, screenWidth, "center")
        
        Screen.removeScale()
        return
    end
    
    local weapon = self.weapons[self.selectedIndex]
    local unlocked = self:isWeaponUnlocked(weapon)
    local evo = evolutions[weapon.id]
    
    -- Left Side: Weapon Visual & Firing Preview
    local previewX = screenWidth * 0.25
    local previewY = screenHeight * 0.55
    
    if unlocked then
        Colors.setColor("accent", 0.4)
        love.graphics.circle("line", previewX, previewY, 30 + math.sin(self.animTimer * 4) * 5)
        Colors.setColor("accent", 0.8)
        love.graphics.polygon("fill", previewX, previewY - 20, previewX - 15, previewY + 10, previewX + 15, previewY + 10)
        
        -- Bullets
        for _, b in ipairs(self.bullets) do
            Colors.setColor("accent", b.life)
            love.graphics.rectangle("fill", b.x - 2, b.y - 5, 4, 10)
        end
    else
        Colors.setColor(0.1, 0.1, 0.1, 0.8)
        love.graphics.polygon("fill", previewX, previewY - 20, previewX - 15, previewY + 10, previewX + 15, previewY + 10)
        
        -- LOCKED Overlay
        love.graphics.setFont(Fonts.getFont("large"))
        love.graphics.setColor(1, 0, 0, 0.8 + math.sin(self.animTimer * 5) * 0.2)
        love.graphics.printf("LOCKED", previewX - 100, previewY + 100, 200, "center")
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
    local currY = panelY + 25
    
    -- Weapon Name
    love.graphics.setFont(Fonts.getFont("large"))
    if unlocked then
        Colors.setColor("accent")
        love.graphics.print(weapon.name:upper(), contentX, currY)
        currY = currY + 30
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.print("UNKNOWN ARMAMENT", contentX, currY)
        currY = currY + 30
    end
    
    -- Stats
    local function drawStat(label, value, color)
        love.graphics.setFont(Fonts.getFont("tiny"))
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(label .. ":", contentX, currY)
        
        love.graphics.setFont(Fonts.getFont("small"))
        if unlocked then
            love.graphics.setColor(unpack(color or {1, 1, 1}))
            love.graphics.print(tostring(value), contentX + 100, currY - 1)
        else
            love.graphics.setColor(0.15, 0.15, 0.15)
            love.graphics.print("???", contentX + 100, currY - 1)
        end
        currY = currY + 20
    end
    
    drawStat("Damage", weapon.damage, {1, 0.3, 0.3})
    drawStat("Fire Rate", weapon.fireRate .. "s", {0.6, 1, 0.6})
    drawStat("Bullet Speed", weapon.bulletSpeed, {1, 1, 1})
    drawStat("Pattern", (weapon.pattern or "Straight"):gsub("^%l", string.upper), {0.6, 0.6, 1})
    
    -- Evolution Section
    if evo then
        currY = currY + 15
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.line(contentX, currY, panelX + panelW - 30, currY)
        currY = currY + 15
        
        love.graphics.setFont(Fonts.getFont("normal"))
        Colors.setColor("xp")
        love.graphics.print("EVOLUTION: " .. evo.name, contentX, currY)
        currY = currY + 25
        
        -- Required Passive
        local passiveUnlocked = self:isPassiveUnlocked(evo.requiredPassiveId)
        love.graphics.setFont(Fonts.getFont("small"))
        Colors.setColor("dim")
        love.graphics.print("Requires: ", contentX, currY)
        
        if passiveUnlocked then
            Colors.setColor("health")
            love.graphics.print(evo.requiredPassiveName, contentX + 80, currY)
        else
            Colors.setColor("danger")
            love.graphics.print(evo.requiredPassiveName .. " (Locked)", contentX + 80, currY)
        end
        currY = currY + 30
        
        -- Evolution Details
        if unlocked and passiveUnlocked then
            Colors.setColor("health")
            love.graphics.setFont(Fonts.getFont("tiny"))
            love.graphics.printf("Evolution Available! " .. evo.changes, contentX, currY, panelW - 60, "left")
            currY = currY + 45
            
            -- Evolved Stats Preview
            local function drawEvoStat(label, value, base)
                love.graphics.setFont(Fonts.getFont("tiny"))
                Colors.setColor("dim")
                love.graphics.print(label .. ":", contentX, currY)
                Colors.setColor("health")
                love.graphics.print(tostring(base) .. " -> " .. tostring(value), contentX + 100, currY)
                currY = currY + 15
            end
            
            drawEvoStat("Evo Damage", evo.evolvedStats.damage, weapon.damage)
            drawEvoStat("Evo Pattern", evo.evolvedStats.pattern, weapon.pattern)
        else
            love.graphics.setFont(Fonts.getFont("tiny"))
            Colors.setColor(0.4, 0.4, 0.4)
            love.graphics.printf("Evolution potential detected. Master the base armament and acquire the " .. evo.requiredPassiveName .. " to transcend.", contentX, currY, panelW - 60, "left")
        end
    end
    
    -- Navigation Bottom Info
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(string.format("Weapon %d of %d", self.selectedIndex, #self.weapons), 0, screenHeight - 110, screenWidth, "center")
    
    -- Controls Hint
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("TAB: Filter | LEFT/RIGHT: Browse | X: Back", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
