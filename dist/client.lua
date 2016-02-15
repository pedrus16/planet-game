Client = {}
Client.__index = Client

setmetatable(Client, {
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Client:_init(address)

  self.host = enet.host_create()
  self.server = self.host:connect(address)
  self.timer = 0
  self.tickRate = 60

  return self
end

function Client:update(dt)

  self.timer = self.timer + dt
  if self.host and self.timer > (1 / self.tickRate) then
    local event = self.host:service()
    while event do
      self:handleEvent(event)
      event = self.host:service()
    end
  end

end

function Client:handleEvent(event)

  if event.type == 'receive' then
    cmd, params = event.data:match("^(%S*) (.*)")
    if cmd == 'up' then -- Update player position

      local x, y = params:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
      localPlayer.body:setPosition(tonumber(x), tonumber(y))

    elseif cmd == "up2" then

      local id, x, y, vX, vY = params:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*)$")
      if tonumber(id) == -1 then
        localPlayer.body:setPosition(tonumber(x), tonumber(y))
      elseif players[id] then
        players[id].body:setPosition(tonumber(x), tonumber(y))
      else
       local newPlayer = Player(tonumber(x), tonumber(y))
       newPlayer.planet = planet1
       players[id] = newPlayer
       table.insert(objects, newPlayer)
      end

    elseif cmd == 'pl' then -- Create a player

      local id, x, y = params:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*)$")
      local newPlayer = Player(tonumber(x), tonumber(y))
      players[id] = newPlayer
      newPlayer.planet = planet1
      table.insert(objects, newPlayer)

    end

  end

end
