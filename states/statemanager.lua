local sm = { states = {}, current = nil }

function sm.register(name, state)
    sm.states[name] = state
end

function sm.switch(name, ...)
    sm.current = sm.states[name]
    if sm.current and sm.current.enter then
        sm.current:enter(...)
    end
end

function sm.update(dt)
    if sm.current and sm.current.update then sm.current:update(dt) end
end

function sm.draw()
    if sm.current and sm.current.draw then sm.current:draw() end
end

function sm.keypressed(key)
    if sm.current and sm.current.keypressed then sm.current:keypressed(key) end
end

return sm
