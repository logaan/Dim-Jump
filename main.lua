require "lib/fun" ()
require "player"
require "world"

function love.load(a)
  love.graphics.setBackgroundColor(171, 205, 236)
  love.graphics.setColor(255, 255, 255, 255)
  love.audio.setVolume(0.1)
  love.keyboard.setKeyRepeat(true)

  title = love.graphics.newImage("assets/title.png")
  blood = love.graphics.newImage("assets/blood.png")
  dimQueue = love.graphics.newImage("assets/dim_queue.png")
  splatSfx = love.audio.newSource("assets/sounds/splat.wav")

  fonts = {
    small = love.graphics.newFont("assets/addstandard.ttf", 18),
    big = love.graphics.newFont("assets/addstandard.ttf", 42)
  }

  love.graphics.setFont(fonts.small)

  local jumpDir = "assets/sounds/jumps/"
  jumpSfx = map(function (f)
    return love.audio.newSource(jumpDir..f)
  end, love.filesystem.getDirectoryItems(jumpDir))

  world = World:new{ground=love.graphics.getHeight() - 80}
  player = Player:new{world=world}
end

updates = 0
draws = 0
keypresses = 0
startTime = os.time()
lastKey = ""

function drawDebug()
  seconds = os.time() - startTime
  love.graphics.print(updates    / seconds, 30, 10)
  love.graphics.print(draws      / seconds, 30, 25)
  love.graphics.print(keypresses / seconds, 30, 40)
  love.graphics.print(os.time() - startTime, 30, 55)

  love.graphics.print(tostring(love.keyboard.isDown(" ")), 230, 10)
  love.graphics.print(lastKey, 230, 25)
end

function pressedKey()
  if love.keyboard.isDown(" ") then
    return keypressed(" ")
  elseif love.keyboard.isDown("up") then
    return keypressed("up")
  elseif love.keyboard.isDown("down") then
    return keypressed("down")
  end
end

function love.update(dt)
  updates = updates + 1

  pressedKey()

  if not player.alive then
    return
  end

  if not player.visible then
    world:moveQueue(dt)

    if world:queueHitGround() then
      player.visible = true
      world:resetQueue()
    end
  else
    local obstacles = world.levels[player.level]

    player.animation:update(dt)
    player:accellerate(dt, love.graphics.getWidth())

    for i, o in ipairs(obstacles) do
      if collision(o) then
        world:addCollisionPoint(i, player.x - (player.w / 2), player.y - (player.h / 6))
        love.audio.play(splatSfx)
        player:kill()
      end
    end

    if player.jumping then
      player:progressJump(dt)
    end

    if love.keyboard.isDown("down") and not (player.jumping or player.ducking) then
      player:duck()
    end
  end

  for i, c in ipairs(player.corpses) do
    if not c:progress(dt) then
      player:removeCorpse(i)
    end
  end
end

function love.draw(dt)
  draws = draws + 1
  if player.alive then
    drawFloor()
    drawLevel()
    drawUI()
    drawQueue()
    drawCorpses()
    drawDebug()

    if player.visible then
      drawPlayer()
    end
  else
    drawUI()
  end
end

--function love.keypressed(key, isrepeat)
--  keypressed(key)
--end

function keypressed(key)
  lastKey = key
  keypresses = keypresses + 1

  if key == "up" or key == " " then
    if player.alive and not player.jumping then
        local sfx = nth(math.random(length(jumpSfx)), jumpSfx)

      love.audio.play(sfx)
      player:jump()
    elseif not player.alive then
      player = Player:new{world=world}
    end
  end
end

function love.keyreleased(key)
  if key == "down" and player.ducking then
    player:stand()
  end
end

function drawQueue()
  love.graphics.draw(dimQueue, 5, world.queueOffset)
end

function drawPlayer()
  local tx, ty = 0, 0

  if player.jumping then
    tx = (player.w / 2) - player.rotation
    ty = (player.h / 2) - player.rotation
  end

  if player.lifeAlpha > 0 then
    withColour(118, 101, 255, player.lifeAlpha, function ()
      love.graphics.printf(player.deaths + 1, player.x, player.y - 20, 1000, "left", player.rotation, 1, 1, tx, ty)
    end)
  end

  player.animation:draw(player.spritesheet, player.x, player.y, player.rotation, 1, 1, tx, ty)
end

function drawFloor()
  love.graphics.rectangle("fill", 0, world.ground, love.graphics.getWidth(), world.ground)
end

function drawLevel()
  local obstacles = world.levels[player.level]
  local r

  for i, o in ipairs(obstacles) do
    r = function ()
      for _, p in pairs(love.math.triangulate(o[3])) do
        love.graphics.polygon("fill", p)
      end
    end

    r()
    love.graphics.setStencil(r)

    for _, pos in ipairs(world.collisionPoints[i]) do
      love.graphics.draw(blood, pos[1], pos[2])
    end

    love.graphics.setStencil()
  end
end

function drawCorpses()
  for _, c in ipairs(player.corpses) do
    withColour(255, 255, 255, c.alpha, function ()
      player.animation:draw(player.spritesheet, c.x, c.y, 0, c.scale, c.scale, c.offset, c.offset)
    end)
  end
end

function drawUI()
  if player.alive then
    love.graphics.draw(title, 10, love.graphics.getHeight() - title:getHeight() - 10)

    withColour(226, 182, 128, 255, function ()
      love.graphics.print("Level " .. player.level, title:getWidth() + 30, love.graphics.getHeight() - 24)
    end)
  else
    withColour(186, 142, 88, 255, function ()
      withFont("big", function ()
        printInCenter("Press UP to play again")
      end)
    end)
  end
end

function collision(o)
  local ox, oy, ow, oh = o[3][1], o[3][2], o[1], o[2]

  return player.x < (ox + ow) and
    ox < (player.x + player.w) and
    player.y < (oy + oh) and
    oy < (player.y + player.h)
end

function collisionFound()
  local obstacles = world.levels[player.level]
  return any(collision, obstacles)
end

function withColour(r, g, b, a, f)
  local _r, _g, _b, _a = love.graphics.getColor()

  love.graphics.setColor(r, g, b, a)
  f()
  love.graphics.setColor(_r, _g, _b, _a)
end

function withFont(name, f)
  local _f = love.graphics.getFont()

  love.graphics.setFont(fonts[name])
  f()
  love.graphics.setFont(_f)
end

function printInCenter(s)
  local f = love.graphics.getFont()
  local fw = f:getWidth(s)
  local fh = f:getHeight(s)

  love.graphics.print(s, (love.graphics.getWidth() / 2) - (fw / 2), (love.graphics.getHeight() / 2) - (fh / 2))
end
