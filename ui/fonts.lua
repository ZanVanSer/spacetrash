local Screen = require('systems.screen')

local Fonts = {}
local fontCache = {}

local SIZES = {
    small = 10,
    normal = 12,
    large = 16,
    huge = 24
}

function Fonts.getFont(sizeName)
    local baseSize = SIZES[sizeName] or 12
    -- Multiply base font size by Screen.getScale() for resolution independence
    local scale = Screen.getScale()
    local finalSize = math.max(1, math.floor(baseSize * scale))
    
    local cacheKey = sizeName .. "_" .. finalSize
    
    if not fontCache[cacheKey] then
        -- Attempt to load a monospace font. Since we don't have a custom .ttf,
        -- we'll use the default font provided by LÖVE at the calculated size.
        -- Note: LÖVE's default font isn't guaranteed to be monospace on all systems,
        -- but without a specific font file, it's the most reliable fallback.
        local success, font = pcall(function()
            return love.graphics.newFont(finalSize)
        end)
        
        if success and font then
            fontCache[cacheKey] = font
        else
            -- Fallback to the current global font if object creation fails
            fontCache[cacheKey] = love.graphics.getFont()
        end
    end
    
    return fontCache[cacheKey]
end

return Fonts
