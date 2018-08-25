local fangorn = require("fangorn")

local entityLimit = 50000

local position = fangorn.Branch.new("position", {}, function() return {x = 0, y = 0} end)
local velocity = fangorn.Branch.new("velocity", {position}, function() return {x = 0, y = 0} end)
local sprite = fangorn.Branch.new("sprite", {position}, function() return {} end)

local maxX
local maxY

function love.load(args)
    maxX = love.graphics.getWidth()
    maxY = love.graphics.getHeight()
end

return {
    update = function(dt)
        for _ = 1, 100 do
            if entityLimit and #position:ents() >= entityLimit then
                break
            end
            local e = fangorn.Ent.new()
            e:grow(velocity, {x = love.math.random(10, 30), y = love.math.random(10, 30)})
            e:grow(sprite)
        end

        local ents = velocity:ents()
        for i = 1, #ents do
            local e = ents[i]
            local pos = e:get(position)
            local vel = e:get(velocity)
            pos.x = pos.x + vel.x * dt
            pos.y = pos.y + vel.y * dt

            if pos.x > maxX or pos.y > maxY then
                if love.math.random() < 0.4 then
                    e:kill()
                else
                    pos.x = 0
                    pos.y = 0
                end
            end
        end
    end,

    draw = function()
        local ents = velocity:ents()
        for i = 1, #ents do
            local e = ents[i]
            local pos = e:get(position)
            if enableDrawing then
                love.graphics.draw(testSprite, pos.x, pos.y)
            end
        end
    end,

    getNumEntities = function() return #position:ents() end,
}