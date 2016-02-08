require "player"
require "planet"
require "rocket"
require "enet"

inputs = {
  left = 'MoveLeft',
  right = 'MoveRight',
  up = 'MoveUp',
  down = 'MoveDown',
  space = 'Jump',
  escape = 'Quit'
}

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
  players = {}

  planet1 = Planet(0, 0, 800, 300)
  localPlayer = Player(-820, 0)
  localPlayer.planet = planet1

  table.insert(objects, localPlayer)
  table.insert(objects, planet1)
  -- table.insert(objects, Planet(500, -2000, 50, 200))
  -- table.insert(objects, Rocket(-920, 50))
  -- table.insert(objects, Rocket(-920, -50))
  -- table.insert(objects, Rocket(-920, 100))
  -- table.insert(objects, Rocket(-920, -100))
  -- table.insert(objects, Rocket(-920, -150))
  -- table.insert(objects, Rocket(-920, 150))
end

function love.load(args)
  height = love.graphics.getHeight()
  width = love.graphics.getWidth()
  tickRate = 60
  currentTime = 0
  ping = 0
  scale = 1
  SERVER = false
  CLIENT = false
  server = nil
  world = love.physics.newWorld(0, 0, true)
  world:setCallbacks(beginContact, endContact, preSolve, postSolve)
  generateEntities()

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
end

function initServer()
  SERVER = true
  host = enet.host_create("localhost:6790")
end

function initClient(address)
  CLIENT = true
  host = enet.host_create()
  server = host:connect(address)
end

function love.update(dt)
  world:update(dt)
  for k, object in pairs(objects) do
    object:update(dt)
  end

  currentTime = currentTime + dt;
  if server then
    ping = server:round_trip_time()
  end
  if currentTime > (1 / tickRate) then
    local event = host:service()
    while event do

      if SERVER then

        if event.type == 'connect' then
          local player = Player(-820, 0)
          player.planet = planet1
          clientID = event.peer:index()
          players[clientID] = player
          table.insert(objects, player)
          local x, y = player.body:getPosition()
          event.peer:send(string.format("%s %d %d", 'up', x, y))

          -- Send the players positions
          local x, y = localPlayer.body:getPosition()
          event.peer:send(string.format("%s %d %d %d", 'pl', 0, x, y))
          for id, player in pairs(players) do
            local x, y = player.body:getPosition()
            if id ~= clientID then
              event.peer:send(string.format("%s %d %d %d", 'pl', id, x, y))
            end
          end
        end
        if event.type == 'receive' then
          cmd, params = event.data:match("^(%S*) (.*)")
          if cmd == 'action' then
            player = players[tonumber(event.peer:index())]
            -- print('action' .. params)
            -- print(player['action' .. params])
            if player and player['action' .. params] then
              print('ACTION !!!')
              player['action' .. params](player, dt)
            end
          end
        end

      end

      if CLIENT then

        if event.type == 'receive' then
          cmd, params = event.data:match("^(%S*) (.*)")
          if cmd == 'up' then -- Update player position

            local x, y = params:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
            localPlayer.body:setPosition(tonumber(x), tonumber(y))

          elseif cmd == "up2" then

            local id, x, y, vX, vY = params:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*)$")
            if tonumber(id) == -1 then
              localPlayer.body:setPosition(tonumber(x), tonumber(y))
            elseif players[id] then
              players[id].body:setPosition(tonumber(x), tonumber(y))
            else
             local newPlayer = Player(tonumber(x), tonumber(y))
             newPlayer.planet = planet1
             players[id] = newPlayer
             table.insert(objects, newPlayer)
            end

          elseif cmd == 'pl' then -- Create a player

            local id, x, y = params:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*)$")
            local newPlayer = Player(tonumber(x), tonumber(y))
            players[id] = newPlayer
            newPlayer.planet = planet1
            table.insert(objects, newPlayer)

          end

        end

      end

      event = host:service()
    end

    if SERVER and host then
      local x, y = localPlayer.body:getPosition()
      local vX, vY = localPlayer.body:getLinearVelocity()
      host:broadcast(string.format("%s %d %d %d %d %d", 'up2', 0, x, y, vX, vY))
      for index,_ in pairs(players) do
        local client = host:get_peer(index)
        if client then
          for id, player in pairs(players) do
            if id == index then
              id = -1
            end
            local x, y = player.body:getPosition()
            local vX, vY = player.body:getLinearVelocity()
            client:send(string.format("%s %d %d %d %d %d", 'up2', id, x, y, vX, vY))
          end
        end
      end
      host:flush()
    end

    currentTime = currentTime - (1 / tickRate)
  end

end

function love.keypressed(key, scancode, isrepeat)
  localPlayer:keypressed(key, scancode, isrepeat)
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
  local x, y = localPlayer.body:getPosition()

  -- move view to screen center
  love.graphics.push()
  love.graphics.translate(width * 0.5, height * 0.5)
  love.graphics.scale(scale, scale)

  -- rotate and move to player angle and position
  love.graphics.push()
  love.graphics.rotate(-localPlayer.body:getAngle() + math.pi)
  love.graphics.translate(-x, -y)

  for k, object in pairs(objects) do
    object:draw()
  end

  love.graphics.pop()
  love.graphics.pop()

  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
  love.graphics.print("Ping: "..tostring(ping), 10, 20)
  if CLIENT then
    love.graphics.print('CLIENT', 10, 30)
  else
    love.graphics.print('SERVER', 10, 30)
  end
end

function beginContact(a, b, coll)
  localPlayer:beginContact(a, b, coll)
end

function endContact(a, b, coll)
  localPlayer:endContact(a, b, coll)
end

function preSolve(a, b, coll)
  localPlayer:preSolve(a, b, coll)
end

function postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
  localPlayer:postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
end
