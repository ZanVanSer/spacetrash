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
        unlockedShips = {"vanguard"},
        unlockedWeapons = {"plasma_lance"},
        unlockedPassives = {},
        unlockedStages = {"nebula_sector"}, -- Start with first stage unlocked
        completedStages = {},
        unlockedItems = {"vanguard", "plasma_lance"}, -- Internal set for Unlocks system
        statistics = {
            totalPlayTime = 0,
            totalRuns = 0,
            totalKills = 0,
            bossesDefeated = 0,
            totalDamageDealt = 0,
            highestLevel = 0,
            -- New difficulty stats
            longestRun = 0,
            maxEliteKills = 0,
            maxHealthMultiplier = 1.0,
            maxDamageMultiplier = 1.0,
            maxThreatLevel = "LOW"
        }
    }
end

function SaveManager.deleteSave(slot)
    return love.filesystem.remove("save" .. slot .. ".json")
end

return SaveManager
