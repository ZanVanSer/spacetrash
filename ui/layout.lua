local Screen = require('systems.screen')

local Layout = {}

-- Convert percentages to virtual coordinates
function Layout.percentX(percent)
    return Screen.getVirtualWidth() * percent
end

function Layout.percentY(percent)
    return Screen.getVirtualHeight() * percent
end

-- Common anchor points
function Layout.centerX()
    return Screen.getVirtualWidth() / 2
end

function Layout.centerY()
    return Screen.getVirtualHeight() / 2
end

function Layout.right()
    return Screen.getVirtualWidth()
end

function Layout.bottom()
    return Screen.getVirtualHeight()
end

-- HUD panel dimensions (design: left 220px panel)
function Layout.hudPanelWidth()
    return 220
end

function Layout.hudPanelX()
    return 0
end

function Layout.gameViewportX()
    return 220
end

function Layout.gameViewportWidth()
    return Screen.getVirtualWidth() - 220
end

-- Spacing helpers
function Layout.spacing(multiplier)
    return 10 * (multiplier or 1)
end

function Layout.padding()
    return 10
end

return Layout
