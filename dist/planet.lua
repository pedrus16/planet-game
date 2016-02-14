require "gameObject"
vector = require "lib/vector"

Planet = {}
Planet.__index = Planet

setmetatable(Planet, {
  __index = GameObject,
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Planet:_init(x, y, radius, gravity, atmosphereSize, density)
  GameObject:_init()

  atmosphereSize = atmosphereSize or 0
  self.density = density or 0
  self.gravity = gravity or 9.81
  self.body = love.physics.newBody(world, x, y)
  self.fixture = love.physics.newFixture(self.body, love.physics.newCircleShape(radius), 0)
  self.fixture:setFriction(1)
  self.atmosphereFixture = love.physics.newFixture(self.body, love.physics.newCircleShape(radius + atmosphereSize), 0)
  self.atmosphereFixture:setSensor(true)
  self.atmosphereFixture:setCategory(2)
  self.shape = self.fixture:getShape()
  self.spritesheet = love.graphics.newImage("resources/level.png")
  self.spritesheet:setFilter("nearest")
  self.sprite = love.graphics.newQuad(18, 2, 16, 16, self.spritesheet:getDimensions())
  self.sprite2 = love.graphics.newQuad(18, 19, 16, 16, self.spritesheet:getDimensions())
  self.batch = love.graphics.newSpriteBatch(self.spritesheet, 100000)
  self.objects = {}

  local segments = math.ceil(self.shape:getRadius() * 2 * math.pi / 16)
  for i = 0, segments,1 do
    self.batch:add(self.sprite, 0, 0, math.rad(i * (360 / segments)), 1, 1, 8, self.shape:getRadius())
  end
  self.batch:flush()
  for i = 0, segments,1 do
    self.batch:add(self.sprite, 0, 0, math.rad(i * (360 / segments)), 1, 1, 8, self.shape:getRadius())
  end

  return self
end

function Planet:update(dt)
  local px, py = self.body:getPosition()

  for key, object in pairs(objects) do
    local gx, gy = self.body:getLocalPoint(object.body:getPosition())
    local distance = vector.polar(gx, gy)
    gx, gy = vector.normalize(gx, gy)
    local force = self.gravity / (distance / self.shape:getRadius())
    object.body:applyForce(-gx * force, -gy * force)
    if object['setPlanet'] and object.planet ~= self and distance < (self.shape:getRadius() + 200) then
      object:setPlanet(self)
    end
  end
end

function Planet:draw()
  love.graphics.setColor(252, 245, 184, 128)
  love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.atmosphereFixture:getShape():getRadius())
  love.graphics.setColor(colorLightGreen())
  love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius())
  love.graphics.draw(self.batch, self.body:getX(), self.body:getY())

  local px, py = self.body:getPosition()
  love.graphics.setColor(colorLight())
  for key, object in pairs(self.objects) do
    local gx, gy = self.body:getLocalPoint(object.body:getPosition())

    local distance = vector.polar(gx, gy)
    gx, gy = vector.normalize(gx, gy)
    local force = self.gravity / (distance / self.shape:getRadius())
    -- love.graphics.line(object.body:getX(), object.body:getY(), object.body:getX() + gx * force, object.body:getY() + gy * force)
  end
end

function Planet:beginContact(a, b, coll)
  if a == self.atmosphereFixture then
    b:getBody():setLinearDamping(self.density)
  elseif b == self.atmosphereFixture then
    a:getBody():setLinearDamping(self.density)
  end
end

function Planet:endContact(a, b, coll)
  if a == self.atmosphereFixture then
    b:getBody():setLinearDamping(0)
  elseif b == self.atmosphereFixture then
    a:getBody():setLinearDamping(0)
  end
end
