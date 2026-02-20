local sm = require "states/statemanager"
local state = {}

function state:draw()
    love.graphics.print("Test State 2 - Press Z", 400, 300)
end

function state:keypressed(key)
    if key == "z" then
        sm.switch("test1")
    end
end

return state
