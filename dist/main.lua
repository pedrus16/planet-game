require "player"
require "planet"
require "rocket"
require "enet"
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

function generateEntities()
  objects = {}

  planet1 = Planet(0, 0, 800, 300)
  player = Player(-820, 0)
  player.planet = planet1

  table.insert(objects, player)
  table.insert(objects, planet1)
  table.insert(objects, Planet(500, -2000, 50, 200))
  table.insert(objects, Rocket(-920, 50))
  table.insert(objects, Rocket(-920, -50))
  table.insert(objects, Rocket(-920, 100))
  table.insert(objects, Rocket(-920, -100))
  table.insert(objects, Rocket(-920, -150))
  table.insert(objects, Rocket(-920, 150))
end

function love.load()
  SERVER = false
  CLIENT = false
  world = love.physics.newWorld(0, 0, true)
  world:setCallbacks(beginContact, endContact, preSolve, postSolve)
  scale = 1

  generateEntities()

end

function initServer()
  SERVER = true
  host = enet.host_create("localhost:6790")
  print('INIT SERVER')
end

function initClient()
  CLIENT = true
  host = enet.host_create()
  server = host:connect("localhost:6790")
  print('INIT CLIENT')
end

height = love.graphics.getHeight()
width = love.graphics.getWidth()
tickRate = 10
currentTime = 0
function love.update(dt)

  if SERVER and currentTime > (1 / tickRate) then
    -- print('server tick')
    local event = host:service()
    if event then
      event.peer:send(event.data)
      if event.type == "receive" then
        print("Got message: ", event.data, event.peer)
        event.peer:send(event.data)
      end
    end
    currentTime = 0
  end
  if CLIENT and currentTime > (1 / tickRate) then
    -- print('client tick')
    local event = host:service()
    if event then
      event.peer:send(currentTime)
      if event.type == "connect" then
        print("Connected to", event.peer)
        event.peer:send("hello world")
      elseif event.type == "receive" then
        print("Got message: ", event.data, event.peer)
        done = true
      end
    end
    currentTime = 0
  end
  currentTime = currentTime + dt;

  world:update(dt)
  for k, object in pairs(objects) do
    object:update(dt)
  end
end

function love.keypressed(key, scancode, isrepeat)
  player:keypressed(key, scancode, isrepeat)
  if key == 'up' and scale <= 16 then
    scale = scale * 2
  end
  if key == 'down' and scale >= 0 then
    scale = scale * 0.5
  end
  if key == 's' then
    initServer()
  end
  if key == 'c' then
    initClient()
  end
end

function love.draw()
  local x, y = player.body:getPosition()

  -- move view to screen center
  love.graphics.push()
  love.graphics.translate(width * 0.5, height * 0.5)
  love.graphics.scale(scale, scale)

  -- rotate and move to player angle and position
  love.graphics.push()
  love.graphics.rotate(player.body:getAngle())
  love.graphics.translate(-x, -y)

  for k, object in pairs(objects) do
    object:draw()
  end

  love.graphics.pop()
  love.graphics.pop()

  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
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
