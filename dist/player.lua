Player = {}
Player.__index = Player

function Player.new(x, y)
  local self = setmetatable({}, Player)

  self.x = x
  self.y = y
  self.width = 12
  self.height = 18
  self.body = love.physics.newBody(world, x, y, "dynamic")
  self.body:setFixedRotation(true)
  self.fixture = love.physics.newFixture(self.body, love.physics.newRectangleShape(0, 0, self.width, self.height), 1)
  self.shape = self.fixture:getShape()
  self.sprite = love.graphics.newImage("player2.png")
  self.sprite:setFilter("nearest")
  self.angle = self.body:getAngle()
  self.planet = {}

  return self
end

function Player.update(self, dt)
  local x, y = self.body:getLinearVelocity()
  local planetX, planetY = self.planet.body:getPosition()
  local playerX, playerY = self.body:getPosition()
  local px, py = vector.normalize(planetX - playerX, planetY - playerY)
  local length, angle = vector.polar(px, py)

  self.body:setAngle(angle + math.pi * 0.5)
  if love.keyboard.isDown("left") then
    local tx, ty = vector.cartesian(length, angle + math.pi * 0.5)
    self.body:setLinearVelocity(tx * 100, ty * 100)
  end

  if love.keyboard.isDown("right") then
    local tx, ty = vector.cartesian(length, angle - math.pi * 0.5)
    self.body:setLinearVelocity(tx * 100, ty * 100)
  end
end

function Player.draw(self)
  -- love.graphics.points(self.body:getPosition())
  love.graphics.setColor(255, 0, 0, 255)
  -- love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.push()
  love.graphics.translate(self.body:getPosition())
  love.graphics.push()
  love.graphics.rotate(self.body:getAngle() + math.pi)
  love.graphics.draw(self.sprite, self.width * -0.5, self.height * -0.5)
  love.graphics.pop()
  love.graphics.pop()
end

function Player.setPlanet(self, planet)
  self.planet = planet
end

function Player.beginContact(self)

end

function Player.endContact(self)

end

function Player.preSolve(self)

end

function Player.postSolve(self)

end
