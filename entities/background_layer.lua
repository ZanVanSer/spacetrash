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
    elseif self.type == "gradient" then
        self.color1 = layerData.color1 or {1, 1, 1}
        self.color2 = layerData.color2 or {0, 0, 0}
        self.gradHeight = layerData.height or 100
    elseif self.type == "vignette" then
        self.color = layerData.color or {0, 0, 0}
        self.thickness = layerData.thickness or 60
    elseif self.type == "expanding_rings" then
        self.rings = {}
        self.maxRadius = layerData.maxRadius or 300
        self.centerX = (layerData.centerX or 0.5) * self.width
        self.centerY = (layerData.centerY or 0.5) * self.height
        self.color = layerData.color or {1, 1, 1}
        local count = layerData.count or 3
        for i = 1, count do
            table.insert(self.rings, {
                radius = (i - 1) * (self.maxRadius / count)
            })
        end
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
        self.shape = layerData.shape or "circle"
        self.color = layerData.color
        self.rotation = layerData.rotation or false
        
        local count = layerData.count or layerData.spawnCount or 5
        local sizeMin, sizeMax
        if type(layerData.size) == "table" then
            sizeMin = layerData.size[1]
            sizeMax = layerData.size[2]
        elseif type(layerData.size) == "number" then
            sizeMin = layerData.size
            sizeMax = layerData.size
        else
            sizeMin = 10
            sizeMax = 30
        end

        for i = 1, count do
            local prop = {
                x = math.random(0, self.width),
                y = math.random(0, self.height),
                speed = self.speed,
                size = math.random(sizeMin, sizeMax)
            }

            if self.shape == "irregular_polygon" then
                prop.vertices = {}
                local numVertices = math.random(6, 8)
                for j = 1, numVertices do
                    local angle = (j / numVertices) * math.pi * 2
                    local dist = prop.size * (0.7 + math.random() * 0.6)
                    table.insert(prop.vertices, math.cos(angle) * dist)
                    table.insert(prop.vertices, math.sin(angle) * dist)
                end
            elseif self.shape == "rectangle" then
                -- Store window states for buildings
                prop.windowRows = math.random(5, 12)
                prop.windows = {}
                for r = 1, prop.windowRows do
                    prop.windows[r] = {
                        math.random() < 0.6,
                        math.random() < 0.6,
                        math.random() < 0.6
                    }
                end
            elseif self.shape == "flame_tendril" then
                prop.points = {}
                for j = 1, 10 do
                    table.insert(prop.points, (j-1) * 10)
                    table.insert(prop.points, math.sin(j * 0.5) * 10)
                end
            end

            if self.rotation then
                prop.angle = math.random() * math.pi * 2
                prop.rotSpeed = (math.random() - 0.5) * 2
            end

            table.insert(self.props, prop)
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
    elseif self.type == "expanding_rings" then
        for _, ring in ipairs(self.rings) do
            ring.radius = ring.radius + self.speed * dt
            if ring.radius > self.maxRadius then
                ring.radius = 0
            end
        end
    elseif self.type == "prop" then
        for _, prop in ipairs(self.props) do
            prop.y = prop.y + prop.speed * 100 * dt
            if self.rotation and prop.angle then
                prop.angle = prop.angle + (prop.rotSpeed or 1) * dt
            end

            -- Occasional window flicker
            if prop.windows and math.random() < 0.005 then
                local r = math.random(1, #prop.windows)
                local c = math.random(1, 3)
                prop.windows[r][c] = not prop.windows[r][c]
            end

            -- Wave flame tendrils
            if self.shape == "flame_tendril" and prop.points then
                for j = 1, #prop.points/2 do
                    prop.points[j*2] = math.sin(love.timer.getTime() * 5 + j) * 15
                end
            end

            if prop.y > self.height + 100 then
                prop.y = -100
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
    if self.type == "fill" or (self.type == "prop" and self.color) or self.type == "vignette" then
        r, g, b = unpack(self.color)
    end
    love.graphics.setColor(r, g, b, self.opacity)
    
    local drawX = self.offsetX
    local drawY = self.offsetY
    
    if self.type == "fill" then
        love.graphics.rectangle("fill", drawX, drawY, self.width, self.height)
    elseif self.type == "gradient" then
        local steps = self.gradHeight / 5
        local baseY = 0
        if self.position == "bottom" then
            baseY = self.height - self.gradHeight
        elseif self.position == "center" then
            baseY = (self.height - self.gradHeight) / 2
        end

        for i = 0, steps - 1 do
            local t = i / (steps - 1)
            local cr = self.color1[1] * (1 - t) + self.color2[1] * t
            local cg = self.color1[2] * (1 - t) + self.color2[2] * t
            local cb = self.color1[3] * (1 - t) + self.color2[3] * t
            love.graphics.setColor(cr, cg, cb, self.opacity)
            love.graphics.rectangle("fill", drawX, baseY + i * 5 + drawY, self.width, 6)
        end
    elseif self.type == "vignette" then
        local steps = 10
        local stepSize = self.thickness / steps
        for i = 1, steps do
            local alpha = self.opacity * (1 - (i-1)/steps)
            love.graphics.setColor(r, g, b, alpha)
            -- Top
            love.graphics.rectangle("fill", 0, (i-1)*stepSize, self.width, stepSize)
            -- Bottom
            love.graphics.rectangle("fill", 0, self.height - i*stepSize, self.width, stepSize)
            -- Left
            love.graphics.rectangle("fill", (i-1)*stepSize, 0, stepSize, self.height)
            -- Right
            love.graphics.rectangle("fill", self.width - i*stepSize, 0, stepSize, self.height)
        end
    elseif self.type == "expanding_rings" then
        for _, ring in ipairs(self.rings) do
            local ringOpacity = self.opacity * (1 - ring.radius / self.maxRadius)
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], ringOpacity)
            love.graphics.circle("line", self.centerX + drawX, self.centerY + drawY, ring.radius)
        end
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
        local layerR, layerG, layerB = 1, 1, 1
        if not self.color then
            if self.spawnArea == "sky" then
                layerR, layerG, layerB = 0.4, 0.6, 1.0
            elseif self.spawnArea == "ground" then
                layerR, layerG, layerB = 0.5, 0.3, 0.1
            end
            love.graphics.setColor(layerR, layerG, layerB, self.opacity * 0.3)
        else
            layerR, layerG, layerB = unpack(self.color)
            love.graphics.setColor(layerR, layerG, layerB, self.opacity)
        end
        
        for _, prop in ipairs(self.props) do
            local s = prop.size * self.scale
            love.graphics.push()
            love.graphics.translate(prop.x + drawX, prop.y + drawY)
            if self.rotation and prop.angle then
                love.graphics.rotate(prop.angle)
            end
            
            -- Set color for building body
            love.graphics.setColor(layerR, layerG, layerB, self.opacity)

            if self.shape == "irregular_polygon" then
                if prop.vertices then
                    love.graphics.scale(self.scale, self.scale)
                    love.graphics.polygon("fill", prop.vertices)
                end
            elseif self.shape == "circle" then
                love.graphics.circle("fill", 0, 0, s)
            elseif self.shape == "rectangle" then
                local w = s * 0.4
                local h = s
                love.graphics.rectangle("fill", -w/2, -h/2, w, h)

                -- Draw windows
                if prop.windows then
                    local winSize = 4 * self.scale
                    local winPadding = (w - 3 * winSize) / 4
                    local rowHeight = h / (prop.windowRows + 1)
                    
                    for row = 1, #prop.windows do
                        for col = 1, 3 do
                            if prop.windows[row][col] then
                                -- Window color: dim yellow/orange [1, 0.9, 0.5, 0.4]
                                love.graphics.setColor(1, 0.9, 0.5, 0.4 * self.opacity)
                                local wx = -w/2 + winPadding + (col-1) * (winSize + winPadding)
                                local wy = -h/2 + row * rowHeight - winSize/2
                                love.graphics.rectangle("fill", wx, wy, winSize, winSize)
                            end
                        end
                    end
                    -- Reset to layer color for next prop
                    love.graphics.setColor(layerR, layerG, layerB, self.opacity)
                end
            elseif self.shape == "triangle" then
                love.graphics.polygon("fill", 0, -s, -s, s, s, s)
            elseif self.shape == "line" then
                love.graphics.line(-s, 0, s, 0)
            elseif self.shape == "flame_tendril" then
                if prop.points then
                    love.graphics.line(prop.points)
                end
            end
            love.graphics.pop()
        end
    end
end

return BackgroundLayer
