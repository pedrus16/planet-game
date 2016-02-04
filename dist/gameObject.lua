GameObject = {}
GameObject.__index = GameObject

setmetatable(GameObject, {
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function GameObject:_init()

end

function GameObject:update(dt)

end

function GameObject:draw()

end
