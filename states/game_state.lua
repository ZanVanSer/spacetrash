local Player = require "entities/player"
local Spawner = require "systems/enemy_spawner"
local dl = require "systems/dataloader"
local UpgradeMenu = require "ui/upgrade_menu"
local Boss = require "entities/boss"
local Menu = require "ui/menu"
local sm = require "states/statemanager"
local state = {}

function state:enter()
    local shipData = dl.getShips()[1]
    self.player = Player.new(shipData)
    self.enemySpawner = Spawner.new()
    self.isPaused = false
    self.upgradeMenu = nil
    self.gameTime = 0
    self.bossSpawned = false
    self.boss = nil
    self.isVictory = false
    self.victoryStats = nil
    self.isPausedByPlayer = false
    self.pauseMenu = nil
    self.enemiesKilled = 0
end

local function checkCircleCollision(x1, y1, r1, x2, y2, r2)
    local distSq = (x1 - x2)^2 + (y1 - y2)^2
    return distSq <= (r1 + r2)^2
end

function state:update(dt)
    if self.isPaused or self.isPausedByPlayer or self.isVictory then return end

    self.gameTime = self.gameTime + dt
    -- Trigger boss spawn
    if self.gameTime >= 180 and not self.bossSpawned then
        local bossData = dl.getBosses()[1]
        self.boss = Boss.new(love.graphics.getWidth() / 2, 80, bossData)
        self.bossSpawned = true
        self.enemySpawner:stop()
    end

    local oldLevel = self.player.level
    self.player:update(dt)
    self.enemySpawner:update(dt)
    
    if self.boss then
        self.boss:update(dt)
        if self.boss.isDead then
            self.isVictory = true
            self.enemiesKilled = self.enemiesKilled + 1
            self.victoryStats = {
                timeSurvived = self.gameTime,
                level = self.player.level,
                enemiesKilled = self.enemiesKilled
            }
        end
    end

    local bullets = self.player:getBullets()
    local enemies = self.enemySpawner:getEnemies()

    -- Bullet-Enemy Collisions
    for _, b in ipairs(bullets) do
        for _, e in ipairs(enemies) do
            if not b.isDead and not e.isDead then
                if checkCircleCollision(b.x, b.y, 4, e.x, e.y, e.radius) then
                    e:takeDamage(b.weaponData.damage)
                    b.isDead = true
                    
                    if e.isDead and not e.xpGiven then
                        self.player:addXP(e.xpValue)
                        e.xpGiven = true
                        self.enemiesKilled = self.enemiesKilled + 1
                    end
                end
            end
        end

        -- Bullet-Boss Collisions
        if self.boss and not self.boss.isDead and not b.isDead then
            if checkCircleCollision(b.x, b.y, 4, self.boss.x, self.boss.y, self.boss.radius) then
                self.boss:takeDamage(b.weaponData.damage)
                b.isDead = true
            end
        end
    end

    -- Enemy-Player Collisions
    for _, e in ipairs(enemies) do
        if not e.isDead then
            if checkCircleCollision(self.player.x, self.player.y, self.player.radius, e.x, e.y, e.radius) then
                self.player.hp = self.player.hp - 10
                e.isDead = true
            end
        end
    end

    -- Boss Bullet-Player Collisions
    if self.boss and not self.boss.isDead then
        local bBullets = self.boss:getBullets()
        for _, bb in ipairs(bBullets) do
            if not bb.isDead then
                if checkCircleCollision(bb.x, bb.y, bb.radius or 8, self.player.x, self.player.y, self.player.radius) then
                    self.player.hp = self.player.hp - bb.damage
                    bb.isDead = true
                end
            end
        end
    end

    -- Death Detection
    if self.player.hp <= 0 then
        local stats = {
            timeSurvived = self.gameTime,
            level = self.player.level,
            enemiesKilled = self.enemiesKilled
        }
        sm.switch("gameover", stats)
        return
    end

    if self.player.level > oldLevel then
        self.isPaused = true
        self.upgradeMenu = UpgradeMenu.new()
    end
end

function state:keypressed(key)
    if self.isVictory then
        if key == "r" then
            sm.switch("game")
        elseif key == "m" then
            sm.switch("main_menu")
        end
        return
    end

    if key == "escape" or key == "p" then
        self.isPausedByPlayer = not self.isPausedByPlayer
        if self.isPausedByPlayer then
            self.pauseMenu = Menu.new({"Resume", "Restart", "Main Menu"})
        else
            self.pauseMenu = nil
        end
        return
    end

    if self.isPausedByPlayer and self.pauseMenu then
        local selection = self.pauseMenu:keypressed(key)
        if selection == 1 then -- Resume
            self.isPausedByPlayer = false
            self.pauseMenu = nil
        elseif selection == 2 then -- Restart
            sm.switch("game")
        elseif selection == 3 then -- Main Menu
            sm.switch("main_menu")
        end
        return
    end

    if self.isPaused and self.upgradeMenu then
        local selectedUpgrade = self.upgradeMenu:keypressed(key)
        if selectedUpgrade then
            self:applyUpgrade(selectedUpgrade)
            self.isPaused = false
            self.upgradeMenu = nil
        end
    end
