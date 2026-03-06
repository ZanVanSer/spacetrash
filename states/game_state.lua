local Player = require "entities/player"
local Spawner = require "systems/enemy_spawner"
local dl = require "systems/dataloader"
local UpgradeMenu = require "ui/upgrade_menu"
local Boss = require "entities/boss"
local Menu = require "ui/menu"
local sm = require "states/statemanager"
local savemanager = require "systems/savemanager"
local Unlocks = require "systems/unlocks"
local Background = require "entities/background"
local Screen = require('systems.screen')
local Screenshake = require('systems.screenshake')
local Particles = require('systems.particles')
local Scanlines = require('ui.scanlines')
local DamageNumbers = require('ui.damage_numbers')
local Layout = require('ui/layout')
local Fonts = require('ui/fonts')
local HUD = require('ui/hud')
local Telegraph = require('ui.attack_telegraph')
local Colors = require('ui.colors')
local state = {}

function state:enter(saveData, stageData, shipData)
    -- Use parameters if provided, otherwise fall back to global state (important for Restarts)
    self.currentSaveData = saveData or _G.currentSaveData
    self.currentSaveSlot = _G.currentSaveSlot
    self.stageData = stageData or self.stageData or {}
    self.shipData = shipData or self.shipData
    
    self.player = Player.new(self.shipData or dl.getShips()[1])
    self.hud = HUD.new()
    self.screenshake = Screenshake
    self.particles = Particles
    self.damageNumbers = DamageNumbers
    self.telegraph = Telegraph.new()
    self.screenFlash = {
        active = false,
        color = {1, 0, 0, 1},
        duration = 0,
        elapsed = 0,
        intensity = 0
    }
    self.wasBossSpecialAttacking = false
    
    self.isPaused = false
    self.upgradeMenu = nil
    self.gameTime = 0
    self.bossSpawned = false
    self.boss = nil
    self.bossEntranceTimer = 0
    self.isVictory = false
    self.victoryStats = nil
    self.isPausedByPlayer = false
    self.pauseMenu = nil
    self.enemiesKilled = 0
    
    -- Stage Configuration
    self.background = Background.new(self.stageData.background or "space_complete")
    self.bossSpawnTime = self.stageData.survivalTime or 180
    self.stageEnemies = self.stageData.enemies or {}
    self.enemySpawnInterval = self.stageData.enemySpawnRate or 2.0
    self.stageBoss = self.stageData.boss
    
    -- Background Tinting for Immersion
    local bgID = self.stageData.background or "space_complete"
    self.backgroundTint = {1, 1, 1} -- Default
    if bgID == "asteroid_belt" then
        self.backgroundTint = {0.8, 0.8, 0.8} -- Grayish
    elseif bgID == "urban_ruins" then
        self.backgroundTint = {1, 0.9, 0.7} -- Warm orange glow
    elseif bgID == "solar_core" then
        self.backgroundTint = {1, 0.7, 0.4} -- Strong fire tint
    end
    
    self.enemySpawner = Spawner.new(self.stageEnemies, self.enemySpawnInterval)
    
    -- Run statistics
    self.runStatistics = {
        kills = 0,
        damageDealt = 0,
        runTime = 0,
        highestLevel = 1,
        bossesDefeated = 0
    }
end

function state:flashScreen(color, duration, intensity)
    local c = color
    if type(color) == "string" then
        c = Colors.getColor(color, 1)
    end
    if type(c) ~= "table" then
        c = {1, 0, 0, 1}
    end

    self.screenFlash.active = true
    self.screenFlash.color = {c[1] or 1, c[2] or 0, c[3] or 0, c[4] or 1}
    self.screenFlash.duration = duration or 0.5
    self.screenFlash.elapsed = 0
    self.screenFlash.intensity = intensity or 0.3
end

local function checkCircleCollision(x1, y1, r1, x2, y2, r2)
    local distSq = (x1 - x2)^2 + (y1 - y2)^2
    return distSq <= (r1 + r2)^2
end

