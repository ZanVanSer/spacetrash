local ScreenShake = {
    intensity = 0,
    duration = 0,
    offsetX = 0,
    offsetY = 0,
    enabled = true
}

function ScreenShake.trigger(intensity, duration)
    if not ScreenShake.enabled then return end
    ScreenShake.intensity = intensity
    ScreenShake.duration = duration
end

function ScreenShake.update(dt)
    if ScreenShake.duration > 0 then
        ScreenShake.offsetX = math.random(-ScreenShake.intensity, ScreenShake.intensity)
        ScreenShake.offsetY = math.random(-ScreenShake.intensity, ScreenShake.intensity)
        
        -- Decay intensity and duration
        ScreenShake.intensity = ScreenShake.intensity * 0.95
        ScreenShake.duration = ScreenShake.duration - dt
    else
        ScreenShake.offsetX = 0
        ScreenShake.offsetY = 0
        ScreenShake.intensity = 0
    end
end

function ScreenShake.apply()
    if ScreenShake.offsetX ~= 0 or ScreenShake.offsetY ~= 0 then
        love.graphics.translate(ScreenShake.offsetX, ScreenShake.offsetY)
    end
end

return ScreenShake
