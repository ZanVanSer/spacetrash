local Screen = require('systems.screen')
local BackgroundLayer = {}
BackgroundLayer.__index = BackgroundLayer

function BackgroundLayer.new(layerData)
    local self = setmetatable({}, BackgroundLayer)
    
    self.type = layerData.type or "fill"
    self.zIndex = layerData.zIndex or 0
    self.speed = layerData.speed or 0
    self.scrollDirection = layerData.scrollDirection or "down"
    self.yOffset = 0
    self.width = Screen.getVirtualWidth()
    self.height = Screen.getVirtualHeight()
    
    -- Positioning and Style
    self.position = layerData.position or "fill"
    self.offsetX = layerData.offsetX or 0
    self.offsetY = layerData.offsetY or 0
    self.scale = layerData.scale or 1.0
    self.opacity = layerData.opacity or 1.0
    
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
        else
            -- Generate procedural placeholder
            self.imgWidth = 256
            self.imgHeight = 256
            local canvas = love.graphics.newCanvas(self.imgWidth, self.imgHeight)
            love.graphics.setCanvas(canvas)
            love.graphics.clear(0, 0, 0, 0)
            
            -- Simple nebula-like pattern
            for i = 1, 10 do
                love.graphics.setColor(math.random(), math.random(), math.random(), 0.2)
                love.graphics.circle("fill", math.random(0, self.imgWidth), math.random(0, self.imgHeight), math.random(20, 80))
            end
            
            love.graphics.setCanvas()
            self.image = canvas
        end
    elseif self.type == "prop" then
        self.props = {}
        self.spawnArea = layerData.spawnArea or "full"
        local spawnCount = layerData.spawnCount or 5
        for i = 1, spawnCount do
            table.insert(self.props, {
                x = math.random(0, self.width),
                y = math.random(0, self.height),
                speed = self.speed,
                radius = math.random(10, 30)
            })
        end
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
    elseif self.type == "prop" then
        for _, prop in ipairs(self.props) do
            prop.y = prop.y + prop.speed * 100 * dt
            if prop.y > self.height then
                prop.y = -50
                prop.x = math.random(0, self.width)
            end
        end
    else
        if self.scrollDirection == "down" then
            self.yOffset = self.yOffset + self.speed * 100 * dt
            
            local wrapHeight = self.height
            if self.type == "image" and self.imgHeight then
                wrapHeight = self.imgHeight * self.scale
            end
            
            if self.yOffset >= wrapHeight then
                self.yOffset = self.yOffset - wrapHeight
            end
        end
    end
end

function BackgroundLayer:draw()
    local r, g, b = 1, 1, 1
    if self.type == "fill" then
        r, g, b = unpack(self.color)
    end
    love.graphics.setColor(r, g, b, self.opacity)
    
    local drawX = self.offsetX
    local drawY = self.offsetY
    
    if self.type == "fill" then
        love.graphics.rectangle("fill", drawX, drawY, self.width, self.height)
    elseif self.type == "stars" then
        for _, star in ipairs(self.stars) do
            love.graphics.circle("fill", star.x + drawX, star.y + drawY, star.size)
        end
    elseif self.type == "image" then
        if self.image then
            local scaledHeight = self.imgHeight * self.scale
            local baseY = 0
            if self.position == "top" then
                baseY = 0
            elseif self.position == "bottom" then
                baseY = self.height - scaledHeight
            elseif self.position == "center" then
                baseY = (self.height - scaledHeight) / 2
            end
            
            if self.repeatFlag then
                local y = (self.yOffset % scaledHeight) - scaledHeight
                while y < self.height do
                    love.graphics.draw(self.image, drawX, y + drawY, 0, self.scale, self.scale)
                    y = y + scaledHeight
                end
            else
                love.graphics.draw(self.image, drawX, baseY + self.yOffset + drawY, 0, self.scale, self.scale)
            end
        end
    elseif self.type == "prop" then
        if self.spawnArea == "sky" then
            love.graphics.setColor(0.4, 0.6, 1.0, self.opacity * 0.5)
        elseif self.spawnArea == "ground" then
            love.graphics.setColor(0.5, 0.3, 0.1, self.opacity * 0.5)
        else
            love.graphics.setColor(1, 1, 1, self.opacity * 0.3)
        end
        
        for _, prop in ipairs(self.props) do
            love.graphics.circle("fill", prop.x + drawX, prop.y + drawY, prop.radius * self.scale)
        end
    end
end

return BackgroundLayer
