local components = require "modules.components"
local composer = require "composer"
local navigation = require "modules.navigation"
local stopwatchClass = require "classes.stopwatch"
local utils = require "modules.utils"

local ballImpulseForce = nil
local data = nil
local elements = nil
local fromMKS = physics.fromMKS
local gravityX = 0
local gravityY = 9.8
local level = nil
local mode = nil
local numberOfShots = nil
local predictedBallPath = nil
local scene = composer.newScene()
local screenX = display.screenOriginX
local screenY = display.screenOriginY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight

local sounds = {
  ball = audio.loadSound("sounds/ball.wav"),
  collision = audio.loadSound("sounds/collision.wav"),
  targetDestroyed = audio.loadSound("sounds/target-destroyed.wav"),
}

function scene:create(event)
  level = event.params.level
  mode = event.params.mode
  data = event.params.data

  physics.start()
  physics.pause()
  physics.setGravity(gravityX, gravityY)

  elements = level:createElements(self.view)
  numberOfShots = 0

  self:configureBall()
  self:configureFrame()
  self:configureObstacles()
  self:configureTargets()
end

function scene:configureBall()
  local ball = elements.ball

  physics.addBody(ball, { bounce = 0.5, density = 1.0, friction = 0.3, radius = ball.width / 2 - 1 })

  ball.angularDamping = 3.0
  ball.isBullet = true

  ball.postCollision = function(_, event)
    if event.force >= 2 then
      utils.playAudio(sounds.collision, event.force / 100)
    end
  end

  ball:addEventListener("postCollision")
end

function scene:configureFrame()
  physics.addBody(elements.frame, "static", {
    bounce = 0.5,
    density = 1.0,
    friction = 0.5,
    chain = { -150, -230, 150, -230, 150, 230, -150, 230 },
    connectFirstAndLastChainVertex = true,
  })
end

function scene:configureObstacles()
  for index = 1, #elements.obstacles do
    local obstacle = elements.obstacles[index]

    if obstacle.name == "corner" then
      local chain = {
        -50, -50, -49, -44, -47, -38, -45, -33, -41, -26, -35, -17, -27, -7, -20, 1, -14, 8,
        -8, 14, -1, 20, 7, 27, 17, 35, 26, 41, 33, 45, 38, 47, 44, 49, 50, 50, -50, 50, -50, -50
      }

      for i = 1, #chain, 2 do
        chain[i] = chain[i] * obstacle.width / 100
        chain[i + 1] = chain[i + 1] * obstacle.height / 100
      end

      physics.addBody(obstacle, "static", { bounce = 0.5, density = 1.0, friction = 0.3, chain = chain })

    elseif obstacle.name:starts("horizontal-barrier") or obstacle.name:starts("vertical-barrier") then
      physics.addBody(obstacle, "static", { bounce = 0.5, density = 1.0, friction = 0.3 })
    end
  end
end

function scene:configureTargets()
  local numberOfTargets = #elements.targets

  for index = 1, numberOfTargets do
    local target = elements.targets[index]
    target.resistance = ({ easy = 4, normal = 8, hard = 16 })[target.name]

    physics.addBody(target, "static", { bounce = 0.5, density = 1.0, friction = 0.3 })

    target.postCollision = function(_, event)
      if event.force < target.resistance then
        return
      end

      transition.to(target, { time = 100, alpha = 0.1, onComplete = physics.removeBody })
      target:removeEventListener("postCollision")
      numberOfTargets = numberOfTargets - 1
      utils.playAudio(sounds.targetDestroyed, 1.0)

      if (numberOfTargets == 0) then
        self:gameOver()
      end
    end

    target:addEventListener("postCollision")
  end
end

