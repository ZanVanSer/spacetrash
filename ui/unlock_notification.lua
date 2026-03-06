local Screen = require('systems.screen')
local Colors = require('ui.colors')
local Fonts = require('ui.fonts')
local dl = require('systems.dataloader')
local WeaponIcons = require('ui.weapon_icons')
local PassiveIcons = require('ui.passive_icons')

local UnlockNotification = {
    active = {}, -- { {timer, item, type, state, xOffset} }
    width = 320,
    height = 70,
    spacing = 10,
    displayTime = 3.5,
    slideTime = 0.4
}

function UnlockNotification.addUnlock(itemType, itemId)
    local data = nil
    if itemType == "ship" then data = dl.getShips()
    elseif itemType == "weapon" then data = dl.getWeapons()
    elseif itemType == "passive" then data = dl.getPassives()
    end
    
    local item = nil
    if data then
        for _, v in ipairs(data) do
            if v.id == itemId then
                item = v
                break
            end
        end
    end
    
    if not item then return end
    
    table.insert(UnlockNotification.active, {
        item = item,
        type = itemType,
        timer = 0,
        state = "slide_in",
        xOffset = UnlockNotification.width + 40
    })
end

function UnlockNotification.update(dt)
    for i = #UnlockNotification.active, 1, -1 do
        local n = UnlockNotification.active[i]
        n.timer = n.timer + dt
        
        if n.state == "slide_in" then
            local progress = n.timer / UnlockNotification.slideTime
            n.xOffset = (1 - progress) * (UnlockNotification.width + 40)
            if n.timer >= UnlockNotification.slideTime then
                n.state = "hold"
                n.timer = 0
                n.xOffset = 0
            end
        elseif n.state == "hold" then
            if n.timer >= UnlockNotification.displayTime then
                n.state = "slide_out"
                n.timer = 0
            end
        elseif n.state == "slide_out" then
            local progress = n.timer / UnlockNotification.slideTime
            n.xOffset = progress * (UnlockNotification.width + 40)
            if n.timer >= UnlockNotification.slideTime then
                table.remove(UnlockNotification.active, i)
            end
        end
    end
end

function UnlockNotification.draw()
    local sw = Screen.getVirtualWidth()
    local startY = 30
    
    for i, n in ipairs(UnlockNotification.active) do
        local x = sw - UnlockNotification.width - 20 + n.xOffset
        local y = startY + (i - 1) * (UnlockNotification.height + UnlockNotification.spacing)
        
        -- Glow Effect
        local pulse = (math.sin(love.timer.getTime() * 4) + 1) / 2
        Colors.setColor("accent", 0.1 + pulse * 0.1)
        love.graphics.rectangle("fill", x - 2, y - 2, UnlockNotification.width + 4, UnlockNotification.height + 4, 4)
        
        -- Background Box
        love.graphics.setColor(0.04, 0.06, 0.08, 0.95)
        love.graphics.rectangle("fill", x, y, UnlockNotification.width, UnlockNotification.height, 4)
        
        -- Cyan Border
        Colors.setColor("accent", 0.6)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, UnlockNotification.width, UnlockNotification.height, 4)
        love.graphics.setLineWidth(1)
        
        -- Item Icon
        love.graphics.push()
        love.graphics.translate(x + 35, y + 35)
        if n.type == "weapon" then
            WeaponIcons.drawIcon(n.item.id, 0, 0, 1.2, 1.0)
        elseif n.type == "passive" then
            PassiveIcons.drawIcon(n.item.id, 0, 0, 1.2, 1.0)
        else
            -- Ship placeholder or icon
            Colors.setColor("white", 0.8)
            love.graphics.rectangle("line", -15, -15, 30, 30, 4)
            love.graphics.polygon("fill", 0, -10, -8, 8, 8, 8)
        end
        love.graphics.pop()
        
        -- Text Content
        Colors.setColor("accent")
        love.graphics.setFont(Fonts.getFont("tiny"))
        love.graphics.print("NEW UNLOCK!", x + 70, y + 10)
        
        Colors.setColor("white")
        love.graphics.setFont(Fonts.getFont("small"))
        love.graphics.print(n.item.name or "Unknown", x + 70, y + 25)
        
        Colors.setColor("dim")
        love.graphics.setFont(Fonts.getFont("tiny"))
        local desc = n.item.description or "New item added to inventory."
        love.graphics.printf(desc, x + 70, y + 42, UnlockNotification.width - 80, "left")
    end
end

return UnlockNotification
