local Screen = require('systems.screen')
local WeaponIcons = require('ui.weapon_icons')
local PassiveIcons = require('ui.passive_icons')
local Colors = require('ui.colors')
local Fonts = require('ui.fonts')
local dl = require('systems/dataloader')

local UpgradeMenu = {}
UpgradeMenu.__index = UpgradeMenu

function UpgradeMenu.new(player)
  local self = setmetatable({}, UpgradeMenu)
  self.player = player
  self.selectedIndex = 1
  self.timer = 0
  self.upgrades = self:generateUpgrades()
  return self
end

function UpgradeMenu:generateUpgrades()
    local allWeapons = dl.getWeapons()
    local allPassives = dl.getPassives()
    local options = {}
    
    -- Count current slots
    local weaponCount = 0
    for _ in pairs(self.player.weaponLevels) do weaponCount = weaponCount + 1 end
    local passiveCount = 0
    for _ in pairs(self.player.passives) do passiveCount = passiveCount + 1 end
    
    -- 1. Potential Weapon Options
    for _, w in ipairs(allWeapons) do
        local currentLevel = self.player.weaponLevels[w.id]
        if currentLevel then
            if currentLevel < 5 then
                table.insert(options, {
                    id = w.id,
                    type = "weapon",
                    name = w.name,
                    level = currentLevel + 1,
                    description = "Upgrade to level " .. (currentLevel + 1),
                    rarity = w.rarity or 100,
                    data = w
                })
            end
        elseif weaponCount < 4 and not w.isEvolution then
            table.insert(options, {
                id = w.id,
                type = "weapon",
                name = w.name,
                level = 1,
                description = "Acquire new weapon system.",
                rarity = w.rarity or 100,
                data = w
            })
        end
    end
    
    -- 2. Potential Passive Options
    for _, p in ipairs(allPassives) do
        local currentLevel = self.player.passives[p.id]
        if currentLevel then
            if currentLevel < 5 then
                table.insert(options, {
                    id = p.id,
                    type = "passive",
                    name = p.name,
                    level = currentLevel + 1,
                    description = p.description or ("Level up to Lv" .. (currentLevel + 1)),
                    rarity = p.rarity or 100,
                    data = p
                })
            end
        elseif passiveCount < 4 then
            table.insert(options, {
                id = p.id,
                type = "passive",
                name = p.name,
                level = 1,
                description = p.description or "Acquire new enhancement module.",
                rarity = p.rarity or 100,
                data = p
            })
        end
    end
    
    -- Weighted Random Selection
    local picked = {}
    local choices = 3
    
    for i = 1, choices do
        if #options == 0 then break end
        
        local totalWeight = 0
        for _, opt in ipairs(options) do
            totalWeight = totalWeight + (opt.rarity or 100)
        end
        
        local rnd = math.random() * totalWeight
        local currentWeight = 0
        for idx, opt in ipairs(options) do
            currentWeight = currentWeight + (opt.rarity or 100)
            if rnd <= currentWeight then
                local choice = table.remove(options, idx)
                
                -- Check for potential evolution
                if choice.type == "weapon" and choice.level == 5 then
                    local reqPassive = choice.data.evolution and choice.data.evolution.requiredPassive
                    if reqPassive and self.player.passives[reqPassive] then
                        choice.isEvolutionPotential = true
                    end
                end
                
                table.insert(picked, choice)
                break
            end
        end
    end
    
    return picked
end

function UpgradeMenu:keypressed(key)
  if key == 'up' then
    self.selectedIndex = self.selectedIndex - 1
    if self.selectedIndex < 1 then self.selectedIndex = #self.upgrades end
  elseif key == 'down' then
    self.selectedIndex = self.selectedIndex + 1
    if self.selectedIndex > #self.upgrades then self.selectedIndex = 1 end
  elseif key == 'z' or key == 'return' then
    return self.upgrades[self.selectedIndex]
  end
  return nil
end

