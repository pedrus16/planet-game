require "player"
require "planet"
-- vector = require "lib/vector"

function colorLight()
  return 252, 245, 184
end

function colorLightGreen()
  return 180, 205, 147
end

function colorDarkGreen()
  return 66, 122, 91
end

function colorDark()
  return 64, 63, 63
end

function love.load()
  love.graphics.setLineStyle("rough")
  world = love.physics.newWorld(0, 0, true)
  world:setCallbacks(beginContact, endContact, preSolve, postSolve)
  scale = 1;
  planet1 = Planet.new(0, 0, 500, 300)
  planet2 = Planet.new(0, -10000, 200, 200)
  player = Player.new(0, -530)
  table.insert(planet1.objects, player)
  table.insert(planet2.objects, player)
end

height = love.graphics.getHeight()
width = love.graphics.getWidth()

function love.draw()
  local x, y = player.body:getPosition()

  -- move view to screen center
  love.graphics.push()
  love.graphics.translate(width * 0.5, height * 0.5)
  love.graphics.scale(scale, scale)

  -- rotate and move to player angle and position
  love.graphics.push()
  love.graphics.rotate(-player.body:getAngle() + math.pi)
  love.graphics.translate(-x, -y)

  player:draw()
  planet1:draw()
  planet2:draw()

  love.graphics.pop()
  love.graphics.pop()

  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
end

function love.update(dt)
  world:update(dt)
  planet1:update(dt)
  planet2:update(dt)
  player:update(dt)
end

function love.keypressed(key, scancode, isrepeat)
  local planetX, planetY = player.planet.body:getPosition()
  local playerX, playerY = player.body:getPosition()
  local px, py = vector.normalize(planetX - playerX, planetY - playerY)
  if key == "space" then
    player.body:applyLinearImpulse(-px * 70, -py * 70)
  end
  if key == 'up' and scale <= 16 then
    scale = scale * 2
  end
  if key == 'down' and scale >= 0 then
    scale = scale * 0.5
  end
end


function beginContact(a, b, coll)
  player:beginContact(a, b, coll)
end

function endContact(a, b, coll)
  player:endContact(a, b, coll)
end

function preSolve(a, b, coll)
  player:preSolve(a, b, coll)
end

function postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
  player:postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
end
