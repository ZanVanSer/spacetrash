local DifficultyScaler = {
    elapsedTime = 0,
    scalingEnabled = true,

    -- Scaling curves (multipliers based on time)
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
    eliteChanceMax = 0.25
}

function DifficultyScaler.init(stageData)
    DifficultyScaler.elapsedTime = 0
    DifficultyScaler.scalingEnabled = true
    
    -- Load stage base difficulty
    DifficultyScaler.baseDifficulty = (stageData and stageData.difficulty) or 1.0
    
    -- Load per-stage scaling parameters if available
    if stageData and stageData.scaling then
        local s = stageData.scaling
        DifficultyScaler.healthCurve = s.healthCurve or 2.0
        DifficultyScaler.damageCurve = s.damageCurve or 0.5
        DifficultyScaler.spawnCurve = s.spawnCurve or 0.6
        DifficultyScaler.eliteChanceStart = s.eliteChanceStart or 180
        DifficultyScaler.eliteChanceMax = s.eliteChanceMax or 0.25
    else
        -- Fallback to defaults
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

function DifficultyScaler.update(dt)
    if not DifficultyScaler.scalingEnabled then return end
    
    DifficultyScaler.elapsedTime = DifficultyScaler.elapsedTime + dt
    
    -- Calculate multipliers based on elapsed time (gradual increase)
    -- Using the curve values loaded from stage data
    DifficultyScaler.healthMultiplier = 1.0 + (DifficultyScaler.elapsedTime / 120) * DifficultyScaler.healthCurve
    DifficultyScaler.damageMultiplier = 1.0 + (DifficultyScaler.elapsedTime / 180) * DifficultyScaler.damageCurve
    DifficultyScaler.spawnRateMultiplier = 1.0 + (DifficultyScaler.elapsedTime / 150) * DifficultyScaler.spawnCurve
    
    -- Speed scaling (optional, but keep it in the table as requested)
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
