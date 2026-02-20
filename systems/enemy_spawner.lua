local Enemy = require "entities/enemy"
local dl = require "systems/dataloader"

local Spawner = {}
Spawner.__index = Spawner

function Spawner.new()
    local self = setmetatable({
        enemies = {},
        spawnTimer = 0,
        spawnInterval = 2,
        active = true
    }, Spawner)
    return self
end

function Spawner:update(dt)
    if not self.active then return end
    
    self.spawnTimer = self.spawnTimer + dt
    if self.spawnTimer >= self.spawnInterval then
        local enemyTypes = dl.getEnemies()
        if #enemyTypes > 0 then
            local data = enemyTypes[love.math.random(#enemyTypes)]
            local x = love.math.random(20, love.graphics.getWidth() - 20)
            table.insert(self.enemies, Enemy.new(x, -20, data))
        end
        self.spawnTimer = 0
    end
    
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        e:update(dt)
        if e.isDead then table.remove(self.enemies, i) end
    end
end

function Spawner:draw()
    for _, e in ipairs(self.enemies) do e:draw() end
end

function Spawner:getEnemies() return self.enemies end
function Spawner:stop() self.active = false end

return Spawner
