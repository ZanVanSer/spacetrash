local Colors = require('ui.colors')
local Layout = require('ui.layout')
local Fonts = require('ui.fonts')
local Screen = require('systems.screen')
local dl = require('systems/dataloader')
local WeaponIcons = require('ui.weapon_icons')
local PassiveIcons = require('ui.passive_icons')

local HUD = {}

function HUD.new()
  local self = setmetatable({}, { __index = HUD })
  self.weaponLookup = dl.createLookup(dl.getWeapons(), "id")
  self.passiveLookup = dl.createLookup(dl.getPassives(), "id")
  return self
end

function HUD:drawAsciiBar(value, maxValue, barWidth, x, y, label, fillColor, emptyColor, suffixText)
  local percent = maxValue > 0 and (value / maxValue) or 0
  percent = math.min(1, math.max(0, percent))
  local filled = math.floor(percent * barWidth)
  local empty = barWidth - filled
  local displayText = suffixText or (math.floor(percent * 100) .. "%")

  -- Draw Label
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("tiny"))
  love.graphics.print(label, x, y - 12)

  -- Draw Bar
  love.graphics.setFont(Fonts.getFont("small"))
  local barData = {
    emptyColor, "[",
    fillColor, string.rep('#', filled),
    emptyColor, string.rep('.', empty),
    emptyColor, "]"
  }
  love.graphics.print(barData, x, y)

  -- Draw Percentage/Value
  Colors.setColor("dim")
  local font = Fonts.getFont("small")
  local fullBarStr = "[" .. string.rep('#', barWidth) .. "]"
  local barPixelWidth = font:getWidth(fullBarStr)
  love.graphics.print(displayText, x + barPixelWidth + 5, y)
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

  -- 3. Boss Arrival Timer
  local survivalTime = (gameState.stageData and gameState.stageData.survivalTime) or 180
  local remainingTime = math.max(0, survivalTime - gameState.gameTime)
  local minutes = math.floor(remainingTime / 60)
  local seconds = math.floor(remainingTime % 60)
  local timerStr = string.format("%02d:%02d", minutes, seconds)
  
  -- Label
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("tiny"))
  love.graphics.printf("TIME TO BOSS", 0, 10, width, "center")
  
  -- Time (with flash warning)
  local timeColor = "accent"
  if remainingTime < 30 and math.floor(gameState.gameTime * 4) % 2 == 0 then
    timeColor = "danger"
  end
  Colors.setColor(timeColor)
  
  local timeFont = Fonts.getFont("huge")
  love.graphics.setFont(timeFont)
  love.graphics.printf(timerStr, 0, 22, width, "center")

  -- Blinking Dot
  if math.floor(gameState.gameTime) % 2 == 0 then
    local textWidth = timeFont:getWidth(timerStr)
    local dotX = (width + textWidth) / 2 + 5
    love.graphics.circle("fill", dotX, 35, 2)
  end

  -- 4. System Integrity Box
  local boxX, boxY = 10, 70
  local boxW, boxH = 200, 65

  -- Border
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", boxX, boxY, boxW, boxH)

  -- Inside Box
  -- HP Bar
  local hpText = string.format("%d/%d", math.ceil(player.hp), player.maxHp)
  self:drawAsciiBar(player.hp, player.maxHp, 15, boxX + 10, boxY + 20, "HP", Colors.COLORS.health, Colors.COLORS.dim, hpText)

  -- REGEN Stat
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.print("REGEN: " .. string.format("%.1f HP/s", player.recovery), boxX + 10, boxY + 45)

  -- 5. XP Progress Box
  local xpBoxX, xpBoxY = 10, 150
  local xpBoxW, xpBoxH = 200, 70

  -- Border
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", xpBoxX, xpBoxY, xpBoxW, xpBoxH)

  -- Level Number
  Colors.setColor("accent")
  love.graphics.setFont(Fonts.getFont("large"))
  love.graphics.printf("LVL " .. player.level, xpBoxX, xpBoxY + 8, xpBoxW, "center")

  -- XP Bar
  self:drawAsciiBar(player.xp, player.xpToNext, 15, xpBoxX + 10, xpBoxY + 40, "", Colors.COLORS.xp, Colors.COLORS.dim)

  -- XP Text
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.printf(string.format("XP: %d/%d", math.floor(player.xp), player.xpToNext), xpBoxX, xpBoxY + 55, xpBoxW, "center")

  -- 6. Weapons display box
  local wBoxX, wBoxY = 10, 240
  local wBoxW = 200
  local slotH = 30
  local wBoxH = 4 * slotH + 8

  -- Border
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", wBoxX, wBoxY, wBoxW, wBoxH)

  for i = 1, 4 do
    local slotY = wBoxY + 4 + (i-1) * slotH
    local weaponId = player.ws.equippedWeapons[i]
    
    if weaponId then
      local wd = self.weaponLookup[weaponId]
      local name = wd and wd.name:upper() or "UNKNOWN"
      
      -- Draw Icon
      WeaponIcons.drawWeaponIcon(weaponId, wBoxX + 20, slotY + 12, 1.0)
      
      Colors.setColor("accent")
      love.graphics.setFont(Fonts.getFont("small"))
      love.graphics.print(name, wBoxX + 40, slotY + 2)
      
      -- Stars/Level (Dynamic)
      local level = player.weaponLevels[weaponId] or 1
      local stars = ""
      for j = 1, 8 do
          stars = stars .. (j <= level and "*" or "-")
      end
      love.graphics.print(stars, wBoxX + 40, slotY + 14)
    else
      -- Generic empty slot icon
      Colors.setColor("dim", 0.3)
      love.graphics.rectangle("line", wBoxX + 12, slotY + 4, 16, 16)
      
      Colors.setColor("dim", 0.5)
      love.graphics.setFont(Fonts.getFont("small"))
      love.graphics.print("-- EMPTY --", wBoxX + 40, slotY + 6)
    end
    
    -- Slot divider
    if i < 4 then
      Colors.setColor("dim", 0.1)
      love.graphics.line(wBoxX + 5, slotY + slotH - 2, wBoxX + wBoxW - 5, slotY + slotH - 2)
    end
  end

  -- 7. Passives display box
  local pBoxX, pBoxY = 10, 375
  local pBoxW = 200
  local pSlotH = 22
  local pBoxH = 4 * pSlotH + 8

  -- Border
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", pBoxX, pBoxY, pBoxW, pBoxH)

  -- For passives, the player.passives is a map {id = level}
  local passiveList = {}
  for id, level in pairs(player.passives or {}) do
    table.insert(passiveList, {id = id, level = level})
  end

  for i = 1, 4 do
    local slotY = pBoxY + 4 + (i-1) * pSlotH
    local passive = passiveList[i]
    
    if passive then
      local pd = self.passiveLookup[passive.id]
      local name = pd and pd.name:upper() or "UNKNOWN"
      
      -- Draw Icon
      PassiveIcons.drawPassiveIcon(passive.id, pBoxX + 18, slotY + 10, 1.0)
      
      Colors.setColor("dim")
      love.graphics.setFont(Fonts.getFont("small"))
      love.graphics.print(name .. " LV" .. passive.level, pBoxX + 35, slotY + 2)
    else
      -- Generic empty slot icon
      Colors.setColor("dim", 0.2)
      love.graphics.rectangle("line", wBoxX + 12, slotY + 4, 14, 14)
      
      Colors.setColor("dim", 0.4)
      love.graphics.setFont(Fonts.getFont("small"))
      love.graphics.print("-- EMPTY --", pBoxX + 35, slotY + 2)
    end
  end

  -- 8. Ship Stats Box
  local sBoxX, sBoxY = 10, 475
  local sBoxW = 200
  local statStep = 12

  local stats = {
    { label = "ARMOR", val = string.format("%d", player.armor) },
    { label = "MIGHT", val = string.format("%d%%", player.might * 100) },
    { label = "SPEED", val = string.format("%d%%", (player.speed / 200) * 100) },
    { label = "AREA",  val = string.format("%d%%", player.area * 100) },
    { label = "CDR",   val = string.format("%d%%", (1 - player.cooldown) * 100) },
    { label = "AMOUNT",val = string.format("%d", player.amount) },
    { label = "CRIT",  val = "0%" }
  }

  local sBoxH = #stats * statStep + 8
  -- Border
  Colors.setColor("accent")
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", sBoxX, sBoxY, sBoxW, sBoxH)

  Colors.setColor("dim")
  for i, stat in ipairs(stats) do
    local y = sBoxY + 4 + (i-1) * statStep
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.print(stat.label, sBoxX + 10, y)
    love.graphics.printf(stat.val, sBoxX, y, sBoxW - 10, "right")
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
  love.graphics.print("ENEMIES: " .. (gameState.enemiesKilled or 0), barX + 20, barY + 5)

  -- Right: SCORE
  Colors.setColor("xp")
  local score = (gameState.enemiesKilled or 0) * 100
  love.graphics.printf("SCORE: " .. score, barX, barY + 5, barW - 20, "right")
end

return HUD
