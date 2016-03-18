Server = {}
Server.__index = Server

setmetatable(Server, {
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Server:_init(address)

  self.host = enet.host_create(address)
  self.timer = 0
  self.tickRate = 60

  -- table.insert(objects, Rocket(50, -32))
  -- table.insert(objects, Rocket(-150, -32))

  return self
end

function Server:update(dt)
  self.timer = self.timer + dt
  if self.host and self.timer > (1 / self.tickRate) then
    local event = self.host:service()
    while event do
      self:handleEvent(event)
      event = self.host:service()
    end

    self:sendUpdates()

    self.timer = self.timer - (1 / self.tickRate)
  end
end

function Server:handleEvent(event)

  if event.type == 'connect' then

    local player = Player(0, -10)
    player.planet = planet1
    local clientID = event.peer:index()
    players[clientID] = player
    table.insert(objects, player)
    local x, y = player.body:getPosition()
    -- Send the players positions
    local x, y = localPlayer.body:getPosition()
    event.peer:send(string.format("%s %f %f %f", 'pl', 0, x, y))
    for id, object in pairs(objects) do
      local x, y = object.body:getPosition()
      local a = object.body:getAngle()
      if object:type() ~= 'Player' then
        self.host:broadcast(string.format("%s %d %f %f %f", object:type(), id, x, y, a))
      end
    end
    for id, player in pairs(players) do
      local x, y = player.body:getPosition()
      if id ~= clientID then
        event.peer:send(string.format("%s %d %f %f", 'pl', id, x, y))
      end
    end

  end

  if event.type == 'receive' then

    cmd, input = event.data:match("^(%S*) (.*)")
    if cmd == 'action' then
      player = players[tonumber(event.peer:index())]
      if player and player.inputs[input] ~= nil then
        player:executeAction(input, 0)
      end
    end

  end

end

function Server:sendUpdates()

  if localPlayer.body:isAwake() then
    local x, y = localPlayer.body:getPosition()
    local vX, vY = localPlayer.body:getLinearVelocity()
    self.host:broadcast(string.format("%s %f %f %f %f %f", 'up2', 0, x, y, vX, vY))
  end
  for index,_ in pairs(players) do
    local client = self.host:get_peer(index)
    if client then
      for id, player in pairs(players) do
        if id == index then
          id = -1
        end
        if player.body:isAwake() then
          local x, y = player.body:getPosition()
          local vX, vY = player.body:getLinearVelocity()
          client:send(string.format("%s %d %f %f %f %f", 'up2', id, x, y, vX, vY))
        end
      end

      for id, object in pairs(objects) do
        if object.body:isAwake() then
          local x, y = object.body:getPosition()
          local vX, vY = object.body:getLinearVelocity()
          local angle = object.body:getAngle()
          client:send(string.format("%s %d %f %f %f %f %f", 'up3', id, x, y, vX, vY, angle))
        end
      end
    end
  end
  self.host:flush()

end
