local special_attacks = {
    handlers = {}
}

--- Generic handler for special attacks from enemies or bosses.
--- Dynamically loads attack logic from systems/specials/[attackType].lua
---
--- @param attackType string Name of the attack (e.g., "spiral_barrage", "aimed_storm")
--- @param attackData table Parameters from JSON definitions
--- @param source table The boss or enemy entity performing the attack
--- @param telegraph table Reference to the telegraph system for visual cues
--- @return table|nil An attack state object with an update(dt) function, or nil if failed
function special_attacks.execute(attackType, attackData, source, telegraph)
    if not attackType or attackType == "" then return nil end

    -- Use cached handler if available
    local handler = special_attacks.handlers[attackType]

    if not handler then
        local path = "systems/specials/" .. attackType
        -- Check if the file exists before requiring to avoid hard errors
        local info = love.filesystem.getInfo(path .. ".lua")
        if info then
            -- Load the handler dynamically
            -- In Love2D, slash paths are generally supported in require
            handler = require(path)
            special_attacks.handlers[attackType] = handler
        else
            return nil
        end
    end

    -- Execute the loaded handler to create the attack state
    if handler and type(handler.execute) == "function" then
        local attackState = handler.execute(attackData, source, telegraph)
        
        -- The attack state must have an update function
        if attackState and type(attackState.update) == "function" then
            return attackState
        end
    end

    return nil
end

return special_attacks
