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
  -- player2 = Player(0, 0)
  -- player2.planet = planet1

  table.insert(objects, player)
  table.insert(objects, player2)
  table.insert(objects, planet1)
  table.insert(objects, Planet(500, -2000, 50, 200))
  table.insert(objects, Rocket(-920, 50))
  table.insert(objects, Rocket(-920, -50))
  table.insert(objects, Rocket(-920, 100))
  table.insert(objects, Rocket(-920, -100))
  table.insert(objects, Rocket(-920, -150))
  table.insert(objects, Rocket(-920, 150))
end

function love.load(args)
  height = love.graphics.getHeight()
  width = love.graphics.getWidth()
  tickRate = 10
  currentTime = 0
  ping = 0
  ping2 = 0
  SERVER = false
  CLIENT = false
  for k, arg in pairs(args) do
    if arg == '--connect' then
      if args[k + 1] then
        initClient(args[k + 1])
      end
    end
  end
  if not CLIENT then
    initServer()
  end
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

function initClient(address)
  CLIENT = true
  host = enet.host_create()
  server = host:connect(address)
  ping = server:round_trip_time()
  print('INIT CLIENT')
end

function love.update(dt)

  local pX, pY = player.body:getPosition();
  local vX, vY = player.body:getLinearVelocity();
  local aV = player.body:getAngularVelocity();
  local a = player.body:getAngle();

  currentTime = currentTime + dt;
  -- print(currentTime .. ' ' .. (1 / tickRate))
  if server then
    ping = server:round_trip_time()
  end
  if currentTime > (0 / tickRate) then
    local event = host:service()
    while event do
      if SERVER then
        if event.type == 'connect' then
          -- Create a player and send its position to the client
          local pl = Player(-820, 0)
          pl.planet = planet1
          table.insert(objects, pl)
          local x, y = pl.body:getPosition()
          event.peer:send(string.format("%s %s %s", 'up', x, y))

          -- Send first player position
          local x, y = player.body:getPosition()
          event.peer:send(string.format("%s %s %s", 'pl', x, y))
        end
      end
      if CLIENT then
        if event.type == 'receive' then
          cmd, params = event.data:match("^(%S*) (.*)")
          print(event.data)
          if cmd == 'up' then -- Update player position
            local x, y = params:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
            player.body:setPosition(tonumber(x), tonumber(y))
          elseif cmd == "up2" then
            print(params)
            local x, y, vX, vY = params:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*)$")
            player2.body:setPosition(tonumber(x), tonumber(y))
          elseif cmd == 'pl' then -- Create a player
            local x, y = params:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
            player2 = Player(tonumber(x), tonumber(y))
            player2.planet = planet1
            table.insert(objects, player2)
          end
        end
      end
      event = host:service()
    end
    if SERVER and host then
      local x, y = player.body:getPosition()
      local vX, vY = player.body:getLinearVelocity()
      host:broadcast(string.format("%s %d %d %d %d", 'up2', x, y, vX, vY))
    end
    currentTime = currentTime - (0 / tickRate)
    -- print(currentTime)
  end

  -- if SERVER and currentTime > (1 / tickRate) then
  --
  --   local event = host:service()
  --   if event then
  --     ping = event.peer:round_trip_time()
  --     if event.type == "connect" then
  --       print("Connected to", event.peer)
  --     end
  --     if event.type == "receive" then
  --       -- print("Got message: ", event.data, event.peer)
  --       -- event.peer:send(event.data)
  --       local data = {}
  --       for i in string.gmatch(event.data, "%S+") do
  --         table.insert(data, i)
  --       end
  --       if data[1] == 'up' then
  --         player2.body:setPosition(tonumber(data[2]), tonumber(data[3]))
  --         player2.body:setLinearVelocity(tonumber(data[4]), tonumber(data[5]))
  --         player2.body:setAngularVelocity(tonumber(data[6]))
  --         player2.body:setAngle(tonumber(data[7]))
  --       end
  --     end
  --     event.peer:ping()
  --     host:broadcast(table.concat({ 'up', pX, pY, vX, vY, aV, a }, ' '), 0)
  --     host:flush()
  --   end
  --   currentTime = 0
  -- end
  -- if CLIENT and currentTime > (1 / tickRate) then
  --   local event = host:service()
  --   if event then
  --     ping = event.peer:round_trip_time()
  --     if event.type == "connect" then
  --       print("Connected to", event.peer)
  --       -- event.peer:send("hello world")
  --     elseif event.type == "receive" then
  --       -- print("Got message: ", event.data, event.peer)
  --       local data = {}
  --       for i in string.gmatch(event.data, "%S+") do
  --         table.insert(data, i)
  --       end
  --       if data[1] == 'up' then
  --         player2.body:setPosition(tonumber(data[2]), tonumber(data[3]))
  --         player2.body:setLinearVelocity(tonumber(data[4]), tonumber(data[5]))
  --         player2.body:setAngularVelocity(tonumber(data[6]))
  --         player2.body:setAngle(tonumber(data[7]))
  --       end
  --     end
  --     event.peer:ping()
  --     event.peer:send(table.concat({ 'up', pX, pY, vX, vY, aV, a }, ' '), 0)
  --     host:flush()
  --   end
  --   currentTime = 0
  -- end
  -- currentTime = currentTime + dt;

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
  if key == 'escape' then
    love.event.quit()
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
  love.graphics.rotate(-player.body:getAngle() + math.pi)
  love.graphics.translate(-x, -y)

  for k, object in pairs(objects) do
    object:draw()
  end

  love.graphics.pop()
  love.graphics.pop()

  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
  love.graphics.print("Ping: "..tostring(ping), 10, 20)
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
