local Menu = {}
Menu.__index = Menu

function Menu.new(options)
    local self = setmetatable({}, Menu)
    self.options = options
    self.selectedIndex = 1
    return self
end

function Menu:keypressed(key)
    if key == "up" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.options
        end
    elseif key == "down" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.options then
            self.selectedIndex = 1
        end
    elseif key == "z" then
        return self.selectedIndex
    elseif key == "x" then
        return -1
    end
end

function Menu:draw(x, y)
    local font = love.graphics.getFont()
    local lineHeight = font:getHeight() + 20
    local totalHeight = #self.options * lineHeight
    local startY = y - totalHeight / 2

    for i, option in ipairs(self.options) do
        local text = option
        local isSelected = (i == self.selectedIndex)
        local optionY = startY + (i - 1) * lineHeight
        
        if isSelected then
            text = "> " .. option .. " <"
            love.graphics.setColor(1, 1, 0) -- Yellow highlight
            
            -- Optional: Selection box
            local textWidth = font:getWidth(text)
            love.graphics.setColor(1, 1, 0, 0.2)
            love.graphics.rectangle("fill", x - textWidth/2 - 10, optionY - 5, textWidth + 20, font:getHeight() + 10)
            
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(1, 1, 1)
        end
        
        -- Center text at x
        local textWidth = font:getWidth(text)
        love.graphics.print(text, x - textWidth / 2, optionY)
    end
end

return Menu
