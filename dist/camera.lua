require "lib.vector"

Camera = {}
Camera.__index = Camera

setmetatable(Camera, {
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Camera:_init(body)
  self.x = 0
  self.y = 0
  self.angle = 0
  -- self.body = body
  -- self.mode = 'FOLLOW'

  return self
end

function Camera:update(dt)
  -- if self.body then
  --   self.x, self.y = self.body:getPosition()
  --   local x, y = self.body:getLinearVelocity()
  --   local speed, angle = vector.polar2cartesian(x, y)
  --
  --   if self.mode == 'SPEED' then
  --     self.angle = -angle - math.pi * 0.5
  --   end
  --
  -- end
end

function Camera:set()
  love.graphics.push()
  love.graphics.rotate(self.angle)
  love.graphics.translate(-self.x, -self.y)
end

function Camera:unset()
  love.graphics.pop()
end
