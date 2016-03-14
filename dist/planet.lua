require "gameObject"
vector = require "lib/vector"
local clipper = require "lib/clipper"

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
  -- self.fixture = love.physics.newFixture(self.body, love.physics.newCircleShape(radius), 0)
  -- self.fixture:setSensor(true)
  -- self.fixture:setCategory(2)
  -- self.fixture:setFriction(1)
  self.atmosphereFixture = love.physics.newFixture(self.body, love.physics.newCircleShape(self.atmosphereSize), 0)
  self.atmosphereFixture:setSensor(true)
  self.atmosphereFixture:setCategory(2)
  -- self.shape = self.fixture:getShape()
  self.radius = radius
  self.spritesheet = love.graphics.newImage("resources/rock.png")
  self.spritesheet:setWrap('repeat', 'repeat')
  self.spritesheet:setFilter("nearest")
  self.sprite = love.graphics.newQuad(0, 0, self.radius * 2, self.radius * 2, self.spritesheet:getDimensions())
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
  local segments = 256
  self.polygons = clipper.polygons()
  self.polygons:add(clipper.polygon())
  local points = {}
  for i = 0, segments -1,2 do
    local angle = (2 * math.pi / segments) * i
    local angle2 = (2 * math.pi / segments) * (i + 1)
    local x1, y1 = radius * math.cos(angle), radius * math.sin(angle)
    local x2, y2 = radius * math.cos(angle2), radius * math.sin(angle2)
    self.polygons:get(1):add(x1 * 1000, y1 * 1000)
    self.polygons:get(1):add(x2 * 1000, y2 * 1000)
  end

  local size = self.polygons:size()
  self.fixtures = {}
  for i = 1, size, 1 do
    self.fixtures[i] = love.physics.newFixture(self.body, love.physics.newChainShape(false, getPoints(self.polygons:get(i))), 0)
    self.fixtures[i]:setFriction(1)
  end

  self.triangles = love.math.triangulate(getPoints(self.polygons:get(1)))
  self.mask = love.graphics.newCanvas(self.radius * 2, self.radius * 2)
  love.graphics.setCanvas(self.mask)
  love.graphics.clear(0, 0, 0)
  love.graphics.push()
  love.graphics.translate(self.radius, self.radius)
  for _, triangle in pairs(self.triangles) do
    love.graphics.setColor(255, 255, 255)
    love.graphics.polygon('fill', triangle)
  end
  love.graphics.pop()
  love.graphics.setCanvas()
  self.mask_shader = love.graphics.newShader[[
     vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
           // a discarded pixel wont be applied as the stencil.
           discard;
        }
        return vec4(1.0);
     }
  ]]
  self.canvas = love.graphics.newCanvas(self.radius * 2, self.radius * 2)
  self.canvas:setFilter('nearest')
  love.graphics.setCanvas(self.canvas)
  love.graphics.setColor(255,255,255)
  love.graphics.draw(self.spritesheet, self.sprite, 0, 0)
  love.graphics.setColor(colorDark())
  love.graphics.setLineWidth(2)
  love.graphics.circle('line', self.radius, self.radius, self.radius, segments)
  love.graphics.setLineWidth(1)
  love.graphics.setCanvas()

  local segments = math.ceil((self.atmosphereFixture:getShape():getRadius() + 16) * 2 * math.pi / 16)
  for i = 0, segments - 1,1 do
    self.atmosphereBatch:add(self.spriteAtmosphere, 0, 0, math.rad(i * (360 / segments)), 1, 1, 8, self.atmosphereFixture:getShape():getRadius() + 16)
  end
  self.atmosphereBatch:flush()
  -- self.mesh = love.graphics.newMesh(vertices, 'fan', 'static')
  -- self.mesh:setTexture(self.spritesheet)

  return self
end

