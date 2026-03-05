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
            if currentLevel < 8 then
                table.insert(options, {
                    id = w.id,
                    type = "weapon",
                    name = w.name,
                    level = currentLevel + 1,
                    description = "Upgrade to level " .. (currentLevel + 1),
                    rarity = w.rarity or 100
                })
            end
        elseif weaponCount < 4 then
            table.insert(options, {
                id = w.id,
                type = "weapon",
                name = w.name,
                level = 1,
                description = "Acquire new weapon system.",
                rarity = w.rarity or 100
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
                    rarity = p.rarity or 100
                })
            end
        elseif passiveCount < 4 then
            table.insert(options, {
                id = p.id,
                type = "passive",
                name = p.name,
                level = 1,
                description = p.description or "Acquire new enhancement module.",
                rarity = p.rarity or 100
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
                table.insert(picked, table.remove(options, idx))
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
  local sw, sh = Screen.getVirtualWidth(), Screen.getVirtualHeight()
  
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle('fill', 0, 0, sw, sh)
  
  Colors.setColor("accent")
  love.graphics.setFont(Fonts.getFont("large"))
  love.graphics.printf("SYSTEM UPGRADE DETECTED", 0, 80, sw, "center")
  
  local startY, bh, sp = 180, 90, 25
  local boxW = 450
  local boxX = sw/2 - boxW/2

  for i, upgrade in ipairs(self.upgrades) do
    local y = startY + (i-1) * (bh + sp)
    local isSelected = (i == self.selectedIndex)
    
    if isSelected then
      Colors.setColor("accent", 0.15)
      love.graphics.rectangle('fill', boxX - 10, y - 5, boxW + 20, bh + 10)
      Colors.setColor("accent", 0.8)
    else
      love.graphics.setColor(0.05, 0.1, 0.12, 0.9)
      love.graphics.rectangle('fill', boxX, y, boxW, bh)
      Colors.setColor("dim", 0.5)
    end
    
    love.graphics.setLineWidth(isSelected and 2 or 1)
    love.graphics.rectangle('line', boxX, y, boxW, bh)
    love.graphics.setLineWidth(1)
    
    local iconX = boxX + 35
    local iconY = y + 30
    local iconScale = 1.8
    
    if upgrade.type == "weapon" then
        WeaponIcons.drawWeaponIcon(upgrade.id, iconX, iconY, iconScale)
    else
        PassiveIcons.drawPassiveIcon(upgrade.id, iconX, iconY, iconScale)
    end
    
    if isSelected then Colors.setColor("accent") else Colors.setColor("accent", 0.7) end
    love.graphics.setFont(Fonts.getFont("large"))
    love.graphics.print(upgrade.name:upper() .. " LV" .. upgrade.level, boxX + 75, y + 15)
    
    Colors.setColor("dim")
    love.graphics.setFont(Fonts.getFont("small"))
    love.graphics.printf(upgrade.description, boxX + 75, y + 45, boxW - 90, "left")
  end
  
  Colors.setColor("dim")
  love.graphics.setFont(Fonts.getFont("small"))
  love.graphics.printf("ARROW KEYS: SELECT  |  Z: INSTALL MODULE", 0, sh - 60, sw, "center")
end

return UpgradeMenu
