require "gameObject"

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
  -- move_up = 'moveUp',
  -- move_down = 'moveDown',
  jump = 'jump'
}

function Player:_init(x, y)
  GameObject._init(self)

  self.x = x
  self.y = y
  self.width = 14
  self.height = 20
  self.body = love.physics.newBody(world, x, y, "dynamic")
  self.body:setFixedRotation(true)
  local playerShape = {
    self.width * 0.5, self.height * 0.5,
    self.width * -0.5, self.height * 0.5,
    self.width * -0.5, self.height * -0.5 + 2,
    self.width * -0.5 + 2, self.height * -0.5,
    self.width * 0.5 - 2, self.height * -0.5,
    self.width * 0.5, self.height * -0.5 + 2
  }
  self.fixture = love.physics.newFixture(self.body, love.physics.newPolygonShape(playerShape), 1)
  self.fixture:setFriction(1)
  self.fixture:setCategory(1)
  self.fixture:setMask(2)
  self.footFixture = love.physics.newFixture(self.body, love.physics.newRectangleShape(0, self.height * -0.5, self.width * 0.8, 4), 0)
  self.footFixture:setSensor(true)
  self.footShape = self.footFixture:getShape()
  self.shape = self.fixture:getShape()
  self.angle = self.body:getAngle()
  self.planet = {}
  self.direction = 1
  self.footContacts = 0
  self.jumpReleased = true
  self.jumpCooldown = 0
  self.inputs = {
    move_left = false,
    move_right = false,
    move_up = false,
    move_down =false,
    jump = false
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

  return self
end

function Player:update(dt)
  -- local x, y = self.body:getLinearVelocity()
  local planetX, planetY = self.planet.body:getPosition()
  local playerX, playerY = self.body:getPosition()
  local px, py = vector.normalize(planetX - playerX, planetY - playerY)
  local length, angle = vector.polar(px, py)

  self.body:setAngle(angle + math.pi * 0.5)
  self.playAnim = self.anim.stand
  if self.jumpCooldown > 0 then
    self.jumpCooldown = self.jumpCooldown - dt
  end

  for key, value in pairs(self.inputs) do
    if value == true then
      local functionName = Player.actions[key]
      if functionName ~= nil then
        self[functionName](self, dt)
      end
    end
  end

  if self.inputs['jump'] == false and self.footContacts > 0 then
    self.jumpReleased = true
  end

  if self.footContacts <= 0 then
    self.playAnim = self.anim.jump
  end

end

function Player:draw()
  -- love.graphics.points(self.body:getPosition())
  -- love.graphics.setColor(255, 0, 0, 255)
  -- love.graphics.setLineStyle('rough')
  -- love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
  -- love.graphics.setColor(255, 0, 0, 255)
  -- love.graphics.polygon("line", self.body:getWorldPoints(self.footShape:getPoints()))
  love.graphics.setColor(255, 255, 255, 255)
  -- love.graphics.setColor(colorLightGreen())
  love.graphics.push()
  love.graphics.translate(self.body:getPosition())
  love.graphics.push()
  love.graphics.rotate(self.body:getAngle() + math.pi)

  local airbourn = 'no'
  if self.footContacts <= 0 then
    airbourn = 'yes'
  end
  local released = 'no'
  if self.jumpReleased then
    released = 'yes'
  end
  local awake = 'no'
  if self.body:isAwake() then
    awake = 'yes'
  end

  love.graphics.print("Contacts " .. self.footContacts, 0, -self.height - 40)
  love.graphics.print("Airbourn? " .. airbourn, 0, -self.height - 10)
  love.graphics.print("Released? " .. released, 0, -self.height - 20)
  love.graphics.print("awake? " .. awake, 0, -self.height - 30)

  love.graphics.scale(self.direction, 1)
  love.graphics.draw(self.spritesheet, self.playAnim, 30 * -0.5, 40 * -0.5)
  love.graphics.pop()
  love.graphics.pop()
end

function Player:setPlanet(planet)
  self.planet = planet
end

function Player:keypressed(key, scancode, isrepeat)
  local command = binding[key]
  if command and self.inputs[command] ~= nil then
    self.inputs[command] = true
  end
end

function Player:keyreleased(key, scancode, isrepeat)
  local command = binding[key]
  if command and self.inputs[command] ~= nil then
    self.inputs[command] = false
  end
end

function Player:beginContact(a, b, coll)
  if a == self.footFixture or b == self.footFixture then
    self.footContacts = self.footContacts + 1
  end
end

function Player:endContact(a, b, coll)
  if a == self.footFixture or b == self.footFixture then
    self.footContacts = self.footContacts - 1
  end
end

function Player:preSolve(a, b, coll)
end

function Player:postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
end

function Player:moveLeft(dt)
    if CLIENT and server then
      server:send('action move_left')
    end
    local px, py = self:_getPlanetDirection()
    local length, angle = vector.polar(px, py)
    local tx, ty = vector.cartesian(length, angle + math.pi * 0.5)
    local vx, vy = vector.normalize(self.body:getLinearVelocity())
    self.direction = 1
    if self.footContacts > 0 and self.jumpCooldown <= 0 then
      self.body:setLinearVelocity(vx + tx * 100, vy + ty * 100)
    else
      self.body:applyForce(tx * 25, ty * 25)
    end
end

function Player:moveRight(dt)
  if CLIENT and server then
    server:send('action move_right')
  end
  local px, py = self:_getPlanetDirection()
  local length, angle = vector.polar(px, py)
  local tx, ty = vector.cartesian(length, angle - math.pi * 0.5)
  local vx, vy = vector.normalize(self.body:getLinearVelocity())
  self.direction = -1
  if self.footContacts > 0 and self.jumpCooldown <= 0 then
    self.body:setLinearVelocity(vx + tx * 100, vy + ty * 100)
  else
    self.body:applyForce(tx * 25, ty * 25)
  end
end

function Player:isMoving()
  local x, y = self.body:getLinearVelocity()
  local a = self.body:getAngularVelocity()
  return math.floor(math.abs(a) * 100) > 0 or math.floor(math.abs(y) * 100) > 0 or math.floor(math.abs(y) * 100) > 0
end

function Player:jump(dt)
  local power = 100
  if self.footContacts > 0 and self.jumpCooldown <= 0 and self.jumpReleased then
    if CLIENT and server then
      server:send('action jump')
    end
    self.jumpCooldown = 0.1
    self.jumpReleased = false
    -- self.footContacts = 0
    local px, py = self:_getPlanetDirection()
    self.body:applyLinearImpulse(-px * power, -py * power)
  end
end

function Player:_getPlanetDirection()
  local planetX, planetY = self.planet.body:getPosition()
  local playerX, playerY = self.body:getPosition()
  return vector.normalize(planetX - playerX, planetY - playerY)
end