function scene:lateUpdate()
  if not ballImpulseForce then
    return
  end

  display.remove(predictedBallPath)

  if not ballImpulseForce.hasEnoughForce then
    return
  end

  predictedBallPath = components.newGroup(self.view)

  local timeStepInterval = 0.05
  local numberOfSteps = 1 / timeStepInterval
  local prevStepX = nil
  local prevStepY = nil

  for step = 0, numberOfSteps, 1 do
    local time = step * timeStepInterval
    local stepX = elements.ball.x + time * ballImpulseForce.x + 0.5 * fromMKS("velocity", gravityX) * (time * time)
    local stepY = elements.ball.y + time * ballImpulseForce.y + 0.5 * fromMKS("velocity", gravityY) * (time * time)

    if step > 0 and physics.rayCast(prevStepX, prevStepY, stepX, stepY, "any") then
      break
    end

    prevStepX = stepX
    prevStepY = stepY

    local circle = display.newCircle(predictedBallPath, stepX, stepY, 2)
    circle.strokeWidth = 1
    circle:setStrokeColor(0.25, 0.25, 0.25)
  end
end

function scene:touch(event)
  local distanceX = event.xStart - event.x
  local distanceY = event.yStart - event.y
  local totalDistance = math.sqrt(distanceX * distanceX + distanceY * distanceY)
  local _ballImpulseForce = { x = distanceX * 4, y = distanceY * 4, hasEnoughForce = totalDistance > 10 }

  ballImpulseForce = nil

  if event.phase == "ended" or event.phase == "cancelled" then
    display.remove(predictedBallPath)
    predictedBallPath = nil
    if event.phase == "ended" then
      if _ballImpulseForce.hasEnoughForce then
        elements.ball:setLinearVelocity(_ballImpulseForce.x, _ballImpulseForce.y)
        numberOfShots = numberOfShots + 1
        utils.playAudio(sounds.ball, 0.4)
      elseif event.y <= screenY + screenHeight * 0.33 then
        self:pause()
      end
    end
  elseif event.phase == "moved" then
    ballImpulseForce = _ballImpulseForce
  end

  return true
end

function scene:pause()
  audio.pause()
  physics.pause()

  if mode == "speedrun" then
    data.stopwatch:pause()
  end

  composer.showOverlay("scenes.pause", { isModal = true, params = { level = level, mode = mode, data = data } })
end

function scene:resume()
  physics.start()
  audio.resume()

  if mode == "speedrun" then
    data.stopwatch:start()
  end
end

function scene:gameOver()
  local configuration = level:configuration()
  local numberOfStars = 0

  if numberOfShots <= configuration.stars.three then
    numberOfStars = 3
  elseif numberOfShots <= configuration.stars.two then
    numberOfStars = 2
  elseif numberOfShots <= configuration.stars.one then
    numberOfStars = 1
  end

  if mode == "classic" then
    data.numberOfShots = numberOfShots
    data.numberOfStars = numberOfStars
  elseif mode == "speedrun" then
    data.stopwatch:pause()
    data.levels[level.name].endTime = data.stopwatch:totalTime()
    data.levels[level.name].numberOfStars = numberOfStars
  end

  level:saveScore(numberOfShots, numberOfStars)
  navigation.showGameOver(level, mode, data)
end

function scene:show(event)
  if event.phase == "did" then
    level:takeScreenshot()

    Runtime:addEventListener("lateUpdate", scene)
    Runtime:addEventListener("touch", scene)
    physics.start()

    if mode == "classic" then
      data = {}
    elseif mode == "speedrun" then
      data.stopwatch = data.stopwatch or stopwatchClass:new()
      utils.nestedGetOrSet(data, "levels", level.name, { startTime = data.stopwatch:totalTime() })
      data.stopwatch:start()
    end
  end
end

function scene:hide(event)
  if event.phase == "will" then
    Runtime:removeEventListener("touch", scene)
    Runtime:removeEventListener("lateUpdate", scene)
    display.remove(predictedBallPath)
  elseif event.phase == "did" then
    audio.stop()
    physics.stop()
    transition.cancelAll()
    composer.removeScene("scenes.game")
  end
end

function scene:destroy(event)
  for key, _ in pairs(sounds) do
    audio.dispose(sounds[key])
    sounds[key] = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
