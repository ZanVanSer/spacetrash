local Colors = require('ui/colors')

local BossVisuals = {}

local function drawGlow(color, drawFunction, scale1, scale2)
    local s1 = scale1 or 1.4
    local s2 = scale2 or 1.15

    love.graphics.push()
    love.graphics.scale(s1, s1)
    Colors.setColor(color, 0.08)
    drawFunction()
    love.graphics.pop()

    love.graphics.push()
    love.graphics.scale(s2, s2)
    Colors.setColor(color, 0.15)
    drawFunction()
    love.graphics.pop()

    Colors.setColor(color, 0.9)
    drawFunction()
end

function BossVisuals.asteroid_guardian(flashTimer, overlayAlpha, aimAngle, chargeLevel)
    local t = love.timer.getTime()
    local baseAim = aimAngle or 0
    local leftAim = baseAim - math.rad(15)
    local rightAim = baseAim + math.rad(15)
    local leftBarrelStartX = -30 + math.cos(leftAim) * 8
    local leftBarrelStartY = 0 + math.sin(leftAim) * 8
    local leftBarrelEndX = -30 + math.cos(leftAim) * 18
    local leftBarrelEndY = 0 + math.sin(leftAim) * 18
    local rightBarrelStartX = 30 + math.cos(rightAim) * 8
    local rightBarrelStartY = 0 + math.sin(rightAim) * 8
    local rightBarrelEndX = 30 + math.cos(rightAim) * 18
    local rightBarrelEndY = 0 + math.sin(rightAim) * 18
    local hullPoints = {
        0, -25, -50, -15, -60, 10, -50, 20, 50, 20, 60, 10, 50, -15
    }

    if flashTimer and flashTimer > 0 and overlayAlpha and overlayAlpha > 0 then
        love.graphics.setColor(1, 1, 1, overlayAlpha)
        love.graphics.polygon("fill", hullPoints)
        love.graphics.setLineWidth(2)
        love.graphics.polygon("line", hullPoints)

        love.graphics.circle("fill", -30, 0, 8)
        love.graphics.circle("fill", 30, 0, 8)
        love.graphics.circle("line", -30, 0, 8)
        love.graphics.circle("line", 30, 0, 8)
        love.graphics.line(leftBarrelStartX, leftBarrelStartY, leftBarrelEndX, leftBarrelEndY)
        love.graphics.line(rightBarrelStartX, rightBarrelStartY, rightBarrelEndX, rightBarrelEndY)

        love.graphics.circle("fill", 0, -10, 6)
        love.graphics.rectangle("fill", -24, 16, 8, 4)
        love.graphics.rectangle("fill", 16, 16, 8, 4)
        return
    end

    local hullShape = function()
        love.graphics.polygon("fill", hullPoints)
    end

    -- Danger glow around the hull silhouette.
    drawGlow("danger", hullShape, 1.4, 1.15)

    -- Main hull body (dark red carrier profile).
    love.graphics.setColor(0.15, 0, 0, 0.95)
    love.graphics.polygon("fill", hullPoints)
    Colors.setColor("danger", 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", hullPoints)

    -- Left and right gun turrets.
    love.graphics.setColor(0.15, 0, 0, 0.95)
    love.graphics.circle("fill", -30, 0, 8)
    love.graphics.circle("fill", 30, 0, 8)
    Colors.setColor("danger", 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", -30, 0, 8)
    love.graphics.circle("line", 30, 0, 8)

    -- Gun barrels extending outward.
    love.graphics.line(leftBarrelStartX, leftBarrelStartY, leftBarrelEndX, leftBarrelEndY)
    love.graphics.line(rightBarrelStartX, rightBarrelStartY, rightBarrelEndX, rightBarrelEndY)

    -- Central bridge weak point with pulsing cyan glow.
    local bridgeAlpha = 0.4 + math.sin(t * 4) * 0.3
    Colors.setColor("accent", math.max(0.1, bridgeAlpha * 0.45))
    love.graphics.circle("fill", 0, -10, 11)
    Colors.setColor("accent", math.max(0.1, bridgeAlpha))
    love.graphics.circle("fill", 0, -10, 6)

    -- Engine exhausts with orange flicker.
    local flicker = (math.sin(t * 20) + 1) * 0.5
    love.graphics.setColor(1, 0.45 + flicker * 0.3, 0, 0.85)
    love.graphics.rectangle("fill", -24, 16, 8, 4)
    love.graphics.rectangle("fill", 16, 16, 8, 4)
end

function BossVisuals.void_destroyer(flashTimer, overlayAlpha, aimAngle, chargeLevel)
    local t = love.timer.getTime()
    local charge = math.max(0, math.min(1, chargeLevel or 0))

    if flashTimer and flashTimer > 0 and overlayAlpha and overlayAlpha > 0 then
        love.graphics.setColor(1, 1, 1, overlayAlpha)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", 0, 0, 45)
        love.graphics.setLineWidth(2)
        for i = 0, 7 do
            local a = (math.pi * 2 / 8) * i
            local x1, y1 = math.cos(a) * 40, math.sin(a) * 40
            local x2, y2 = math.cos(a) * 50, math.sin(a) * 50
            love.graphics.line(x1, y1, x2, y2)
        end
        love.graphics.circle("fill", 0, 0, 20)
        love.graphics.circle("fill", 0, 0, 5)
        return
    end

    local ring = function()
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", 0, 0, 45)
    end

    -- Glowing mechanical outer ring.
    drawGlow("danger", ring, 1.4, 1.15)
    Colors.setColor("danger", 1)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", 0, 0, 45)

    -- 8 ring segments / tick marks (r=40 to r=50).
    Colors.setColor("danger", 0.9)
    love.graphics.setLineWidth(2)
    for i = 0, 7 do
        local a = (math.pi * 2 / 8) * i
        local x1, y1 = math.cos(a) * 40, math.sin(a) * 40
        local x2, y2 = math.cos(a) * 50, math.sin(a) * 50
        love.graphics.line(x1, y1, x2, y2)
    end

    -- Core void.
    love.graphics.setColor(0.05, 0, 0, 1)
    love.graphics.circle("fill", 0, 0, 20)
    love.graphics.setColor(0.5, 0, 0, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", 0, 0, 20)

    -- Energy core pulse indicating imminent shot.
    local coreRadius = 5 + (charge * 5)
    local pulse = 0.55 + (math.sin(t * 8) + 1) * 0.225
    local coreAlpha = 0.5 + (charge * 0.5)
    Colors.setColor("danger", math.max(pulse, coreAlpha))
    love.graphics.circle("fill", 0, 0, coreRadius)
    Colors.setColor("danger", math.min(1, math.max(pulse, coreAlpha) + 0.15))
    love.graphics.circle("line", 0, 0, coreRadius + 3)

    if charge > 0 then
        local ringPulse = (math.sin(t * 10) + 1) * 0.5
        local ringAlpha = (0.25 + charge * 0.55) * (0.7 + ringPulse * 0.3)
        local ring1 = coreRadius + 4 + charge * 4 + ringPulse * 2
        local ring2 = coreRadius + 10 + charge * 6 + ringPulse * 3
        Colors.setColor("danger", math.min(1, ringAlpha))
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", 0, 0, ring1)
        Colors.setColor("danger", math.min(1, ringAlpha * 0.8))
        love.graphics.circle("line", 0, 0, ring2)
    end
end

function BossVisuals.default(flashTimer, overlayAlpha, aimAngle, chargeLevel)
    if flashTimer and flashTimer > 0 and overlayAlpha and overlayAlpha > 0 then
        love.graphics.setColor(1, 1, 1, overlayAlpha)
        love.graphics.circle("fill", 0, 0, 42)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", 0, 0, 42)
        return
    end

    local body = function()
        love.graphics.circle("fill", 0, 0, 42)
    end

    drawGlow("danger", body, 1.4, 1.15)

    Colors.setColor("danger", 1)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", 0, 0, 42)
end

local function drawBossById(bossId, flashTimer, overlayAlpha, aimAngle, chargeLevel)
    if bossId == "asteroid_boss" or bossId == "asteroid_guardian" then
        BossVisuals.asteroid_guardian(flashTimer, overlayAlpha, aimAngle, chargeLevel)
    elseif bossId == "void_destroyer" then
        BossVisuals.void_destroyer(flashTimer, overlayAlpha, aimAngle, chargeLevel)
    else
        BossVisuals.default(flashTimer, overlayAlpha, aimAngle, chargeLevel)
    end
end

function BossVisuals.drawBoss(bossId, x, y, scale, rotation, flashTimer, aimAngle, chargeLevel)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(rotation or 0)
    love.graphics.scale(scale or 1, scale or 1)

    drawBossById(bossId, flashTimer, nil, aimAngle, chargeLevel)

    if flashTimer and flashTimer > 0 then
        local alpha = math.min(1, flashTimer * 2)
        drawBossById(bossId, flashTimer, alpha, aimAngle, chargeLevel)
    end

    love.graphics.pop()
end

BossVisuals.drawGlow = drawGlow

return BossVisuals
