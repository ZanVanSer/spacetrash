local DifficultyScaler = {
    elapsedTime = 0,
    scalingEnabled = true,

    -- Scaling curves (multipliers based on time)
    healthMultiplier = 1.0,
    damageMultiplier = 1.0,
    spawnRateMultiplier = 1.0,
    speedMultiplier = 1.0,
    baseDifficulty = 1.0
}

function DifficultyScaler.init(stageData)
    DifficultyScaler.elapsedTime = 0
    DifficultyScaler.scalingEnabled = true
    
    -- Load stage base difficulty
    DifficultyScaler.baseDifficulty = (stageData and stageData.difficulty) or 1.0
    
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
    DifficultyScaler.healthMultiplier = 1.0 + (DifficultyScaler.elapsedTime / 120) * 0.5
    DifficultyScaler.damageMultiplier = 1.0 + (DifficultyScaler.elapsedTime / 180) * 0.3
    DifficultyScaler.spawnRateMultiplier = 1.0 + (DifficultyScaler.elapsedTime / 150) * 0.4
    
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
