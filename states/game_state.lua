local Player = require "entities/player"
local Spawner = require "systems/enemy_spawner"
local dl = require "systems/dataloader"
local state = {}

function state:enter()
    local shipData = dl.getShips()[1]
    self.player = Player.new(shipData)
    self.enemySpawner = Spawner.new()
end

local function checkCircleCollision(x1, y1, r1, x2, y2, r2)
    local distSq = (x1 - x2)^2 + (y1 - y2)^2
    return distSq <= (r1 + r2)^2
end

function state:update(dt)
    self.player:update(dt)
    self.enemySpawner:update(dt)

    local bullets = self.player:getBullets()
    local enemies = self.enemySpawner:getEnemies()

    -- Bullet-Enemy Collisions
    for _, b in ipairs(bullets) do
        for _, e in ipairs(enemies) do
            if not b.isDead and not e.isDead then
                -- Bullets are 4x10 rectangles, treating as 4r circle for simplicity or use point
                if checkCircleCollision(b.x, b.y, 4, e.x, e.y, e.radius) then
                    e:takeDamage(b.weaponData.damage)
                    b.isDead = true
                end
            end
        end
    end

    -- Enemy-Player Collisions
    for _, e in ipairs(enemies) do
        if not e.isDead then
            if checkCircleCollision(self.player.x, self.player.y, self.player.radius, e.x, e.y, e.radius) then
                self.player.hp = self.player.hp - 10
                e.isDead = true
            end
        end
    end
end

function state:draw()
    love.graphics.clear(0.05, 0.05, 0.1)
    self.player:draw()
    self.enemySpawner:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. self.player.hp, 10, 10)
end

return state
