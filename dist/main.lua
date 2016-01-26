require "player"
require "planet"
require "rocket"
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
  -- love.graphics.setLineStyle("rough")
  world = love.physics.newWorld(0, 0, true)
  world:setCallbacks(beginContact, endContact, preSolve, postSolve)
  scale = 1;

  planet1 = Planet.new(0, 0, 800, 300)
  planet2 = Planet.new(0, -5000, 200, 200)
  planet3 = Planet.new(-1000, -2000, 200, 300)
  planet4 = Planet.new(500, -2000, 50, 200)

  player = Player.new(-820, 0)
  player:setPlanet(planet1)

  rocket1 = Rocket.new(-920, 50)
  rocket2 = Rocket.new(-920, -50)
  rocket3 = Rocket.new(-920, 100)
  rocket4 = Rocket.new(-920, -100)
  rocket5 = Rocket.new(-920, -150)
  rocket6 = Rocket.new(-920, 150)

  table.insert(planet1.objects, player)
  table.insert(planet1.objects, rocket1)
  table.insert(planet1.objects, rocket2)
  table.insert(planet1.objects, rocket3)
  table.insert(planet1.objects, rocket4)
  table.insert(planet1.objects, rocket5)
  table.insert(planet1.objects, rocket6)
  -- table.insert(planet2.objects, player)
  -- table.insert(planet3.objects, player)
  -- table.insert(planet4.objects, player)
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

  planet1:draw()
  planet2:draw()
  planet3:draw()
  planet4:draw()

  player:draw()

  rocket1:draw()
  rocket2:draw()
  rocket3:draw()
  rocket4:draw()
  rocket5:draw()
  rocket6:draw()

  love.graphics.pop()
  love.graphics.pop()

  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
end

function love.update(dt)
  world:update(dt)

  planet1:update(dt)
  planet2:update(dt)
  planet3:update(dt)
  planet4:update(dt)

  player:update(dt)

  rocket1:update(dt)
  rocket2:update(dt)
  rocket3:update(dt)
  rocket4:update(dt)
  rocket5:update(dt)
  rocket6:update(dt)
end

function love.keypressed(key, scancode, isrepeat)
  player:keypressed(key, scancode, isrepeat)
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
