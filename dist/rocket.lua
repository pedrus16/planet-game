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

-- command = action
Rocket.actions = {
  move_left = 'moveLeft',
  move_right = 'moveRight',
  move_up = 'moveUp',
  move_down = 'moveDown',
  use = 'ejectDriver',
  zoom_in = 'zoomIn',
  zoom_out = 'zoomOut',
}

function Rocket:_init(x, y, angle)
  GameObject:_init()

  self.type = 'rocket'
  self.power = 1000000000
  self.cooldown = 0
  self.driver = nil
  self.width = 28
  self.height = 52
  self.body = love.physics.newBody(world, x, y, "dynamic")
  self.body:setAngularDamping(0.1)
  self.body:setAngle(angle or 0)
  self.fixture = love.physics.newFixture(self.body, love.physics.newPolygonShape(16 - 16, 6 - 26, 28 - 16, 40 - 26, 29 - 16, 57 - 26, 2 - 16, 57 - 26, 3 - 16, 40 - 26), 1000000)
  self.fixture:setFriction(1)
  self.fixture:setUserData({ type = 'rocket', data = self })
  self.shape = self.fixture:getShape()
  self.angle = self.body:getAngle()
  -- self.inputs = {
  --   move_left = false,
  --   move_right = false,
  --   move_up = false,
  --   move_down = false,
  --   use = false,
  --   zoom_in = false,
  --   zoom_out = false
  -- }
  self.spritesheet = love.graphics.newImage("resources/rocket.png")
  self.spritesheet:setFilter("nearest")
  self.sprite = love.graphics.newQuad(2, 6, 28, 52, self.spritesheet:getDimensions())
  self.trajectory = {}

  return self
end

function Rocket:update(dt)

  if self.cooldown > 0 then
    self.cooldown = self.cooldown - dt
  end

  local step = 6/60
  local i
  local x, y = self.body:getPosition()
  local vx, vy = self.body:getLinearVelocity()

  self.trajectory = {x, y, x, y}
  local damping = 0
  for i = 3,3600,2 do
    local hit = false;
    for _, planet in pairs(planets) do

      local gx, gy = planet.body:getLocalPoint(x, y)
      local radius = planet.shape:getRadius() * planet.gravityFall
      local distance = vector.polar(gx, gy) - planet.shape:getRadius()
      local damping = 0
      if distance <= planet.atmosphereSize then
        damping = planet.density
      end
      gx, gy = vector.normalize(gx, gy)
      local a = planet.gravity * step * math.pow(radius / (radius + distance), 2)
      vx = vx + gx * -a - vx * damping * step
      vy = vy + gy * -a - vy * damping * step

      xn, yn, fraction = planet.fixture:rayCast(x, y, x + vx * step, y + vy * step, 1)
      if xn and yn and fraction then
        hitx, hity = x + (x + vx * step - x) * fraction, y + (y + vy * step - y) * fraction
        self.trajectory[i] = hitx
        self.trajectory[i + 1] = hity
        hit = true;
      end

    end

    if hit == true then
      break;
    end

    x = x + vx * step
    y = y + vy * step
    self.trajectory[i] = x
    self.trajectory[i + 1] = y
  end

  -- INPUTS
  -- for key, value in pairs(self.inputs) do
  --   if value == true then
  --     local functionName = Rocket.actions[key]
  --     if functionName ~= nil then
  --       self[functionName](self, dt)
  --     end
  --   end
  -- end

end

function Rocket:draw()

  love.graphics.push()
  love.graphics.translate(self.body:getPosition())
  love.graphics.push()

  -- local vx, vy = self.body:getLinearVelocity()
  -- local s, a = vector.polar(vx, vy)
  -- vx, vy = vector.cartesian(100, a)
  -- love.graphics.line(0, 0, vx, vy)

  love.graphics.setColor(180, 205, 147);
  love.graphics.rotate(self.body:getAngle())
  love.graphics.draw(self.spritesheet, self.sprite, 30 * -0.5, 40 * -0.5)

  love.graphics.pop()
  love.graphics.pop()

  if self.driver and self.driver == localPlayer then
    love.graphics.setLineWidth(1 / scale)
    love.graphics.setColor(255, 0, 0, 255)
    love.graphics.line(self.trajectory)
  end

  -- love.graphics.setPointSize(4)
  -- love.graphics.setColor(255, 0, 0, 255)
  -- love.graphics.points(self.body:getWorldPoint(0, self.height * 0.5))
end

-- function Rocket:keypressed(key, scancode, isrepeat)
--   local command = binding[key]
--   if command and self.inputs[command] ~= nil then
--     self.inputs[command] = true
--   end
-- end
--
-- function Rocket:keyreleased(key, scancode, isrepeat)
--   local command = binding[key]
--   if command and self.inputs[command] ~= nil then
--     self.inputs[command] = false
--   end
-- end

function Rocket:beginContact(a, b, coll)
end

function Rocket:endContact(a, b, coll)
end

function Rocket:moveUp(dt)
  if client then
    client.server:send('drive move_up')
  end
  local x, y = self.body:getWorldCenter(0, self.height * 0.5)
  local fx, fy = vector.cartesian(1, self.body:getAngle() - math.pi * 0.5)
  self.body:applyForce(fx * self.power, fy  * self.power, x, y)
end

function Rocket:moveDown(dt)
  if client then
    client.server:send('drive move_down')
  end
  local x, y = self.body:getWorldCenter(0, self.height * 0.5)
  local fx, fy = vector.cartesian(1, self.body:getAngle() + math.pi * 0.5)
  self.body:applyForce(fx * self.power, fy  * self.power, x, y)
end

function Rocket:moveLeft(dt)
  if client then
    client.server:send('drive move_left')
  end
  self.body:applyTorque(-1000000000)
end

function Rocket:moveRight(dt)
  if client then
    client.server:send('drive move_right')
  end
  self.body:applyTorque(1000000000)
end

function Rocket:setDriver(driver)
  if self.cooldown <= 0 then
    self.cooldown = 0.4
    self.driver = driver
    driver.drive = self
    driver.body:setActive(false)
    -- camera.body = self.body
  end
end

function Rocket:ejectDriver(dt)
  if client then
    client.server:send('drive use')
  end
  if self.cooldown <= 0 and self.driver then
    self.cooldown = 0.4
    self.driver.drive = nil
    self.driver.body:setActive(true)
    self.driver.body:setLinearVelocity(self.body:getLinearVelocity())
    camera.body = self.driver.body
    self.driver = nil
  end
end

function Rocket:beginContact(a, b, coll)
end

function Rocket:endContact(a, b, coll)
end

function Rocket:zoomIn(dt)
  self.driver.inputs['zoom_in'] = false
  if scale <= 16 then
    scale = scale * 2
  end
end

function Rocket:zoomOut(dt)
  self.driver.inputs['zoom_out'] = false
  if scale > 0 then
    scale = scale * 0.5
  end
end
