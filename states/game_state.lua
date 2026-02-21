local Player = require "entities/player"
local Spawner = require "systems/enemy_spawner"
local dl = require "systems/dataloader"
local UpgradeMenu = require "ui/upgrade_menu"
local state = {}

function state:enter()
    local shipData = dl.getShips()[1]
    self.player = Player.new(shipData)
    self.enemySpawner = Spawner.new()
    self.isPaused = false
    self.upgradeMenu = nil
    self.gameTime = 0
    self.bossSpawned = false
end

local function checkCircleCollision(x1, y1, r1, x2, y2, r2)
    local distSq = (x1 - x2)^2 + (y1 - y2)^2
    return distSq <= (r1 + r2)^2
end

function state:update(dt)
    if self.isPaused then return end

    self.gameTime = self.gameTime + dt
    if self.gameTime >= 180 and not self.bossSpawned then
        -- Trigger boss spawn
        self.bossSpawned = true
        self.enemySpawner:stop()
    end

    local oldLevel = self.player.level
    self.player:update(dt)
    self.enemySpawner:update(dt)

    local bullets = self.player:getBullets()
    local enemies = self.enemySpawner:getEnemies()

    -- Bullet-Enemy Collisions
    for _, b in ipairs(bullets) do
        for _, e in ipairs(enemies) do
            if not b.isDead and not e.isDead then
                -- Bullets are 4x10 rectangles, treating as 4r circle for simplicity or use point
                if checkCircleCollision(b.x, b.y, 4, e.x, e.y, e.radius) then
                    e:takeDamage(b.weaponData.damage)
                    b.isDead = true
                    
                    if e.isDead and not e.xpGiven then
                        self.player:addXP(e.xpValue)
                        e.xpGiven = true
                    end
                end
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

    if self.player.level > oldLevel then
        self.isPaused = true
        self.upgradeMenu = UpgradeMenu.new()
    end
end

function state:keypressed(key)
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
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. self.player.hp, 10, 50)
    
    -- XP Bar
    local barWidth = 400
    local barHeight = 20
    local barX = (love.graphics.getWidth() - barWidth) / 2
    local barY = 10

    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle('fill', barX, barY, barWidth, barHeight)

    -- XP Fill
    local fillPercent = self.player.xp / self.player.xpToNext
    love.graphics.setColor(0.3, 0.8, 0.3)
    love.graphics.rectangle('fill', barX, barY, barWidth * fillPercent, barHeight)

    -- Border
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', barX, barY, barWidth, barHeight)

    -- Level text
    love.graphics.print("Level: " .. self.player.level, 10, 10)
    love.graphics.print("XP: " .. self.player.xp .. "/" .. self.player.xpToNext, 10, 30)

    -- Game Timer
    local minutes = math.floor(self.gameTime / 60)
    local seconds = math.floor(self.gameTime % 60)
    local timerStr = string.format("Time: %02d:%02d", minutes, seconds)
    love.graphics.print(timerStr, love.graphics.getWidth() - 100, 10)

    if self.isPaused and self.upgradeMenu then
        self.upgradeMenu:draw()
    end
end

return state
