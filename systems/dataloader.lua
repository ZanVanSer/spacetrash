local json = require "systems/json"
local dl = { cache = {} }

function dl.loadJSON(filename)
    if dl.cache[filename] then return dl.cache[filename] end
    local path = "data/" .. filename .. ".json"
    local info = love.filesystem.getInfo(path)
    if not info then return {} end
    
    local content, size = love.filesystem.read(path)
    if not content then return {} end
    
    local data = json.decode(content)
    dl.cache[filename] = data
    return data
end

function dl.createLookup(dataArray, keyField)
    local lookup = {}
    for _, item in ipairs(dataArray) do
        if item[keyField] then
            lookup[item[keyField]] = item
        end
    end
    return lookup
end

local function createGetter(name)
    dl["get" .. name:gsub("^%l", string.upper)] = function()
        return dl.loadJSON(name)
    end
end

local types = {"weapons", "ships", "enemies", "bosses", "stages", "upgrades", "backgrounds"}
for _, t in ipairs(types) do createGetter(t) end

return dl