end

function state:applyUpgrade(upgrade)
    local effect = upgrade.effect
    local p = self.player
    
    if effect.type == "stat_mult" then
        if effect.stat == "damage" then
            p.damageMult = (p.damageMult or 1) * effect.value
        elseif effect.stat == "fireRate" then
            p.fireRateMult = (p.fireRateMult or 1) * effect.value
        elseif effect.stat == "speed" then
            p.speed = p.speed * effect.value
        end
    elseif effect.type == "stat_add" then
        if effect.stat == "maxHealth" then
            p.maxHp = p.maxHp + effect.value
            p.hp = p.hp + effect.value
        end
    end
end

function state:draw()
    love.graphics.clear(0.05, 0.05, 0.1)
    self.player:draw()
    self.enemySpawner:draw()
    
    if self.boss then
        self.boss:draw()
        
        -- Global Boss Health Bar
        if not self.boss.isDead then
            local barWidth = 600
            local barHeight = 20
            local barX = (love.graphics.getWidth() - barWidth) / 2
            local barY = 40
            
            love.graphics.setColor(0.2, 0, 0)
            love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
            
            local fillPercent = math.max(0, self.boss.health / self.boss.maxHealth)
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", barX, barY, barWidth * fillPercent, barHeight)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
            love.graphics.printf(self.boss.bossData.name, barX, barY + 2, barWidth, "center")
        end
    end
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. math.ceil(self.player.hp), 10, 50)
    
    -- XP Bar
    local barWidth = 400
    local barHeight = 20
    local barX = (love.graphics.getWidth() - barWidth) / 2
    local barY = 10

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle('fill', barX, barY, barWidth, barHeight)

    local fillPercent = self.player.xp / self.player.xpToNext
    love.graphics.setColor(0.3, 0.8, 0.3)
    love.graphics.rectangle('fill', barX, barY, barWidth * fillPercent, barHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', barX, barY, barWidth, barHeight)

    love.graphics.print("Level: " .. self.player.level, 10, 10)
    love.graphics.print("XP: " .. math.floor(self.player.xp) .. "/" .. self.player.xpToNext, 10, 30)

    -- Game Timer
    local minutes = math.floor(self.gameTime / 60)
    local seconds = math.floor(self.gameTime % 60)
    local timerStr = string.format("Time: %02d:%02d", minutes, seconds)
    love.graphics.print(timerStr, love.graphics.getWidth() - 100, 10)

    if self.isPaused and self.upgradeMenu then
        self.upgradeMenu:draw()
    end

    if self.isVictory then
        -- Semi-transparent gold overlay
        love.graphics.setColor(0.1, 0.1, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        love.graphics.setColor(1, 0.8, 0)
        local font = love.graphics.newFont(64)
        local oldFont = love.graphics.getFont()
        love.graphics.setFont(font)
        love.graphics.printf("VICTORY!", 0, love.graphics.getHeight() * 0.2, love.graphics.getWidth(), "center")
        
        love.graphics.setFont(oldFont)
        love.graphics.setColor(1, 1, 1)
        if self.victoryStats then
            local statsY = love.graphics.getHeight() * 0.4
            local mins = math.floor(self.victoryStats.timeSurvived / 60)
            local secs = math.floor(self.victoryStats.timeSurvived % 60)
            love.graphics.printf(string.format("Time: %02d:%02d", mins, secs), 0, statsY, love.graphics.getWidth(), "center")
            love.graphics.printf("Level: " .. self.victoryStats.level, 0, statsY + 30, love.graphics.getWidth(), "center")
            love.graphics.printf("Enemies Killed: " .. self.victoryStats.enemiesKilled, 0, statsY + 60, love.graphics.getWidth(), "center")
        end
        
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Press R to Restart | Press M for Main Menu", 0, love.graphics.getHeight() * 0.7, love.graphics.getWidth(), "center")
    end

    if self.isPausedByPlayer and self.pauseMenu then
        -- Semi-transparent dark overlay
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        -- "PAUSED" text at top
        love.graphics.setColor(1, 1, 1)
        local font = love.graphics.getFont()
        local text = "PAUSED"
        love.graphics.printf(text, 0, 100, love.graphics.getWidth(), "center")
        
        self.pauseMenu:draw(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    end
end

return state
