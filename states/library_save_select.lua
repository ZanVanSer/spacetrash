local sm = require "states/statemanager"
local savemanager = require "systems/savemanager"
local dl = require "systems/dataloader"
local Menu = require "ui/menu"
local Screen = require('systems.screen')
local Fonts = require('ui/fonts')
local Colors = require "ui/colors"
local Scanlines = require "ui/scanlines"

local state = {}

function state:enter(originalSaveData)
    self.originalSaveData = originalSaveData
    self.saves = {}
    local options = {}
    
    for i = 1, 3 do
        local data = savemanager.loadSave(i)
        self.saves[i] = data
        
        local label = "Slot " .. i .. ": "
        if data and data.statistics then
            local stats = data.statistics
            local mins = math.floor(stats.totalPlayTime / 60)
            local hours = math.floor(mins / 60)
            mins = mins % 60
            label = label .. "Lvl " .. (stats.highestLevel or 1) .. " - " .. string.format("%dh %02dm", hours, mins)
        else
            label = label .. "Empty"
        end
        table.insert(options, label)
    end
    table.insert(options, "Back")
    
    self.menu = Menu.new(options)
    self.animTimer = 0
end

function state:update(dt)
    self.animTimer = self.animTimer + dt
end

function state:keypressed(key)
    local selection = self.menu:keypressed(key)
    
    if selection == -1 or selection == 4 or key == "x" or key == "escape" then
        sm.switch("library", self.originalSaveData)
    elseif selection and selection >= 1 and selection <= 3 then
        local data = self.saves[selection]
        if data then
            sm.switch("library_stats", data)
        else
            -- If empty, maybe just show default stats or a message?
            -- User specifically asked to open statistic screen of this save
            sm.switch("library_stats", savemanager.getDefaultSave())
        end
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
    
    Colors.setColor("bg")
    love.graphics.rectangle("fill", 0, 0, Screen.getVirtualWidth(), Screen.getVirtualHeight())
    
    local screenWidth = Screen.getVirtualWidth()
    local screenHeight = Screen.getVirtualHeight()
    
    -- Title
    Colors.setColor("accent")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("SELECT ARCHIVE SLOT", 0, screenHeight * 0.1, screenWidth, "center")
    
    -- Corner Brackets
    Colors.setColor("accent", 0.3)
    self:drawCornerBrackets(20, 20, screenWidth - 40, screenHeight - 40, 30)
    
    -- Menu
    love.graphics.setFont(Fonts.getFont("normal"))
    self.menu:draw(screenWidth / 2, screenHeight / 2 - 80)
    
    -- Preview of stats for highlighted slot
    local idx = self.menu.selectedIndex
    if idx <= 3 then
        local data = self.saves[idx]
        local infoY = screenHeight * 0.5
        local panelW = 400
        local panelX = (screenWidth - panelW) / 2
        
        love.graphics.setColor(0.05, 0.1, 0.15, 0.8)
        love.graphics.rectangle("fill", panelX, infoY, panelW, 200, 8)
        Colors.setColor("accent", 0.2)
        love.graphics.rectangle("line", panelX, infoY, panelW, 200, 8)
        
        if data and data.statistics then
            local stats = data.statistics
            Colors.setColor("white")
            love.graphics.setFont(Fonts.getFont("small"))
            love.graphics.printf("TOTAL KILLS: " .. (stats.totalKills or 0), 0, infoY + 30, screenWidth, "center")
            love.graphics.printf("BOSSES DEFEATED: " .. (stats.bossesDefeated or 0), 0, infoY + 60, screenWidth, "center")
            love.graphics.printf("HIGHEST LEVEL: " .. (stats.highestLevel or 0), 0, infoY + 90, screenWidth, "center")
            
            Colors.setColor("xp")
            love.graphics.printf("ACCESS GRANTED - PRESS Z TO VIEW FULL LOGS", 0, infoY + 140, screenWidth, "center")
        else
            Colors.setColor("dim")
            love.graphics.printf("NO DATA FOUND IN THIS SLOT", 0, infoY + 80, screenWidth, "center")
        end
    end
    
    Scanlines.drawScanlines()
    
    -- Controls Hint
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("Arrow Keys: Navigate | Z: Access Archives | X: Back", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
