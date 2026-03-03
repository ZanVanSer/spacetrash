local sm = require "states/statemanager"
local DataLoader = require "systems/dataloader"
local BossVisuals = require "entities/boss_visuals"
local Colors = require "ui/colors"
local Fonts = require "ui/fonts"
local Screen = require "systems/screen"
local Scanlines = require "ui/scanlines"

local state = {}

function state:isBossEncountered(bossId)
    if not bossId or not self.saveData then return false end
    if self.saveData.encounteredBosses then
        for _, id in ipairs(self.saveData.encounteredBosses) do
            if id == bossId then return true end
        end
    end
    if self.saveData.completedStages then
        local stages = DataLoader.getStages()
        for _, stageId in ipairs(self.saveData.completedStages) do
            for _, stage in ipairs(stages) do
                if stage.id == stageId and stage.boss == bossId then return true end
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
    self.transitionAlpha = 1
    self.slideOffset = 0
    
    self.particles = {}
    for i = 1, 20 do
        table.insert(self.particles, {
            x = math.random(Screen.getVirtualWidth()),
            y = math.random(Screen.getVirtualHeight()),
            speed = math.random(10, 25),
            size = math.random(1, 3),
            alpha = math.random() * 0.15
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
        if #self.allBosses > 0 then
            self.selectedIndex = (key == "left") and (self.selectedIndex - 1) or (self.selectedIndex + 1)
            if self.selectedIndex < 1 then self.selectedIndex = #self.allBosses end
            if self.selectedIndex > #self.allBosses then self.selectedIndex = 1 end
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
    love.graphics.printf("BOSS ARCHIVES", 0, 40, screenWidth, "center")
    
    if #self.allBosses > 0 then
        local boss = self.allBosses[self.selectedIndex]
        local encountered = self:isBossEncountered(boss.id)
        
        love.graphics.push()
        love.graphics.translate(self.slideOffset, 0)
        
        local previewX, previewY = screenWidth * 0.25, screenHeight * 0.5
        local pulse = math.sin(self.animTimer * 1.5) * 15
        if encountered then
            Colors.setColor("danger", 0.1 * self.transitionAlpha)
            love.graphics.circle("fill", previewX, previewY + pulse, 100 + math.sin(self.animTimer * 3) * 20)
            BossVisuals.drawBoss(boss.id, previewX, previewY + pulse, 2.0, math.sin(self.animTimer * 0.8) * 0.05, 0, 0, 0, 0.5 + math.sin(self.animTimer * 2) * 0.5, self.animTimer % 4 > 3)
        else
            love.graphics.setColor(0.02, 0, 0, self.transitionAlpha)
            love.graphics.circle("fill", previewX, previewY + pulse, 80)
            Colors.setColor("danger", 0.4 * self.transitionAlpha)
            love.graphics.setFont(Fonts.getFont("huge"))
            love.graphics.printf("?????", previewX - 100, previewY + pulse - 20, 200, "center")
            love.graphics.setFont(Fonts.getFont("large"))
            love.graphics.printf("NOT ENCOUNTERED", previewX - 150, previewY + 120, 300, "center")
        end
        
        local panelX, panelY = screenWidth * 0.5, 115
        local panelW, panelH = screenWidth * 0.45, screenHeight - 180
        love.graphics.setColor(0.08, 0, 0, 0.9 * self.transitionAlpha)
        love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 12)
        Colors.setColor("danger", 0.4 * self.transitionAlpha)
        self:drawCornerBrackets(panelX, panelY, panelW, panelH, 25)
        
        local contentX, currY = panelX + 30, panelY + 30
        love.graphics.setFont(Fonts.getFont("large"))
        if encountered then
            Colors.setColor("danger", self.transitionAlpha)
            love.graphics.print(boss.name:upper(), contentX, currY)
        else
            Colors.setColor("dim", 0.3 * self.transitionAlpha)
            love.graphics.print("DATA CORRUPTED", contentX, currY)
        end
        currY = currY + 45
        
        if encountered then
            local function drawStat(label, value, color)
                love.graphics.setFont(Fonts.getFont("small"))
                Colors.setColor("dim", 0.6 * self.transitionAlpha)
                love.graphics.print(label .. ":", contentX, currY)
                love.graphics.setFont(Fonts.getFont("normal"))
                Colors.setColor(color[1], color[2], color[3], self.transitionAlpha)
                love.graphics.print(tostring(value), contentX + 130, currY - 2)
                currY = currY + 26
            end
            drawStat("Max Health", boss.maxHealth, {1, 0.2, 0.2})
            drawStat("Ordnance DMG", boss.bulletDamage or "??", {1, 0.4, 0.4})
            drawStat("Phases", #(boss.phases or {}), {1, 0.6, 1})
            
            currY = currY + 10
            Colors.setColor("danger", self.transitionAlpha)
            love.graphics.setFont(Fonts.getFont("normal"))
            love.graphics.print("TACTICAL LOGS:", contentX, currY)
            currY = currY + 25
            love.graphics.setFont(Fonts.getFont("tiny"))
            Colors.setColor("dim", self.transitionAlpha)
            for i, phase in ipairs(boss.phases or {}) do
                love.graphics.print(string.format("P%d: %s behavior", i, phase.behavior or "standard"), contentX + 10, currY)
                currY = currY + 15
                if phase.specialAttack then
                    Colors.setColor("xp", self.transitionAlpha)
                    love.graphics.print("  - " .. (phase.specialAttack.type:upper()), contentX + 10, currY)
                    currY = currY + 15
                    Colors.setColor("dim", self.transitionAlpha)
                end
                if currY > panelY + panelH - 60 then break end
            end
        else
            love.graphics.setFont(Fonts.getFont("normal"))
            Colors.setColor("dim", 0.4 * self.transitionAlpha)
            love.graphics.printf("NEUTRALIZE TARGET TO UNLOCK INTEL", contentX, panelY + panelH/2 - 20, panelW - 60, "center")
        end
        love.graphics.pop()
    end
    
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(string.format("Entry %d / %d", self.selectedIndex, #self.allBosses), 0, screenHeight - 110, screenWidth, "center")
    Scanlines.drawScanlines()
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("LEFT/RIGHT: Browse | X: Back", 0, screenHeight - 50, screenWidth, "center")
    love.graphics.setFont(oldFont)
    Screen.removeScale()
end

return state
