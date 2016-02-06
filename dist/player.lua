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

function Player:_init(x, y)
  GameObject._init(self)

  self.x = x
  self.y = y
  self.width = 14
  self.height = 20
  self.body = love.physics.newBody(world, x, y, "dynamic")
  self.body:setFixedRotation(true)
  self.fixture = love.physics.newFixture(self.body, love.physics.newRectangleShape(0, 0, self.width, self.height), 1)
  self.fixture:setFriction(1)
  self.shape = self.fixture:getShape()
  self.angle = self.body:getAngle()
  self.planet = {}
  self.direction = 1
  self.isAirbourn = true

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

  currentFrame = 0

  return self
end

function Player:update(dt)
  local x, y = self.body:getLinearVelocity()
  local planetX, planetY = self.planet.body:getPosition()
  local playerX, playerY = self.body:getPosition()
  local px, py = vector.normalize(planetX - playerX, planetY - playerY)
  local length, angle = vector.polar(px, py)

  local l = vector.polar(self.body:getLinearVelocity()) / 10

  self.body:setAngle(angle + math.pi * 0.5)
  self.playAnim = self.anim.stand
  if not self.isAirbourn and love.keyboard.isDown("left") or love.keyboard.isDown("a") then
    local tx, ty = vector.cartesian(length, angle + math.pi * 0.5)
    self.body:setLinearVelocity(tx * 100, ty * 100)
    self.direction = 1
    currentFrame = currentFrame + dt
    self.playAnim = self.anim.run[math.floor(currentFrame * l) % 3 + 1]

    if server then
      server:send('left')
    end
  end

  if not self.isAirbourn and love.keyboard.isDown("right") or love.keyboard.isDown("d") then
    local tx, ty = vector.cartesian(length, angle - math.pi * 0.5)
    self.body:setLinearVelocity(tx * 100, ty * 100)
    self.direction = -1
    currentFrame = currentFrame + dt
    self.playAnim = self.anim.run[math.floor(currentFrame * l) % 3 + 1]

    if server then
      server:send('right')
    end
  end

  if self.isAirbourn then
    self.playAnim = self.anim.jump
  end

  -- if object.planet ~= self and distance < (self.shape:getRadius() + 100) then
    -- object:setPlanet(self)
  -- end

end

runSpeed = 1
function Player:requestFrame(dt)
  return self
end

function Player:draw()
  -- love.graphics.points(self.body:getPosition())
  -- love.graphics.setColor(255, 0, 0, 255)
  -- love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
  love.graphics.setColor(255, 255, 255, 255)
  -- love.graphics.setColor(colorLightGreen());
  love.graphics.push()
  love.graphics.translate(self.body:getPosition())
  love.graphics.push()
  love.graphics.rotate(self.body:getAngle() + math.pi)
  love.graphics.scale(self.direction, 1)

  love.graphics.draw(self.spritesheet, self.playAnim, 30 * -0.5, 40 * -0.5)

  love.graphics.pop()
  love.graphics.pop()
end

function Player:setPlanet(planet)
  self.planet = planet
end

function Player:keypressed(key, scancode, isrepeat)
  local planetX, planetY = self.planet.body:getPosition()
  local playerX, playerY = self.body:getPosition()
  local px, py = vector.normalize(planetX - playerX, planetY - playerY)
  if not self.isAirbourn and key == "space" then
    self.isAirbourn = true
    self.body:applyLinearImpulse(-px * 70, -py * 70)

    if server then
      server:send('jump')
    end
  end
end

function Player:beginContact(a, b, coll)
end

function Player:endContact(a, b, coll)
  if a == self.fixture or b == self.fixture then
    self.isAirbourn = true
  end
end

function Player:preSolve(a, b, coll)
  if a == self.fixture or b == self.fixture then
    self.isAirbourn = false
  end
end

function Player:postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)

end
