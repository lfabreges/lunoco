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
  return ball
end

local function createFrame(parent, level)
  local frame = level:newFrame(parent, display.actualContentWidth, display.actualContentHeight)
  frame.anchorX = 0
  frame.anchorY = 0
  frame.x = display.screenOriginX
  frame.y = display.screenOriginY
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
      corner.type = configuration.type
      obstacles[index] = corner
    elseif configuration.type:starts("horizontal-barrier") or configuration.type:starts("vertical-barrier") then
      local barrier = level:newObstacleBarrier(parent, configuration.type, configuration.width, configuration.height)
      barrier.anchorChildren = true
      barrier.anchorX = 0
      barrier.anchorY = 0
      barrier.x = 10 + configuration.x
      barrier.y = 10 + configuration.y
      barrier.type = configuration.type
      obstacles[index] = barrier
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
  end
  return targets
end

game.createLevelElements = function(parent, level)
  local configuration = level:configuration()
  local elements = {}
  elements.frame = createFrame(parent, level)
  elements.background = createBackground(parent, level)
  elements.obstacles = createObstacles(parent, level)
  elements.targets = createTargets(parent, level)
  elements.ball = createBall(parent, level)
  return elements
end

game.createLevelConfiguration = function(elements)
  local configuration = {}
  configuration.ball = { x = elements.ball.x - 10, y = elements.ball.y + 5 }
  configuration.obstacles = {}
  configuration.targets = {}

  for index = 1, #elements.obstacles do
    local obstacle = elements.obstacles[index]
    if obstacle.type == "corner" then
      configuration.obstacles[index] = {
        type = obstacle.type,
        x = obstacle.x - 10 - obstacle.width / 2,
        y = obstacle.y - 10 - obstacle.height / 2,
        width = obstacle.width,
        height = obstacle.height,
        rotation = obstacle.rotation,
      }
    elseif obstacle.type:starts("horizontal-barrier") or obstacle.type:starts("vertical-barrier") then
      configuration.obstacles[index] = {
        type = obstacle.type,
        x = obstacle.x - 10,
        y = obstacle.y - 10,
        width = obstacle.width,
        height = obstacle.height,
      }
    end
  end

  for index = 1, #elements.targets do
    local target = elements.targets[index]
    configuration.targets[index] = {
      type = target.type,
      x = target.x - 10,
      y = target.y - 10,
      width = target.width,
      height = target.height,
    }
  end

  return configuration
end

return game
