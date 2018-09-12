
local fangorn = require("fangorn")

local entityLimit = 50000

local maxX
local maxY
local testSprite
local forest

function love.load(args)
  maxX = love.graphics.getWidth()
  maxY = love.graphics.getHeight()
  testSprite = love.graphics.newCanvas(16, 16)
  love.graphics.setCanvas(testSprite)
  love.graphics.setColor(1,1,1,1)
  love.graphics.circle("fill",8,8,6)
  love.graphics.setColor(0,0,0,1)
  love.graphics.circle("line",8,8,6)
  love.graphics.circle("line",10,8,1)
  love.graphics.setCanvas()
  love.graphics.setColor(1,1,1,1)

  forest = fangorn.forest.new()
  forest:definebranch("pos", {}, function() return {x = 0, y = 0} end)
  forest:definebranch("vel", {"pos"}, function() return {x = 0, y = 0} end)
  forest:definebranch("spr", {"pos"}, function() return true end)
end

function love.update(dt)
  for _ = 1, 100 do
    if entityLimit and #forest.ents >= entityLimit then
      break
    end
    local e = forest:growent()
    forest:growbranch(e, "vel", {x = love.math.random(10, 30), y = love.math.random(10, 30)})
    forest:growbranch(e, "spr")
  end

  forest:each("vel", function(e)
    e.pos.x = e.pos.x + e.vel.x * dt
    e.pos.y = e.pos.y + e.vel.y * dt

    if e.pos.x > maxX or e.pos.y > maxY then
      if love.math.random() < 0.4 then
        forest:killent(e)
      else
        e.pos.x = 0
        e.pos.y = 0
      end
    end
  end)

	love.window.setTitle(" Entities: " .. #forest.ents
.. " | FPS: " .. love.timer.getFPS()
.. " | Memory: " .. math.floor(collectgarbage 'count') .. 'kb'
.. " | Delta: " .. love.timer.getDelta())
end

function love.keypressed(key)
	if key == 'escape' then love.event.quit() end
end

function love.draw()
  forest:each("spr", function(e)
    if not enableDrawing then
      love.graphics.draw(testSprite, e.pos.x, e.pos.y)
    end
  end)
end

