local Colors = require('ui.colors')
local Layout = require('ui.layout')
local Fonts = require('ui.fonts')
local Screen = require('systems.screen')
local dl = require('systems/dataloader')

local HUD = {}

function HUD.new()
  local self = setmetatable({}, { __index = HUD })
  self.weaponLookup = dl.createLookup(dl.getWeapons(), "id")
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

  -- 4. System Integrity Box
  local boxX, boxY = 10, 100
  local boxW, boxH = 200, 115

  -- Floating Label
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.print("SYSTEM INTEGRITY", boxX + 5, boxY - 12)

  -- Border
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", boxX, boxY, boxW, boxH)

  -- Inside Box
  -- HULL Bar
  self:drawAsciiBar(player.hp, player.maxHp, 15, boxX + 10, boxY + 25, "HULL", Colors.COLORS.health, Colors.COLORS.dim)

  -- ARMOR Bar (assuming 10 is max visual armor for bar scaling)
  self:drawAsciiBar(player.armor, 10, 15, boxX + 10, boxY + 65, "ARMOR", Colors.COLORS.accent, Colors.COLORS.dim)

  -- REGEN Stat
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.print("REGEN: " .. string.format("%.1f HP/s", player.recovery), boxX + 10, boxY + 95)

  -- 5. XP Progress Box
  local xpBoxX, xpBoxY = 10, 230
  local xpBoxW, xpBoxH = 200, 100

  -- Floating Label
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.print("XP PROGRESS", xpBoxX + 5, xpBoxY - 12)

  -- Border
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", xpBoxX, xpBoxY, xpBoxW, xpBoxH)

  -- Level Number
  Colors.setColor("accent")
  love.graphics.setFont(Fonts.getFont("huge"))
  love.graphics.printf("LVL " .. player.level, xpBoxX, xpBoxY + 15, xpBoxW, "center")

  -- XP Bar
  self:drawAsciiBar(player.xp, player.xpToNext, 15, xpBoxX + 10, xpBoxY + 60, "", Colors.COLORS.xp, Colors.COLORS.dim)

  -- XP Text
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.printf(string.format("XP: %d/%d", math.floor(player.xp), player.xpToNext), xpBoxX, xpBoxY + 80, xpBoxW, "center")

  -- 6. Weapons display box
  local wBoxX, wBoxY = 10, 350
  local wBoxW = 200
  local slotH = 40
  local wBoxH = 4 * slotH + 20

  -- Floating Label
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.print("WEAPONS", wBoxX + 5, wBoxY - 12)

  -- Border
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", wBoxX, wBoxY, wBoxW, wBoxH)

  for i = 1, 4 do
    local slotY = wBoxY + 10 + (i-1) * slotH
    local weaponId = player.ws.equippedWeapons[i]
    
    if weaponId then
      local wd = self.weaponLookup[weaponId]
      local name = wd and wd.name:upper() or "UNKNOWN"
      
      Colors.setColor("accent")
      love.graphics.setFont(Fonts.getFont("small"))
      love.graphics.print("W" .. i .. ": " .. name, wBoxX + 10, slotY + 5)
      
      -- Stars (Level 1 for now)
      local stars = "★☆☆☆☆"
      love.graphics.print(stars, wBoxX + 10, slotY + 20)
    else
      Colors.setColor("dim")
      love.graphics.setFont(Fonts.getFont("small"))
      love.graphics.print("W" .. i .. ": -- EMPTY --", wBoxX + 10, slotY + 12)
    end
    
    -- Slot divider
    if i < 4 then
      Colors.setColor("dim", 0.3)
      love.graphics.line(wBoxX + 10, slotY + slotH, wBoxX + wBoxW - 10, slotY + slotH)
    end
  end
end

return HUD
