local Bullet = require "entities/bullet"
local dl = require "systems/dataloader"

local WEAPON_SOUNDS = {
  -- Base weapons
  plasma_lance = { name = "weapons.plasma_lance", vol = 1.0 },
  missile_swarm = { name = "weapons.missile_swarm", vol = 1.0 },
  arc_conductor = { name = "weapons.arc_conductor", vol = 0.6 }, -- Lower volume for rapid fire
  scatter_blaster = { name = "weapons.scatter_blaster", vol = 1.0 },
  orbital_drones = { name = "weapons.orbital_drones", vol = 0.6 }, -- Lower volume for rapid fire
  gravity_mines = { name = "weapons.gravity_mines_drop", vol = 1.0 },
  railgun = { name = "weapons.railgun", vol = 1.2 }, -- Higher volume for impact
  nanite_swarm = nil,  -- No sound file for this weapon
  photon_whip = { name = "weapons.photon_whip", vol = 0.8 },
  pulse_wave = { name = "weapons.pulse_wave", vol = 1.2 }, -- Higher volume for impact
  
  -- Evolved weapons (use base weapon sounds)
  quantum_splitter = { name = "weapons.plasma_lance", vol = 1.0 },
  apocalypse_barrage = { name = "weapons.missile_swarm", vol = 1.0 },
  tesla_storm = { name = "weapons.arc_conductor", vol = 0.6 },
  shrapnel_cannon = { name = "weapons.scatter_blaster", vol = 1.0 },
  sentinel_network = { name = "weapons.orbital_drones", vol = 0.6 },
  singularity_engine = { name = "weapons.gravity_mines_drop", vol = 1.0 },
  annihilator_cannon = { name = "weapons.railgun", vol = 1.2 },
  grey_goo_protocol = nil,  -- Uses nanite_swarm (no sound)
  solar_flare = { name = "weapons.photon_whip", vol = 0.8 },
  electromagnetic_cataclysm = { name = "weapons.pulse_wave", vol = 1.2 }
}

local WS = {}
WS.__index = WS

function WS.new(audioManager)
    local self = setmetatable({
        equippedWeapons = {},
        bullets = {},
        shootTimers = {},
        bursts = {},
        audioManager = audioManager
    }, WS)
    return self
end

function WS:getWeaponSound(weaponId)
  local data = WEAPON_SOUNDS[weaponId]
  if data then
    return data.name, data.vol
  end
  return nil
end

