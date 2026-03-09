local Colors = require('ui.colors')
local Fonts = require('ui.fonts')

local DamageNumbers = {}
DamageNumbers.__index = DamageNumbers

function DamageNumbers.new()
    return setmetatable({
        active = {}
    }, DamageNumbers)
end

---@class DamageNumber
---@field x number
---@field y number
---@field damage number
---@field lifetime number
---@field maxLifetime number
---@field vx number
---@field vy number
---@field isCrit boolean
---@field text string
---@field colorKey string

---Spawn a new floating damage number
---@param x number The x position (virtual coordinates)
---@param y number The y position (virtual coordinates)
---@param damage number|string The damage amount or custom text
---@param isCrit boolean Whether this is a critical hit
function DamageNumbers:spawn(x, y, damage, isCrit)
    local text = ""
    if type(damage) == "string" then
        text = damage
    else
        text = tostring(math.floor(damage))
        if isCrit then
            text = text .. "!"
        end
    end

    local number = {
        x = x,
        y = y,
        damage = damage,
        lifetime = 1.0,
        maxLifetime = 1.0,
        -- Initial velocity: floats upward and slightly random sideways
        vx = (love.math.random() - 0.5) * 40,
        vy = -60,
        isCrit = isCrit,
        text = text,
        colorKey = isCrit and "xp" or "white"
    }
    table.insert(self.active, number)
end

---Update active damage numbers
---@param dt number Delta time
function DamageNumbers:update(dt)
    for i = #self.active, 1, -1 do
        local n = self.active[i]
        n.lifetime = n.lifetime - dt

        if n.lifetime <= 0 then
            table.remove(self.active, i)
        else
            -- Move damage numbers
            n.x = n.x + n.vx * dt
            n.y = n.y + n.vy * dt

            -- Velocity slows down (deceleration)
            local drag = 2.0
            n.vx = n.vx * (1 - drag * dt)
            n.vy = n.vy * (1 - drag * dt)
        end
    end
end

---Draw active damage numbers
function DamageNumbers:draw()
    local oldFont = love.graphics.getFont()
    local oldR, oldG, oldB, oldA = love.graphics.getColor()

    for _, n in ipairs(self.active) do
        local alpha = math.max(0, n.lifetime / n.maxLifetime)
        
        -- Set font and color based on crit status
        if n.isCrit then
            love.graphics.setFont(Fonts.getFont("large"))
            Colors.setColor(n.colorKey, alpha)
        else
            love.graphics.setFont(Fonts.getFont("small"))
            love.graphics.setColor(1, 1, 1, alpha)
        end

        local font = love.graphics.getFont()
        local width = font:getWidth(n.text)
        
        -- Draw damage value as text, centered horizontally
        love.graphics.print(n.text, math.floor(n.x - width / 2), math.floor(n.y))
    end

    -- Restore graphics state
    love.graphics.setFont(oldFont)
    love.graphics.setColor(oldR, oldG, oldB, oldA)
end

return DamageNumbers
