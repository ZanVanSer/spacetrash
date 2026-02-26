return {
    update = function(enemy, dt)
        -- Move down
        enemy.y = enemy.y + enemy.speed * dt
        -- Sine wave movement on x-axis
        enemy.x = enemy.x + math.sin(enemy.y * 0.02) * 100 * dt
    end
}
