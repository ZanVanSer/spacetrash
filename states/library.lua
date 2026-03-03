local sm = require "states/statemanager"
local Menu = require "ui/menu"
local Screen = require "systems/screen"
local Fonts = require "ui/fonts"
local Colors = require "ui/colors"
local DataLoader = require "systems/dataloader"
local Scanlines = require "ui/scanlines"

local state = {}

function state:enter(saveData)
    self.saveData = saveData or {
        unlockedShips = {},
        unlockedWeapons = {},
        unlockedPassives = {},
        encounteredEnemies = {},
        encounteredBosses = {},
        statistics = {
            totalPlayTime = 0,
            totalRuns = 0,
            totalKills = 0,
            bossesDefeated = 0,
            totalDamageDealt = 0,
            highestLevel = 0
        }
    }
    
    self.categories = {
        "Ships",
        "Weapons",
        "Passives",
        "Enemies",
        "Bosses",
        "Statistics",
        "Back"
    }
    
    self.menu = Menu.new(self.categories)
    self.selectedCategory = 1
    
    self.totalShips = #(DataLoader.getShips() or {})
    self.totalWeapons = #(DataLoader.getWeapons() or {})
    self.totalPassives = #(DataLoader.getUpgrades() or {})
    self.totalEnemies = #(DataLoader.getEnemies() or {})
    self.totalBosses = #(DataLoader.getBosses() or {})
    
    self.unlockedCounts = {
        Ships = #(self.saveData.unlockedShips or {}),
        Weapons = #(self.saveData.unlockedWeapons or {}),
        Passives = #(self.saveData.unlockedPassives or {}),
        Enemies = #(self.saveData.encounteredEnemies or {}),
        Bosses = #(self.saveData.encounteredBosses or {})
    }
    self.animTimer = 0
end

function state:update(dt)
    self.animTimer = self.animTimer + dt
end

function state:keypressed(key)
    local selection = self.menu:keypressed(key)
    self.selectedCategory = self.menu.selectedIndex
    
    if selection == -1 or (key == "x" or key == "escape") then
        sm.switch("main_menu")
    elseif selection == 1 then sm.switch("library_ships", self.saveData)
    elseif selection == 2 then sm.switch("library_weapons", self.saveData)
    elseif selection == 3 then sm.switch("library_passives", self.saveData)
    elseif selection == 4 then sm.switch("library_enemies", self.saveData)
    elseif selection == 5 then sm.switch("library_bosses", self.saveData)
    elseif selection == 6 then sm.switch("library_save_select", self.saveData)
    elseif selection == 7 then sm.switch("main_menu")
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
    
    Colors.setColor("accent", 0.1)
    for i = 1, 15 do
        local x = (math.sin(self.animTimer * 0.5 + i) * 0.5 + 0.5) * screenWidth
        local y = (math.cos(self.animTimer * 0.3 + i) * 0.5 + 0.5) * screenHeight
        love.graphics.circle("fill", x, y, 2)
    end
    
    Colors.setColor("accent", 0.3)
    self:drawCornerBrackets(20, 20, screenWidth - 40, screenHeight - 40, 30)
    
    Colors.setColor("accent")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("CENTRAL DATABASE", 0, screenHeight * 0.1, screenWidth, "center")
    
    love.graphics.setFont(Fonts.getFont("normal"))
    local startY, lineHeight = screenHeight * 0.25, 45
    for i, category in ipairs(self.categories) do
        local isSelected = (i == self.menu.selectedIndex)
        local y = startY + (i - 1) * lineHeight
        
        if category == "Back" or category == "Statistics" then
            local labelX = screenWidth / 2 - 80
            if isSelected then
                Colors.setColor("accent")
                love.graphics.print("> " .. category:upper() .. " <", labelX - 25, y)
            else
                Colors.setColor("dim")
                love.graphics.print(category:upper(), labelX, y)
            end
        else
            local unlocked = self.unlockedCounts[category] or 0
            local total = 0
            if category == "Ships" then total = self.totalShips
            elseif category == "Weapons" then total = self.totalWeapons
            elseif category == "Passives" then total = self.totalPassives
            elseif category == "Enemies" then total = self.totalEnemies
            elseif category == "Bosses" then total = self.totalBosses
            end
            
            local percent = (total > 0) and (unlocked / total) or 0
            local labelX = screenWidth / 2 - 200
            if isSelected then
                Colors.setColor("accent")
                love.graphics.print("> " .. category:upper() .. " [" .. unlocked .. "/" .. total .. "]", labelX, y)
            else
                Colors.setColor("dim")
                love.graphics.print(category:upper() .. " [" .. unlocked .. "/" .. total .. "]", labelX + 25, y)
            end
            
            local barW, barH, barX, barY = 150, 12, screenWidth / 2 + 50, y + 4
            love.graphics.setColor(0.05, 0.05, 0.05, 1)
            love.graphics.rectangle("fill", barX, barY, barW, barH, 2)
            if percent >= 1 then Colors.setColor("health") else Colors.setColor("accent") end
            love.graphics.rectangle("fill", barX, barY, barW * percent, barH, 2)
            love.graphics.setColor(1, 1, 1, 0.1)
            love.graphics.rectangle("line", barX, barY, barW, barH, 2)
        end
    end
    
    Scanlines.drawScanlines()
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("UP/DOWN: Navigate | Z/ENTER: Access | X/ESC: Terminate", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
