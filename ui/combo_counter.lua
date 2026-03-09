local Colors = require('ui.colors')
local Fonts = require('ui.fonts')
local Screen = require('systems.screen')
local Particles = require('systems.particles')
local Screenshake = require('systems.screenshake')

local ComboCounter = {}
ComboCounter.__index = ComboCounter

function ComboCounter.new()
    local self = setmetatable({
        comboCount = 0,
        comboTimer = 0,
        maxComboTime = 3.0,
        pulseTimer = 0,
        lastMilestone = 0
    }, ComboCounter)
    return self
end

---Triggered when an enemy is killed
---@param x number X position of kill (for particles)
---@param y number Y position of kill (for particles)
function ComboCounter:onKill(x, y)
    self.comboCount = self.comboCount + 1
    self.comboTimer = self.maxComboTime
    
    -- Check for 10x milestones
    local milestone = math.floor(self.comboCount / 10)
    if milestone > self.lastMilestone and self.comboCount > 0 then
        self.lastMilestone = milestone
        
        -- Milestone Effects: Every 10 combo
        Screenshake.trigger(5 + math.min(milestone, 5), 0.3)
        Particles.spawn(x or 0, y or 0, 20, "accent", 150, 2)
        
        -- Spawn a ring effect if we have the system
        if Particles.rings then
            table.insert(Particles.rings, {
                x = x or 0,
                y = y or 0,
                radius = 0,
                maxRadius = 100,
                life = 0.5,
                maxLife = 0.5,
                colorKey = "accent"
            })
        end
    end
end

---Triggered when player takes damage
function ComboCounter:onPlayerHit()
    self.comboCount = 0
    self.comboTimer = 0
    self.lastMilestone = 0
end

---Update combo timer
---@param dt number Delta time
function ComboCounter:update(dt)
    if self.comboCount > 0 then
        self.comboTimer = self.comboTimer - dt
        if self.comboTimer <= 0 then
            self.comboCount = 0
            self.lastMilestone = 0
        end
    end
    
    self.pulseTimer = self.pulseTimer + dt
end

---Draw combo counter
function ComboCounter:draw()
    if self.comboCount < 3 then return end
    
    local sw, sh = Screen.getVirtualWidth(), Screen.getVirtualHeight()
    
    -- Position: Top-right of game area
    local x = sw - 20
    local y = 80
    
    -- Determine color and label based on combo level
    local color = "white"
    local label = "COMBO!"
    local isMega = false
    
    if self.comboCount >= 50 then
        color = "danger"
        label = "MEGA COMBO!"
        isMega = true
    elseif self.comboCount >= 25 then
        color = "danger" 
    elseif self.comboCount >= 10 then
        color = "xp"
    end
    
    -- Visual effects
    local alpha = math.min(1, self.comboTimer * 2)
    local pulse = 1.0 + math.sin(self.pulseTimer * (isMega and 15 or 8)) * 0.05
    
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(pulse, pulse)
    
    -- Flashing for Mega Combo
    if isMega and math.floor(self.pulseTimer * 10) % 2 == 0 then
        Colors.setColor("white", alpha)
    else
        Colors.setColor(color, alpha)
    end
    
    love.graphics.setFont(Fonts.getFont("large"))
    local comboText = self.comboCount .. "x " .. label
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(comboText)
    
    -- Draw text right-aligned
    love.graphics.print(comboText, -textWidth, 0)
    
    -- Timer Bar
    local barWidth = 100
    local barHeight = 4
    local currentBarW = barWidth * (self.comboTimer / self.maxComboTime)
    
    love.graphics.setColor(0, 0, 0, 0.5 * alpha)
    love.graphics.rectangle("fill", -barWidth, 35, barWidth, barHeight)
    
    Colors.setColor(color, alpha)
    love.graphics.rectangle("fill", -barWidth + (barWidth - currentBarW), 35, currentBarW, barHeight)
    
    love.graphics.pop()
end

return ComboCounter
