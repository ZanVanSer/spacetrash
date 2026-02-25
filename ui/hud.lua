local Colors = require('ui.colors')
local Layout = require('ui.layout')
local Fonts = require('ui.fonts')
local Screen = require('systems.screen')
local dl = require('systems/dataloader')

local HUD = {}

function HUD.new()
  local self = setmetatable({}, { __index = HUD })
  self.weaponLookup = dl.createLookup(dl.getWeapons(), "id")
  self.upgradeLookup = dl.createLookup(dl.getUpgrades(), "id")
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

  -- 7. Passives display box
  local pBoxX, pBoxY = 10, 525
  local pBoxW = 200
  local pSlotH = 35
  local pBoxH = 4 * pSlotH + 20

  -- Floating Label
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.print("PASSIVES", pBoxX + 5, pBoxY - 12)

  -- Border
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", pBoxX, pBoxY, pBoxW, pBoxH)

  for i = 1, 4 do
    local slotY = pBoxY + 10 + (i-1) * pSlotH
    -- Assuming player.passives exists or will exist as a list of {id, level}
    local passive = player.passives and player.passives[i]
    
    if passive then
      local ud = self.upgradeLookup[passive.id]
      local name = ud and ud.name:upper() or "UNKNOWN"
      local level = passive.level or 1
      
      Colors.setColor("dim")
      love.graphics.setFont(Fonts.getFont("small"))
      love.graphics.print("P" .. i .. ": " .. name, pBoxX + 10, slotY + 2)
      love.graphics.print("Lv " .. level, pBoxX + 10, slotY + 15)
    else
      Colors.setColor("dim", 0.6)
      love.graphics.setFont(Fonts.getFont("small"))
      love.graphics.print("P" .. i .. ": -- EMPTY --", pBoxX + 10, slotY + 10)
    end
    
    -- Slot divider
    if i < 4 then
      Colors.setColor("dim", 0.2)
      love.graphics.line(pBoxX + 10, slotY + pSlotH, pBoxX + pBoxW - 10, slotY + pSlotH)
    end
  end

  -- 8. Ship Stats Box
  local sBoxX, sBoxY = 10, 700
  local sBoxW, sBoxH = 200, 150
  local statStep = 25

  -- Floating Label
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.print("SHIP STATS", sBoxX + 5, sBoxY - 12)

  -- Border
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", sBoxX, sBoxY, sBoxW, sBoxH)

  local stats = {
    { label = "MIGHT", val = string.format("%d%%", player.might * 100) },
    { label = "SPEED", val = string.format("%d%%", (player.speed / 200) * 100) },
    { label = "AREA",  val = string.format("%d%%", player.area * 100) },
    { label = "CDR",   val = string.format("%d%%", (1 - player.cooldown) * 100) },
    { label = "CRIT",  val = "0%" } -- Not yet implemented in player
  }

  Colors.setColor("dim")
  for i, stat in ipairs(stats) do
    local y = sBoxY + 10 + (i-1) * statStep
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.print(stat.label, sBoxX + 10, y)
    love.graphics.printf(stat.val, sBoxX, y, sBoxW - 10, "right")

    if i < #stats then
      Colors.setColor("dim", 0.2)
      love.graphics.line(sBoxX + 10, y + 20, sBoxX + sBoxW - 10, y + 20)
      Colors.setColor("dim")
    end
  end

  -- 9. Bottom Status Bar
  local vw = Screen.getVirtualWidth()
  local vh = Screen.getVirtualHeight()
  local barX = 220
  local barY = vh - 20
  local barW = vw - barX

  -- Background
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("fill", barX, barY, barW, 20)

  -- Top line
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.line(barX, barY, vw, barY)

  love.graphics.setFont(Fonts.getFont("small"))

  -- Left: ENEMIES
  Colors.setColor("danger")
  love.graphics.print("ENEMIES: " .. (gameState.enemiesKilled or 0), barX + 10, barY + 5)

  -- Center: SCORE
  Colors.setColor("xp")
  local score = (gameState.enemiesKilled or 0) * 100
  love.graphics.printf("SCORE: " .. score, barX, barY + 5, barW, "center")

  -- Right: SYSTEM_STABLE
  Colors.setColor("health")
  love.graphics.printf("SYSTEM_STABLE: TRUE", barX, barY + 5, barW - 10, "right")
end

return HUD
