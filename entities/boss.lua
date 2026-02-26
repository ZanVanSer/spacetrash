local Screen = require('systems.screen')
local Boss = {}
Boss.__index = Boss

function Boss.new(x, y, bossData)
    local self = setmetatable({}, Boss)
    self.bossData = bossData
    self.x = x or Screen.getVirtualWidth() / 2
    self.y = y or 100
    self.health = bossData.health
    self.maxHealth = bossData.health
    self.speed = bossData.speed
    self.radius = bossData.radius
    self.direction = 1 -- Default direction for behaviors like side_to_side
    self.isDead = false
    self.shootTimer = 0
    self.bullets = {}
    return self
end

function Boss:update(dt)
    if self.isDead then return end

    -- Load and run behavior
    local behavior = require("behaviors/" .. self.bossData.behavior)
    if behavior and behavior.update then
        behavior.update(self, dt)
    end

    -- Boundary enforcement (Viewport: 220-800, padding 40)
    if self.x < 260 then
        self.x = 260
        self.direction = 1
    elseif self.x > Screen.getVirtualWidth() - 40 then
        self.x = Screen.getVirtualWidth() - 40
        self.direction = -1
    end

    -- Shooting logic
    self.shootTimer = self.shootTimer + dt
    if self.shootTimer >= self.bossData.shootInterval then
        local pattern = require("patterns/boss_" .. self.bossData.shootPattern)
        if pattern and pattern.createBullets then
            local newBullets = pattern.createBullets(self.x, self.y, self.bossData)
            for _, b in ipairs(newBullets) do
                table.insert(self.bullets, b)
            end
        end
        self.shootTimer = 0
    end

    -- Update bullets
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b.x = b.x + (b.vx or 0) * dt
        b.y = b.y + (b.vy or 0) * dt

        -- Remove off-screen bullets
        if b.y > Screen.getVirtualHeight() + 50 or b.y < -50 or 
           b.x < -50 or b.x > Screen.getVirtualWidth() + 50 or b.isDead then
            table.remove(self.bullets, i)
        end
    end
end

function Boss:takeDamage(amount)
    self.health = self.health - amount
    if self.health <= 0 then
        self.health = 0
        self.isDead = true
    end
end

function Boss:getBullets()
    return self.bullets
end

function Boss:draw()
    if self.isDead then return end

    -- Draw Boss: Red triangle pointing down
    love.graphics.setColor(1, 0, 0)
    love.graphics.polygon("fill", 
        self.x - self.radius, self.y - self.radius, -- Top left
        self.x + self.radius, self.y - self.radius, -- Top right
        self.x, self.y + self.radius                 -- Bottom center
    )

    -- Draw Bullets
    local t = love.timer.getTime()
    local Colors = require('ui/colors')
    for _, b in ipairs(self.bullets) do
        local r = b.radius or 8
        local pulse = 1.0 + math.sin(t * 10) * 0.1
        
        local drawCircle = function()
            love.graphics.circle("fill", b.x, b.y, r)
        end

        -- Outer glow
        love.graphics.push()
        love.graphics.translate(b.x, b.y)
        love.graphics.scale(1.3 * pulse, 1.3 * pulse)
        love.graphics.translate(-b.x, -b.y)
        Colors.setColor("danger", 0.1)
        drawCircle()
        love.graphics.pop()

        -- Mid glow
        love.graphics.push()
        love.graphics.translate(b.x, b.y)
        love.graphics.scale(1.15 * pulse, 1.15 * pulse)
        love.graphics.translate(-b.x, -b.y)
        Colors.setColor("danger", 0.2)
        drawCircle()
        love.graphics.pop()

        -- Main bullet
        Colors.setColor("danger", 0.9)
        drawCircle()
    end
end

return Boss
