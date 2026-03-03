local sm = require "states/statemanager"
local Menu = require "ui/menu"
local Screen = require "systems/screen"
local Fonts = require "ui/fonts"
local Colors = require "ui/colors"
local DataLoader = require "systems/dataloader"

local state = {}

function state:enter(saveData)
    self.saveData = saveData or {
        unlockedShips = {},
        unlockedWeapons = {},
        unlockedPassives = {},
        encounteredEnemies = {},
        encounteredBosses = {}
    }
    
    self.categories = {
        "Ships",
        "Weapons",
        "Passives",
        "Enemies",
        "Bosses",
        "Back"
    }
    
    self.menu = Menu.new(self.categories)
    self.selectedCategory = 1
    
    -- Load data to get total counts
    self.totalShips = #(DataLoader.getShips() or {})
    self.totalWeapons = #(DataLoader.getWeapons() or {})
    self.totalPassives = #(DataLoader.getUpgrades() or {})
    self.totalEnemies = #(DataLoader.getEnemies() or {})
    self.totalBosses = #(DataLoader.getBosses() or {})
    
    -- Helper to get unlocked counts
    self.unlockedCounts = {
        Ships = #(self.saveData.unlockedShips or {}),
        Weapons = #(self.saveData.unlockedWeapons or {}),
        Passives = #(self.saveData.unlockedPassives or {}),
        Enemies = #(self.saveData.encounteredEnemies or {}),
        Bosses = #(self.saveData.encounteredBosses or {})
    }
end

function state:keypressed(key)
    local selection = self.menu:keypressed(key)
    self.selectedCategory = self.menu.selectedIndex
    
    if selection == -1 or (key == "x" or key == "escape") then
        sm.switch("main_menu")
    elseif selection == 1 then
        sm.switch("library_ships", self.saveData)
    elseif selection == 2 then
        sm.switch("library_weapons", self.saveData)
    elseif selection == 3 then
        sm.switch("library_passives", self.saveData)
    elseif selection == 4 then
        sm.switch("library_enemies", self.saveData)
    elseif selection == 5 then
        sm.switch("library_bosses", self.saveData)
    elseif selection == 6 then
        sm.switch("main_menu")
    end
end

function state:draw()
    Screen.applyScale()
    local oldFont = love.graphics.getFont()
    
    -- Dark background
    Colors.setColor("bg")
    love.graphics.rectangle("fill", 0, 0, Screen.getVirtualWidth(), Screen.getVirtualHeight())
    
    local screenWidth = Screen.getVirtualWidth()
    local screenHeight = Screen.getVirtualHeight()
    
    -- Title
    Colors.setColor("accent")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("LIBRARY", 0, screenHeight * 0.1, screenWidth, "center")
    
    -- Category List with counts
    love.graphics.setFont(Fonts.getFont("normal"))
    
    local startY = screenHeight * 0.3
    local lineHeight = 40
    
    for i, category in ipairs(self.categories) do
        local isSelected = (i == self.menu.selectedIndex)
        local y = startY + (i - 1) * lineHeight
        
        local text = category
        if category ~= "Back" then
            local unlocked = self.unlockedCounts[category] or 0
            local total = 0
            if category == "Ships" then total = self.totalShips
            elseif category == "Weapons" then total = self.totalWeapons
            elseif category == "Passives" then total = self.totalPassives
            elseif category == "Enemies" then total = self.totalEnemies
            elseif category == "Bosses" then total = self.totalBosses
            end
            text = string.format("%s [%d/%d]", category, unlocked, total)
        end
        
        if isSelected then
            Colors.setColor("accent")
            love.graphics.print("> " .. text .. " <", screenWidth / 2 - 100, y)
        else
            Colors.setColor("dim")
            love.graphics.print(text, screenWidth / 2 - 80, y)
        end
    end
    
    -- Controls Hint
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("UP/DOWN: Navigate | Z/ENTER: Open | X/ESC: Back", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
