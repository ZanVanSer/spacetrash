local BackgroundLayer = {}
BackgroundLayer.__index = BackgroundLayer

function BackgroundLayer.new(layerData)
    local self = setmetatable({}, BackgroundLayer)
    
    self.type = layerData.type or "fill"
    self.zIndex = layerData.zIndex or 0
    self.speed = layerData.speed or 0
    self.scrollDirection = layerData.scrollDirection or "down"
    self.yOffset = 0
    self.width = 800
    self.height = 600
    
    if self.type == "fill" then
        self.color = layerData.color or {0, 0, 0}
    elseif self.type == "stars" then
        self.stars = {}
        local count = layerData.count or 100
        for i = 1, count do
            table.insert(self.stars, {
                x = math.random(0, self.width),
                y = math.random(0, self.height),
                size = math.random(1, 2)
            })
        end
    elseif self.type == "image" then
        -- Handle later
    elseif self.type == "prop" then
        -- Handle later
    end
    
    return self
end

function BackgroundLayer:update(dt)
    if self.type == "stars" then
        for _, star in ipairs(self.stars) do
            star.y = star.y + self.speed * 100 * dt
            if star.y > self.height then
                star.y = -10
                star.x = math.random(0, self.width)
            end
        end
    elseif self.scrollDirection == "down" then
        self.yOffset = self.yOffset + self.speed * 100 * dt
        if self.yOffset >= self.height then
            self.yOffset = self.yOffset - self.height
        end
    end
end

function BackgroundLayer:draw()
    if self.type == "fill" then
        love.graphics.setColor(unpack(self.color))
        love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    elseif self.type == "stars" then
        love.graphics.setColor(1, 1, 1)
        for _, star in ipairs(self.stars) do
            love.graphics.circle("fill", star.x, star.y, star.size)
        end
    elseif self.type == "image" then
        -- Placeholder for image drawing
    elseif self.type == "prop" then
        -- Placeholder for prop drawing
    end
end

return BackgroundLayer
