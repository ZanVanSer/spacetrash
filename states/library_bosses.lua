local sm = require "states/statemanager"
local DataLoader = require "systems/dataloader"
local BossVisuals = require "entities/boss_visuals"
local Colors = require "ui/colors"
local Fonts = require "ui/fonts"
local Screen = require "systems/screen"

local state = {}

function state:isBossEncountered(bossId)
    if not bossId then return false end
    if not self.saveData then return false end
    
    -- Check encounteredBosses list if it exists
    if self.saveData.encounteredBosses then
        for _, id in ipairs(self.saveData.encounteredBosses) do
            if id == bossId then return true end
        end
    end
    
    -- Fallback: if they have defeated any boss, maybe they encountered this one?
    -- (Not ideal, but better than nothing if encounteredBosses is missing)
    -- Actually, let's check completedStages
    if self.saveData.completedStages then
        local stages = DataLoader.getStages()
        for _, stageId in ipairs(self.saveData.completedStages) do
            for _, stage in ipairs(stages) do
                if stage.id == stageId and stage.boss == bossId then
                    return true
                end
            end
        end
    end
    
    return false
end

function state:enter(saveData)
    self.saveData = saveData or {}
    
    self.allBosses = DataLoader.getBosses()
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
            self.selectedIndex = #self.allBosses
        end
    elseif key == "right" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.allBosses then
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
    
    if #self.allBosses == 0 then
        Colors.setColor("accent")
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.printf("No boss data found.", 0, screenHeight/2, screenWidth, "center")
        Screen.removeScale()
        return
    end
    
    local boss = self.allBosses[self.selectedIndex]
    local encountered = self:isBossEncountered(boss.id)
    
    -- Title
    Colors.setColor("danger")
    love.graphics.setFont(Fonts.getFont("huge"))
    love.graphics.printf("BOSS ARCHIVES", 0, 40, screenWidth, "center")
    
    -- Left Side: Boss Visual Preview
    local previewX = screenWidth * 0.25
    local previewY = screenHeight * 0.5
    local pulse = math.sin(self.animTimer * 1.5) * 15
    local rotation = math.sin(self.animTimer * 0.8) * 0.05
    
    if encountered then
        -- Draw boss with some animated parameters to make it look "alive"
        local healthPulse = 0.5 + math.sin(self.animTimer * 2) * 0.5
        local isSpecial = (self.animTimer % 4 > 3)
        BossVisuals.drawBoss(boss.id, previewX, previewY + pulse, 2.0, rotation, 0, rotation, 0, healthPulse, isSpecial)
    else
        -- Draw as silhouette
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.circle("fill", previewX, previewY + pulse, 80)
        
        love.graphics.setFont(Fonts.getFont("huge"))
        love.graphics.setColor(0.2, 0, 0, 0.8)
        love.graphics.printf("?????", previewX - 100, previewY + pulse - 20, 200, "center")
        
        -- LOCKED Overlay
        love.graphics.setFont(Fonts.getFont("large"))
        love.graphics.setColor(1, 0, 0, 0.6 + math.sin(self.animTimer * 5) * 0.3)
        love.graphics.printf("NOT ENCOUNTERED", previewX - 150, previewY + 120, 300, "center")
    end
    
    -- Right Side: Information Panel
    local panelX = screenWidth * 0.5
    local panelY = 100
    local panelW = screenWidth * 0.45
    local panelH = screenHeight - 160
    
    love.graphics.setColor(0.08, 0, 0, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12)
    love.graphics.setColor(Colors.getColor("danger", 0.4))
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 12)
    
    local contentX = panelX + 30
    local currY = panelY + 30
    
    -- Name
    love.graphics.setFont(Fonts.getFont("large"))
    if encountered then
        Colors.setColor("danger")
        love.graphics.print(boss.name:upper(), contentX, currY)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.print("DATA CORRUPTED", contentX, currY)
    end
    currY = currY + 45
    
    if encountered then
        -- Stats
        local function drawStat(label, value, color)
            love.graphics.setFont(Fonts.getFont("small"))
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print(label .. ":", contentX, currY)
            
            love.graphics.setFont(Fonts.getFont("normal"))
            love.graphics.setColor(unpack(color or {1, 1, 1}))
            love.graphics.print(tostring(value), contentX + 130, currY - 2)
            currY = currY + 26
        end
        
        drawStat("Max Health", boss.maxHealth, {1, 0.2, 0.2})
        drawStat("Bullet DMG", boss.bulletDamage or "??", {1, 0.4, 0.4})
        drawStat("Proj Speed", boss.bulletSpeed or "??", {1, 1, 1})
        drawStat("Phases", #(boss.phases or {}), {1, 0.6, 1})
        
        -- Appearances
        local appearance = "Unknown Sector"
        for _, stage in ipairs(self.stages) do
            if stage.boss == boss.id then
                appearance = stage.name
                break
            end
        end
        drawStat("Primary Sector", appearance, {0.4, 0.8, 1})
        
        currY = currY + 10
        
        -- Phase Info
        love.graphics.setFont(Fonts.getFont("normal"))
        Colors.setColor("danger")
        love.graphics.print("PHASE LOGS:", contentX, currY)
        currY = currY + 25
        
        love.graphics.setFont(Fonts.getFont("tiny"))
        love.graphics.setColor(0.8, 0.7, 0.7)
        for i, phase in ipairs(boss.phases or {}) do
            local phaseDesc = string.format("P%d (>%d%% HP): %s movement", i, (phase.healthPercent or 0) * 100, phase.behavior or "normal")
            love.graphics.print(phaseDesc, contentX + 10, currY)
            currY = currY + 15
            
            if phase.specialAttack then
                love.graphics.setColor(1, 0.8, 0.2)
                love.graphics.print("  - SPECIAL: " .. (phase.specialAttack.type or "Unknown"), contentX + 10, currY)
                currY = currY + 15
                love.graphics.setColor(0.8, 0.7, 0.7)
            end
            
            if currY > panelY + panelH - 80 then break end
        end
        
        -- Defeat count
        currY = panelY + panelH - 50
        Colors.setColor("xp")
        love.graphics.setFont(Fonts.getFont("small"))
        local kills = 0
        if self.saveData.statistics and self.saveData.statistics.bossesDefeatedPerId then
            kills = self.saveData.statistics.bossesDefeatedPerId[boss.id] or 0
        end
        love.graphics.print("Confirmations of Neutralization: " .. kills, contentX, currY)
    else
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.printf("DEFEAT SUBJECT TO UNLOCK TACTICAL ENTRY", contentX, panelY + panelH / 2 - 20, panelW - 60, "center")
    end
    
    -- Navigation Bottom Info
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(string.format("Boss Entry %d of %d", self.selectedIndex, #self.allBosses), 0, screenHeight - 110, screenWidth, "center")
    
    -- Controls Hint
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("LEFT/RIGHT: Browse Bosses | X: Back to Library", 0, screenHeight - 50, screenWidth, "center")
    
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
