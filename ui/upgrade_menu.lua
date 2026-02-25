local Screen = require('systems.screen')
local UpgradeMenu = {}
UpgradeMenu.__index = UpgradeMenu

function UpgradeMenu.new()
  local menu = {}
  menu.upgrades = {}
  menu.selectedIndex = 1
  
  local dl = require('systems/dataloader')
  local allUpgrades = dl.getUpgrades()
  
  local picked = {}
  local available = {}
  for i, u in ipairs(allUpgrades) do available[i] = u end
  
  for i = 1, math.min(3, #allUpgrades) do
    local idx = math.random(#available)
    table.insert(picked, table.remove(available, idx))
  end
  menu.upgrades = picked
  
  return setmetatable(menu, UpgradeMenu)
end

function UpgradeMenu:keypressed(key)
  if key == 'up' then
    self.selectedIndex = self.selectedIndex - 1
    if self.selectedIndex < 1 then self.selectedIndex = #self.upgrades end
  elseif key == 'down' then
    self.selectedIndex = self.selectedIndex + 1
    if self.selectedIndex > #self.upgrades then self.selectedIndex = 1 end
  elseif key == 'z' then
    return self.upgrades[self.selectedIndex]
  end
  return nil
end

function UpgradeMenu:draw()
  local sw, sh = Screen.getVirtualWidth(), Screen.getVirtualHeight()
  
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle('fill', 0, 0, sw, sh)
  
  love.graphics.setColor(1, 1, 1)
  love.graphics.printf("LEVEL UP! Choose an upgrade:", 0, 100, sw, "center")
  
  local startY, bh, sp = 200, 80, 20
  for i, upgrade in ipairs(self.upgrades) do
    local y = startY + (i-1) * (bh + sp)
    if i == self.selectedIndex then
      love.graphics.setColor(0.8, 0.8, 0.3)
      love.graphics.rectangle('fill', sw/2 - 210, y - 5, 420, bh + 10)
    end
    
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle('fill', sw/2 - 200, y, 400, bh)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', sw/2 - 200, y, 400, bh)
    
    love.graphics.print(upgrade.name, sw/2 - 180, y + 10)
    love.graphics.print(upgrade.description, sw/2 - 180, y + 40)
  end
  
  love.graphics.printf("Arrow Keys: Select  |  Z: Confirm", 0, sh - 50, sw, "center")
end

return UpgradeMenu