function WS:checkEvolution(weaponId, equippedPassives, weaponLevel)
    if not self.lookup then self.lookup = dl.createLookup(dl.getWeapons(), "id") end
    local wd = self.lookup[weaponId]
    if not wd or not wd.evolution then return nil end
    
    if (weaponLevel or 1) < 5 then return nil end
    
    local required = wd.evolution.requiredPassive
    local hasPassive = false
    for _, pId in ipairs(equippedPassives or {}) do
        if pId == required then
            hasPassive = true
            break
        end
    end
    
    if hasPassive then
        return wd.evolution.id
    end
    
    return nil
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
                -- Adjusted formula: Base + Bonus - 1 (Assuming 1 is the default ship amount)
                -- This ensures Amount 1 ship + Amount 1 weapon = 1 projectile
                local finalAmount = math.max(1, weaponAmount + (amountBonus or 1) - 1)
                
                local soundName, soundVol = self:getWeaponSound(id)

                if wd.pattern == "orbital" or wd.pattern == "whip" then
                    local currentCount = 0
                    for _, b in ipairs(self.bullets) do
                        if b.weaponData.id == id then currentCount = currentCount + 1 end
                    end
                    
                    if currentCount < finalAmount then
                        -- Play weapon sound
                        if soundName and self.audioManager then
                            self.audioManager.playSound(soundName, soundVol)
                        end

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
                                special = wd.special,
                                specialEffect = wd.specialEffect,
                                chainRange = wd.chainRange,
                                explosionRadius = wd.explosionRadius,
                                explosionDamage = wd.explosionDamage,
                                miniMissileCount = wd.miniMissileCount,
                                miniMissileDamage = wd.miniMissileDamage,
                                chainTargets = wd.chainTargets,
                                spreadDamage = wd.spreadDamage,
                                pullRadius = wd.pullRadius,
                                burnDamage = wd.burnDamage,
                                burnDuration = wd.burnDuration
                            }
                            local b = Bullet.new(playerX, playerY, bulletWeaponData)
                            b.orbitAngle = ((currentCount + i - 1) / finalAmount) * math.pi * 2
                            table.insert(self.bullets, b)
                        end
                    end
                    self.shootTimers[id] = 0
                elseif wd.pattern == "wave" then
                    if not self.bursts[id] then
                        self.bursts[id] = {
                            count = finalAmount,
                            timer = 0.25, -- Start slightly delayed or immediate
                            interval = 0.25 
                        }
                    end
                    self.shootTimers[id] = 0
                elseif wd.pattern == "mines" then
                    local exists = false
                    for _, b in ipairs(self.bullets) do
                        if b.weaponData.id == id then exists = true; break end
                    end
                    if exists then
                        self.shootTimers[id] = 0
                    else
                        -- Play weapon sound
                        if soundName and self.audioManager then
                            self.audioManager.playSound(soundName, soundVol)
                        end

                        for i = 1, finalAmount do
                            local bData = {
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
                            local b = Bullet.new(playerX, playerY, bData)
                            local xOffset = (finalAmount > 1) and ((i - (finalAmount + 1) / 2) * 15) or 0
                            b.x = b.x + xOffset
                            table.insert(self.bullets, b)
                        end
                        self.shootTimers[id] = 0
                    end
                else
                    -- Regular patterns
                    -- Play weapon sound
                    if soundName and self.audioManager then
                        self.audioManager.playSound(soundName, soundVol)
                    end

                    for i = 1, finalAmount do
                        local bData = {
                            id = id,
                            damage = wd.damage * (might or 1.0),
                            bulletSpeed = wd.bulletSpeed,
                            pattern = wd.pattern,
                            area = (wd.area or 1.0) * (area or 1.0),
                            pierce = (wd.pierce or 0) + (pierceBonus or 0),
                            amount = finalAmount,
                            special = wd.special,
                            specialEffect = wd.specialEffect,
                            chainRange = wd.chainRange,
                            explosionRadius = wd.explosionRadius,
                            explosionDamage = wd.explosionDamage,
                            miniMissileCount = wd.miniMissileCount,
                            miniMissileDamage = wd.miniMissileDamage,
                            chainTargets = wd.chainTargets,
                            spreadDamage = wd.spreadDamage,
                            pullRadius = wd.pullRadius,
                            burnDamage = wd.burnDamage,
                            burnDuration = wd.burnDuration,
                            duration = wd.duration
                        }
                        local b = Bullet.new(playerX, playerY, bData)
                        if wd.pattern == "spread" then
                            local spreadAngle = math.rad(wd.spreadAngle or 30)
                            if finalAmount > 1 then
                                b.angle = (-math.pi/2 - spreadAngle/2) + (i - 1) * (spreadAngle / (finalAmount - 1))
                            else
                                b.angle = -math.pi/2
                            end
                        else
                            local xOffset = (finalAmount > 1) and ((i - (finalAmount + 1) / 2) * 15) or 0
                            b.x = b.x + xOffset
                        end
                        table.insert(self.bullets, b)
                    end
                    self.shootTimers[id] = 0
                end
            end
        end
    end

    -- Handle Bursts
    if self.bursts then
        for id, burst in pairs(self.bursts) do
            burst.timer = burst.timer + dt
            if burst.timer >= burst.interval then
                local wd = self.lookup[id]
                if wd then
                    local soundName, soundVol = self:getWeaponSound(id)
                    if soundName and self.audioManager then
                        self.audioManager.playSound(soundName, soundVol)
                    end

                    local bData = {
                        id = id,
                        damage = wd.damage * (might or 1.0),
                        bulletSpeed = wd.bulletSpeed,
                        pattern = wd.pattern,
                        area = (wd.area or 1.0) * (area or 1.0),
                        pierce = (wd.pierce or 0) + (pierceBonus or 0),
                        amount = burst.count,
                        special = wd.special,
                        specialEffect = wd.specialEffect,
                        chainRange = wd.chainRange,
                        explosionRadius = wd.explosionRadius,
                        explosionDamage = wd.explosionDamage,
                        miniMissileCount = wd.miniMissileCount,
                        miniMissileDamage = wd.miniMissileDamage,
                        chainTargets = wd.chainTargets,
                        spreadDamage = wd.spreadDamage,
                        pullRadius = wd.pullRadius,
                        burnDamage = wd.burnDamage,
                        burnDuration = wd.burnDuration
                    }
                    local b = Bullet.new(playerX, playerY, bData)
                    table.insert(self.bullets, b)
                end
                burst.count = burst.count - 1
                burst.timer = 0
                if burst.count <= 0 then
                    self.bursts[id] = nil
                    self.shootTimers[id] = 0
                end
            end
        end
    end

    -- Update and Context
    local sm = require("states/statemanager")
    local enemies = {}
    if sm.current and sm.current.enemySpawner then
        for _, e in ipairs(sm.current.enemySpawner:getEnemies()) do
            if not e.isDead then table.insert(enemies, e) end
        end
    end
    if sm.current and sm.current.boss and not sm.current.boss.isDead then
        table.insert(enemies, sm.current.boss)
    end

    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b.enemies = enemies
        b.playerX, b.playerY = playerX, playerY
        b.gameState = sm.current
        b:update(dt)

        -- Handle Gravity Pull
        if not b.isDead and (b.weaponData.special == "black_holes" or b.weaponData.specialEffect == "pull") then
            local pullRange = 150 * (b.weaponData.area or 1.0)
            local pullForce = 200
            for _, e in ipairs(enemies) do
                if not e.isDead then
                    local dx, dy = b.x - e.x, b.y - e.y
                    local distSq = dx*dx + dy*dy
                    if distSq < pullRange*pullRange then
                        local dist = math.sqrt(distSq)
                        if dist > 5 then
                            local force = (1 - dist / pullRange) * pullForce
                            e.pullX = (e.pullX or 0) + (dx / dist) * force
                            e.pullY = (e.pullY or 0) + (dy / dist) * force
                        end
                    end
                end
            end
        end

        if b.isDead then table.remove(self.bullets, i) end
    end
end

function WS:draw()
    for _, b in ipairs(self.bullets) do b:draw() end
end

function WS:getBullets() return self.bullets end

return WS
