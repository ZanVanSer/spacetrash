local Unlocks = {}

Unlocks.definitions = {
    -- Ship Unlocks
    {
        type = "ship",
        id = "interceptor",
        name = "Interceptor",
        condition = { type = "level", value = 10, description = "Reach Level 10 in any run" }
    },
    {
        type = "ship",
        id = "fortress",
        name = "Fortress",
        condition = { type = "stage", value = "nebula_sector", description = "Complete the Nebula Sector" }
    },
    {
        type = "ship",
        id = "storm_caller",
        name = "Storm Caller",
        condition = { type = "stage", value = "asteroid_belt", description = "Complete the Asteroid Belt" }
    },
    {
        type = "ship",
        id = "swarm_commander",
        name = "Swarm Commander",
        condition = { type = "stage", value = "void_rift", description = "Complete the Void Rift" }
    },

    -- Weapon Unlocks
    {
        type = "weapon",
        id = "railgun",
        name = "Railgun",
        condition = { type = "kills", value = 1000, description = "Destroy 1,000 enemies total" }
    },
    {
        type = "weapon",
        id = "nanite_swarm",
        name = "Nanite Swarm",
        condition = { type = "level", value = 20, description = "Reach Level 20 in any run" }
    },
    {
        type = "weapon",
        id = "photon_whip",
        name = "Photon Whip",
        condition = { type = "boss", value = "void_reaper", description = "Defeat the Void Reaper" }
    },

    -- Passive Unlocks
    {
        type = "passive",
        id = "energy_matrix",
        name = "Energy Matrix",
        condition = { type = "level", value = 5, description = "Reach Level 5" }
    },
    {
        type = "passive",
        id = "dark_matter_core",
        name = "Dark Matter Core",
        condition = { type = "stage", value = "nebula_sector", description = "Reach the Nebula Sector" }
    }
}

function Unlocks.checkUnlocks(saveData, currentRun)
    local newlyUnlocked = {}
    local unlockedSet = {}
    
    -- Create a set of already unlocked IDs for fast lookup
    for _, id in ipairs(saveData.unlockedItems or {}) do
        unlockedSet[id] = true
    end

    for _, def in ipairs(Unlocks.definitions) do
        if not unlockedSet[def.id] then
            local conditionMet = false
            local cond = def.condition

            if cond.type == "level" then
                if (currentRun.maxLevel or 0) >= cond.value then
                    conditionMet = true
                end
            elseif cond.type == "stage" then
                if saveData.completedStages and saveData.completedStages[cond.value] then
                    conditionMet = true
                end
            elseif cond.type == "kills" then
                if (saveData.totalKills or 0) + (currentRun.kills or 0) >= cond.value then
                    conditionMet = true
                end
            elseif cond.type == "boss" then
                if (saveData.defeatedBosses and saveData.defeatedBosses[cond.value]) or 
                   (currentRun.defeatedBosses and currentRun.defeatedBosses[cond.value]) then
                    conditionMet = true
                end
            end

            if conditionMet then
                table.insert(newlyUnlocked, def)
            end
        end
    end

    return newlyUnlocked
end

function Unlocks.getConditionProgress(itemId, saveData)
    for _, def in ipairs(Unlocks.definitions) do
        if def.id == itemId then
            local cond = def.condition
            local current = 0
            local target = cond.value
            local progress = 0
            local ready = false

            if cond.type == "level" then
                current = (saveData.statistics and saveData.statistics.highestLevel) or 0
                progress = math.min(1, current / target)
            elseif cond.type == "stage" then
                if saveData.completedStages and saveData.completedStages[target] then
                    current = 1
                    target = 1
                    progress = 1
                else
                    current = 0
                    target = 1
                    progress = 0
                end
            elseif cond.type == "kills" then
                current = (saveData.statistics and saveData.statistics.totalKills) or 0
                progress = math.min(1, current / target)
            elseif cond.type == "boss" then
                if saveData.statistics and saveData.statistics.bossesDefeated and saveData.statistics.bossesDefeated > 0 then
                    -- This is a bit simplified, ideally we'd track specific bosses
                    current = 1
                    target = 1
                    progress = 1
                else
                    current = 0
                    target = 1
                    progress = 0
                end
            end

            if progress >= 1 then ready = true end
            return {
                description = cond.description,
                current = current,
                target = target,
                progress = progress,
                ready = ready
            }
        end
    end
    return nil
end

function Unlocks.getDefinition(itemId)
    for _, def in ipairs(Unlocks.definitions) do
        if def.id == itemId then return def end
    end
    return nil
end

return Unlocks
