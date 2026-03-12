local Screen = require('systems.screen')

local Fonts = {}
local fontCache = {}
local FONT_PATH = "assets/fonts/ShareTechMono-Regular.ttf"

local SIZES = {
    tiny = 8,
    small = 10,
    medium = 14,
    normal = 12,
    large = 16,
    huge = 24
}

function Fonts.getFont(sizeName)
    local baseSize = SIZES[sizeName] or 12
    -- Fonts are loaded at base size - scaling is handled by Screen.applyScale() coordinate transformation
    -- This ensures crisp text at any resolution
    local finalSize = baseSize
    
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

-- Text wrapping utility: returns wrapped text and height
-- Uses the specified font to measure text width
function Fonts.wrapText(text, maxWidth, fontOrSize)
    local font = type(fontOrSize) == "string" and Fonts.getFont(fontOrSize) or fontOrSize
    if not font then return text, 0 end
    
    local lines = {}
    local currentLine = ""
    
    -- Split by words
    for word in text:gmatch("%S+%") do
        local testLine = currentLine == "" and word or currentLine .. " " .. word
        local width = font:getWidth(testLine)
        
        if width <= maxWidth then
            currentLine = testLine
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
            end
            -- Check if single word is too wide
            if font:getWidth(word) > maxWidth then
                -- Force-break long words
                local part = ""
                for i = 1, #word do
                    local char = word:sub(i, i)
                    local testPart = part .. char
                    if font:getWidth(testPart) > maxWidth then
                        table.insert(lines, part)
                        part = char
                    else
                        part = testPart
                    end
                end
                currentLine = part
            else
                currentLine = word
            end
        end
    end
    
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    
    return table.concat(lines, "\n"), #lines * font:getHeight()
end

-- Text truncation utility: truncates text with ellipsis if too wide
function Fonts.truncateText(text, maxWidth, fontOrSize, ellipsis)
    local font = type(fontOrSize) == "string" and Fonts.getFont(fontOrSize) or fontOrSize
    ellipsis = ellipsis or "..."
    if not font then return text end
    
    local textWidth = font:getWidth(text)
    if textWidth <= maxWidth then
        return text
    end
    
    -- Binary search for max chars
    local minLen = 1
    local maxLen = #text
    local result = text
    
    while minLen <= maxLen do
        local mid = math.floor((minLen + maxLen) / 2)
        local testText = text:sub(1, mid) .. ellipsis
        if font:getWidth(testText) <= maxWidth then
            result = testText
            minLen = mid + 1
        else
            maxLen = mid - 1
        end
    end
    
    return result
end

return Fonts
