require "gameObject"
require "debug"
require "lib.vector"
local anim8 = require "lib.anim8"

Player = {}
Player.__index = Player

setmetatable(Player, {
  __index = GameObject,
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Player:_init(x, y)
  GameObject._init(self)

  self.zoom = 1
  self.x = x
  self.y = y
  self.width = 14
  self.height = 20
  self.airSpeed = 300
  self.groundSpeed = 60
  self.body = love.physics.newBody(world, x, y, "dynamic")
  self.body:setFixedRotation(true)
  -- self.body:setLinearDamping(0.1)
  local playerShape = {
    self.width * -0.5, self.height * -0.5,
    self.width * 0.5, self.height * -0.5,
    self.width * 0.5, self.height * 0.5 - 2,
    self.width * 0.5 - 2, self.height * 0.5,
    self.width * -0.5 + 2, self.height * 0.5,
    self.width * -0.5, self.height * 0.5 - 2
  }

  self.fixture = love.physics.newFixture(self.body, love.physics.newPolygonShape(playerShape), 28)
  self.fixture:setFriction(1)
  self.fixture:setUserData(self)
  self.shape = self.fixture:getShape()

  self.footFixture = love.physics.newFixture(self.body, love.physics.newRectangleShape(0, self.height * 0.5, self.width * 0.7, 2), 0)
  -- self.footFixture:setSensor(true)
  self.footFixture:setMask(2)
  self.footShape = self.footFixture:getShape()

  self.actionFixture = love.physics.newFixture(self.body, love.physics.newRectangleShape(0, 0, self.width * 2, self.height), 0)
  self.actionFixture:setSensor(true)
  self.actionFixture:setCategory(2)
  self.actionShape = self.actionFixture:getShape()

  self.angle = self.body:getAngle()
  self.planet = nil
  self.direction = 1
  self.footContacts = 0
  self.jumpReleased = true
  self.jumpCooldown = 0
  self.inputs = {
    move_left = false,
    move_right = false,
    move_up = false,
    move_down = false,
    zoom_in = false,
    zoom_out = false,
    jump = false,
    use = false
  }
  self.actions = {
    move_left = 'moveLeft',
    move_right = 'moveRight',
    jump = 'jump',
    zoom_in = 'zoomIn',
    zoom_out = 'zoomOut',
    use = 'use'
  }
  self.spritesheet = love.graphics.newImage("resources/mario.png")
  self.spritesheet:setFilter("nearest")
  self.grid = anim8.newGrid(30, 40, self.spritesheet:getWidth(), self.spritesheet:getHeight())
  self.animation = anim8.newAnimation(self.grid:getFrames('2-4', 4), 0.08)
  -- self.anim = {
  --   stand = love.graphics.newQuad(0, 120, 30, 40, self.spritesheet:getDimensions()),
  --   run = {
  --     love.graphics.newQuad(30, 120, 30, 40, self.spritesheet:getDimensions()),
  --     love.graphics.newQuad(60, 120, 30, 40, self.spritesheet:getDimensions()),
  --     love.graphics.newQuad(90, 120, 30, 40, self.spritesheet:getDimensions())
  --   },
  --   jump = love.graphics.newQuad(120, 120, 30, 40, self.spritesheet:getDimensions())
  -- }
  -- self.playAnim = self.anim.stand
  self.drive = nil
  self.usable = nil

  self.debugContact = {
    x1 = 0,
    y1 = 0,
    x2 = 0,
    y2 = 0,
    tx = 0,
    ty = 0
  }
  self.contact = nil
  return self
end

function Player:update(dt)
  if self.planet ~= nil then
    local _, angle = vector.polar2cartesian(self:_getPlanetDirection())
    self.body:setAngle(angle + math.pi * 0.5)
    self.body:setFixedRotation(true)
  else
    self.body:setFixedRotation(false)
  end
  -- self.playAnim = self.anim.stand
  if self.jumpCooldown > 0 then
    self.jumpCooldown = self.jumpCooldown - dt
  end

  for input, isDown in pairs(self.inputs) do
    if isDown == true then
      if client then
        client.server:send('action ' .. input)
      end
      self:executeAction(input, dt)
    end
  end

  if self.inputs['jump'] == false and self.footContacts > 0 then
    self.jumpReleased = true
  end

  if self.footContacts <= 0 then
    -- self.playAnim = self.anim.jump
    self.animation:pauseAtStart()
  else
    self.animation:resume()
  end

  if self.drive and self.drive.body then
    self.body:setPosition(self.drive.body:getPosition())
    self.body:setAngle(self.drive.body:getAngle())
  end

  -- self.animation:update(dt)
end

function Player:executeAction(key, dt)
  if self.drive == nil then
    local functionName = self.actions[key]
    if self[functionName] ~= nil then
      self[functionName](self, dt)
    end
  else
    local functionName = self.drive.actions[key]
    if self.drive[functionName] ~= nil then
      self.drive[functionName](self.drive, dt)
    end
  end
end

function Player:draw()
  love.graphics.setColor(180, 205, 147, 255)
  love.graphics.push()
  love.graphics.translate(self.body:getPosition())
  love.graphics.push()
  love.graphics.rotate(self.body:getAngle())
  love.graphics.scale(self.direction, 1)
  self.animation:draw(self.spritesheet, 30 * -0.5, 40 * -0.5)
  -- love.graphics.draw(self.spritesheet, self.playAnim, 30 * -0.5, 40 * -0.5)
  love.graphics.pop()
  love.graphics.pop()

  -- DEBUG
  love.graphics.line(self.debugContact.x1, self.debugContact.y1, self.debugContact.x1 + self.debugContact.tx * 20, self.debugContact.y1 + self.debugContact.ty * 20)
  if self.debugContact.x2 ~= nil and self.debugContact.y2 ~= nil then
    love.graphics.line(self.debugContact.x2, self.debugContact.y2, self.debugContact.x2 + self.debugContact.tx * 20, self.debugContact.y2 + self.debugContact.ty * 20)
  end
  love.graphics.setColor(255, 0, 0, 255)
  love.graphics.polygon("line", self.body:getWorldPoints(self.footShape:getPoints()))
  love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
  love.graphics.setColor(255, 0, 0, 255)
end

function Player:setPlanet(planet)
  self.planet = planet
end

function Player:keypressed(key, scancode, isrepeat)
    if self.drive and self.drive['keypressed'] then
      self.drive:keypressed(key, scancode, isrepeat)
    end
    local command = binding[key]
    if command and self.inputs[command] ~= nil then
      self.inputs[command] = true
    end
end

function Player:keyreleased(key, scancode, isrepeat)
    if self.drive and self.drive['keyreleased'] then
      self.drive:keyreleased(key, scancode, isrepeat)
    end
  -- else
    local command = binding[key]
    if command and self.inputs[command] ~= nil then
      self.inputs[command] = false
    end
end

function Player:moveLeft(dt)
  if client then
    client.server:send('action move_left')
  end
  if self.planet ~= nil then
    local px, py = self:_getPlanetDirection()
    local length, angle = vector.polar2cartesian(px, py)
    local tx, ty = vector.cartesian2polar(length, angle - math.pi * 0.5)
    local vx, vy = vector.normalize(self.body:getLinearVelocity())
    self.direction = 1
    if self.footContacts > 0 and self.jumpCooldown <= 0 then
      self.body:setLinearVelocity(vx - self.debugContact.tx * self.groundSpeed, vy - self.debugContact.ty * self.groundSpeed)
      self.animation:update(dt)
    else
      self.body:applyForce(tx * self.airSpeed, ty * self.airSpeed)
    end
  else
    self.body:applyTorque(-1000)
  end
end

function Player:moveRight(dt)
  if client then
    client.server:send('action move_right')
  end
  if self.planet ~= nil then
    local px, py = self:_getPlanetDirection()
    local length, angle = vector.polar2cartesian(px, py)
    local tx, ty = vector.cartesian2polar(length, angle + math.pi * 0.5)
    local vx, vy = vector.normalize(self.body:getLinearVelocity())
    self.direction = -1
    if self.footContacts > 0 and self.jumpCooldown <= 0 then
      self.body:setLinearVelocity(vx + self.debugContact.tx * self.groundSpeed, vy + self.debugContact.ty * self.groundSpeed)
      self.animation:update(dt)
    else
      self.body:applyForce(tx * self.airSpeed, ty * self.airSpeed)
    end
  else
    self.body:applyTorque(1000)
  end
end

function Player:isMoving()
  local x, y = self.body:getLinearVelocity()
  local a = self.body:getAngularVelocity()
  return math.floor(math.abs(a) * 100) > 0 or math.floor(math.abs(y) * 100) > 0 or math.floor(math.abs(y) * 100) > 0
end

function Player:jump(dt)
  if self.planet ~= nil then
    self.animation:pause()
    local power = 1900
    if self.footContacts > 0 and self.jumpCooldown <= 0 and self.jumpReleased then
      if client then
        client.server:send('action jump')
      end
      self.jumpCooldown = 0.1
      self.jumpReleased = false
      local px, py = self:_getPlanetDirection()
      self.body:applyLinearImpulse(px * power, py * power)
    end
  end
end

function Player:zoomIn(dt)
    self.inputs['zoom_in'] = false
    if self.zoom <= 16 then
      self.zoom = self.zoom * 2
    end
end

function Player:zoomOut(dt)
  self.inputs['zoom_out'] = false
  if self.zoom > 0 then
    self.zoom = self.zoom * 0.5
  end
end

function Player:use(dt)
  if client then
    client.server:send('action use')
  end
  if self.usable and self.usable['setDriver'] then
    self.usable:setDriver(self)
  end
end

function Player:_getPlanetDirection()
  return vector.normalize(self.planet.body:getLocalPoint(self.body:getPosition()))
end

function Player:type()
  return 'Player'
end

function Player:beginContact(a, b, coll)
  if a == self.footFixture or b == self.footFixture then
    self.footContacts = self.footContacts + 1
  end
  if a == self.actionFixture then
    local object = b:getUserData()
    if object and object.type == 'rocket' then
      self.usable = object.data
    end
  end
  if b == self.actionFixture then
    local object = a:getUserData()
    if object and object.type == 'rocket' then
      self.usable = object.data
    end
  end
end

function Player:endContact(a, b, coll)
  if a == self.footFixture or b == self.footFixture then
    self.footContacts = self.footContacts - 1
  end
  if a == self.actionFixture then
    self.usable = nil
  end
  if b == self.actionFixture then
    self.usable = nil
  end
end

function Player:preSolve(a, b, contact)
  if a == self.footFixture or b == self.footFixture then
     contact:setEnabled(false)
    print(self.debugContact.x1, self.debugContact.y1)
    print(self.debugContact.x2, self.debugContact.y2)
    local l, a = vector.polar2cartesian(contact:getNormal())
    self.debugContact.tx, self.debugContact.ty = vector.cartesian2polar(l, a + math.pi * 0.5)
    self.debugContact.x1, self.debugContact.y1, self.debugContact.x2, self.debugContact.y2 = contact:getPositions()
  end
end

function Player:postSolve(a, b, contact)
end