function UpgradeMenu:draw()
  local dt = love.timer.getDelta()
  self.timer = self.timer + dt
  
  local sw, sh = Screen.getVirtualWidth(), Screen.getVirtualHeight()
  local animDuration = 0.3
  local progress = math.min(1.0, self.timer / animDuration)
  -- Ease out cubic
  local easeOut = 1 - math.pow(1 - progress, 3)
  
  -- Dim background
  love.graphics.setColor(0, 0, 0, 0.85 * progress)
  love.graphics.rectangle('fill', 0, 0, sw, sh)
  
  Colors.setColor("accent", progress)
  love.graphics.setFont(Fonts.getFont("large"))
  love.graphics.printf("SYSTEM UPGRADE DETECTED", 0, 80, sw, "center")
  
  local startY, bh, sp = 180, 100, 20
  local boxW = 500
  local finalBoxX = sw/2 - boxW/2

  for i, upgrade in ipairs(self.upgrades) do
    local isSelected = (i == self.selectedIndex)
    
    -- Slide in from sides (even left, odd right)
    local offsetX = (i % 2 == 0) and (sw * (1 - easeOut)) or (-sw * (1 - easeOut))
    local boxX = finalBoxX + offsetX
    local y = startY + (i-1) * (bh + sp)
    
    -- Rarity Logic
    local rarityColor = "dim" -- Common
    local rarityName = "COMMON"
    if upgrade.rarity <= 40 then
        rarityColor = "xp" -- Rare (Gold)
        rarityName = "RARE"
    elseif upgrade.rarity <= 75 then
        rarityColor = "accent" -- Uncommon (Cyan)
        rarityName = "UNCOMMON"
    end
    
    -- Card Pulse if selected
    local pulse = 1.0
    if isSelected then
        pulse = 1.0 + math.sin(love.timer.getTime() * 8) * 0.02
        boxX = boxX - (boxW * (pulse - 1.0)) / 2
    end
    local currentBoxW = boxW * pulse
    local currentBoxH = bh * pulse

    -- Draw Background
    if isSelected then
        Colors.setColor(rarityColor, 0.2)
        love.graphics.rectangle('fill', boxX, y, currentBoxW, currentBoxH)
    else
        love.graphics.setColor(0.05, 0.1, 0.12, 0.9)
        love.graphics.rectangle('fill', boxX, y, currentBoxW, currentBoxH)
    end
    
    -- Draw Border
    if isSelected then
        -- Glowing Border
        local glowAlpha = 0.5 + math.sin(love.timer.getTime() * 10) * 0.3
        Colors.setColor(rarityColor, glowAlpha)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle('line', boxX, y, currentBoxW, currentBoxH)
    else
        Colors.setColor(rarityColor, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle('line', boxX, y, currentBoxW, currentBoxH)
    end
    
    -- Evolution Special Border
    if upgrade.isEvolutionPotential then
        Colors.setColor("xp", 0.8 + math.sin(love.timer.getTime() * 12) * 0.2)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle('line', boxX - 4, y - 4, currentBoxW + 8, currentBoxH + 8)
        
        love.graphics.setFont(Fonts.getFont("tiny"))
        love.graphics.print("EVOLUTION!", boxX + 5, y - 15)
    end
    
    love.graphics.setLineWidth(1)
    
    -- Draw Icon
    local iconX = boxX + 40 * pulse
    local iconY = y + bh/2
    local iconScale = 2.0 * pulse
    
    if upgrade.type == "weapon" then
        WeaponIcons.drawWeaponIcon(upgrade.id, iconX, iconY, iconScale)
    else
        PassiveIcons.drawPassiveIcon(upgrade.id, iconX, iconY, iconScale)
    end
    
    -- Draw Text
    local textX = boxX
    local textW = currentBoxW
    
    -- Name & Level (Centered globally in block)
    Colors.setColor(rarityColor)
    love.graphics.setFont(Fonts.getFont("normal"))
    love.graphics.printf(upgrade.name:upper(), textX, y + 15, textW, "center")
    
    love.graphics.setFont(Fonts.getFont("small"))
    Colors.setColor("dim")
    love.graphics.printf("LV" .. upgrade.level .. " | " .. rarityName, textX, y + 35, textW, "center")
    
    -- Description or Stat Changes (Centered globally in block)
    love.graphics.setFont(Fonts.getFont("tiny"))
    if upgrade.type == "passive" and upgrade.data.effects and upgrade.data.effects[upgrade.level] then
        local effectY = y + 55
        for _, effect in ipairs(upgrade.data.effects[upgrade.level]) do
            local valStr = (effect.type == "multiply") and (string.format("%+d%%", effect.value * 100)) or (string.format("%+g", effect.value))
            local statName = effect.stat:gsub("(%l)(%w+)", function(a,b) return a:upper()..b end)
            
            love.graphics.setColor(0.4, 1.0, 0.4, 0.9) -- Green for stats
            love.graphics.printf(valStr .. " " .. statName, textX, effectY, textW, "center")
            effectY = effectY + 12
        end
    else
        Colors.setColor("dim", 0.9)
        love.graphics.printf(upgrade.description, textX + 40 * pulse, y + 55, textW - 80 * pulse, "center")
    end
  end
  
  -- Footer
  if progress > 0.8 then
    Colors.setColor("dim", (progress - 0.8) * 5)
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf("ARROW KEYS: SELECT  |  Z: INSTALL MODULE", 0, sh - 60, sw, "center")
  end
end

return UpgradeMenu
