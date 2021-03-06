Corpse = {
  x = 0,
  y = 0,
  offset = 0,
  scale = 1,
  alpha = 255
}

function Corpse:new(o)
  o = o or {}

  setmetatable(o, self)
  self.__index = self

  return o
end

function Corpse:progress(dt)
  local next_alpha = self.alpha - (800 * dt)
  local progress = (next_alpha >= 0)

  if progress then
    self.offset = self.offset + (20 * dt)
    self.scale = self.scale + (20 * dt)
    self.alpha = next_alpha
  end

  return progress
end
