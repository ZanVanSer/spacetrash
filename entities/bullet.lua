local Colors = require('ui.colors')
local Screen = require('systems.screen')
local Particles = require('systems.particles')

local Bullet = {}
Bullet.__index = Bullet

function Bullet.new(x, y, weaponData)
    local self = setmetatable({}, Bullet)
    self.x, self.y = x, y
    self.oldX, self.oldY = x, y
    self.weaponData = weaponData
    self.isDead = false
    self.lifeTimer = weaponData.duration or nil
    self.isExploded = false
    self.hitEnemies = {} 
    self.hitResetTimer = 0
    
    -- Cloud/Whip pre-generation
    if weaponData.pattern == "cloud" then
        self.naniteOffsets = {}
        local step = 0.15 
        for ix = -1, 1, step do
            for iy = -1, 1, step do
                if ix*ix + iy*iy <= 1 then
                    table.insert(self.naniteOffsets, {
                        x = ix, 
                        y = iy, 
                        phase = math.random() * math.pi * 2,
                        visible = math.random() > 0.3 
                    })
                end
            end
        end
    end
    
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
    self.oldX, self.oldY = self.x, self.y
    local pattern = require("patterns/player_" .. self.weaponData.pattern)
    pattern.update(self, dt)

    -- Tick reset for DoT patterns
    if self.weaponData.pattern == "cloud" or self.weaponData.pattern == "whip" then
        self.hitResetTimer = self.hitResetTimer + dt
        local resetTime = (self.weaponData.pattern == "whip") and 0.25 or 0.5
        if self.hitResetTimer >= resetTime then 
            self.hitEnemies = {}
            self.hitResetTimer = 0
        end
    end

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

    -- Bounds check
    if self.weaponData.pattern ~= "orbital" and self.weaponData.pattern ~= "whip" then
        local margin = 100
        if self.y < -margin or self.y > Screen.getVirtualHeight() + margin or
           self.x < -margin or self.x > Screen.getVirtualWidth() + margin then
            self.isDead = true
        end
    end
end

function Bullet:draw()
    if self.weaponData.pattern == "mines" then
        local areaRange = 60 * (self.weaponData.area or 1.0)
        Colors.setColor("accent", 0.05)
        love.graphics.circle("line", self.x, self.y, areaRange)
        Colors.setColor("accent", 0.02)
        love.graphics.circle("fill", self.x, self.y, areaRange)
    elseif self.weaponData.pattern == "cloud" then
        local areaRange = 5 * (self.weaponData.area or 1.0)
        local pulse = 1.0 + math.sin(love.timer.getTime() * 4) * 0.05
        Colors.setColor("xp", 0.1)
        love.graphics.circle("fill", self.x, self.y, areaRange * pulse)
        Colors.setColor("xp", 0.15)
        love.graphics.circle("line", self.x, self.y, areaRange * pulse)
    elseif self.weaponData.pattern == "whip" then
        -- Draw the whip tail connecting to player
        if self.playerX and self.playerY then
            love.graphics.setLineWidth(3)
            Colors.setColor("accent", 0.4)
            love.graphics.line(self.playerX, self.playerY, self.x, self.y)
            love.graphics.setLineWidth(1)
        end
    end

    local drawShape = function()
        if self.weaponData.pattern == "mines" then
            love.graphics.circle("fill", 0, 0, 6)
            love.graphics.rectangle("fill", -8, -2, 16, 4)
            love.graphics.rectangle("fill", -2, -8, 4, 16)
        elseif self.weaponData.pattern == "railgun" then
            love.graphics.rectangle("fill", -2, -20, 4, 40)
        elseif self.weaponData.pattern == "cloud" then
            local time = love.timer.getTime()
            local areaRange = 5 * (self.weaponData.area or 1.0)
            local pulse = 1.0 + math.sin(time * 6) * 0.03
            local currentRadius = areaRange * pulse
            
            if self.naniteOffsets then
                for _, off in ipairs(self.naniteOffsets) do
                    local flicker = math.sin(time * 10 + off.phase)
                    if flicker > -0.4 then
                        Colors.setColor("xp", 0.4 + flicker * 0.4)
                        local x = off.x * currentRadius
                        local y = off.y * currentRadius
                        love.graphics.rectangle("fill", x-1, y-1, 2, 2)
                    end
                end
            end
        elseif self.weaponData.pattern == "whip" then
            -- Whip head: Glowing energy ball affected by area
            local ballSize = 3 * (self.weaponData.area or 1.0)
            love.graphics.circle("fill", 0, 0, ballSize)
        else
            love.graphics.polygon("fill", 0, -5, -2, 0, 0, 5, 2, 0)
        end
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)

    -- Glow passes
    love.graphics.push()
    love.graphics.scale(1.3, 1.3)
    Colors.setColor("accent", 0.1)
    if self.weaponData.pattern == "cloud" then Colors.setColor("xp", 0.05) end
    drawShape()
    love.graphics.pop()

    love.graphics.push()
    love.graphics.scale(1.15, 1.15)
    Colors.setColor("accent", 0.2)
    if self.weaponData.pattern == "cloud" then Colors.setColor("xp", 0.1) end
    drawShape()
    love.graphics.pop()

    if self.weaponData.pattern == "mines" and self.lifeTimer and self.lifeTimer < 1.0 then
        if math.floor(love.timer.getTime() * 10) % 2 == 0 then
            Colors.setColor("danger", 0.9)
        else
            Colors.setColor("accent", 0.9)
        end
    elseif self.weaponData.pattern == "cloud" then
        -- Handled inside
    else
        Colors.setColor("accent", 0.9)
        drawShape()
    end

    love.graphics.pop()
end

return Bullet
