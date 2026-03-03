local sm = require "states/statemanager"
local DataLoader = require "systems/dataloader"
local EnemyVisuals = require "entities/enemy_visuals"
local Colors = require "ui/colors"
local Fonts = require "ui/fonts"
local Screen = require "systems/screen"

local state = {}

function state:enter(saveData)
    self.saveData = saveData or {
        statistics = {
            totalKills = 0
        }
    }
    
    self.enemies = DataLoader.getEnemies()
    self.stages = DataLoader.getStages()
    self.selectedIndex = 1
    self.animTimer = 0
end

function state:update(dt)
    self.animTimer = self.animTimer + dt
end

function state:keypressed(key)
    if key == "left" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.enemies
        end
    elseif key == "right" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.enemies then
            self.selectedIndex = 1
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
    
    if #self.enemies == 0 then
        Colors.setColor("accent")
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.printf("No enemy data found.", 0, screenHeight/2, screenWidth, "center")
        Screen.removeScale()
        return
    end
    
    local enemy = self.enemies[self.selectedIndex]
    
    -- Title
    Colors.setColor("accent")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("ENEMY ARCHIVES", 0, 40, screenWidth, "center")
    
    -- Left Side: Enemy Visual Preview
    local previewX = screenWidth * 0.25
    local previewY = screenHeight * 0.5
    local pulse = math.sin(self.animTimer * 2) * 10
    local rotation = math.sin(self.animTimer * 1.5) * 0.1
    
    -- Draw enemy in danger red color (handled by EnemyVisuals)
    EnemyVisuals.drawEnemy(enemy.id, previewX, previewY + pulse, 3.0, rotation)
    
    -- Right Side: Information Panel
    local panelX = screenWidth * 0.5
    local panelY = 100
    local panelW = screenWidth * 0.45
    local panelH = screenHeight - 160
    
    love.graphics.setColor(0.1, 0, 0, 0.8) -- Slightly red background for enemies
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12)
    love.graphics.setColor(Colors.getColor("danger", 0.3))
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 12)
    
    local contentX = panelX + 30
    local currY = panelY + 30
    
    -- Name and Type
    love.graphics.setFont(Fonts.getFont("large"))
    Colors.setColor("danger")
    love.graphics.print(enemy.name:upper(), contentX, currY)
    currY = currY + 30
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.print("Hostile Signature: " .. (enemy.behavior or "Unknown"), contentX, currY)
    currY = currY + 50
    
    -- Stats
    local function drawStat(label, value, color)
        love.graphics.setFont(Fonts.getFont("small"))
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(label .. ":", contentX, currY)
        
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.setColor(unpack(color or {1, 1, 1}))
        love.graphics.print(tostring(value), contentX + 130, currY - 2)
        currY = currY + 28
    end
    
    drawStat("Health", enemy.hp or "Unknown", {1, 0.3, 0.3})
    drawStat("Speed", enemy.speed or "Unknown", {1, 1, 1})
    drawStat("XP Value", enemy.xp or "Unknown", {1, 1, 0})
    drawStat("Attack Type", (enemy.shootPattern or "No Range"):gsub("^%l", string.upper), {1, 0.5, 0})
    
    -- Spawn Locations
    currY = currY + 10
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Sectors Detected:", contentX, currY)
    currY = currY + 20
    
    love.graphics.setFont(Fonts.getFont("normal"))
    Colors.setColor("accent")
    local foundStages = {}
    for _, stage in ipairs(self.stages) do
        if stage.enemies then
            for _, eId in ipairs(stage.enemies) do
                if eId == enemy.id then
                    table.insert(foundStages, stage.name)
                    break
                end
            end
        end
    end
    
    if #foundStages > 0 then
        for _, sName in ipairs(foundStages) do
            love.graphics.print("- " .. sName, contentX + 10, currY)
            currY = currY + 22
        end
    else
        love.graphics.print("- Deep Space", contentX + 10, currY)
        currY = currY + 22
    end
    
    -- Kill count if tracked (using total kills as placeholder if per-enemy not available)
    currY = panelY + panelH - 60
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("small"))
    local killStr = "Kill Count: Not Tracked"
    if self.saveData.statistics and self.saveData.statistics.killsPerEnemy then
        killStr = "Kills: " .. (self.saveData.statistics.killsPerEnemy[enemy.id] or 0)
    end
    love.graphics.print(killStr, contentX, currY)
    
    -- Navigation Bottom Info
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(string.format("Enemy %d of %d", self.selectedIndex, #self.enemies), 0, screenHeight - 110, screenWidth, "center")
    
    -- Controls Hint
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("LEFT/RIGHT: Browse Enemies | X: Back to Library", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
