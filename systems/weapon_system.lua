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

function WS:update(dt, playerX, playerY, might, cooldown, area, amountBonus)
    if not self.lookup then self.lookup = dl.createLookup(dl.getWeapons(), "id") end

    for _, id in ipairs(self.equippedWeapons) do
        local wd = self.lookup[id]
        if wd then
            self.shootTimers[id] = self.shootTimers[id] + dt
            
            local finalFireRate = wd.fireRate * (cooldown or 1.0)
            
            if self.shootTimers[id] >= finalFireRate then
                local weaponAmount = wd.amount or 1
                local finalAmount = math.floor(weaponAmount * (1 + (amountBonus or 0)))
                
                for i = 1, finalAmount do
                    local bulletWeaponData = {
                        damage = wd.damage * (might or 1.0),
                        bulletSpeed = wd.bulletSpeed,
                        pattern = wd.pattern,
                        area = (wd.area or 1.0) * (area or 1.0)
                    }
                    
                    -- Simple horizontal spread for multiple bullets
                    local xOffset = 0
                    if finalAmount > 1 then
                        xOffset = (i - (finalAmount + 1) / 2) * 15
                    end
                    
                    table.insert(self.bullets, Bullet.new(playerX + xOffset, playerY, bulletWeaponData))
                end
                self.shootTimers[id] = 0
            end
        end
    end

    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b:update(dt)
        if b.isDead then table.remove(self.bullets, i) end
    end
end

function WS:draw()
    for _, b in ipairs(self.bullets) do b:draw() end
end

function WS:getBullets() return self.bullets end

return WS
