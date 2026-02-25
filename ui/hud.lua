local Colors = require('ui.colors')
local Layout = require('ui.layout')
local Fonts = require('ui.fonts')
local Screen = require('systems.screen')

local HUD = {}

function HUD.new()
  local self = setmetatable({}, { __index = HUD })
  return self
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
end

return HUD
