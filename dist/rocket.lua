require "gameObject"

Rocket = {}
Rocket.__index = Rocket

setmetatable(Rocket, {
  __index = GameObject,
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Rocket:_init(x, y, angle)
  GameObject:_init()

  self.driver = {}
  self.width = 28
  self.height = 52
  self.body = love.physics.newBody(world, x, y, "dynamic")
  self.body:setAngle(angle or 0)
  -- self.body:setFixedRotation(true)
  self.fixture = love.physics.newFixture(self.body, love.physics.newPolygonShape(16 - 16, 6 - 26, 28 - 16, 40 - 26, 29 - 16, 57 - 26, 2 - 16, 57 - 26, 3 - 16, 40 - 26), 4)
  self.fixture:setFriction(1)
  self.shape = self.fixture:getShape()
  self.angle = self.body:getAngle()
  -- self.useFixture = love.physics.newFixture(self.body, love.physics.newRectangleShape(0, 0, 64, 64), 1)
  -- self.useFixture:setCategory(2)
  -- self.useFixture:setMask(1)
  -- self.useFixture:setSensor(true)
  -- self.useFixture:setDensity(0)
  -- self.body:resetMassData()
  -- self.useShape = self.useFixture:getShape()
  self.spritesheet = love.graphics.newImage("resources/rocket.png")
  self.spritesheet:setFilter("nearest")
  self.sprite = love.graphics.newQuad(2, 6, 28, 52, self.spritesheet:getDimensions())

  return self
end

function Rocket:setDriver(player)
  self.driver = player
end

function Rocket:update(dt)

end

function Rocket:draw()
  -- love.graphics.setColor(255, 0, 0, 255)
  -- love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))

  -- love.graphics.setLineStyle('rough')
  -- love.graphics.polygon("line", self.body:getWorldPoints(self.useShape:getPoints()))

  love.graphics.push()
  love.graphics.translate(self.body:getPosition())
  love.graphics.push()

  love.graphics.setColor(colorLight());
  love.graphics.rotate(self.body:getAngle())
  love.graphics.scale(self.direction, 1)
  love.graphics.draw(self.spritesheet, self.sprite, 30 * -0.5, 40 * -0.5)

  love.graphics.pop()
  love.graphics.pop()
end

function Rocket:beginContact(a, b, coll)
  -- if a == self.useFixture then
  -- elseif b == self.useFixture then
  -- end
end

function Rocket:endContact(a, b, coll)
  -- if a == self.useFixture then
  -- elseif b == self.useFixture then
  -- end
end
