local ShipVisuals = {}

-- Color Palette
local CYAN = {0, 1, 0.8}
local DIM_TEAL = {0, 0.6, 0.48}
local WHITE = {1, 1, 1}

-- Helper function to draw a shape with glow
local function drawGlow(color, drawFunction, outerScale, midScale)
    local os = outerScale or 1.4
    local ms = midScale or 1.15
    
    -- First pass: Outer Glow
    love.graphics.push()
    love.graphics.scale(os, os)
    love.graphics.setColor(color[1], color[2], color[3], 0.08)
    drawFunction()
    love.graphics.pop()
    
    -- Second pass: Mid Glow
    love.graphics.push()
    love.graphics.scale(ms, ms)
    love.graphics.setColor(color[1], color[2], color[3], 0.15)
    drawFunction()
    love.graphics.pop()
    
    -- Third pass: Main Shape
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    drawFunction()
end

function ShipVisuals.vanguard()
    local body = function()
        love.graphics.polygon("fill", 0, -16, -10, 10, 0, 6, 10, 10)
    end
    
    drawGlow(CYAN, body)
    
    -- Engine pods
    love.graphics.setColor(CYAN[1], CYAN[2], CYAN[3], 0.8)
    love.graphics.polygon("fill", -10, 4, -16, 12, -8, 12)
    love.graphics.polygon("fill", 10, 4, 16, 12, 8, 12)
    
    -- Cockpit
    love.graphics.setColor(WHITE[1], WHITE[2], WHITE[3], 1)
    love.graphics.circle("fill", 0, -6, 2)
end

function ShipVisuals.interceptor()
    local body = function()
        love.graphics.polygon("fill", 0, -20, -5, 12, 0, 8, 5, 12)
    end
    
    -- Stronger glow for interceptor
    drawGlow(CYAN, body, 1.5, 1.2)
    
    -- Swept wings
    love.graphics.setColor(CYAN[1], CYAN[2], CYAN[3], 1.0)
    love.graphics.polygon("fill", -5, 2, -20, 16, -4, 16, -3, 6)
    love.graphics.polygon("fill", 5, 2, 20, 16, 4, 16, 3, 6)
    
    -- Nose point
    love.graphics.setColor(WHITE[1], WHITE[2], WHITE[3], 1)
    love.graphics.circle("fill", 0, -20, 1.5)
end

function ShipVisuals.fortress()
    local body = function()
        love.graphics.polygon("fill", 0, -14, -12, -6, -16, 8, -10, 16, 10, 16, 16, 8, 12, -6)
    end
    
    drawGlow(CYAN, body)
    
    -- Armor panel lines
    love.graphics.setColor(CYAN[1], CYAN[2], CYAN[3], 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.line(-8, -2, -12, 8)
    love.graphics.line(8, -2, 12, 8)
    love.graphics.line(-6, 6, 6, 6)
    
    -- Cockpit window
    love.graphics.setColor(CYAN[1], CYAN[2], CYAN[3], 0.6)
    love.graphics.rectangle("fill", -4, -10, 8, 6)
end

function ShipVisuals.swarm_commander()
    local body = function()
        love.graphics.polygon("fill", 0, -12, -8, -4, -18, 10, -14, 16, 14, 16, 18, 10, 8, -4)
    end
    
    drawGlow(CYAN, body)
    
    -- Drone bays
    love.graphics.setColor(CYAN[1], CYAN[2], CYAN[3], 0.5)
    love.graphics.rectangle("line", -16, 4, 6, 8)
    love.graphics.rectangle("line", 10, 4, 6, 8)
    
    -- Indicator lights
    love.graphics.setColor(CYAN[1], CYAN[2], CYAN[3], 0.8)
    love.graphics.circle("fill", -13, 8, 1.5)
    love.graphics.circle("fill", 13, 8, 1.5)
end

function ShipVisuals.storm_caller()
    local body = function()
        love.graphics.polygon("fill", 0, -18, -7, 0, -12, 14, -4, 10, 0, 6, 4, 10, 12, 14, 7, 0)
    end
    
    -- Stronger glow for storm caller
    drawGlow(CYAN, body, 1.5, 1.2)
    
    -- Energy coils
    love.graphics.setColor(CYAN[1], CYAN[2], CYAN[3], 0.8)
    love.graphics.circle("line", -12, 14, 4)
    love.graphics.circle("line", 12, 14, 4)
    
    love.graphics.setColor(CYAN[1], CYAN[2], CYAN[3], 0.7)
    love.graphics.circle("fill", -12, 14, 2)
    love.graphics.circle("fill", 12, 14, 2)
    
    -- Arc lightning
    love.graphics.setColor(CYAN[1], CYAN[2], CYAN[3], 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.line(-12, 14, -4, 10, 4, 10, 12, 14)
end

function ShipVisuals.default()
    love.graphics.setColor(CYAN[1], CYAN[2], CYAN[3], 0.9)
    love.graphics.polygon("fill", 0, -10, -8, 8, 8, 8)
end

function ShipVisuals.drawShip(shipId, x, y, scale, rotation)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(rotation or 0)
    love.graphics.scale(scale or 1, scale or 1)
    
    if shipId == "vanguard" then
        ShipVisuals.vanguard()
    elseif shipId == "interceptor" then
        ShipVisuals.interceptor()
    elseif shipId == "fortress" then
        ShipVisuals.fortress()
    elseif shipId == "swarm_commander" then
        ShipVisuals.swarm_commander()
    elseif shipId == "storm_caller" then
        ShipVisuals.storm_caller()
    else
        ShipVisuals.default()
    end
    
    love.graphics.pop()
end

return ShipVisuals