local function checkSegmentCircleCollision(x1, y1, x2, y2, cx, cy, cr)
    -- Vector from p1 to p2
    local dx = x2 - x1
    local dy = y2 - y1
    
    -- Vector from p1 to center
    local lcx = cx - x1
    local lcy = cy - y1
    
    -- Projection of center onto line p1-p2
    local lenSq = dx*dx + dy*dy
    local t = 0
    if lenSq > 0 then
        t = (lcx * dx + lcy * dy) / lenSq
        t = math.max(0, math.min(1, t))
    end
    
    -- Closest point on segment
    local closestX = x1 + t * dx
    local closestY = y1 + t * dy
    
    -- Distance squared from closest point to center
    local distSq = (cx - closestX)^2 + (cy - closestY)^2
    return distSq <= cr^2
end

function state:saveProgress(isTerminal)
    if not self.currentSaveData then return end
    
    if isTerminal then
        -- Ensure statistics table exists
        if not self.currentSaveData.statistics then
            self.currentSaveData.statistics = {
                totalPlayTime = 0,
                totalRuns = 0,
                totalKills = 0,
                bossesDefeated = 0,
                totalDamageDealt = 0,
                highestLevel = 0
            }
        end

        local stats = self.currentSaveData.statistics
        stats.totalKills = (stats.totalKills or 0) + self.runStatistics.kills
        stats.totalDamageDealt = (stats.totalDamageDealt or 0) + self.runStatistics.damageDealt
        stats.totalPlayTime = (stats.totalPlayTime or 0) + self.runStatistics.runTime
        stats.totalRuns = (stats.totalRuns or 0) + 1
        stats.bossesDefeated = (stats.bossesDefeated or 0) + self.runStatistics.bossesDefeated
        stats.highestLevel = math.max(stats.highestLevel or 0, self.runStatistics.highestLevel)

        -- Use the global currentSaveSlot if not explicitly stored
        local slot = self.currentSaveSlot or _G.currentSaveSlot
        if slot then
            savemanager.createSave(slot, self.currentSaveData)
        end
    end
end

function state:checkGameplayUnlocks()
    if not self.currentSaveData then return end
    
    local newUnlocks = Unlocks.checkUnlocks(self.currentSaveData, self.runStatistics)
    
    if #newUnlocks > 0 then
        -- Add to save data
        for _, unlock in ipairs(newUnlocks) do
            if unlock.type == "ship" then
                self.currentSaveData.unlockedShips = self.currentSaveData.unlockedShips or {}
                table.insert(self.currentSaveData.unlockedShips, unlock.id)
            elseif unlock.type == "weapon" then
                self.currentSaveData.unlockedWeapons = self.currentSaveData.unlockedWeapons or {}
                table.insert(self.currentSaveData.unlockedWeapons, unlock.id)
            elseif unlock.type == "passive" then
                self.currentSaveData.unlockedPassives = self.currentSaveData.unlockedPassives or {}
                table.insert(self.currentSaveData.unlockedPassives, unlock.id)
            end
            
            -- Queue notification for later
            self.runStatistics.queuedNotifications = self.runStatistics.queuedNotifications or {}
            table.insert(self.runStatistics.queuedNotifications, "UNLOCKED: " .. unlock.name)
        end
        
        -- Mark items as unlocked in the currentSaveData structure to prevent re-triggering
        self.currentSaveData.unlockedItems = self.currentSaveData.unlockedItems or {}
        for _, unlock in ipairs(newUnlocks) do
            table.insert(self.currentSaveData.unlockedItems, unlock.id)
        end
        
        -- Save immediately to persist the unlock
        self:saveProgress(false)
    end
end

