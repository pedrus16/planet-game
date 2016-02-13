require "player"
require "planet"
require "rocket"
require "enet"
suit = require "lib.suit"

binding = {
  left = 'move_left',
  right = 'move_right',
  up = 'move_up',
  down = 'move_down',
  space = 'jump',
  escape = 'quit'
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
  localPlayer = Player(0, -820)
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
  upload = 0
  download = 0
  scale = 1
  SERVER = false
  CLIENT = false
  server = nil
  backgroundSprite = love.graphics.newImage("resources/space2.png")
  backgroundSprite:setFilter("nearest")
  backgroundSprite:setWrap('repeat', 'repeat')
  background = love.graphics.newQuad(0, 0, width * 2 + 256, height * 2 + 256, backgroundSprite:getDimensions())

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
end

function initServer()
  SERVER = true
  host = enet.host_create("*:6790")
  table.insert(objects, Rocket(50, -820))
end

function initClient(address)
  CLIENT = true
  host = enet.host_create()
  server = host:connect(address)
end

startTime = love.timer.getTime()
timer = 0
gameStarted = false
addressInput = { text = 'localhost' }
menu = false
function love.update(dt)

  if not gameStarted then

    if not menu then
      if suit.Button("Jouer", (width - 100) * 0.5, height * 0.5, 100, 30).hit then
        initServer()
        gameStarted = true
      end
      if suit.Button("Se connecter", (width - 100) * 0.5, (height * 0.5) + 35, 100, 30).hit then
        menu = true
      end
    end

    if menu then
      suit.Input(addressInput, (width - 100) * 0.5, height * 0.5, 100, 30)
      if suit.Button("Effacer", (width - 100) * 0.5 + 105, height * 0.5, 50, 30).hit then
        addressInput.text = ''
      end
      if suit.Button("Coller", (width - 100) * 0.5 + 160, height * 0.5, 50, 30).hit then
        addressInput.text = love.system.getClipboardText()
      end
      if suit.Button("Go", (width - 100) * 0.5, (height * 0.5) + 35, 100, 30).hit then
        initClient(addressInput.text .. ':6790')
        gameStarted = true
      end
      if suit.Button("Retour", (width - 100) * 0.5, (height * 0.5) + 70, 100, 30).hit then
        menu = false
      end
    end

  end

  world:update(dt)
  for k, object in pairs(objects) do
    object:update(dt)
  end

  currentTime = currentTime + dt
  if server then
    ping = server:round_trip_time()
  end
  timer = timer + dt
  if host and timer > 0.5 then
    local totalTime = love.timer.getTime() - startTime
    upload = host:total_sent_data() / totalTime
    download = host:total_received_data() / totalTime
    timer = timer - 0.5
  end
  if host and currentTime > (1 / tickRate) then
    local event = host:service()
    while event do

      if SERVER then

        if event.type == 'connect' then
          local player = Player(0, -900)
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
            if player and player.inputs[params] ~= nil then
              local functionName = Player.actions[params]
              if functionName ~= nil then
                player[functionName](player, dt)
              end
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
      if localPlayer.body:isAwake() then
        local x, y = localPlayer.body:getPosition()
        local vX, vY = localPlayer.body:getLinearVelocity()
        host:broadcast(string.format("%s %d %d %d %d %d", 'up2', 0, x, y, vX, vY))
      end
      for index,_ in pairs(players) do
        local client = host:get_peer(index)
        if client then
          for id, player in pairs(players) do
            if id == index then
              id = -1
            end
            if player.body:isAwake() then
              local x, y = player.body:getPosition()
              local vX, vY = player.body:getLinearVelocity()
              client:send(string.format("%s %d %d %d %d %d", 'up2', id, x, y, vX, vY))
            end
          end
        end
      end
      host:flush()
    end

    currentTime = currentTime - (1 / tickRate)
  end
end

function love.keypressed(key, scancode, isrepeat)
  suit.keypressed(key)
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

function love.keyreleased(key, scancode, isrepeat)
  localPlayer:keyreleased(key, scancode, isrepeat)
end

function love.textinput(t)
  suit.textinput(t)
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


  -- TEST
  love.graphics.push()
  -- love.graphics.translate(localPlayer.body:getPosition())
  love.graphics.push()
  love.graphics.translate(-localPlayer.body:getX() % 256, -localPlayer.body:getY() % 256)
  love.graphics.push()
  love.graphics.draw(backgroundSprite, background, -width, -height)
  love.graphics.pop()
  love.graphics.pop()
  love.graphics.pop()
  -- /TEST


  love.graphics.translate(-x, -y)


  for k, object in pairs(objects) do
    object:draw()
  end

  love.graphics.pop()
  love.graphics.pop()


  suit.draw()

  if CLIENT then
    love.graphics.print('CLIENT', 10, 10)
  else
    love.graphics.print('SERVER', 10, 10)
  end
  love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 10, 24)
  love.graphics.print("Ping: ".. tostring(ping) .. 'ms', 10, 38)
  love.graphics.print(string.format('Upload: %g kb/s', tostring(upload / 1000)), 10, 52)
  love.graphics.print(string.format('Download: %g kb/s', tostring(download / 1000)), 10, 66)
end

function beginContact(a, b, coll)
  localPlayer:beginContact(a, b, coll)
  for _,player in pairs(players) do
    player:beginContact(a, b, coll)
  end
end

function endContact(a, b, coll)
  localPlayer:endContact(a, b, coll)
  for _,player in pairs(players) do
    player:endContact(a, b, coll)
  end
end

function preSolve(a, b, coll)
  localPlayer:preSolve(a, b, coll)
  for _,player in pairs(players) do
    player:preSolve(a, b, coll)
  end
end

function postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
  localPlayer:postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
  for _,player in pairs(players) do
    player:postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
  end
end
