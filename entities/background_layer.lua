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
        self.imagePath = layerData.imagePath
        self.repeatFlag = layerData["repeat"] or false
        if self.imagePath and love.filesystem.getInfo(self.imagePath) then
            self.image = love.graphics.newImage(self.imagePath)
            self.imgWidth = self.image:getWidth()
            self.imgHeight = self.image:getHeight()
        end
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
    else
        if self.scrollDirection == "down" then
            self.yOffset = self.yOffset + self.speed * 100 * dt
            
            local wrapHeight = self.height
            if self.type == "image" and self.imgHeight then
                wrapHeight = self.imgHeight
            end
            
            if self.yOffset >= wrapHeight then
                self.yOffset = self.yOffset - wrapHeight
            end
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
        if self.image then
            love.graphics.setColor(1, 1, 1)
            if self.repeatFlag then
                local y = self.yOffset - self.imgHeight
                while y < self.height do
                    love.graphics.draw(self.image, 0, y)
                    y = y + self.imgHeight
                end
            else
                love.graphics.draw(self.image, 0, self.yOffset)
            end
        end
    elseif self.type == "prop" then
        -- Placeholder for prop drawing
    end
end

return BackgroundLayer