function state:update(dt)
    -- Always update background, screenshake, and particles, even when paused
    self.background:update(dt)
    self.screenshake.update(dt)
    self.particles.update(dt)
    self.damageNumbers.update(dt)
    self.telegraph:update(dt)
    if self.screenFlash.active then
        self.screenFlash.elapsed = self.screenFlash.elapsed + dt
        if self.screenFlash.elapsed >= self.screenFlash.duration then
            self.screenFlash.active = false
        end
    end

    if self.bossEntranceTimer > 0 then
        self.bossEntranceTimer = self.bossEntranceTimer - dt
    end

    if self.isPaused or self.isPausedByPlayer or self.isVictory then return end

    self.gameTime = self.gameTime + dt
    
    -- Track run statistics
    self.runStatistics.runTime = self.runStatistics.runTime + dt
    if self.player.level > self.runStatistics.highestLevel then
        self.runStatistics.highestLevel = self.player.level
    end

    -- Trigger boss spawn
    if self.gameTime >= self.bossSpawnTime and not self.bossSpawned then
        local bossLookup = dl.createLookup(dl.getBosses(), "id")
        local bossData = bossLookup[self.stageBoss] or dl.getBosses()[1]
        self.boss = Boss.new(Layout.centerX(), 80, bossData)
        self.bossSpawned = true
        self.enemySpawner:stop()
        self.screenshake.trigger(15, 1.0)
        self.particles.bossHit(self.boss.x, self.boss.y)
        self.bossEntranceTimer = 2.0
    end

    local oldLevel = self.player.level
    self.player:update(dt)
    self.enemySpawner:update(dt, self.player.x, self.player.y)
    
    if self.boss then
        self.boss:update(dt, self.player.x, self.player.y, self.telegraph)
        
        -- Special Attack Flash
        if self.boss.isSpecialAttacking and not self.wasBossSpecialAttacking then
            self:flashScreen(Colors.COLORS.danger, 0.5, 0.3)
            self.screenshake.trigger(10, 0.5)
        end
        self.wasBossSpecialAttacking = self.boss.isSpecialAttacking

        -- Phase Transition Flash
        if self.boss.isTransitioning and not self.wasBossTransitioning then
            self:flashScreen({1, 1, 1, 1}, 0.4, 0.5) -- White flash for phase change
            self.screenshake.trigger(15, 0.6)
        end
        self.wasBossTransitioning = self.boss.isTransitioning

        if self.boss.isDead then
            self.isVictory = true
            self.enemiesKilled = self.enemiesKilled + 1
            self.runStatistics.kills = self.runStatistics.kills + 1
            self.runStatistics.bossesDefeated = self.runStatistics.bossesDefeated + 1
            self:checkGameplayUnlocks()
            self.screenshake.trigger(10, 0.5)
            self.particles.enemyDeath(self.boss.x, self.boss.y)
            
            -- Apply Rewards
            local rewards = self.stageData.rewards or {}
            local unlockedItems = {}
            
            local function addToSet(list, item)
                if not item then return false end
                for _, v in ipairs(list) do
                    if v == item then return false end
                end
                table.insert(list, item)
                return true
            end

            -- Ensure tables exist
            self.currentSaveData.completedStages = self.currentSaveData.completedStages or {}
            self.currentSaveData.unlockedStages = self.currentSaveData.unlockedStages or {}
            self.currentSaveData.unlockedShips = self.currentSaveData.unlockedShips or {}
            self.currentSaveData.unlockedWeapons = self.currentSaveData.unlockedWeapons or {}

            -- Unlock Ship
            if rewards.unlockShip and addToSet(self.currentSaveData.unlockedShips, rewards.unlockShip) then
                table.insert(unlockedItems, "NEW SHIP UNLOCKED!")
            end
            -- Unlock Weapon
            if rewards.unlockWeapon and addToSet(self.currentSaveData.unlockedWeapons, rewards.unlockWeapon) then
                table.insert(unlockedItems, "NEW WEAPON UNLOCKED!")
            end
            -- Unlock Stage (Explicit Reward)
            if rewards.unlockStage then
                addToSet(self.currentSaveData.unlockedStages, rewards.unlockStage)
            end
            -- Mark Current Stage Completed
            addToSet(self.currentSaveData.completedStages, self.stageData.id)
            self:checkGameplayUnlocks()

            self.victoryStats = {
                timeSurvived = self.gameTime,
                level = self.player.level,
                enemiesKilled = self.enemiesKilled,
                notifications = unlockedItems
            }
            
            self.victoryMenu = Menu.new({"Retry", "Stage Select", "Main Menu"})
            self:saveProgress(true)
        end
    end

    local bullets = self.player:getBullets()
    local enemies = self.enemySpawner:getEnemies()

    -- Bullet-Enemy Collisions
    for _, b in ipairs(bullets) do
        -- Ensure hit tracking exists (now in Bullet.new but safety first)
        b.hitEnemies = b.hitEnemies or {}
        
        for _, e in ipairs(enemies) do
            if not b.isDead and not e.isDead and not b.hitEnemies[e] then
                -- Define collision radius based on pattern
                local bRadius = 4
                if b.weaponData.pattern == "cloud" then
                    bRadius = 5 * (b.weaponData.area or 1.0)
                elseif b.weaponData.pattern == "whip" then
                    bRadius = 3 * (b.weaponData.area or 1.0)
                elseif b.weaponData.pattern == "wave" then
                    bRadius = b.waveRadius or 0
                end

                -- Continuous Collision Check (Segment vs Circle)
                if checkSegmentCircleCollision(b.oldX, b.oldY, b.x, b.y, e.x, e.y, e.radius + bRadius) then
                    if b.weaponData.pattern == "mines" then
                        b:explode()
                        break
                    end
                    
                    local damage = b.weaponData.damage
                    e:takeDamage(damage)
                    self.damageNumbers.spawn(e.x, e.y, damage, false)
                    self.runStatistics.damageDealt = self.runStatistics.damageDealt + damage
                    
                    b.hitEnemies[e] = true
                    
                    -- Only break if not a cloud, whip, or wave (these can hit multiple enemies)
                    if b.weaponData.pattern ~= "cloud" and b.weaponData.pattern ~= "whip" and b.weaponData.pattern ~= "wave" then
                        -- Handle Special: Chains
                        if b.weaponData.special == "chains" then
                            local chainCount = b.weaponData.amount or 1
                            local chainRange = 150 * (b.weaponData.area or 1.0)
                            local currentSource = e
                            
                            for i = 1, chainCount do
                                local nearest = nil
                                local minDist = chainRange
                                
                                -- Check regular enemies
                                for _, nextE in ipairs(enemies) do
                                    if not nextE.isDead and nextE ~= currentSource and not b.hitEnemies[nextE] then
                                        local dx, dy = nextE.x - currentSource.x, nextE.y - currentSource.y
                                        local distSq = dx*dx + dy*dy
                                        if distSq < minDist*minDist then
                                            minDist = math.sqrt(distSq)
                                            nearest = nextE
                                        end
                                    end
                                end
                                
                                -- Check boss
                                if self.boss and not self.boss.isDead and self.boss ~= currentSource and not b.hitEnemies[self.boss] then
                                    local dx, dy = self.boss.x - currentSource.x, self.boss.y - currentSource.y
                                    local distSq = dx*dx + dy*dy
                                    if distSq < minDist*minDist then
                                        minDist = math.sqrt(distSq)
                                        nearest = self.boss
                                    end
                                end
                                
                                if nearest then
                                    local chainDamage = math.floor(b.weaponData.damage * 0.5)
                                    nearest:takeDamage(chainDamage)
                                    self.damageNumbers.spawn(nearest.x, nearest.y, chainDamage, false)
                                    self.runStatistics.damageDealt = self.runStatistics.damageDealt + chainDamage
                                    b.hitEnemies[nearest] = true
                                    
                                    -- Visual Effect
                                    self.particles.lightningChain(currentSource.x, currentSource.y, nearest.x, nearest.y, "accent")
                                    
                                    currentSource = nearest
                                    
                                    -- Handle enemy death for each link in the chain
                                    if nearest ~= self.boss and nearest.isDead and not nearest.xpGiven then
                                        self.player:addXP(nearest.xpValue)
                                        nearest.xpGiven = true
                                        self.enemiesKilled = self.enemiesKilled + 1
                                        self.runStatistics.kills = self.runStatistics.kills + 1
                                        self.screenshake.trigger(2, 0.1)
                                        self.particles.enemyDeath(nearest.x, nearest.y)
                                        self.particles.xpPickup(self.player.x, self.player.y)
                                    end
                                else
                                    break
                                end
                            end
                        end
                        
                        -- Handle Pierce
                        if b.weaponData.pierce and b.weaponData.pierce > 0 then
                            b.weaponData.pierce = b.weaponData.pierce - 1
                        else
                            b.isDead = true
                        end
                    end
                    
                    if e.isDead and not e.xpGiven then
                        self.player:addXP(e.xpValue)
                        e.xpGiven = true
                        self.enemiesKilled = self.enemiesKilled + 1
                        self.runStatistics.kills = self.runStatistics.kills + 1
                        self:checkGameplayUnlocks()
                        self.screenshake.trigger(2, 0.1)
                        self.particles.enemyDeath(e.x, e.y)
                        self.particles.xpPickup(self.player.x, self.player.y)
                    end
                    
                    -- Break the enemy loop since this bullet might have moved or died
                    if b.isDead then break end
                end
            end
        end

        -- Bullet-Boss Collisions
        if self.boss and not self.boss.isDead and not b.isDead and not b.hitEnemies[self.boss] then
            local bRadius = 4
            if b.weaponData.pattern == "cloud" then
                bRadius = 5 * (b.weaponData.area or 1.0)
            elseif b.weaponData.pattern == "whip" then
                bRadius = 3 * (b.weaponData.area or 1.0)
            elseif b.weaponData.pattern == "wave" then
                bRadius = b.waveRadius or 0
            end

            if checkSegmentCircleCollision(b.oldX, b.oldY, b.x, b.y, self.boss.x, self.boss.y, self.boss.radius + bRadius) then
                if b.weaponData.pattern == "mines" then
                    b:explode()
                else
                    local damage = b.weaponData.damage
                    self.boss:takeDamage(damage)
                    self.damageNumbers.spawn(b.x, b.y, damage, false)
                    self.runStatistics.damageDealt = self.runStatistics.damageDealt + damage

                    b.hitEnemies[self.boss] = true

                    if b.weaponData.pierce and b.weaponData.pierce > 0 then
                        b.weaponData.pierce = b.weaponData.pierce - 1
                    else
                        -- Don't kill clouds, whips, or waves on boss hit
                        if b.weaponData.pattern ~= "cloud" and b.weaponData.pattern ~= "whip" and b.weaponData.pattern ~= "wave" then
                            b.isDead = true
                        end
                    end

                    self.screenshake.trigger(5, 0.15)
                    self.particles.bossHit(b.x, b.y)
                end
            end
        end
    end

    -- Enemy-Player Collisions
    for _, e in ipairs(enemies) do
        if not e.isDead then
            if checkCircleCollision(self.player.x, self.player.y, self.player.radius, e.x, e.y, e.radius) then
                self.player:takeDamage(e:getContactDamage())
                e.isDead = true
                self.screenshake.trigger(8, 0.2)
                self.particles.playerHit(self.player.x, self.player.y)
            end

            -- Enemy Bullet-Player Collisions
            local eBullets = e:getBullets()
            for _, eb in ipairs(eBullets) do
                if not eb.isDead then
                    if checkCircleCollision(eb.x, eb.y, eb.radius or 6, self.player.x, self.player.y, self.player.radius) then
                        self.player:takeDamage(eb.patternData.damage or 5)
                        eb.isDead = true
                        self.particles.playerHit(self.player.x, self.player.y)
                        self.screenshake.trigger(6, 0.15)
                    end
                end
            end
        end
    end

    -- Boss Bullet-Player Collisions
    if self.boss and not self.boss.isDead then
        -- Player-Boss Body Contact Collision
        if checkCircleCollision(self.player.x, self.player.y, self.player.radius, self.boss.x, self.boss.y, self.boss.radius) then
            self.player:takeDamage(self.boss:getContactDamage() * dt * 60)
            self.screenshake.trigger(10, 0.1)
            self.particles.playerHit(self.player.x, self.player.y)
        end

        local bBullets = self.boss:getBullets()
        for _, bb in ipairs(bBullets) do
            if not bb.isDead then
                if checkCircleCollision(bb.x, bb.y, bb.radius or 8, self.player.x, self.player.y, self.player.radius) then
                    self.player:takeDamage(bb.patternData.damage or 10)
                    bb.isDead = true
                    self.screenshake.trigger(8, 0.2)
                    self.particles.playerHit(self.player.x, self.player.y)
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
        self:saveProgress(true)
        sm.switch("gameover", stats, self.currentSaveData)
        return
    end

    if self.player.level > oldLevel then
        self.isPaused = true
        self.upgradeMenu = UpgradeMenu.new(self.player)
        self:checkGameplayUnlocks()
    end

    -- Global Death Processing (Catch-all for AOE/Chains)
    for _, e in ipairs(enemies) do
        if e.isDead and not e.xpGiven then
            self.player:addXP(e.xpValue)
            e.xpGiven = true
            self.enemiesKilled = self.enemiesKilled + 1
            self.runStatistics.kills = self.runStatistics.kills + 1
            self.screenshake.trigger(2, 0.1)
            self.particles.enemyDeath(e.x, e.y)
            self.particles.xpPickup(self.player.x, self.player.y)
            self:checkGameplayUnlocks()
        end
    end
