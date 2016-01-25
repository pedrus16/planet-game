vector = require "lib/vector"

Planet = {}
Planet.__index = Planet

function Planet.new(x, y, radius, gravity)
  local self = setmetatable({}, Planet)

  self.gravity = gravity or 9.81;
  self.body = love.physics.newBody(world, x, y)
  self.fixture = love.physics.newFixture(self.body, love.physics.newCircleShape(radius), 1)
  self.shape = self.fixture:getShape()
  self.spritesheet = love.graphics.newImage("level.png")
  self.spritesheet:setFilter("nearest")
  self.sprite = love.graphics.newQuad(18, 2, 16, 16, self.spritesheet:getDimensions())
  self.sprite2 = love.graphics.newQuad(18, 19, 16, 16, self.spritesheet:getDimensions())
  self.batch = love.graphics.newSpriteBatch(self.spritesheet)
  self.objects = {}

  local segments = math.ceil(self.shape:getRadius() * 2 * math.pi / 16)
  for i = 0, segments,1 do
    self.batch:add(self.sprite, 0, 0, math.rad(i * (360 / segments)), 1, 1, 8, self.shape:getRadius())
  end
  self.batch:flush()

  return self
end

function Planet.update(self, dt)
  local px, py = self.body:getPosition()

  for key, object in pairs(self.objects) do
    local ox, oy = object.body:getPosition()
    local gx, gy = px - ox, py - oy
    local distance = vector.polar(gx, gy)
    gx, gy = vector.normalize(px - ox, py - oy)
    local force = self.gravity / (distance / self.shape:getRadius())
    object.body:applyForce(gx * force, gy * force)
    if object.planet ~= self and distance < (self.shape:getRadius() + 100) then
      object:setPlanet(self)
    end
  end
end

function Planet.draw(self)
  love.graphics.setColor(colorLight());
  love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.shape:getRadius())
  love.graphics.draw(self.batch, self.body:getX(), self.body:getY())

  local px, py = self.body:getPosition()
  for key, object in pairs(self.objects) do
    local ox, oy = object.body:getPosition()
    local gx, gy = px - ox, py - oy

    local distance = vector.polar(gx, gy)
    gx, gy = vector.normalize(px - ox, py - oy)
    local force = self.gravity / (distance / self.shape:getRadius())
    love.graphics.setColor(colorLight())
    -- love.graphics.line(object.body:getX(), object.body:getY(), object.body:getX() + gx * force, object.body:getY() + gy * force)
  end
end
