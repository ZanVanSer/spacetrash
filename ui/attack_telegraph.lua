local Colors = require('ui/colors')

local AttackTelegraph = {}

local function copyColor(color)
  if type(color) == 'table' then
    return {color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1}
  end

  local c = Colors.getColor(color or 'danger', 1)
  return {c[1], c[2], c[3], c[4]}
end

local function addTelegraph(self, telegraph)
  table.insert(self.telegraphs, telegraph)
  return telegraph
end

function AttackTelegraph.new()
  local manager = {
    telegraphs = {}
  }

  function manager:update(dt)
    local expiredAny = false

    for i = #self.telegraphs, 1, -1 do
      local telegraph = self.telegraphs[i]
      telegraph.elapsed = telegraph.elapsed + dt

      if telegraph.elapsed >= telegraph.duration then
        table.remove(self.telegraphs, i)
        expiredAny = true
      end
    end

    return expiredAny
  end

  function manager:draw()
    for _, telegraph in ipairs(self.telegraphs) do
      local base = telegraph.color
      local pulseAlpha = 0.3 + math.sin(telegraph.elapsed * 10) * 0.2
      local alpha = math.max(0, math.min(1, pulseAlpha))

      if telegraph.type == 'line' then
        local width = 2 + math.sin(telegraph.elapsed * 15)
        love.graphics.setLineWidth(math.max(1, width))
        love.graphics.setColor(base[1], base[2], base[3], alpha)
        love.graphics.line(telegraph.x, telegraph.y, telegraph.data.x2, telegraph.data.y2)
      elseif telegraph.type == 'area' then
        local fillPercent = math.max(0, math.min(1, telegraph.elapsed / telegraph.duration))
        local fillRadius = telegraph.data.radius * fillPercent
        local pulseRadius = telegraph.data.radius + math.sin(telegraph.elapsed * 10) * 2

        love.graphics.setColor(base[1], base[2], base[3], alpha * 0.35)
        love.graphics.circle('fill', telegraph.x, telegraph.y, fillRadius)

        love.graphics.setLineWidth(2)
        love.graphics.setColor(base[1], base[2], base[3], alpha)
        love.graphics.circle('line', telegraph.x, telegraph.y, pulseRadius)
      elseif telegraph.type == 'cone' then
        local angle = telegraph.data.angle
        local spread = telegraph.data.spread
        local length = telegraph.data.length
        local startAngle = angle - spread * 0.5
        local endAngle = angle + spread * 0.5

        local x1 = telegraph.x + math.cos(startAngle) * length
        local y1 = telegraph.y + math.sin(startAngle) * length
        local x2 = telegraph.x + math.cos(endAngle) * length
        local y2 = telegraph.y + math.sin(endAngle) * length

        love.graphics.setLineWidth(2)
        love.graphics.setColor(base[1], base[2], base[3], alpha)
        love.graphics.line(telegraph.x, telegraph.y, x1, y1)
        love.graphics.line(telegraph.x, telegraph.y, x2, y2)
        love.graphics.arc('line', 'open', telegraph.x, telegraph.y, length, startAngle, endAngle)
      elseif telegraph.type == 'screen' then
        local w, h = love.graphics.getDimensions()
        love.graphics.setColor(base[1], base[2], base[3], alpha * 0.35)
        love.graphics.rectangle('fill', 0, 0, w, h)
      end
    end

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
  end

  function manager:createLineTelegraph(x1, y1, x2, y2, duration, color)
    return addTelegraph(self, {
      type = 'line',
      x = x1,
      y = y1,
      duration = duration or 1,
      elapsed = 0,
      data = {
        x2 = x2,
        y2 = y2,
        pulseSpeed = 8,
        widthMin = 2,
        widthMax = 7
      },
      color = copyColor(color)
    })
  end

  function manager:createAreaTelegraph(x, y, radius, duration, color)
    return addTelegraph(self, {
      type = 'area',
      x = x,
      y = y,
      duration = duration or 1,
      elapsed = 0,
      data = {
        radius = radius,
        fillProgress = 0,
        pulseSpeed = 6,
        expandAmount = 6
      },
      color = copyColor(color)
    })
  end

  function manager:createConeTelegraph(x, y, angle, spread, length, duration, color)
    return addTelegraph(self, {
      type = 'cone',
      x = x,
      y = y,
      duration = duration or 1,
      elapsed = 0,
      data = {
        angle = angle or 0,
        spread = spread or (math.pi / 4),
        length = length or 200
      },
      color = copyColor(color)
    })
  end

  function manager:createScreenTelegraph(duration, color)
    return addTelegraph(self, {
      type = 'screen',
      x = 0,
      y = 0,
      duration = duration or 0.35,
      elapsed = 0,
      data = {
        flashSpeed = 12
      },
      color = copyColor(color)
    })
  end

  return manager
end

return AttackTelegraph
