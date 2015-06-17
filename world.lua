World = {
  gravity = 0.8,
  velocity = -10,
  queue_offset = -30,
  queue_speed = 120,
  ground = 0,

  -- x, w, h, float.
  levels = {
    { {160, 20, 20, 0}, {360, 20, 20, 0}, {600, 20, 20, 0} },
    { {120, 20, 20, 0}, {300, 20, 20, 0}, {400, 20, 20, 0}, {520, 20, 30, 0}, {700, 35, 15, 0} },
    { {110, 20, 20, 0}, {200, 20, 20, 0}, {290, 20, 20, 0}, {350, 100, 5, 29}, {490, 35, 12, 0}, {600, 20, 40, 0}, {740, 20, 30, 0} },
    { {100, 200, 4, 27}, {340, 40, 10, 0}, {350, 20, 10, 10}, {420, 200, 4, 17}, {660, 30, 30, 0} },
    { {120, 20, 20, 0}, {190, 20, 20, 0}, {260, 20, 20, 0}, {330, 20, 20, 0}, {400, 20, 20, 0}, {490, 20, 20, 0}, {560, 20, 20, 0}, {630, 20, 20, 0}, {700, 20, 20, 0}, {770, 20, 20, 0} },
  }
}

function World:new(o)
  o = o or {}

  setmetatable(o, self)
  self.__index = self

  return o
end

function World:moveQueue(dt)
  self.queue_offset = self.queue_offset + (self.queue_speed * dt)
end

function World:queueHitGround()
  return self.queue_offset > -6
end

function World:resetQueue()
  self.queue_offset = -30
end
