local DifficultyScaler = {
    elapsedTime = 0,
    scalingEnabled = true,

    -- Scaling multipliers
    healthMultiplier = 1.0,
    damageMultiplier = 1.0,
    spawnRateMultiplier = 1.0,
    speedMultiplier = 1.0,
    baseDifficulty = 1.0,
    
    -- Per-stage scaling parameters
    healthCurve = 2.0,
    damageCurve = 0.5,
    spawnCurve = 0.6,
    eliteChanceStart = 180,
    eliteChanceMax = 0.25,

    -- Event System
    eventMilestones = {
        { id = "reinforcements", time = 180, triggered = false },
        { id = "eliteSquadron", time = 300, triggered = false },
        { id = "maxAlert", time = 420, triggered = false },
        { id = "overwhelming", time = 600, triggered = false }
    },
    pendingEvents = {},
    alertTimer = 0
}

function DifficultyScaler.init(stageData)
    DifficultyScaler.elapsedTime = 0
    DifficultyScaler.scalingEnabled = true
    DifficultyScaler.pendingEvents = {}
    DifficultyScaler.alertTimer = 0
    
    -- Load stage base difficulty
    DifficultyScaler.baseDifficulty = (stageData and stageData.difficulty) or 1.0
    
    -- Reset milestones
    for _, e in ipairs(DifficultyScaler.eventMilestones) do
        e.triggered = false
    end

    -- Load per-stage scaling parameters if available
    if stageData and stageData.scaling then
        local s = stageData.scaling
        DifficultyScaler.healthCurve = s.healthCurve or 2.0
        DifficultyScaler.damageCurve = s.damageCurve or 0.5
        DifficultyScaler.spawnCurve = s.spawnCurve or 0.6
        DifficultyScaler.eliteChanceStart = s.eliteChanceStart or 180
        DifficultyScaler.eliteChanceMax = s.eliteChanceMax or 0.25
        
        -- Override milestone times if stage defines them
        if s.eliteChanceStart then
            -- Update elite squadron milestone if it exists
            for _, e in ipairs(DifficultyScaler.eventMilestones) do
                if e.id == "eliteSquadron" then e.time = s.eliteChanceStart + 60 end
                if e.id == "reinforcements" then e.time = s.eliteChanceStart end
            end
        end
    else
        DifficultyScaler.healthCurve = 2.0
        DifficultyScaler.damageCurve = 0.5
        DifficultyScaler.spawnCurve = 0.6
        DifficultyScaler.eliteChanceStart = 180
        DifficultyScaler.eliteChanceMax = 0.25
    end
    
    -- Reset all multipliers to 1.0
    DifficultyScaler.healthMultiplier = 1.0
    DifficultyScaler.damageMultiplier = 1.0
    DifficultyScaler.spawnRateMultiplier = 1.0
    DifficultyScaler.speedMultiplier = 1.0
end

function DifficultyScaler.triggerEvent(eventType)
    local events = {
        reinforcements = {
            type = "reinforcements",
            name = "Enemy Reinforcements!",
            shake = 10,
            flash = true,
            spawnBurst = 12
        },
        eliteSquadron = {
            type = "eliteSquadron",
            name = "Elite Squadron Detected!",
            eliteCount = 4
        },
        maxAlert = {
            type = "maxAlert",
            name = "Maximum Alert!",
            duration = 30,
            spawnMultiplier = 2.0
        },
        overwhelming = {
            type = "overwhelming",
            name = "Overwhelming Force!",
            spawnMultiplier = 1.5
        }
    }
    return events[eventType]
end

function DifficultyScaler.getPendingEvents()
    local events = {}
    for i, e in ipairs(DifficultyScaler.pendingEvents) do
        events[i] = e
    end
    DifficultyScaler.pendingEvents = {}
    return events
end

function DifficultyScaler.update(dt)
    if not DifficultyScaler.scalingEnabled then return end
    
    DifficultyScaler.elapsedTime = DifficultyScaler.elapsedTime + dt
    
    -- Check for milestone events
    for _, e in ipairs(DifficultyScaler.eventMilestones) do
        if not e.triggered and DifficultyScaler.elapsedTime >= e.time then
            e.triggered = true
            local eventData = DifficultyScaler.triggerEvent(e.id)
            table.insert(DifficultyScaler.pendingEvents, eventData)
            
            if e.id == "maxAlert" then
                DifficultyScaler.alertTimer = eventData.duration
            end
        end
    end

    -- Event-based spawn multipliers
    local eventSpawnMult = 1.0
    
    -- Maximum Alert logic (Temporary boost)
    if DifficultyScaler.alertTimer > 0 then
        DifficultyScaler.alertTimer = DifficultyScaler.alertTimer - dt
        eventSpawnMult = eventSpawnMult * 2.0
    end

    -- Overwhelming Force logic (Permanent boost)
    if DifficultyScaler.elapsedTime >= 600 then
        eventSpawnMult = eventSpawnMult * 1.5
    end

    -- Calculate final multipliers based on elapsed time
    DifficultyScaler.healthMultiplier = 1.0 + (DifficultyScaler.elapsedTime / 120) * DifficultyScaler.healthCurve
    DifficultyScaler.damageMultiplier = 1.0 + (DifficultyScaler.elapsedTime / 180) * DifficultyScaler.damageCurve
    DifficultyScaler.spawnRateMultiplier = (1.0 + (DifficultyScaler.elapsedTime / 150) * DifficultyScaler.spawnCurve) * eventSpawnMult
    
    DifficultyScaler.speedMultiplier = 1.0 + (DifficultyScaler.elapsedTime / 300) * 0.2
end

function DifficultyScaler.getHealthMultiplier()
    return DifficultyScaler.healthMultiplier
end

function DifficultyScaler.getDamageMultiplier()
    return DifficultyScaler.damageMultiplier
end

function DifficultyScaler.getSpawnRateMultiplier()
    return DifficultyScaler.spawnRateMultiplier
end

return DifficultyScaler
