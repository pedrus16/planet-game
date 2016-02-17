require "gameObject"
require "debug"

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

Player.actions = {
  move_left = 'moveLeft',
  move_right = 'moveRight',
  jump = 'jump',
  zoom_in = 'zoomIn',
  zoom_out = 'zoomOut',
  use = 'use'
}

function Player:_init(x, y)
  GameObject._init(self)

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
    self.width * 0.5, self.height * 0.5,
    self.width * -0.5, self.height * 0.5,
    self.width * -0.5, self.height * -0.5 + 2,
    self.width * -0.5 + 2, self.height * -0.5,
    self.width * 0.5 - 2, self.height * -0.5,
    self.width * 0.5, self.height * -0.5 + 2
  }

  self.fixture = love.physics.newFixture(self.body, love.physics.newRectangleShape(0, 0, self.width, self.height), 28)
  self.fixture:setFriction(1)
  self.fixture:setUserData(self)
  self.shape = self.fixture:getShape()

  self.footFixture = love.physics.newFixture(self.body, love.physics.newRectangleShape(0, self.height * 0.5, self.width * 0.8, 4), 0)
  self.footFixture:setSensor(true)
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
  self.spritesheet = love.graphics.newImage("resources/mario.png")
  self.spritesheet:setFilter("nearest")
  self.anim = {
    stand = love.graphics.newQuad(0, 120, 30, 40, self.spritesheet:getDimensions()),
    run = {
      love.graphics.newQuad(30, 120, 30, 40, self.spritesheet:getDimensions()),
      love.graphics.newQuad(60, 120, 30, 40, self.spritesheet:getDimensions()),
      love.graphics.newQuad(90, 120, 30, 40, self.spritesheet:getDimensions())
    },
    jump = love.graphics.newQuad(120, 120, 30, 40, self.spritesheet:getDimensions())
  }
  self.playAnim = self.anim.stand
  self.drive = nil
  self.usable = nil
  POS = self.body:getY()
  -- print(0)
  return self
end

function Player:update(dt)
  if self.planet ~= nil then
    local _, angle = vector.polar(self:_getPlanetDirection())
    self.body:setAngle(angle + math.pi * 0.5)
    self.body:setFixedRotation(true)
  else
    self.body:setFixedRotation(false)
  end
  self.playAnim = self.anim.stand
  if self.jumpCooldown > 0 then
    self.jumpCooldown = self.jumpCooldown - dt
  end

  if  not self.drive then
    for key, value in pairs(self.inputs) do
      if value == true then
        local functionName = Player.actions[key]
        if functionName ~= nil then
          self[functionName](self, dt)
        end
      end
    end
  end

  if self.inputs['jump'] == false and self.footContacts > 0 then
    self.jumpReleased = true
  end

  if self.footContacts <= 0 then
    self.playAnim = self.anim.jump
  end

  if self.drive and self.drive.body then
    self.body:setPosition(self.drive.body:getPosition())
    self.body:setAngle(self.drive.body:getAngle())
  end
  print(self.footContacts)
end

function Player:draw()
  -- love.graphics.points(self.body:getPosition())
  -- love.graphics.setColor(255, 0, 0, 255)
  -- love.graphics.setLineStyle('rough')
  -- love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
  love.graphics.setColor(255, 0, 0, 255)
  love.graphics.polygon("line", self.body:getWorldPoints(self.footShape:getPoints()))
  love.graphics.setColor(255, 0, 0, 255)
  love.graphics.polygon("line", self.body:getWorldPoints(self.actionShape:getPoints()))
  love.graphics.setColor(180, 205, 147, 255)
  -- love.graphics.setColor(colorLightGreen())
  love.graphics.push()
  -- if self.drive and self.drive.body then
    -- love.graphics.translate(self.drive.body:getPosition())
  -- else
    love.graphics.translate(self.body:getPosition())
  -- end
  love.graphics.push()
  love.graphics.rotate(self.body:getAngle())

  -- local airbourn = 'no'
  -- if self.footContacts <= 0 then
  --   airbourn = 'yes'
  -- end
  -- local released = 'no'
  -- if self.jumpReleased then
  --   released = 'yes'
  -- end
  -- local awake = 'no'
  -- if self.body:isAwake() then
  --   awake = 'yes'
  -- end
  --
  -- love.graphics.print("Airbourn? " .. airbourn, 0, -self.height - 10)
  -- love.graphics.print("Released? " .. released, 0, -self.height - 20)
  -- love.graphics.print("awake? " .. awake, 0, -self.height - 30)
  -- love.graphics.print("Contacts " .. self.footContacts, 0, -self.height - 40)
  -- love.graphics.print("Damping " .. self.body:getLinearDamping(), 0, -self.height - 50)
  -- local x, y = self.body:getLinearVelocity()
  -- love.graphics.print(x, 0, -self.height - 50)
  -- love.graphics.print(y, 0, -self.height - 40)

  love.graphics.scale(self.direction, 1)
  love.graphics.draw(self.spritesheet, self.playAnim, 30 * -0.5, 40 * -0.5)
  love.graphics.pop()
  love.graphics.pop()
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

function Player:moveLeft(dt)
  if client then
    client.server:send('action move_left')
  end
  if self.planet ~= nil then
    local px, py = self:_getPlanetDirection()
    local length, angle = vector.polar(px, py)
    local tx, ty = vector.cartesian(length, angle - math.pi * 0.5)
    local vx, vy = vector.normalize(self.body:getLinearVelocity())
    self.direction = 1
    if self.footContacts > 0 and self.jumpCooldown <= 0 then
      self.body:setLinearVelocity(vx + tx * self.groundSpeed, vy + ty * self.groundSpeed)
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
    local length, angle = vector.polar(px, py)
    local tx, ty = vector.cartesian(length, angle + math.pi * 0.5)
    local vx, vy = vector.normalize(self.body:getLinearVelocity())
    self.direction = -1
    if self.footContacts > 0 and self.jumpCooldown <= 0 then
      self.body:setLinearVelocity(vx + tx * self.groundSpeed, vy + ty * self.groundSpeed)
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
    local power = 1500
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
    if scale <= 16 then
      scale = scale * 2
    end
end

function Player:zoomOut(dt)
  self.inputs['zoom_out'] = false
  if scale > 0 then
    scale = scale * 0.5
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