end

function state:keypressed(key)
    if self.isVictory and self.victoryMenu then
        local selection = self.victoryMenu:keypressed(key)
        if selection == 1 then -- Retry
            sm.switch("game")
        elseif selection == 2 then -- Stage Select
            sm.switch("stage_select", self.currentSaveData)
        elseif selection == 3 then -- Main Menu
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
    if upgrade.type == "weapon" then
        self.player:upgradeWeapon(upgrade.id)
    elseif upgrade.type == "passive" then
        self.player:upgradePassive(upgrade.id)
    end
end
function state:draw()
    Screen.applyScale()
    local oldFont = love.graphics.getFont()
    self.background:draw()

    love.graphics.push()
    self.screenshake.apply()

    -- Corner Brackets (radar screen feel)
    local vw, vh = Screen.getVirtualWidth(), Screen.getVirtualHeight()
    local hudW = 220
    local time = love.timer.getTime()
    local bPulse = math.sin(time * 3) * 5
    local bSize = 20 + bPulse
    local bAlpha = 0.6 + math.sin(time * 2) * 0.2
    
    love.graphics.setLineWidth(1)
    Colors.setColor("accent", bAlpha)
    
    -- Top Left
    love.graphics.line(hudW, 0, hudW + bSize, 0)
    love.graphics.line(hudW, 0, hudW, bSize)
    -- Top Right
    love.graphics.line(vw - bSize, 0, vw, 0)
    love.graphics.line(vw, 0, vw, bSize)
    -- Bottom Left
    love.graphics.line(hudW, vh - bSize, hudW, vh)
    love.graphics.line(hudW, vh, hudW + bSize, vh)
    -- Bottom Right
    love.graphics.line(vw - bSize, vh, vw, vh)
    love.graphics.line(vw, vh - bSize, vw, vh)

    self.player:draw()
    
    -- Apply background tint for game elements
    love.graphics.setColor(self.backgroundTint[1], self.backgroundTint[2], self.backgroundTint[3], 1.0)
    self.enemySpawner:draw()
    
    if self.boss then
        self.boss:draw()
        
        -- Global Boss Health Bar (Background)
        if not self.boss.isDead then
            local barWidth = 600
            local barHeight = 10
            local barX = hudW + (vw - hudW - barWidth) / 2
            local barY = 15
            
            love.graphics.setColor(0.2, 0, 0)
            love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
            
            local fillPercent = math.max(0, self.boss.health / self.boss.maxHealth)
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", barX, barY, barWidth * fillPercent, barHeight)
            
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
        end
    end
    
    -- Reset tint
    love.graphics.setColor(1, 1, 1, 1)

    self.particles.draw()
    self.damageNumbers.draw()
    self.telegraph:draw()
    
    love.graphics.pop()

    -- HUD
    self.hud:draw(self.player, self)

    -- Boss Entrance Warning
    if self.bossEntranceTimer > 0 then
        -- Flash effect
        local flashAlpha = math.min(0.5, self.bossEntranceTimer)
        love.graphics.setColor(1, 0, 0, flashAlpha)
        love.graphics.rectangle("fill", hudW, 0, vw - hudW, vh)
        
        -- Text Warning
        if math.floor(love.timer.getTime() * 5) % 2 == 0 then
            love.graphics.setColor(1, 0, 0)
            love.graphics.setFont(Fonts.getFont("large"))
            love.graphics.printf("WARNING: BOSS DETECTED", hudW, vh * 0.4, vw - hudW, "center")
        end
    end

    if self.isPaused and self.upgradeMenu then
        self.upgradeMenu:draw()
    end

    if self.isVictory then
        -- Semi-transparent gold overlay
        love.graphics.setColor(0.1, 0.1, 0, 0.8)
        love.graphics.rectangle("fill", hudW, 0, vw - hudW, vh)
        
        love.graphics.setColor(1, 0.8, 0)
        love.graphics.setFont(Fonts.getFont("huge"))
        love.graphics.printf("VICTORY!", hudW, vh * 0.2, vw - hudW, "center")
        
        love.graphics.setFont(Fonts.getFont("normal"))
        love.graphics.setColor(1, 1, 1)
        local statsY = vh * 0.4
        if self.victoryStats then
            local mins = math.floor(self.victoryStats.timeSurvived / 60)
            local secs = math.floor(self.victoryStats.timeSurvived % 60)
            love.graphics.printf(string.format("Time: %02d:%02d", mins, secs), hudW, statsY, vw - hudW, "center")
            love.graphics.printf("Level: " .. self.victoryStats.level, hudW, statsY + 30, vw - hudW, "center")
            love.graphics.printf("Enemies Killed: " .. self.victoryStats.enemiesKilled, hudW, statsY + 60, vw - hudW, "center")
            
            -- Draw Notifications (Rewards)
            if self.victoryStats.notifications and #self.victoryStats.notifications > 0 then
                love.graphics.setColor(0.4, 1, 0.4)
                local notifyY = statsY + 110
                for _, msg in ipairs(self.victoryStats.notifications) do
                    love.graphics.printf(msg, hudW, notifyY, vw - hudW, "center")
                    notifyY = notifyY + 30
                end
            end
        end
        
        if self.victoryMenu then
            self.victoryMenu:draw(hudW + (vw - hudW) / 2, vh * 0.65)
        end
        
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Arrows Keys: Move | Z: Select", hudW, vh - 50, vw - hudW, "center")
    end

    if self.isPausedByPlayer and self.pauseMenu then
        -- Semi-transparent dark overlay (only game area)
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", hudW, 0, vw - hudW, vh)
        
        -- "PAUSED" text at top
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(Fonts.getFont("large"))
        local text = "PAUSED"
        love.graphics.printf(text, hudW, 100, vw - hudW, "center")
        
        self.pauseMenu:draw(hudW + (vw - hudW) / 2, vh / 2)
    end
    love.graphics.setFont(oldFont)

    Scanlines.drawScanlines()

    if self.screenFlash.active then
        local sf = self.screenFlash
        local progress = math.max(0, math.min(1, sf.elapsed / math.max(0.0001, sf.duration)))
        local alpha = sf.intensity * (1 - progress)
        if alpha > 0 then
            love.graphics.setColor(sf.color[1], sf.color[2], sf.color[3], alpha)
            love.graphics.rectangle("fill", 0, 0, vw, vh)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)

    Screen.removeScale()
end

return state
