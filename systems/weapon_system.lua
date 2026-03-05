local Bullet = require "entities/bullet"
local dl = require "systems/dataloader"

local WS = {}
WS.__index = WS

function WS.new()
    local self = setmetatable({
        equippedWeapons = {},
        bullets = {},
        shootTimers = {}
    }, WS)
    return self
end

function WS:equipWeapon(weaponId)
    table.insert(self.equippedWeapons, weaponId)
    self.shootTimers[weaponId] = 0
end

function WS:update(dt, playerX, playerY, might, cooldown, area, amountBonus, pierceBonus)
    if not self.lookup then self.lookup = dl.createLookup(dl.getWeapons(), "id") end

    for _, id in ipairs(self.equippedWeapons) do
        local wd = self.lookup[id]
        if wd then
            self.shootTimers[id] = self.shootTimers[id] + dt
            
            local finalFireRate = wd.fireRate * (cooldown or 1.0)
            
            if self.shootTimers[id] >= finalFireRate then
                local weaponAmount = wd.amount or 1
                local finalAmount = weaponAmount + (amountBonus or 0)
                
                if wd.pattern == "orbital" or wd.pattern == "whip" then
                    -- Count existing orbital/whip bullets for this weapon
                    local currentCount = 0
                    for _, b in ipairs(self.bullets) do
                        if b.weaponData.id == id then
                            currentCount = currentCount + 1
                        end
                    end
                    
                    if currentCount < finalAmount then
                        local toSpawn = finalAmount - currentCount
                        for i = 1, toSpawn do
                            local bulletWeaponData = {
                                id = id,
                                damage = wd.damage * (might or 1.0),
                                bulletSpeed = wd.bulletSpeed,
                                pattern = wd.pattern,
                                area = (wd.area or 1.0) * (area or 1.0),
                                pierce = (wd.pierce or 0) + (pierceBonus or 0),
                                amount = finalAmount,
                                special = wd.special
                            }
                            local b = Bullet.new(playerX, playerY, bulletWeaponData)
                            -- Spread out based on final count
                            b.orbitAngle = ((currentCount + i - 1) / finalAmount) * math.pi * 2
                            table.insert(self.bullets, b)
                        end
                    end
                else
                    -- Mines: Only fire if NO bullets of this weapon already exist
                    if wd.pattern == "mines" then
                        local exists = false
                        for _, b in ipairs(self.bullets) do
                            if b.weaponData.id == id then
                                exists = true
                                break
                            end
                        end
                        if exists then
                            -- Reset timer to 0 so it only starts counting AFTER they are gone
                            self.shootTimers[id] = 0
                        else
                            -- Original spawn logic
                            for i = 1, finalAmount do
                                local bulletWeaponData = {
                                    id = id,
                                    damage = wd.damage * (might or 1.0),
                                    bulletSpeed = wd.bulletSpeed,
                                    pattern = wd.pattern,
                                    area = (wd.area or 1.0) * (area or 1.0),
                                    pierce = (wd.pierce or 0) + (pierceBonus or 0),
                                    amount = finalAmount,
                                    special = wd.special,
                                    duration = (wd.duration or 3.0) * (cooldown or 1.0)
                                }
                                
                                local b = Bullet.new(playerX, playerY, bulletWeaponData)
                                
                                -- Default horizontal offset for multiple bullets
                                local xOffset = 0
                                if finalAmount > 1 then
                                    xOffset = (i - (finalAmount + 1) / 2) * 15
                                end
                                b.x = b.x + xOffset
                                
                                table.insert(self.bullets, b)
                            end
                            self.shootTimers[id] = 0
                        end
                    else
                        -- Regular spawn logic for non-mines
                        for i = 1, finalAmount do
                            local bulletWeaponData = {
                                id = id,
                                damage = wd.damage * (might or 1.0),
                                bulletSpeed = wd.bulletSpeed,
                                pattern = wd.pattern,
                                area = (wd.area or 1.0) * (area or 1.0),
                                pierce = (wd.pierce or 0) + (pierceBonus or 0),
                                amount = finalAmount,
                                special = wd.special,
                                duration = wd.duration
                            }
                            
                            local b = Bullet.new(playerX, playerY, bulletWeaponData)
                            
                            -- Pattern-specific initialization
                            if wd.pattern == "spread" then
                                local spreadAngle = wd.spreadAngle or 30
                                local angleRad = math.rad(spreadAngle)
                                if finalAmount > 1 then
                                    local startAngle = -math.pi/2 - angleRad/2
                                    local angleStep = angleRad / (finalAmount - 1)
                                    b.angle = startAngle + (i - 1) * angleStep
                                else
                                    b.angle = -math.pi/2
                                end
                            else
                                -- Default horizontal offset for multiple bullets
                                local xOffset = 0
                                if finalAmount > 1 then
                                    xOffset = (i - (finalAmount + 1) / 2) * 15
                                end
                                b.x = b.x + xOffset
                            end
                            
                            table.insert(self.bullets, b)
                        end
                        self.shootTimers[id] = 0
                    end
                end
            end
        end
    end

    -- Get enemies for homing/orbital patterns
    local sm = require("states/statemanager")
    local enemies = {}
    if sm.current and sm.current.enemySpawner then
        local spawnerEnemies = sm.current.enemySpawner:getEnemies()
        for _, e in ipairs(spawnerEnemies) do
            if not e.isDead then table.insert(enemies, e) end
        end
    end
    -- Include boss as a potential target
    local boss = sm.current and sm.current.boss
    if boss and not boss.isDead then
        table.insert(enemies, boss)
    end

    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        -- Pass context to bullet for pattern logic
        b.enemies = enemies
        b.playerX = playerX
        b.playerY = playerY
        b.gameState = sm.current
        
        b:update(dt)
        if b.isDead then table.remove(self.bullets, i) end
    end
end

function WS:draw()
    for _, b in ipairs(self.bullets) do b:draw() end
end

function WS:getBullets() return self.bullets end

return WS
