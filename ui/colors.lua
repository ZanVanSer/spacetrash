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

return {
  COLORS = COLORS,
  getColor = getColor,
  setColor = setColor
}
