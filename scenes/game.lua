local components = require "modules.components"
local composer = require "composer"
local game = require "modules.game"
local levelClass = require "classes.level"
local navigation = require "modules.navigation"
local utils = require "modules.utils"

local ball = nil
local ballImpulseForce = nil
local fromMKS = physics.fromMKS
local gravityX = 0
local gravityY = 9.8
local level = nil
local numberOfShots = nil
local predictedBallPath = nil
local scene = composer.newScene()

local sounds = {
  ball = audio.loadSound("sounds/ball.wav"),
  collision = audio.loadSound("sounds/collision.wav"),
  targetDestroyed = audio.loadSound("sounds/target-destroyed.wav"),
}

local function gameOver()
  local configuration = level:configuration()
  local numberOfStars = 0
  if numberOfShots <= configuration.stars.three then
    numberOfStars = 3
  elseif numberOfShots <= configuration.stars.two then
    numberOfStars = 2
  elseif numberOfShots <= configuration.stars.one then
    numberOfStars = 1
  end
  level:saveScore(numberOfShots, numberOfStars)
  navigation.showGameOver(level, numberOfShots, numberOfStars)
end

local function takeLevelScreenshot()
  local screenshot = display.captureBounds(display.currentStage.contentBounds)
  local screenshotScale = screenshot.xScale * 0.33
  screenshot.xScale = screenshotScale
  screenshot.yScale = screenshotScale
  level:saveImage(screenshot, "screenshot")
  display.remove(screenshot)
end

function scene:create(event)
  level = event.params.level

  local objects = game.createLevel(self.view, level)
  physics.setGravity(gravityX, gravityY)
  ball = objects.ball
  numberOfShots = 0

  ball.postCollision = function(_, event)
    if event.force >= 2 then
      utils.playAudio(sounds.collision, event.force / 100)
    end
  end

  ball.angularDamping = 3.0
  ball.isBullet = true
  ball:addEventListener("postCollision")

  local numberOfTargets = #objects.targets

  for index = 1, numberOfTargets do
    local target = objects.targets[index]
    local targetResistance = 8

    if target.type == "easy" then
      targetResistance = targetResistance * 0.5
    elseif target.type == "hard" then
      targetResistance = targetResistance * 2
    end

    target.postCollision = function(_, event)
      if event.force < targetResistance then
        return
      end

      transition.to(target, { time = 100, alpha = 0.1, onComplete = physics.removeBody })
      target:removeEventListener("postCollision")
      numberOfTargets = numberOfTargets - 1
      utils.playAudio(sounds.targetDestroyed, 1.0)

      if (numberOfTargets == 0) then
        gameOver()
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
    local stepX = ball.x + time * ballImpulseForce.x + 0.5 * fromMKS("velocity", gravityX) * (time * time)
    local stepY = ball.y + time * ballImpulseForce.y + 0.5 * fromMKS("velocity", gravityY) * (time * time)

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
        ball:setLinearVelocity(_ballImpulseForce.x, _ballImpulseForce.y)
        numberOfShots = numberOfShots + 1
        utils.playAudio(sounds.ball, 0.4)
      elseif event.y <= display.screenOriginY + display.actualContentHeight * 0.4 then
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
  composer.showOverlay("scenes.pause", { isModal = true, params = { level = level } })
end

function scene:resume()
  physics.start()
  audio.resume()
end

function scene:show(event)
  if event.phase == "did" then
    Runtime:addEventListener("lateUpdate", scene)
    Runtime:addEventListener("touch", scene)
    physics.start()
    timer.performWithDelay(0, takeLevelScreenshot)
  end
end

function scene:hide(event)
  if event.phase == "did" then
    Runtime:removeEventListener("touch", scene)
    Runtime:removeEventListener("lateUpdate", scene)
    audio.stop()
    physics.stop()
    transition.cancel()
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
