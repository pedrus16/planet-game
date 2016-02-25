require "camera"
require "client"
require "enet"
require "planet"
require "player"
require "rocket"
require "server"
require "debug"
suit = require "lib.suit"

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


function love.load(args)
  love.graphics.setLineStyle('rough')
  love.physics.setMeter(20)
  binding = {
    a       = 'move_left',
    d       = 'move_right',
    w       = 'move_up',
    s       = 'move_down',
    space   = 'jump',
    z       = 'zoom_in',
    x       = 'zoom_out',
    escape  = 'quit',
    e       = 'use'
  }
  height = love.graphics.getHeight()
  width = love.graphics.getWidth()
  upload = 0
  download = 0
  ping = 0
  backgroundSprite = love.graphics.newImage("resources/space2.png")
  backgroundSprite:setFilter("nearest")
  backgroundSprite:setWrap('repeat', 'repeat')
  background = love.graphics.newQuad(0, 0, width * 2 + 256, height * 2 + 256, backgroundSprite:getDimensions())
  camera = Camera()
  gameStarted = false
  addressInput = { text = 'localhost' }
  menu = false

  world = love.physics.newWorld(0, 0, true)
  world:setCallbacks(beginContact, endContact, preSolve, postSolve)
  generateWorld()

  for k, arg in pairs(args) do
    if arg == '--connect' then
      if args[k + 1] then
        client = Client(args[k + 1])
      end
    end
  end
end

function generateWorld()
  objects = {}
  players = {}
  planets = {}
  planet1 = Planet(0, 2000, 2000, 9.81 * love.physics.getMeter(), 3000, 0.1, 10)
  planet2 = Planet(0, -40000, 1000, 5 * love.physics.getMeter(), 2000, 0.01, 10)
  localPlayer = Player(0, -10)
  localPlayer.planet = planet1
  camera.body = localPlayer.body


  table.insert(planets, planet1)
  table.insert(planets, planet2)

  table.insert(objects, planet1)
  table.insert(objects, planet2)
  table.insert(objects, localPlayer)
  -- table.insert(players, localPlayer)
  -- table.insert(objects, Planet(500, -2000, 50, 200))
  -- table.insert(objects, Rocket(50, -32))
  -- table.insert(objects, Rocket(-920, -50))
  -- table.insert(objects, Rocket(-920, 100))
  -- table.insert(objects, Rocket(-920, -100))
  -- table.insert(objects, Rocket(-920, -150))
  -- table.insert(objects, Rocket(-920, 150))
end

function love.update(dt)

  if not gameStarted then

    if not menu then
      if suit.Button("Jouer", (width - 100) * 0.5, height * 0.5, 100, 30).hit then
        server = Server('*:6790')
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
        client = Client(addressInput.text .. ':6790')
        -- initClient(addressInput.text .. ':6790')
        gameStarted = true
      end
      if suit.Button("Retour", (width - 100) * 0.5, (height * 0.5) + 70, 100, 30).hit then
        menu = false
      end
    end

  end

  world:update(1/60)
  camera.x, camera.y = localPlayer.body:getPosition()
  camera.angle = -localPlayer.body:getAngle()
  for k, object in pairs(objects) do
    object:update(dt)
  end

  if server then
    server:update(dt)
  elseif client then
    client:update(dt)
  end

end

function love.keypressed(key, scancode, isrepeat)
  suit.keypressed(key)
  localPlayer:keypressed(key, scancode, isrepeat)
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
  love.graphics.scale(localPlayer.zoom, localPlayer.zoom)

  -- rotate and move to player angle and position
  -- love.graphics.push()
  -- love.graphics.rotate(-localPlayer.body:getAngle() + math.pi)

  -- background
  -- love.graphics.push()
  -- love.graphics.push()
  -- love.graphics.translate(-localPlayer.body:getX() % 256, -localPlayer.body:getY() % 256)
  -- love.graphics.push()
  -- love.graphics.setColor(180, 205, 147)
  -- love.graphics.draw(backgroundSprite, background, -width, -height)
  -- love.graphics.pop()
  -- love.graphics.pop()
  -- love.graphics.pop()
  -- background

  -- love.graphics.translate(-x, -y)

  camera:set()
  for k, object in pairs(objects) do
    object:draw()
  end
  camera:unset()

  -- love.graphics.pop()
  love.graphics.pop()

  suit.draw()

  if client then
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
  for _,object in pairs(objects) do
    object:beginContact(a, b, coll)
  end
end

function endContact(a, b, coll)
  localPlayer:endContact(a, b, coll)
  for _,object in pairs(objects) do
    object:endContact(a, b, coll)
  end
end
