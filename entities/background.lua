local dl = require "systems/dataloader"
local BackgroundLayer = require "entities/background_layer"

local Background = {}
Background.__index = Background

function Background.new(backgroundId)
    local self = setmetatable({}, Background)
    
    local backgrounds = dl.getBackgrounds()
    local bgData = nil
    for _, bg in ipairs(backgrounds) do
        if bg.id == backgroundId then
            bgData = bg
            break
        end
    end
    
    self.layers = {}
    if bgData then
        for _, layerData in ipairs(bgData.layers) do
            table.insert(self.layers, BackgroundLayer.new(layerData))
        end
        
        -- Sort layers by zIndex (lowest first)
        table.sort(self.layers, function(a, b)
            return (a.zIndex or 0) < (b.zIndex or 0)
        end)
    end
    
    return self
end

function Background:update(dt)
    for _, layer in ipairs(self.layers) do
        layer:update(dt)
    end
end

function Background:draw()
    for _, layer in ipairs(self.layers) do
        layer:draw()
    end
end

return Background
