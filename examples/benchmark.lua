local fangorn = require("fangorn")

local entityLimit = 50000

local position = fangorn.Branch.new("position", {}, function() return {x = 0, y = 0} end)
local velocity = fangorn.Branch.new("velocity", {position}, function() return {x = 0, y = 0} end)
local sprite = fangorn.Branch.new("sprite", {position}, function() return {} end)

local maxX
local maxY
local testSprite

function love.load(args)
    maxX = love.graphics.getWidth()
    maxY = love.graphics.getHeight()
    testSprite = love.graphics.newCanvas(16, 16)
    love.graphics.setCanvas(testSprite)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", 8, 8, 6)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("line", 8, 8, 6)
    love.graphics.circle("line", 10, 8, 1)
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
end

function love.update(dt)
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

	love.window.setTitle(
        " Entities: " .. #position:ents() ..
        " | FPS: " .. love.timer.getFPS() ..
        " | Memory: " .. math.floor(collectgarbage("count")) .. "kb" ..
        " | Delta: " .. love.timer.getDelta())
end

function love.keypressed(key)
	if key == "escape" then love.event.quit() end
end

function love.draw()
	local ents = velocity:ents()
    for i = 1, #ents do
        local e = ents[i]
        local pos = e:get(position)
        if enableDrawing then
            love.graphics.draw(testSprite, pos.x, pos.y)
        end
    end
end