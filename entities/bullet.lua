local Colors = require('ui.colors')
local Screen = require('systems.screen')
local Particles = require('systems.particles')

local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(x, y, weaponData)
    local self = setmetatable({}, Bullet)
    self.x, self.y = x, y
    self.weaponData = weaponData
    self.isDead = false
    self.lifeTimer = weaponData.duration or nil
    self.isExploded = false
    return self
end

function Bullet:explode()
    if self.isExploded then return end
    self.isExploded = true
    self.isDead = true

    Particles.explosion(self.x, self.y, self.weaponData.area or 1.0)

    -- AOE Damage
    if self.enemies then
        local areaRange = 60 * (self.weaponData.area or 1.0)
        for _, e in ipairs(self.enemies) do
            if not e.isDead then
                local dx, dy = e.x - self.x, e.y - self.y
                local distSq = dx*dx + dy*dy
                if distSq < areaRange*areaRange then
                    local damage = self.weaponData.damage
                    e:takeDamage(damage)

                    if self.gameState then
                        self.gameState.damageNumbers.spawn(e.x, e.y, damage, false)
                        self.gameState.runStatistics.damageDealt = self.gameState.runStatistics.damageDealt + damage
                    end
                end
            end
        end
    end
end
function Bullet:update(dt)
    local pattern = require("patterns/player_" .. self.weaponData.pattern)
    pattern.update(self, dt)

    if self.lifeTimer then
        self.lifeTimer = self.lifeTimer - dt
        if self.lifeTimer <= 0 then 
            if self.weaponData.pattern == "mines" then
                self:explode()
            else
                self.isDead = true 
            end
        end
    end

    -- Bounds check: Don't kill orbital drones for being off-screen
    if self.weaponData.pattern ~= "orbital" then
        local margin = 100
        if self.y < -margin or self.y > Screen.getVirtualHeight() + margin or
           self.x < -margin or self.x > Screen.getVirtualWidth() + margin then
            self.isDead = true
        end
    end
end

function Bullet:draw()
    if self.weaponData.pattern == "mines" then
        -- Draw faint radius circle for mines
        local areaRange = 60 * (self.weaponData.area or 1.0)
        Colors.setColor("accent", 0.05)
        love.graphics.circle("line", self.x, self.y, areaRange)
        
        -- Subtle fill
        Colors.setColor("accent", 0.02)
        love.graphics.circle("fill", self.x, self.y, areaRange)
    end

    local drawShape = function()
        if self.weaponData.pattern == "mines" then
            -- Octagon/Circle shape for mines
            love.graphics.circle("fill", 0, 0, 6)
            love.graphics.rectangle("fill", -8, -2, 16, 4)
            love.graphics.rectangle("fill", -2, -8, 4, 16)
        else
            -- Diamond/Rectangle shape for standard bullets
            love.graphics.polygon("fill", 0, -5, -2, 0, 0, 5, 2, 0)
        end
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)

    -- 3-pass glow effect
    -- Outer glow
    love.graphics.push()
    love.graphics.scale(1.3, 1.3)
    Colors.setColor("accent", 0.1)
    drawShape()
    love.graphics.pop()

    -- Mid glow
    love.graphics.push()
    love.graphics.scale(1.15, 1.15)
    Colors.setColor("accent", 0.2)
    drawShape()
    love.graphics.pop()

    -- Main bullet/mine
    if self.weaponData.pattern == "mines" and self.lifeTimer and self.lifeTimer < 1.0 then
        -- Blink red when about to explode
        if math.floor(love.timer.getTime() * 10) % 2 == 0 then
            Colors.setColor("danger", 0.9)
        else
            Colors.setColor("accent", 0.9)
        end
    else
        Colors.setColor("accent", 0.9)
    end
    drawShape()

    love.graphics.pop()
end

return Bullet
