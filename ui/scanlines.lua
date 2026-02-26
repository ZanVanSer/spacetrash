local Screen = require('systems.screen')

local Scanlines = {}

function Scanlines.drawScanlines()
    local vw, vh = Screen.getVirtualWidth(), Screen.getVirtualHeight()
    
    love.graphics.setColor(1, 1, 1, 0.015)
    love.graphics.setLineWidth(1)
    
    for y = 0, vh, 4 do
        love.graphics.line(0, y, vw, y)
    end
end

return Scanlines
