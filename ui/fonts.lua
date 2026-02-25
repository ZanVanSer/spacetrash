local Screen = require('systems.screen')

local Fonts = {}
local fontCache = {}
local FONT_PATH = "assets/fonts/ShareTechMono-Regular.ttf"

local SIZES = {
    tiny = 8,
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
        -- Attempt to load the custom monospace font.
        local success, font = pcall(function()
            if love.filesystem.getInfo(FONT_PATH) then
                return love.graphics.newFont(FONT_PATH, finalSize)
            else
                return love.graphics.newFont(finalSize)
            end
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
