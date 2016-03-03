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

function Planet:_init(x, y, radius, gravity, atmosphereSize, density, gravityFall)
  GameObject:_init()

  self.atmosphereSize = atmosphereSize or 0
  self.gravityFall = gravityFall or 1
  self.density = density or 0
  self.gravity = gravity or 9.81 * love.physics.getMeter()
  self.body = love.physics.newBody(world, x, y)
  self.fixture = love.physics.newFixture(self.body, love.physics.newCircleShape(radius), 0)
  self.fixture:setSensor(true)
  self.fixture:setCategory(2)
  -- self.fixture:setFriction(1)
  self.atmosphereFixture = love.physics.newFixture(self.body, love.physics.newCircleShape(self.atmosphereSize), 0)
  self.atmosphereFixture:setSensor(true)
  self.atmosphereFixture:setCategory(2)
  -- self.shape = self.fixture:getShape()
  self.radius = radius
  self.spritesheet = love.graphics.newImage("resources/level.png")
  self.spritesheet:setWrap('clampzero', 'clampzero')
  self.spritesheet:setFilter("nearest")
  self.sprite = love.graphics.newQuad(18, 2, 16, 16, self.spritesheet:getDimensions())
  self.spriteAtmosphere = love.graphics.newQuad(70, 191, 16, 16, self.spritesheet:getDimensions())
  self.batch = love.graphics.newSpriteBatch(self.spritesheet, 10000)
  self.atmosphereBatch = love.graphics.newSpriteBatch(self.spritesheet, 10000)
  self.objects = {}

  local segments = math.ceil(self.radius * 2 * math.pi / 16)
  for i = 0, segments,1 do
    self.batch:add(self.sprite, 0, 0, math.rad(i * (360 / segments)), 1, 1, 8, self.radius)
  end
  self.batch:flush()

  local radius = self.radius
  -- 0.042, 0.076,
  -- 0.079, 0.141,
  local vertices = {
    {
      -- center
      0, 0, -- position of the vertex
      0.042, 0.141, -- texture coordinate at the vertex position
      255, 0, 0, -- color of the vertex
    },
  }
  local segments = 128
  for i = 0, segments,1 do
    local angle = (2 * math.pi / segments) * i
    local angle2 = (2 * math.pi / segments) * (i + 1)
    table.insert(vertices, {
      radius * math.cos(angle), radius * math.sin(angle), -- position of the vertex
      0.042, 0.076, -- texture coordinate at the vertex position
      255, 255, 255, -- color of the vertex
    })
    table.insert(vertices, {
      radius * math.cos(angle2), radius * math.sin(angle2), -- position of the vertex
      0.079, 0.076, -- texture coordinate at the vertex position
      255, 255, 255, -- color of the vertex
    })
    local x1, y1 = radius * math.cos(angle), radius * math.sin(angle)
    local x2, y2 = radius * math.cos(angle2), radius * math.sin(angle2)
    love.physics.newFixture(self.body, love.physics.newEdgeShape(x1, y1, x2, y2), 0)
  end
  for i = 0, segments, 1 do
  end

  local segments = math.ceil((self.atmosphereFixture:getShape():getRadius() + 16) * 2 * math.pi / 16)
  for i = 0, segments - 1,1 do
    self.atmosphereBatch:add(self.spriteAtmosphere, 0, 0, math.rad(i * (360 / segments)), 1, 1, 8, self.atmosphereFixture:getShape():getRadius() + 16)
  end
  self.atmosphereBatch:flush()
  self.mesh = love.graphics.newMesh(vertices, 'fan', 'static')
  self.mesh:setTexture(self.spritesheet)

  return self
end

function Planet:update(dt)
  local px, py = self.body:getPosition()

  for key, object in pairs(objects) do
    if object.body:getMass() > 0 then
      local gx, gy = self.body:getLocalPoint(object.body:getPosition())
      local radius = self.radius * self.gravityFall
      local distance = vector.polar(gx, gy) - self.radius
      gx, gy = vector.normalize(gx, gy)
      local force = object.body:getMass() * self.gravity * math.pow(radius / (radius + distance), 2)
      object.body:applyForce(gx * -force, gy * -force)
    end
  end
end

function Planet:draw()
  -- love.graphics.setLineWidth(10)
  -- love.graphics.setColor(180, 205, 147, 32)
  -- love.graphics.circle("line", self.body:getX(), self.body:getY(), self.atmosphereFixture:getShape():getRadius() + 15)
  -- love.graphics.setColor(180, 205, 147, 64)
  -- love.graphics.circle("line", self.body:getX(), self.body:getY(), self.atmosphereFixture:getShape():getRadius() + 5)
  love.graphics.setColor(180, 205, 147, 128)
  love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.atmosphereFixture:getShape():getRadius())
  love.graphics.draw(self.atmosphereBatch, self.body:getX(), self.body:getY())
  love.graphics.setColor(colorLightGreen())
  love.graphics.draw(self.mesh, self.body:getX(), self.body:getY())
  -- love.graphics.circle("line", self.body:getX(), self.body:getY(), self.radius)
  -- love.graphics.draw(self.batch, self.body:getX(), self.body:getY())
  -- love.graphics.setLineWidth(4)
  -- love.graphics.setColor(255, 0, 255, 255)
  -- love.graphics.line(self.body:getX(), self.body:getY(), self.body:getX(), self.body:getY() - self.radius)
  -- love.graphics.setLineWidth(1)

  -- local px, py = self.body:getPosition()
  -- love.graphics.setColor(colorLight())
  -- for key, object in pairs(objects) do
  --   local gx, gy = self.body:getLocalPoint(object.body:getPosition())
  --   local radius = self.radius * self.gravityFall
  --   local distance = vector.polar(gx, gy) - self.radius
  --   local force = self.gravity * math.pow(radius / (radius + distance), 2)
  --
  --   gx, gy = vector.normalize(gx, gy)
  --   love.graphics.line(object.body:getX(), object.body:getY(), object.body:getX() + gx * -force, object.body:getY() + gy * -force)
  -- end
end

function Planet:beginContact(a, b, coll)
  if a == self.atmosphereFixture then
    local data = b:getUserData()
    if data then
      data.planet = self
    end
    b:getBody():setLinearDamping(self.density)
  elseif b == self.atmosphereFixture then
    local data = a:getUserData()
    if data then
      data.planet = self
    end
    a:getBody():setLinearDamping(self.density)
  end
end

function Planet:endContact(a, b, coll)
  if a == self.atmosphereFixture then
    local data = b:getUserData()
    if data then
      data.planet = nil
    end
    b:getBody():setLinearDamping(0)
  elseif b == self.atmosphereFixture then
    local data = a:getUserData()
    if data then
      data.planet = nil
    end
    a:getBody():setLinearDamping(0)
  end
end

function Planet:type()
  return 'Planet'
end
