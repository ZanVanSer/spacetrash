local json = require "systems/json"

local SaveManager = {}

function SaveManager.saveExists(slot)
    local info = love.filesystem.getInfo("save" .. slot .. ".json")
    return info ~= nil
end

function SaveManager.loadSave(slot)
    local filename = "save" .. slot .. ".json"
    if not SaveManager.saveExists(slot) then
        return nil
    end
    
    local contents, _ = love.filesystem.read(filename)
    if contents then
        return json.decode(contents)
    end
    return nil
end

function SaveManager.createSave(slot, data)
    local filename = "save" .. slot .. ".json"
    local encoded = json.encode(data)
    local success, _ = love.filesystem.write(filename, encoded)
    return success
end

function SaveManager.getDefaultSave()
    return {
        level = 1,
        xp = 0,
        unlockedShips = {"vanguard"},
        unlockedWeapons = {"basic_laser"},
        completedStages = {},
        totalPlayTime = 0
    }
end

function SaveManager.deleteSave(slot)
    return love.filesystem.remove("save" .. slot .. ".json")
end

return SaveManager
