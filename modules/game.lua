local game = {}

local function createBackground(parent, level)
  local background = level:newBackground(parent, 300, 460)
  background.anchorX = 0
  background.anchorY = 0
  background:translate(10, 10)
  return background
end

local function createBall(parent, level)
  local configuration = level:configuration()
  local ball = level:newBall(parent, 30, 30)
  ball.x = 10 + configuration.ball.x
  ball.y = 10 + configuration.ball.y - 15

  physics.addBody(ball, {
    bounce = 0.5,
    density = 1.0,
    friction = 0.3,
    radius = ball.width / 2 - 1,
  })

  return ball
end

local function createFrame(parent, level)
  local frame = level:newFrame(parent, display.actualContentWidth, display.actualContentHeight)
  frame.anchorX = 0
  frame.anchorY = 0
  frame.x = display.screenOriginX
  frame.y = display.screenOriginY

  physics.addBody(frame, "static", {
    bounce = 0.5,
    density = 1.0,
    friction = 0.5,
    chain = { -150, -230, 150, -230, 150, 230, -150, 230 },
    connectFirstAndLastChainVertex = true,
  })

  return frame
end

local function createObstacles(parent, level)
  local configuration = level:configuration()
  local obstacles = {}

  for index, configuration in ipairs(configuration.obstacles) do
    if configuration.type == "corner" then
      local corner = level:newObstacleCorner(parent, configuration.width, configuration.height)
      corner.x = 10 + configuration.x + corner.width / 2
      corner.y = 10 + configuration.y + corner.height / 2
      corner.rotation = configuration.rotation
      obstacles[index] = corner

      local chain = {
        -50, -50, -49, -44, -47, -38, -45, -33, -41, -26, -35, -17, -27, -7, -20, 1, -14, 8,
        -8, 14, -1, 20, 7, 27, 17, 35, 26, 41, 33, 45, 38, 47, 44, 49, 50, 50, -50, 50, -50, -50
      }
      for i = 1, #chain, 2 do
        chain[i] = chain[i] * corner.width / 100
        chain[i + 1] = chain[i + 1] * corner.height / 100
      end

      physics.addBody(corner, "static", {
        bounce = 0.5,
        density = 1.0,
        friction = 0.3,
        chain = chain,
      })

    elseif configuration.type:starts("horizontal-barrier") or configuration.type:starts("vertical-barrier") then
      local barrier = level:newObstacleBarrier(parent, configuration.type, configuration.width, configuration.height)
      barrier.anchorChildren = true
      barrier.anchorX = 0
      barrier.anchorY = 0
      barrier.x = 10 + configuration.x
      barrier.y = 10 + configuration.y
      obstacles[index] = barrier

      physics.addBody(barrier, "static", {
        bounce = 0.5,
        density = 1.0,
        friction = 0.3,
      })
    end
  end

  return obstacles
end

local function createTargets(parent, level)
  local configuration = level:configuration()
  local targets = {}

  for index, configuration in ipairs(configuration.targets) do
    local target = level:newTarget(parent, configuration.type, configuration.width, configuration.height)
    target.anchorChildren = true
    target.anchorX = 0
    target.anchorY = 0
    target.x = 10 + configuration.x
    target.y = 10 + configuration.y
    target.type = configuration.type
    targets[index] = target

    physics.addBody(target, "static", {
      bounce = 0.5,
      density = 1.0,
      friction = 0.3,
    })
  end

  return targets
end

game.createLevel = function(parent, level)
  local configuration = level:configuration()
  local objects = {}

  physics.start()
  physics.pause()

  objects.frame = createFrame(parent, level)
  objects.background = createBackground(parent, level)
  objects.obstacles = createObstacles(parent, level)
  objects.targets = createTargets(parent, level)
  objects.ball = createBall(parent, level)

  return objects
end

return game
