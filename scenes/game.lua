local components = require "components"
local composer = require "composer"
local navigation = require "navigation"
local utils = require "utils"

local ball = nil
local ballImpulseForce = nil
local config = nil
local gravityX = 0
local gravityY = 9.8
local level = nil
local levelName = nil
local numberOfShots = nil
local predictedBallPath = nil
local scale = 30
local scene = composer.newScene()

local sounds = {
  ball = audio.loadSound("sounds/ball.wav"),
  collision = audio.loadSound("sounds/collision.wav"),
  targetDestroyed = audio.loadSound("sounds/target-destroyed.wav"),
}

local function gameOver()
  local numberOfStars = 0

  if numberOfShots <= config.stars.three then
    numberOfStars = 3
  elseif numberOfShots <= config.stars.two then
    numberOfStars = 2
  elseif numberOfShots <= config.stars.one then
    numberOfStars = 1
  end

  local scores = utils.loadScores()

  if (not scores[levelName] or scores[levelName].numberOfShots > numberOfShots) then
    scores[levelName] = { numberOfShots = numberOfShots, numberOfStars = numberOfStars }
    utils.saveScores(scores)
  end

  composer.showOverlay("scenes.game-over", {
    isModal = true,
    effect = "crossFade",
    time = 500,
    params = {
      levelName = levelName,
      numberOfShots = numberOfShots,
      numberOfStars = numberOfStars,
    },
  })
end

local function handleBallImpulseOnScreenTouch(event)
  local distanceX = event.xStart - event.x
  local distanceY = event.yStart - event.y
  local totalDistance = math.sqrt(distanceX * distanceX + distanceY * distanceY)
  local _ballImpulseForce = { x = distanceX * 4, y = distanceY * 4, hasEnoughForce = totalDistance > 10 }

  ballImpulseForce = nil

  if event.phase == "began" then
    display.getCurrentStage():setFocus(event.target)
  elseif event.phase == "ended" or event.phase == "cancelled" then
    display.getCurrentStage():setFocus(nil)
    display.remove(predictedBallPath)
    predictedBallPath = nil

    if event.phase == "ended" and _ballImpulseForce.hasEnoughForce then
      ball:setLinearVelocity(_ballImpulseForce.x, _ballImpulseForce.y)
      numberOfShots = numberOfShots + 1
      utils.playAudio(sounds.ball, 0.4)
    end
  elseif event.phase == "moved" then
    ballImpulseForce = _ballImpulseForce
  end

  return true
end

local function predictBallPathOnLateUpdate()
  if not ballImpulseForce then
    return false
  end

  display.remove(predictedBallPath)

  if not ballImpulseForce.hasEnoughForce then
    return false
  end

  predictedBallPath = components.newGroup(level)

  local timeStepInterval = 0.05
  local numberOfSteps = 1 / timeStepInterval
  local prevStepX = nil
  local prevStepY = nil

  for step = 0, numberOfSteps, 1 do
    local time = step * timeStepInterval
    local stepX = ball.x + time * ballImpulseForce.x + 0.5 * gravityX * scale * (time * time)
    local stepY = ball.y + time * ballImpulseForce.y + 0.5 * gravityY * scale * (time * time)

    if step > 0 and physics.rayCast(prevStepX, prevStepY, stepX, stepY, "any") then
      break
    end

    prevStepX = stepX
    prevStepY = stepY

    display.newCircle(predictedBallPath, stepX, stepY, 2)
  end
end

local function takeLevelScreenshot()
  local screenshot = display.captureBounds(display.currentStage.contentBounds)
  local screenshotScale = screenshot.xScale * 0.33
  screenshot:scale(screenshotScale, screenshotScale)
  utils.saveLevelImage(screenshot, levelName, "screenshot")
  display.remove(screenshot)
end

function scene:create(event)
  local screenX = display.screenOriginX
  local screenY = display.screenOriginY
  local screenWidth = display.actualContentWidth
  local screenHeight = display.actualContentHeight

  local tapRectangle = display.newRect(self.view, screenX, screenY, screenWidth, screenHeight * 0.25)
  tapRectangle.anchorX = 0
  tapRectangle.anchorY = 0
  tapRectangle.alpha = 0
  tapRectangle.isHitTestable = true
  tapRectangle:addEventListener("tap", scene.pauseOnTap)

  local touchRectangle = display.newRect(self.view, screenX, screenY + screenHeight, screenWidth, screenHeight * 0.75)
  touchRectangle.anchorX = 0
  touchRectangle.anchorY = 1
  touchRectangle.alpha = 0
  touchRectangle.isHitTestable = true
  touchRectangle:addEventListener("touch", handleBallImpulseOnScreenTouch)
end

function scene:createLevel()
  physics.start()
  physics.pause()
  physics.setScale(scale)
  physics.setGravity(gravityX, gravityY)

  level = components.newGroup(self.view)

  self:createFrame()
  self:createBackground()
  self:createObstacles()
  self:createTargets()
  self:createBall()

  numberOfShots = 0
