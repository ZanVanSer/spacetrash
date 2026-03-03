local sm = require "states/statemanager"
local DataLoader = require "systems/dataloader"
local EnemyVisuals = require "entities/enemy_visuals"
local Colors = require "ui/colors"
local Fonts = require "ui/fonts"
local Screen = require "systems/screen"
local Scanlines = require "ui/scanlines"

local state = {}

function state:enter(saveData)
    self.saveData = saveData or { statistics = { totalKills = 0 } }
    self.enemies = DataLoader.getEnemies()
    self.stages = DataLoader.getStages()
    self.selectedIndex = 1
    self.animTimer = 0
    self.transitionAlpha = 1
    self.slideOffset = 0
    
    self.particles = {}
    for i = 1, 20 do
        table.insert(self.particles, {
            x = math.random(Screen.getVirtualWidth()),
            y = math.random(Screen.getVirtualHeight()),
            speed = math.random(15, 40),
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
    if key == "left" or key == "right" then
        if #self.enemies > 0 then
            self.selectedIndex = (key == "left") and (self.selectedIndex - 1) or (self.selectedIndex + 1)
            if self.selectedIndex < 1 then self.selectedIndex = #self.enemies end
            if self.selectedIndex > #self.enemies then self.selectedIndex = 1 end
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
        Colors.setColor("danger", p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
    
    Colors.setColor("danger")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("ENEMY ARCHIVES", 0, 40, screenWidth, "center")
    
    if #self.enemies > 0 then
        local enemy = self.enemies[self.selectedIndex]
        love.graphics.push()
        love.graphics.translate(self.slideOffset, 0)
        
        local previewX, previewY = screenWidth * 0.25, screenHeight * 0.5
        local pulse = math.sin(self.animTimer * 2) * 10
        Colors.setColor("danger", 0.1 * self.transitionAlpha)
        love.graphics.circle("fill", previewX, previewY + pulse, 60 + math.sin(self.animTimer * 4) * 10)
        EnemyVisuals.drawEnemy(enemy.id, previewX, previewY + pulse, 3.0, math.sin(self.animTimer * 1.5) * 0.1)
        
        local panelX, panelY = screenWidth * 0.5, 115
        local panelW, panelH = screenWidth * 0.45, screenHeight - 180
        love.graphics.setColor(0.1, 0, 0, 0.85 * self.transitionAlpha)
        love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12)
        Colors.setColor("danger", 0.3 * self.transitionAlpha)
        self:drawCornerBrackets(panelX, panelY, panelW, panelH, 25)
        
        local contentX, currY = panelX + 30, panelY + 30
        love.graphics.setFont(Fonts.getFont("large"))
        Colors.setColor("danger", self.transitionAlpha)
        love.graphics.print(enemy.name:upper(), contentX, currY)
        currY = currY + 30
        Colors.setColor("dim", self.transitionAlpha)
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.print("Signature: " .. (enemy.behavior or "Unknown"), contentX, currY)
        currY = currY + 50
        
        local function drawStat(label, value, color)
            love.graphics.setFont(Fonts.getFont("small"))
            Colors.setColor("dim", 0.6 * self.transitionAlpha)
            love.graphics.print(label .. ":", contentX, currY)
            love.graphics.setFont(Fonts.getFont("normal"))
            Colors.setColor(color[1], color[2], color[3], self.transitionAlpha)
            love.graphics.print(tostring(value), contentX + 130, currY - 2)
            currY = currY + 28
        end
        drawStat("Integrity", enemy.hp or "??", {1, 0.3, 0.3})
        drawStat("Thrust", enemy.speed or "??", {1, 1, 1})
        drawStat("Bounty", enemy.xp or "??", {1, 1, 0})
        drawStat("Ordnance", (enemy.shootPattern or "None"):gsub("^%l", string.upper), {1, 0.5, 0})
        
        currY = currY + 15
        love.graphics.setFont(Fonts.getFont("small"))
        Colors.setColor("dim", 0.6 * self.transitionAlpha)
        love.graphics.print("Sectors Detected:", contentX, currY)
        currY = currY + 22
        love.graphics.setFont(Fonts.getFont("normal"))
        Colors.setColor("accent", self.transitionAlpha)
        local stagesFound = 0
        for _, stage in ipairs(self.stages) do
            if stage.enemies then
                for _, eId in ipairs(stage.enemies) do
                    if eId == enemy.id then
                        love.graphics.print("- " .. stage.name, contentX + 10, currY)
                        currY, stagesFound = currY + 22, stagesFound + 1
                        break
                    end
                end
            end
        end
        if stagesFound == 0 then love.graphics.print("- Deep Space", contentX + 10, currY) end
        
        currY = panelY + panelH - 50
        Colors.setColor("dim", 0.5 * self.transitionAlpha)
        love.graphics.setFont(Fonts.getFont("small"))
        local kills = (self.saveData.statistics and self.saveData.statistics.killsPerEnemy) and (self.saveData.statistics.killsPerEnemy[enemy.id] or 0) or 0
        love.graphics.print("Neutralization Count: " .. kills, contentX, currY)
        love.graphics.pop()
    end
    
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(string.format("Entry %d / %d", self.selectedIndex, #self.enemies), 0, screenHeight - 110, screenWidth, "center")
    Scanlines.drawScanlines()
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("LEFT/RIGHT: Browse | X: Back", 0, screenHeight - 50, screenWidth, "center")
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
