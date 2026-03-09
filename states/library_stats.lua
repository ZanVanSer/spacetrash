local sm = require "states/statemanager"
local Colors = require "ui/colors"
local Fonts = require "ui/fonts"
local Screen = require "systems/screen"
local Scanlines = require "ui/scanlines"

local state = {}

function state:enter(saveData)
    self.saveData = saveData or {}
    self.stats = self.saveData.statistics or {
        totalPlayTime = 0,
        totalRuns = 0,
        totalKills = 0,
        bossesDefeated = 0,
        totalDamageDealt = 0,
        highestLevel = 0
    }
    self.animTimer = 0
    self.transitionAlpha = 0
    
    self.particles = {}
    for i = 1, 30 do
        table.insert(self.particles, {
            x = math.random(Screen.getVirtualWidth()),
            y = math.random(Screen.getVirtualHeight()),
            speed = math.random(5, 15),
            size = math.random(1, 2),
            alpha = math.random() * 0.1
        })
    end
end

function state:update(dt)
    self.animTimer = self.animTimer + dt
    self.transitionAlpha = math.min(1, self.transitionAlpha + dt * 4)
    for _, p in ipairs(self.particles) do
        p.y = p.y + p.speed * dt
        if p.y > Screen.getVirtualHeight() then p.y = -10 end
    end
end

function state:keypressed(key)
    if key == "x" or key == "escape" then
        sm.switch("library_save_select", self.saveData)
    end
end

function state:drawCornerBrackets(x, y, w, h, size)
    local s = size or 10
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
    love.graphics.printf("MISSION ARCHIVES", 0, 40, screenWidth, "center")
    
    local panelW, panelH, margin = screenWidth * 0.4, 120, 40
    local panels = {
        { title = "FLIGHT LOGS", color = "accent", items = { { label = "Total Runs", value = self.stats.totalRuns or 0 }, { label = "Flight Time", value = string.format("%dh %02dm", math.floor((self.stats.totalPlayTime or 0) / 3600), math.floor(((self.stats.totalPlayTime or 0) % 3600) / 60)) }, { label = "Highest Rank", value = "Lvl " .. (self.stats.highestLevel or 0) } } },
        { title = "COMBAT DATA", color = "danger", items = { { label = "Neutralizations", value = self.stats.totalKills or 0 }, { label = "Damage Output", value = math.floor((self.stats.totalDamageDealt or 0)) }, { label = "Priority Targets", value = self.stats.bossesDefeated or 0 } } },
        { title = "PREFERENCES", color = "xp", items = { { label = "Favorite Ship", value = self.stats.favoriteShip or "Vanguard" }, { label = "Main Armament", value = self.stats.favoriteWeapon or "Basic Laser" }, { label = "Target Rival", value = self.stats.mostKilledEnemy or "Drone" } } },
        { title = "RECORDS", color = "health", items = { 
            { label = "Peak Difficulty", value = string.format("x%.1f HP, x%.1f DMG", self.stats.maxHealthMultiplier or 1.0, self.stats.maxDamageMultiplier or 1.0) }, 
            { label = "Longest Flight", value = string.format("%02d:%02d", math.floor((self.stats.longestRun or 0) / 60), math.floor((self.stats.longestRun or 0) % 60)) }, 
            { label = "Elite Kills", value = self.stats.maxEliteKills or 0 } 
        } }
    }
    
    local startX = (screenWidth - (panelW * 2 + margin)) / 2
    local startY = 120
    for i, panel in ipairs(panels) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        local px, py = startX + col * (panelW + margin), startY + row * (panelH + margin)
        local hover = math.sin(self.animTimer * 2 + i) * 2
        py = py + hover
        
        love.graphics.setColor(0.05, 0.08, 0.1, 0.8 * self.transitionAlpha)
        love.graphics.rectangle("fill", px, py, panelW, panelH, 8)
        Colors.setColor(panel.color, 0.2 * self.transitionAlpha)
        self:drawCornerBrackets(px, py, panelW, panelH, 15)
        
        Colors.setColor(panel.color, self.transitionAlpha)
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.print(panel.title, px + 15, py + 10)
        
        love.graphics.setFont(Fonts.getFont("small"))
        local itemY = py + 40
        for _, item in ipairs(panel.items) do
            Colors.setColor("dim", 0.6 * self.transitionAlpha)
            love.graphics.print(item.label .. ":", px + 20, itemY)
            Colors.setColor("white", self.transitionAlpha)
            love.graphics.print(tostring(item.value), px + panelW - 120, itemY)
            itemY = itemY + 22
        end
    end
    
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    local totalCompletion = (self.saveData.unlockedShips and #self.saveData.unlockedShips or 0) + (self.saveData.unlockedWeapons and #self.saveData.unlockedWeapons or 0)
    love.graphics.printf("Overall Archive Status: " .. totalCompletion .. " modules verified", 0, screenHeight - 100, screenWidth, "center")
    Scanlines.drawScanlines()
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("X: Back to Library", 0, screenHeight - 50, screenWidth, "center")
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