end

function scene:createBackground()
  local background = components.newLevelBackground(level, levelName, 300, 460)
  background.anchorX, background.anchorY = 0, 0
  background:translate(10, 10)
end

function scene:createBall()
  ball = components.newBall(level, levelName, 30, 30)

  ball.x = 10 + config.ball.x
  ball.y = 10 + config.ball.y - 15

  ball.postCollision = function(self, event)
    if event.force >= 2 then
      utils.playAudio(sounds.collision, event.force / 100)
    end
  end

  physics.addBody(ball, { radius = ball.width / 2 - 1, density = 1.0, friction = 0.3, bounce = 0.5 })
  ball.angularDamping = 1.5

  ball:addEventListener("postCollision")
end

function scene:createFrame()
  local frame = components.newFrame(level, levelName, display.actualContentWidth, display.actualContentHeight)
  frame.anchorX = 0
  frame.anchorY = 0
  frame.x = display.screenOriginX
  frame.y = display.screenOriginY

  physics.addBody(frame, "static", {
    density = 1.0,
    friction = 0.5,
    bounce = 0.5,
    chain = { -150, -230, 150, -230, 150, 230, -150, 230 },
    connectFirstAndLastChainVertex = true,
  })
end

function scene:createObstacles()
  for _, config in ipairs(config.obstacles) do
    if config.type == "corner" then
      local corner = components.newObstacleCorner(level, levelName, config.width, config.height)

      corner.type = "corner"
      corner.x = 10 + config.x + corner.width / 2
      corner.y = 10 + config.y + corner.height / 2
      corner.rotation = config.rotation

      local chain = {
        -50, -50, -49, -44, -47, -38, -45, -33, -41, -26, -35, -17, -27, -7, -20, 1, -14, 8,
        -8, 14, -1, 20, 7, 27, 17, 35, 26, 41, 33, 45, 38, 47, 44, 49, 50, 50, -50, 50, -50, -50
      }

      local scaledChain = {}

      for i = 1, #chain, 2 do
        scaledChain[i] = chain[i] * config.width / 100
        scaledChain[i + 1] = chain[i + 1] * config.height / 100
      end

      physics.addBody(corner, "static", { density = 1.0, friction = 0.3, bounce = 0.5, chain = scaledChain })

    elseif config.type:starts("horizontal-barrier") or config.type:starts("vertical-barrier") then
      local barrier = components.newObstacleBarrier(level, levelName, config.type, config.width, config.height)

      barrier.type = "barrier"
      barrier.anchorChildren = true
      barrier.anchorX = 0
      barrier.anchorY = 0
      barrier.x = 10 + config.x
      barrier.y = 10 + config.y

      physics.addBody(barrier, "static", { density = 1.0, friction = 0.3, bounce = 0.5 })
    end
  end
end

function scene:createTargets()
  local numberOfTargets = 0

  for _, config in ipairs(config.targets) do
    local target = components.newTarget(level, levelName, config.type, config.width, config.height)

    target.type = "target"
    target.anchorChildren = true
    target.anchorX = 0
    target.anchorY = 0
    target.x = 10 + config.x
    target.y = 10 + config.y

    local targetResistance = 8

    if config.type == "easy" then
      targetResistance = targetResistance / 2
    elseif config.type == "hard" then
      targetResistance = targetResistance * 2
    end

    target.postCollision = function(self, event)
      if event.force < targetResistance then
        return false
      end

      transition.to(self, { time = 100, alpha = 0.1, onComplete = physics.removeBody } )
      target:removeEventListener("postCollision")
      numberOfTargets = numberOfTargets - 1
      utils.playAudio(sounds.targetDestroyed, 1.0)

      if (numberOfTargets == 0) then
        gameOver()
      end
    end

    numberOfTargets = numberOfTargets + 1
    physics.addBody(target, "static", { density = 1.0, friction = 0.3, bounce = 0.5 })
    target:addEventListener("postCollision")
  end
end

function scene:pauseOnTap()
  audio.pause()
  physics.pause()
  composer.showOverlay("scenes.pause", { isModal = true, params = { levelName = levelName }})
  return true
end

function scene:resume()
  physics.start()
  audio.resume()
end

function scene:show(event)
  if event.phase == "will" then
    levelName = event.params.levelName
    config = require ("levels." .. levelName)
    self:createLevel()
  elseif event.phase == "did" then
    Runtime:addEventListener("lateUpdate", predictBallPathOnLateUpdate)
    physics.start()
    timer.performWithDelay(0, takeLevelScreenshot)
  end
end

function scene:hide(event)
  if event.phase == "did" then
    Runtime:removeEventListener("lateUpdate", predictBallPathOnLateUpdate)
    audio.stop()
    physics.stop()
    transition.cancel()
    display.remove(level)
    ball = nil
    level = nil
    predictedBallPath = nil
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
