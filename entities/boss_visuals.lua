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

local function getDamageTier(healthPercent)
    local hp = math.max(0, math.min(1, healthPercent or 1))
    if hp > 0.75 then return 0, hp end
    if hp > 0.5 then return 1, hp end
    if hp > 0.25 then return 2, hp end
    return 3, hp
end

function BossVisuals.asteroid_guardian(flashTimer, overlayAlpha, aimAngle, chargeLevel, healthPercent)
    local t = love.timer.getTime()
    local damageTier = getDamageTier(healthPercent)
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
    local hullR, hullA = 0.15, 0.95
    if damageTier == 1 then
        hullR, hullA = 0.12, 0.9
    elseif damageTier == 2 then
        hullR, hullA = 0.09, 0.9
    elseif damageTier == 3 then
        hullR, hullA = 0.06, 0.88
    end
    love.graphics.setColor(hullR, 0, 0, hullA)
    love.graphics.polygon("fill", hullPoints)
    Colors.setColor("danger", damageTier >= 1 and 0.85 or 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", hullPoints)

    -- Left and right gun turrets.
    love.graphics.setColor(hullR, 0, 0, hullA)
    love.graphics.circle("fill", -30, 0, 8)
    love.graphics.circle("fill", 30, 0, 8)
    Colors.setColor("danger", damageTier >= 1 and 0.85 or 1)
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

    -- Light smoke puffs when moderately damaged.
    if damageTier >= 1 then
        local smokeCount = damageTier >= 2 and 5 or 3
        for i = 1, smokeCount do
            local drift = t * (0.8 + i * 0.2)
            local sx = -34 + i * 16 + math.sin(drift * 1.7) * 3
            local sy = -16 - (i * 3) - (drift % 8)
            local sr = 2 + (i % 2)
            love.graphics.setColor(0.2, 0.2, 0.2, 0.18 + (damageTier * 0.05))
            love.graphics.circle("fill", sx, sy, sr)
        end
    end

    -- Crack lines increase as health drops.
    if damageTier >= 2 then
        local cracks = {
            {-45, -8, -10, 8},
            {-8, -18, 8, 14},
            {26, -12, 44, 10},
            {-30, 12, -6, 18},
            {6, 6, 30, 16},
            {-2, -24, 16, -4}
        }
        local crackCount = damageTier == 2 and 3 or 6
        Colors.setColor("danger", damageTier == 2 and 0.65 or 0.8)
        love.graphics.setLineWidth(1)
        for i = 1, crackCount do
            local c = cracks[i]
            love.graphics.line(c[1], c[2], c[3], c[4])
        end
    end

    -- Heavy damage sparks at critical HP.
    if damageTier == 3 then
        for i = 0, 5 do
            local a = t * 18 + i * 1.2
            local sx = math.cos(a) * (28 + (i % 3) * 8)
            local sy = math.sin(a) * (16 + (i % 2) * 10)
            local ex = sx + math.cos(a * 1.9) * 6
            local ey = sy + math.sin(a * 1.9) * 6
            love.graphics.setColor(1, 0.6, 0, 0.55)
            love.graphics.setLineWidth(1)
            love.graphics.line(sx, sy, ex, ey)
        end
    end
end

function BossVisuals.void_destroyer(flashTimer, overlayAlpha, aimAngle, chargeLevel, healthPercent)
    local t = love.timer.getTime()
    local charge = math.max(0, math.min(1, chargeLevel or 0))
    local damageTier = getDamageTier(healthPercent)

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

    local function drawRing(radius, lineWidth, alpha)
        love.graphics.setLineWidth(lineWidth)
        if damageTier == 0 then
            love.graphics.circle("line", 0, 0, radius)
            return
        end

        local segments = 12
        local step = (math.pi * 2) / segments
        local skipped = {}
        if damageTier == 1 then
            skipped = {2}
        elseif damageTier == 2 then
            skipped = {2, 7, 10}
        else
            skipped = {1, 3, 6, 8, 10}
        end
        local skipMap = {}
        for _, idx in ipairs(skipped) do
            skipMap[idx] = true
        end

        for i = 0, segments - 1 do
            local idx = i + 1
            if not skipMap[idx] then
                local a1 = i * step
                local a2 = a1 + step * 0.85
                love.graphics.arc("line", "open", 0, 0, radius, a1, a2)
            end
        end
    end

    local ring = function()
        drawRing(45, 3, 1)
    end

    -- Glowing mechanical outer ring.
    drawGlow("danger", ring, 1.4, 1.15)
    Colors.setColor("danger", damageTier >= 1 and 0.8 or 1)
    drawRing(45, 3, 1)

    -- 8 ring segments / tick marks (r=40 to r=50).
    Colors.setColor("danger", damageTier >= 2 and 0.65 or 0.9)
    love.graphics.setLineWidth(2)
    for i = 0, 7 do
        if damageTier < 2 or (i % 3 ~= 1) then
        local a = (math.pi * 2 / 8) * i
        local x1, y1 = math.cos(a) * 40, math.sin(a) * 40
        local x2, y2 = math.cos(a) * 50, math.sin(a) * 50
        love.graphics.line(x1, y1, x2, y2)
        end
    end

    -- Core void.
    local coreDark = damageTier == 0 and 0.05 or (damageTier == 1 and 0.04 or (damageTier == 2 and 0.03 or 0.02))
    love.graphics.setColor(coreDark, 0, 0, 1)
    love.graphics.circle("fill", 0, 0, 20)
    love.graphics.setColor(0.5, 0, 0, damageTier == 3 and 0.55 or 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", 0, 0, 20)

    -- Energy core pulse indicating imminent shot.
    local coreRadius = 5 + (charge * 5)
    local pulse = 0.55 + (math.sin(t * 8) + 1) * 0.225
    local coreAlpha = 0.5 + (charge * 0.5)
    if damageTier == 3 then
        -- Erratic flicker under heavy damage.
        local flicker = 0.45 + (math.sin(t * 37) + math.sin(t * 19) + math.sin(t * 53)) * 0.15
        coreAlpha = math.max(0.2, math.min(1, coreAlpha * flicker))
        coreRadius = coreRadius + math.sin(t * 41) * 1.5
    end
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

    if damageTier == 3 then
        for i = 0, 6 do
            local a = t * 16 + i * (math.pi * 2 / 7)
            local sx = math.cos(a) * 24
            local sy = math.sin(a) * 24
            local ex = sx + math.cos(a + math.sin(t * 11 + i) * 0.7) * 7
            local ey = sy + math.sin(a + math.sin(t * 11 + i) * 0.7) * 7
            love.graphics.setColor(1, 0.6, 0, 0.55)
            love.graphics.setLineWidth(1)
            love.graphics.line(sx, sy, ex, ey)
        end
    end
end

function BossVisuals.default(flashTimer, overlayAlpha, aimAngle, chargeLevel, healthPercent)
    local points = {0, 40, -40, -30, 40, -30}

    if flashTimer and flashTimer > 0 and overlayAlpha and overlayAlpha > 0 then
        love.graphics.setColor(1, 1, 1, overlayAlpha)
        love.graphics.polygon("fill", points)
        love.graphics.setLineWidth(2)
        love.graphics.polygon("line", points)
        return
    end

    local body = function()
        love.graphics.polygon("fill", points)
    end

    drawGlow("danger", body, 1.4, 1.15)

    Colors.setColor("danger", 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", points)
end

function BossVisuals.drawBoss(bossId, x, y, scale, rotation, flashTimer, aimAngle, chargeLevel, healthPercent)
    local drawFn = BossVisuals[bossId] or BossVisuals.default

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(rotation or 0)
    love.graphics.scale(scale or 1, scale or 1)

    drawFn(flashTimer, nil, aimAngle, chargeLevel, healthPercent)

    if flashTimer and flashTimer > 0 then
        local alpha = math.min(1, flashTimer * 2)
        drawFn(flashTimer, alpha, aimAngle, chargeLevel, healthPercent)
    end

    love.graphics.pop()
end

BossVisuals.asteroid_boss = BossVisuals.asteroid_guardian

BossVisuals.drawGlow = drawGlow

return BossVisuals
