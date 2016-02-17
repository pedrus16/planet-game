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

function Rocket:_init(x, y)
  GameObject:_init()

  self.power = 1000000000
  self.cooldown = 0
  self.driver = nil
  self.width = 28
  self.height = 52
  self.body = love.physics.newBody(world, x, y, "dynamic")
  self.fixture = love.physics.newFixture(self.body, love.physics.newPolygonShape(16 - 16, 6 - 26, 28 - 16, 40 - 26, 29 - 16, 57 - 26, 2 - 16, 57 - 26, 3 - 16, 40 - 26), 1000000)
  self.fixture:setFriction(1)
  self.fixture:setUserData({ type = 'rocket', data = self })
  self.shape = self.fixture:getShape()
  self.angle = self.body:getAngle()
  self.inputs = {
    move_left = false,
    move_right = false,
    move_up = false,
    move_down = false,
    use = false,
    zoom_in = false,
    zoom_out = false
  }
  self.spritesheet = love.graphics.newImage("resources/rocket.png")
  self.spritesheet:setFilter("nearest")
  self.sprite = love.graphics.newQuad(2, 6, 28, 52, self.spritesheet:getDimensions())

  return self
end

function Rocket:update(dt)

  if self.cooldown > 0 then
    self.cooldown = self.cooldown - dt
  end

  if self.driver then
    -- camera.x, camera.y = self.drive.body:getPosition()
    -- camera.angle = -self.drive.body:getAngle()
  end

  for key, value in pairs(self.inputs) do
    if value == true then
      local functionName = Rocket.actions[key]
      if functionName ~= nil then
        self[functionName](self, dt)
      end
    end
  end

end

function Rocket:draw()
  -- love.graphics.setColor(255, 0, 0, 255)
  -- love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))

  -- love.graphics.setLineStyle('rough')
  -- love.graphics.polygon("line", self.body:getWorldPoints(self.useShape:getPoints()))
  love.graphics.push()
  love.graphics.translate(self.body:getPosition())
  love.graphics.push()

  -- love.graphics.rotate(self.body:getAngle())
  local vx, vy = self.body:getLinearVelocity()
  local s, a = vector.polar(vx, vy)
  vx, vy = vector.cartesian(100, a)
  love.graphics.line(0, 0, vx, vy)

  love.graphics.setColor(180, 205, 147);
  love.graphics.rotate(self.body:getAngle())
  love.graphics.draw(self.spritesheet, self.sprite, 30 * -0.5, 40 * -0.5)

  love.graphics.pop()
  love.graphics.pop()

  -- love.graphics.setPointSize(4)
  -- love.graphics.setColor(255, 0, 0, 255)
  -- love.graphics.points(self.body:getWorldPoint(0, self.height * 0.5))
end

function Rocket:keypressed(key, scancode, isrepeat)
  local command = binding[key]
  if command and self.inputs[command] ~= nil then
    self.inputs[command] = true
  end
end

function Rocket:keyreleased(key, scancode, isrepeat)
  local command = binding[key]
  if command and self.inputs[command] ~= nil then
    self.inputs[command] = false
  end
end

function Rocket:beginContact(a, b, coll)
end

function Rocket:endContact(a, b, coll)
end

function Rocket:moveUp(dt)
  local x, y = self.body:getWorldCenter(0, self.height * 0.5)
  local fx, fy = vector.cartesian(1, self.body:getAngle() - math.pi * 0.5)
  self.body:applyForce(fx * self.power, fy  * self.power, x, y)
end

function Rocket:moveDown(dt)
  local x, y = self.body:getWorldCenter(0, self.height * 0.5)
  local fx, fy = vector.cartesian(1, self.body:getAngle() + math.pi * 0.5)
  self.body:applyForce(fx * self.power, fy  * self.power, x, y)
end

function Rocket:moveLeft(dt)
  self.body:applyTorque(-1000000000)
end

function Rocket:moveRight(dt)
  self.body:applyTorque(1000000000)
end

function Rocket:setDriver(driver)
  if self.cooldown <= 0 then
    self.cooldown = 0.4
    self.driver = driver
    driver.drive = self
    driver.body:setActive(false)
    camera.body = self.body
  end
end

function Rocket:ejectDriver(dt)
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
    self.inputs['zoom_in'] = false
    if scale <= 16 then
      scale = scale * 2
    end
end

function Rocket:zoomOut(dt)
    self.inputs['zoom_out'] = false
  if scale > 0 then
    scale = scale * 0.5
  end
end
