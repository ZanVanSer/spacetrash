local Screen = {}

local VIRTUAL_WIDTH = 800
local VIRTUAL_HEIGHT = 600

function Screen.getVirtualWidth()
    return VIRTUAL_WIDTH
end

function Screen.getVirtualHeight()
    return VIRTUAL_HEIGHT
end

function Screen.getActualWidth()
    return love.graphics.getWidth()
end

function Screen.getActualHeight()
    return love.graphics.getHeight()
end

function Screen.getScaleX()
    return Screen.getActualWidth() / VIRTUAL_WIDTH
end

function Screen.getScaleY()
    return Screen.getActualHeight() / VIRTUAL_HEIGHT
end

function Screen.getScale()
    return math.min(Screen.getScaleX(), Screen.getScaleY())
end

function Screen.applyScale()
    love.graphics.push()
    love.graphics.scale(Screen.getScaleX(), Screen.getScaleY())
end

function Screen.removeScale()
    love.graphics.pop()
end

function Screen.toVirtualX(screenX)
    return screenX / Screen.getScaleX()
end

function Screen.toVirtualY(screenY)
    return screenY / Screen.getScaleY()
end

function Screen.toScreenX(virtualX)
    return virtualX * Screen.getScaleX()
end

function Screen.toScreenY(virtualY)
    return virtualY * Screen.getScaleY()
end

return Screen
