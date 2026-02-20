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

function WS:update(dt, playerX, playerY, damageMult, fireRateMult)
    self.damageMult = damageMult or 1
    self.fireRateMult = fireRateMult or 1
    if not self.lookup then self.lookup = dl.createLookup(dl.getWeapons(), "id") end

    for _, id in ipairs(self.equippedWeapons) do
        local wd = self.lookup[id]
        if wd then
            self.shootTimers[id] = self.shootTimers[id] + dt
            if self.shootTimers[id] >= (wd.fireRate * self.fireRateMult) then
                local bulletWeaponData = {
                    damage = wd.damage * self.damageMult,
                    bulletSpeed = wd.bulletSpeed,
                    pattern = wd.pattern
                }
                table.insert(self.bullets, Bullet.new(playerX, playerY, bulletWeaponData))
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
