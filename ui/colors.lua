local COLORS = {
  bg = {6/255, 12/255, 14/255, 1},
  accent = {0/255, 255/255, 204/255, 1},
  dim = {0/255, 153/255, 122/255, 1},
  danger = {255/255, 68/255, 68/255, 1},
  xp = {255/255, 215/255, 0/255, 1},
  health = {57/255, 255/255, 20/255, 1}
}

local function getColor(colorName, alpha)
  local c = COLORS[colorName]
  if not c then return {1, 1, 1, alpha or 1} end
  return {c[1], c[2], c[3], alpha or c[4]}
end

local function setColor(colorName, alpha)
  local c = getColor(colorName, alpha)
  love.graphics.setColor(c)
end

local function drawGlow(color, drawFunction, scale1, scale2)
    local s1 = scale1 or 1.4
    local s2 = scale2 or 1.15
    
    -- Pass 1: Outer Glow
    love.graphics.push()
    love.graphics.scale(s1, s1)
    setColor(color, 0.08)
    drawFunction()
    love.graphics.pop()
    
    -- Pass 2: Mid Glow
    love.graphics.push()
    love.graphics.scale(s2, s2)
    setColor(color, 0.15)
    drawFunction()
    love.graphics.pop()
    
    -- Pass 3: Main Shape
    love.graphics.push()
    setColor(color, 0.9)
    drawFunction()
    love.graphics.pop()
end

return {
  COLORS = COLORS,
  getColor = getColor,
  setColor = setColor,
  drawGlow = drawGlow
}
