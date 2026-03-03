local sm = require "states/statemanager"
local DataLoader = require "systems/dataloader"
local Colors = require "ui/colors"
local Fonts = require "ui/fonts"
local Screen = require "systems/screen"

local state = {}

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

function state:enter(saveData)
    self.saveData = saveData or {
        unlockedWeapons = {"basic_laser"}
    }
    
    local allWeapons = DataLoader.getWeapons()
    
    -- Filter and Sort: Unlocked first, then locked
    self.weapons = {}
    local unlocked = {}
    local locked = {}
    
    for _, weapon in ipairs(allWeapons) do
        if self:isWeaponUnlocked(weapon) then
            table.insert(unlocked, weapon)
        else
            table.insert(locked, weapon)
        end
    end
    
    for _, w in ipairs(unlocked) do table.insert(self.weapons, w) end
    for _, w in ipairs(locked) do table.insert(self.weapons, w) end
    
    self.selectedIndex = 1
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
    if #self.weapons > 0 then
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
    if key == "left" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.weapons
        end
        self.bullets = {} -- Clear preview on change
    elseif key == "right" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.weapons then
            self.selectedIndex = 1
        end
        self.bullets = {} -- Clear preview on change
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
    
    if #self.weapons == 0 then
        Colors.setColor("accent")
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.printf("No weapon data found.", 0, screenHeight/2, screenWidth, "center")
        Screen.removeScale()
        return
    end
    
    local weapon = self.weapons[self.selectedIndex]
    local unlocked = self:isWeaponUnlocked(weapon)
    
    -- Title
    Colors.setColor("accent")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("WEAPON ARCHIVES", 0, 40, screenWidth, "center")
    
    -- Left Side: Weapon Visual & Firing Preview
    local previewX = screenWidth * 0.25
    local previewY = screenHeight * 0.55
    
    -- Draw weapon "base"
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
    local panelY = 100
    local panelW = screenWidth * 0.45
    local panelH = screenHeight - 160
    
    love.graphics.setColor(0.05, 0.1, 0.12, 0.8)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12)
    love.graphics.setColor(Colors.getColor("accent", 0.2))
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 12)
    
    local contentX = panelX + 30
    local currY = panelY + 30
    
    -- Weapon Name and Rarity
    love.graphics.setFont(Fonts.getFont("large"))
    if unlocked then
        Colors.setColor("accent")
        love.graphics.print(weapon.name:upper(), contentX, currY)
        currY = currY + 30
        Colors.setColor("xp") -- Use XP color for rarity/type info
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.print("Rarity: Common", contentX, currY)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.print("UNKNOWN ARMAMENT", contentX, currY)
        currY = currY + 30
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.print("Rarity: Unknown", contentX, currY)
    end
    currY = currY + 50
    
    -- Stats
    local function drawStat(label, value, color)
        love.graphics.setFont(Fonts.getFont("small"))
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(label .. ":", contentX, currY)
        
        love.graphics.setFont(Fonts.getFont("normal"))
        if unlocked then
            love.graphics.setColor(unpack(color or {1, 1, 1}))
            love.graphics.print(tostring(value), contentX + 130, currY - 2)
        else
            love.graphics.setColor(0.15, 0.15, 0.15)
            love.graphics.print("???", contentX + 130, currY - 2)
        end
        currY = currY + 24
    end
    
    drawStat("Damage", weapon.damage, {1, 0.3, 0.3})
    drawStat("Fire Rate", weapon.fireRate .. "s", {0.6, 1, 0.6})
    drawStat("Bullet Speed", weapon.bulletSpeed, {1, 1, 1})
    drawStat("Pattern", (weapon.pattern or "Straight"):gsub("^%l", string.upper), {0.6, 0.6, 1})
    drawStat("Area", (weapon.area or 1.0), {1, 0.9, 0.4})
    
    currY = currY + 20
    
    -- Level Progression
    love.graphics.setFont(Fonts.getFont("normal"))
    if unlocked then
        Colors.setColor("accent")
        love.graphics.print("UPGRADES", contentX, currY)
        currY = currY + 25
        love.graphics.setFont(Fonts.getFont("small"))
        love.graphics.setColor(0.8, 0.8, 0.8)
        local levels = {
            "Lv2: +20% Damage",
            "Lv3: +1 Projectile",
            "Lv4: +10% Fire Rate",
            "Lv5: +30% Area"
        }
        for _, lvl in ipairs(levels) do
            love.graphics.print(lvl, contentX + 10, currY)
            currY = currY + 18
        end
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.print("UPGRADES: LOCKED", contentX, currY)
    end
    
    -- Unlock Condition
    if not unlocked then
        currY = panelY + panelH - 60
        Colors.setColor("xp")
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.print("Unlock: " .. (weapon.unlockCondition or "Complete Missions"), contentX, currY)
    end
    
    -- Navigation Bottom Info
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(string.format("Weapon %d of %d", self.selectedIndex, #self.weapons), 0, screenHeight - 110, screenWidth, "center")
    
    -- Controls Hint
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("LEFT/RIGHT: Browse Weapons | X: Back to Library", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
