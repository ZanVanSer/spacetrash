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

  -- 3.5 Threat Level Display
  local threatX, threatY = 10, 75
  local threatW, threatH = 200, 45
  local gameTime = gameState.gameTime
  
  local threatLevel = "LOW"
  local threatColor = Colors.COLORS.health
  local pulse = 1.0
  
  if gameTime < 120 then
    threatLevel = "LOW"
    threatColor = Colors.COLORS.health
  elseif gameTime < 240 then
    threatLevel = "MODERATE"
    threatColor = Colors.COLORS.xp
  elseif gameTime < 360 then
    threatLevel = "HIGH"
    threatColor = {1, 0.5, 0, 1} -- Orange
  elseif gameTime < 480 then
    threatLevel = "CRITICAL"
    threatColor = Colors.COLORS.danger
  else
    threatLevel = "EXTREME"
    threatColor = Colors.COLORS.danger
    pulse = 0.7 + math.abs(math.sin(love.timer.getTime() * 10)) * 0.3
  end

  -- Border
  Colors.setColor("accent", 0.3)
  love.graphics.rectangle("line", threatX, threatY, threatW, threatH)
  
  -- Label
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("tiny"))
  love.graphics.print("THREAT LEVEL", threatX + 5, threatY + 4)
  
  -- Level Name
  love.graphics.setColor(threatColor[1], threatColor[2], threatColor[3], (threatColor[4] or 1) * pulse)
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.print(threatLevel, threatX + 80, threatY + 2)
  
  local DifficultyScaler = require('systems.difficulty_scaler')
  local hMult = DifficultyScaler.getHealthMultiplier()
  Colors.setColor("dim")
  love.graphics.print(string.format("(x%.1f)", hMult), threatX + 150, threatY + 2)

  -- Danger Meter
  local meterX, meterY = threatX + 10, threatY + 22
  local meterW, meterH = 180, 12
  local meterFill = math.min(1.0, gameTime / 600) -- Fills over 10 minutes
  
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", meterX, meterY, meterW, meterH)
  
  love.graphics.setColor(threatColor[1], threatColor[2], threatColor[3], (threatColor[4] or 1) * 0.8)
  love.graphics.rectangle("fill", meterX, meterY, meterW * meterFill, meterH)
  
  Colors.setColor("accent", 0.5)
  love.graphics.rectangle("line", meterX, meterY, meterW, meterH)

  -- 4. System Integrity Box
  local boxX, boxY = 10, 130
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
  local xpBoxX, xpBoxY = 10, 205
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
  local wBoxX, wBoxY = 10, 285
  local wBoxW = 200
  local slotH = 28
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
      WeaponIcons.drawWeaponIcon(weaponId, wBoxX + 20, slotY + 11, 0.9)
      
      Colors.setColor("accent")
      local smallFont = Fonts.getFont("small")
      love.graphics.setFont(smallFont)
      -- Truncate name if too wide for slot
      local maxNameWidth = wBoxW - 45  -- Reserve space for icon + padding
      if smallFont:getWidth(name) > maxNameWidth then
        name = Fonts.truncateText(name, maxNameWidth, smallFont)
      end
      love.graphics.print(name, wBoxX + 40, slotY + 1)
      
      -- Stars/Level (Dynamic)
      local level = player.weaponLevels[weaponId] or 1
      local stars = ""
      for j = 1, 5 do
          stars = stars .. (j <= level and "*" or "-")
      end
      love.graphics.print(stars, wBoxX + 40, slotY + 12)
    else
      -- Generic empty slot icon
      Colors.setColor("dim", 0.3)
      love.graphics.rectangle("line", wBoxX + 12, slotY + 4, 14, 14)
      
      Colors.setColor("dim", 0.5)
      love.graphics.setFont(Fonts.getFont("small"))
      love.graphics.print("-- EMPTY --", wBoxX + 40, slotY + 4)
    end
    
    -- Slot divider
    if i < 4 then
      Colors.setColor("dim", 0.1)
      love.graphics.line(wBoxX + 5, slotY + slotH - 1, wBoxX + wBoxW - 5, slotY + slotH - 1)
    end
  end

  -- 7. Passives display box
  local pBoxX, pBoxY = 10, 410
  local pBoxW = 200
  local pSlotH = 20
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
      local nameWithLevel = name .. " LV" .. passive.level
      
      -- Draw Icon
      PassiveIcons.drawPassiveIcon(passive.id, pBoxX + 18, slotY + 10, 0.9)
      
      Colors.setColor("dim")
      local smallFont = Fonts.getFont("small")
      love.graphics.setFont(smallFont)
      -- Truncate name if too wide for slot
      local maxNameWidth = pBoxW - 40  -- Reserve space for icon + padding
      if smallFont:getWidth(nameWithLevel) > maxNameWidth then
        nameWithLevel = Fonts.truncateText(nameWithLevel, maxNameWidth, smallFont)
      end
      love.graphics.print(nameWithLevel, pBoxX + 35, slotY + 2)
    else
      -- Generic empty slot icon
      Colors.setColor("dim", 0.2)
      love.graphics.rectangle("line", wBoxX + 12, slotY + 4, 12, 12)
      
      Colors.setColor("dim", 0.4)
      love.graphics.setFont(Fonts.getFont("small"))
      love.graphics.print("-- EMPTY --", pBoxX + 35, slotY + 2)
    end
  end

  -- 8. Ship Stats Box
  local sBoxX, sBoxY = 10, 498
  local sBoxW = 200
  local statStep = 10

  local stats = {
    { label = "ARMOR", val = string.format("%d", player.armor) },
    { label = "MIGHT", val = string.format("%d%%", player.might * 100) },
    { label = "SPEED", val = string.format("%d%%", (player.speed / 200) * 100) },
    { label = "AREA",  val = string.format("%d%%", player.area * 100) },
    { label = "CDR",   val = string.format("%d%%", (1 - player.cooldown) * 100) },
    { label = "AMOUNT",val = string.format("%d", player.amount) }
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
