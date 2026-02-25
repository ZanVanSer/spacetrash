local Colors = require('ui.colors')
local Layout = require('ui.layout')
local Fonts = require('ui.fonts')
local Screen = require('systems.screen')

local HUD = {}

function HUD.new()
  local self = setmetatable({}, { __index = HUD })
  return self
end

function HUD:drawAsciiBar(value, maxValue, barWidth, x, y, label, fillColor, emptyColor)
  local percent = maxValue > 0 and (value / maxValue) or 0
  percent = math.min(1, math.max(0, percent))
  local filled = math.floor(percent * barWidth)
  local empty = barWidth - filled
  local pctText = math.floor(percent * 100) .. "%"

  -- Draw Label
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.print(label, x, y - 15)

  -- Draw Bar
  love.graphics.setFont(Fonts.getFont("normal"))
  local barData = {
    emptyColor, "[",
    fillColor, string.rep('█', filled),
    emptyColor, string.rep('░', empty),
    emptyColor, "]"
  }
  love.graphics.print(barData, x, y)

  -- Draw Percentage
  Colors.setColor("dim")
  local font = Fonts.getFont("normal")
  local fullBarStr = "[" .. string.rep('█', barWidth) .. "]"
  local barPixelWidth = font:getWidth(fullBarStr)
  love.graphics.print(pctText, x + barPixelWidth + 5, y)
end

function HUD:draw(player, gameState)
  local width = 220
  local height = Screen.getVirtualHeight()

  -- 1. Draw HUD panel background
  love.graphics.setColor(8/255, 15/255, 18/255, 1)
  love.graphics.rectangle("fill", 0, 0, width, height)

  -- 2. Draw vertical divider line
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.line(width, 0, width, height)

  -- 3. Mission Clock
  local minutes = math.floor(gameState.gameTime / 60)
  local seconds = math.floor(gameState.gameTime % 60)
  local timerStr = string.format("%02d:%02d", minutes, seconds)
  
  -- Label
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.printf("MISSION CLOCK", 0, 20, width, "center")
  
  -- Time
  Colors.setColor("accent")
  local timeFont = Fonts.getFont("huge")
  love.graphics.setFont(timeFont)
  love.graphics.printf(timerStr, 0, 35, width, "center")

  -- Blinking Dot
  if math.floor(gameState.gameTime) % 2 == 0 then
    local textWidth = timeFont:getWidth(timerStr)
    local dotX = (width + textWidth) / 2 + 5
    love.graphics.circle("fill", dotX, 50, 3)
  end
end

return HUD
