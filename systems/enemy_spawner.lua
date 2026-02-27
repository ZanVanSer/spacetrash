local Enemy = require "entities/enemy"
local dl = require "systems/dataloader"
local Screen = require('systems.screen')

local Spawner = {}
Spawner.__index = Spawner

function Spawner.new(enemyList, spawnInterval)
    local self = setmetatable({
        enemies = {},
        spawnTimer = 0,
        spawnInterval = spawnInterval or 2,
        enemyList = enemyList or {"drone"},
        active = true
    }, Spawner)
    
    -- Create lookup for enemy data
    local allEnemies = dl.getEnemies()
    local lookup = dl.createLookup(allEnemies, "id")
    self.enemyDataList = {}
    for _, id in ipairs(self.enemyList) do
        if lookup[id] then
            table.insert(self.enemyDataList, lookup[id])
        end
    end
    
    return self
end

function Spawner:update(dt, playerX, playerY)
    if self.active then
        self.spawnTimer = self.spawnTimer + dt
        if self.spawnTimer >= self.spawnInterval then
            if #self.enemyDataList > 0 then
                local data = self.enemyDataList[love.math.random(#self.enemyDataList)]
                -- Spawn within game viewport (220 to 800) with buffer
                local x = love.math.random(240, Screen.getVirtualWidth() - 20)
                table.insert(self.enemies, Enemy.new(x, -20, data))
            end
            self.spawnTimer = 0
        end
    end
    
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        if e then
            e:update(dt, playerX, playerY)
            if e.isDead then table.remove(self.enemies, i) end
        end
    end
end

function Spawner:draw()
    for _, e in ipairs(self.enemies) do e:draw() end
end

function Spawner:getEnemies() return self.enemies end
function Spawner:stop() self.active = false end

return Spawner
