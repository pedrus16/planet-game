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

    local player = Player(0, -900)
    player.planet = planet1
    local clientID = event.peer:index()
    players[clientID] = player
    table.insert(objects, player)
    local x, y = player.body:getPosition()
    -- Send the players positions
    local x, y = localPlayer.body:getPosition()
    event.peer:send(string.format("%s %d %d %d", 'pl', 0, x, y))
    for id, player in pairs(players) do
      local x, y = player.body:getPosition()
      if id ~= clientID then
        event.peer:send(string.format("%s %d %d %d", 'pl', id, x, y))
      end
    end

  end

  if event.type == 'receive' then

    cmd, params = event.data:match("^(%S*) (.*)")
    if cmd == 'action' then
      player = players[tonumber(event.peer:index())]
      if player and player.inputs[params] ~= nil then
        local functionName = Player.actions[params]
        if functionName ~= nil then
          player[functionName](player, dt)
        end
      end
    end

  end

end

function Server:sendUpdates()

  if localPlayer.body:isAwake() then
    local x, y = localPlayer.body:getPosition()
    local vX, vY = localPlayer.body:getLinearVelocity()
    self.host:broadcast(string.format("%s %d %d %d %d %d", 'up2', 0, x, y, vX, vY))
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
          client:send(string.format("%s %d %d %d %d %d", 'up2', id, x, y, vX, vY))
        end
      end
    end
  end
  self.host:flush()
  
end
