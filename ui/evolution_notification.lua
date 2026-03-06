local Screen = require('systems.screen')
local Colors = require('ui.colors')
local Fonts = require('ui.fonts')

local EvolutionNotification = {
    active = false,
    weaponName = "",
    evolvedName = "",
    passiveName = "",
    timer = 0,
    callback = nil
}

function EvolutionNotification.show(weaponName, evolvedName, passiveName, onEvolve)
    EvolutionNotification.weaponName = weaponName
    EvolutionNotification.evolvedName = evolvedName
    EvolutionNotification.passiveName = passiveName
    EvolutionNotification.callback = onEvolve
    EvolutionNotification.active = true
    EvolutionNotification.timer = 0
end

function EvolutionNotification.update(dt)
    if not EvolutionNotification.active then return end
    EvolutionNotification.timer = EvolutionNotification.timer + dt
end

function EvolutionNotification.draw()
    if not EvolutionNotification.active then return end

    local sw, sh = Screen.getVirtualWidth(), Screen.getVirtualHeight()
    local w, h = 500, 180
    local x, y = sw / 2 - w / 2, sh / 2 - h / 2

    -- Dark Overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Pulsing Border
    local pulse = (math.sin(EvolutionNotification.timer * 5) + 1) / 2
    love.graphics.setLineWidth(3)
    Colors.setColor("accent", 0.3 + pulse * 0.7)
    love.graphics.rectangle("line", x - 10, y - 10, w + 20, h + 20, 10)
    love.graphics.setLineWidth(1)

    -- Main Box
    love.graphics.setColor(0.05, 0.1, 0.12, 0.95)
    love.graphics.rectangle("fill", x, y, w, h, 8)
    Colors.setColor("accent", 0.5)
    love.graphics.rectangle("line", x, y, w, h, 8)

    -- Text: Evolution Available
    Colors.setColor("accent")
    love.graphics.setFont(Fonts.getFont("large"))
    love.graphics.printf("EVOLUTION AVAILABLE!", x, y + 20, w, "center")

    -- Text: Weapon Transition
    love.graphics.setFont(Fonts.getFont("medium"))
    Colors.setColor("white")
    love.graphics.printf(EvolutionNotification.weaponName .. " -> " .. EvolutionNotification.evolvedName, x, y + 65, w, "center")

    -- Text: Required Passive
    love.graphics.setFont(Fonts.getFont("tiny"))
    Colors.setColor("dim")
    love.graphics.printf("Requires: " .. EvolutionNotification.passiveName, x, y + 100, w, "center")

    -- Button Prompts
    local promptPulse = (math.sin(EvolutionNotification.timer * 8) + 1) / 2
    love.graphics.setFont(Fonts.getFont("small"))
    
    -- Evolve Prompt
    Colors.setColor("accent", 0.7 + promptPulse * 0.3)
    love.graphics.printf("[Z] EVOLVE NOW", x, y + 140, w/2, "right")
    
    -- Dismiss Prompt
    Colors.setColor("danger", 0.7)
    love.graphics.printf("DISMISS [X]", x + w/2 + 20, y + 140, w/2 - 20, "left")
end

function EvolutionNotification.keypressed(key)
    if not EvolutionNotification.active then return end

    if key == 'z' then
        EvolutionNotification.active = false
        if EvolutionNotification.callback then
            EvolutionNotification.callback()
        end
        return true
    elseif key == 'x' then
        EvolutionNotification.active = false
        return true
    end
end

return EvolutionNotification