function Planet:dig(x, y, radius)


  local hole = clipper.polygon()
  local segments = 16
  for i = 0, segments -1,2 do
    local angle = (2 * math.pi / segments) * i
    local angle2 = (2 * math.pi / segments) * (i + 1)
    local x1, y1 = radius * math.cos(angle), radius * math.sin(angle)
    local x2, y2 = radius * math.cos(angle2), radius * math.sin(angle2)
    hole:add((x + x1) * 1000, (y + y1) * 1000)
    hole:add((x + x2) * 1000, (y + y2) * 1000)
  end

  love.graphics.setCanvas(self.mask)
  love.graphics.push()
  love.graphics.translate(self.radius, self.radius)
  love.graphics.setColor(0, 0, 0)
  love.graphics.circle('fill', x, y, radius, segments)
  love.graphics.pop()
  love.graphics.setCanvas()

  love.graphics.setCanvas(self.canvas)
  love.graphics.push()
  love.graphics.translate(self.radius, self.radius)
  love.graphics.setColor(colorDark())
  love.graphics.circle('fill', x, y, radius + 1, segments)
  love.graphics.pop()
  love.graphics.setCanvas()

  local cl = clipper.new()
  cl:add_subject(self.polygons)
  cl:add_clip(hole)
  self.polygons = cl:execute('difference'):clean(100)
  for _, fixture in pairs(self.fixtures) do
    fixture:destroy()
  end
  local size = self.polygons:size()
  self.fixtures = {}
  for i = 1, size, 1 do
    if self.polygons:get(i):size() > 2 then
      self.fixtures[i] = love.physics.newFixture(self.body, love.physics.newChainShape(false, getPoints(self.polygons:get(i))), 0)
      self.fixtures[i]:setFriction(1)
    end
  end
end

function Planet:fill(x, y, radius)
  local hole = clipper.polygon()
  local segments = 16
  for i = 0, segments -1,2 do
    local angle = (2 * math.pi / segments) * i
    local angle2 = (2 * math.pi / segments) * (i + 1)
    local x1, y1 = radius * math.cos(angle), radius * math.sin(angle)
    local x2, y2 = radius * math.cos(angle2), radius * math.sin(angle2)
    hole:add((x + x1) * 1000, (y + y1) * 1000)
    hole:add((x + x2) * 1000, (y + y2) * 1000)
  end

  love.graphics.setCanvas(self.mask)
  love.graphics.push()
  love.graphics.translate(self.radius, self.radius)
  love.graphics.setColor(255, 255, 255)
  love.graphics.circle('fill', x, y, radius, segments)
  love.graphics.pop()
  love.graphics.setCanvas()

  local cl = clipper.new()
  cl:add_subject(self.polygons)
  cl:add_clip(hole)
  self.polygons = cl:execute('union'):clean(100)
  for _, fixture in pairs(self.fixtures) do
    fixture:destroy()
  end
  local size = self.polygons:size()
  self.fixtures = {}
  for i = 1, size, 1 do
    if self.polygons:get(i):size() > 2 then
      self.fixtures[i] = love.physics.newFixture(self.body, love.physics.newChainShape(false, getPoints(self.polygons:get(i))), 0)
      self.fixtures[i]:setFriction(1)
    end
  end
end

function getPoints(polygon)
  local size = polygon:size()
  local points = {}
  for i = 1, size, 1 do
    local point = polygon:get(i)
    table.insert(points, tonumber(point.x) / 1000)
    table.insert(points, tonumber(point.y) / 1000)
  end
  table.insert(points, points[1])
  table.insert(points, points[2])
  return points
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
  love.graphics.setColor(180, 205, 147, 128)
  love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.atmosphereFixture:getShape():getRadius())
  love.graphics.draw(self.atmosphereBatch, self.body:getX(), self.body:getY())
  love.graphics.setColor(colorLightGreen())
  -- love.graphics.draw(self.mesh, self.body:getX(), self.body:getY())
  -- love.graphics.setColor(255, 0, 255, 255)
  love.graphics.push()
  love.graphics.translate(self.body:getX(), self.body:getY())
  love.graphics.setLineWidth(1 / localPlayer.zoom)

  local function myStencilFunction()
    love.graphics.setShader(self.mask_shader)
    love.graphics.draw(self.mask, -self.radius, -self.radius)
    love.graphics.setShader()
  end
  love.graphics.stencil(myStencilFunction, "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  love.graphics.draw(self.canvas, -self.radius, -self.radius)
  love.graphics.setStencilTest()

  love.graphics.pop()

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
