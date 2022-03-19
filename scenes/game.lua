local components = require "components"
local composer = require "composer"
local navigation = require "navigation"
local utils = require "utils"

local ball = nil
local ballImpulseForce = nil
local config = nil
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
  local _ballImpulseForce = { x = (event.xStart - event.x) * 4, y = (event.yStart - event.y) * 4 }
  ballImpulseForce = nil

  if event.phase == "began" then
    display.getCurrentStage():setFocus(event.target)
  elseif event.phase == "ended" or event.phase == "cancelled" then
    display.remove(predictedBallPath)
    predictedBallPath = nil
    display.getCurrentStage():setFocus(nil)

    if event.phase == "ended" then
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

  local timeStepInterval = 0.1
  local gravityX, gravityY = physics.getGravity()

  display.remove(predictedBallPath)
  predictedBallPath = components.newGroup(level)

  local prevStepX = nil
  local prevStepY = nil

  for step = 0, 10, 1 do
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

  display.save(screenshot, {
    baseDir = system.DocumentsDirectory,
    filename = "level." .. levelName .. ".png",
    captureOffscreenArea = true,
  })

  display.remove(screenshot)
end

function scene:create(event)
  local screenX = display.screenOriginX
  local screenY = display.screenOriginY
  local screenWidth = display.actualContentWidth
  local screenHeight = display.actualContentHeight

  local background = display.newRect(self.view, screenX, screenY, screenWidth, screenHeight)
  background.anchorX = 0
  background.anchorY = 0
  background:setFillColor(0.5)

  local tapRectangle = display.newRect(self.view, screenX, screenY, screenWidth, screenHeight * 0.3)
  tapRectangle.anchorX = 0
  tapRectangle.anchorY = 0
  tapRectangle.alpha = 0
  tapRectangle.isHitTestable = true
  tapRectangle:addEventListener("tap", scene.pauseOnTap)

  local touchRectangle = display.newRect(self.view, screenX, screenY + screenHeight, screenWidth, screenHeight * 0.7)
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
  physics.setGravity(0, 9.8)

  level = components.newGroup(self.view)

  self:createFrame()
  self:createObstacles()
  self:createTargets()
  self:createBall()

  numberOfShots = 0
end

function scene:createBall()
  ball = display.newImageRect(level, "images/ball.png", 30, 30)

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
  local frame = display.newImageRect(level, "images/frame.png", 480, 720)

  frame.x = display.contentCenterX
  frame.y = display.contentCenterY

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
      local corner = components.newGroup(level)
      local cornerDrawing = display.newImageRect(corner, "images/corner.png", config.width, config.height)
      local cornerMask = graphics.newMask("images/corner-mask.png")

      cornerDrawing:setMask(cornerMask)
      cornerDrawing.maskScaleX = cornerDrawing.width / 394
      cornerDrawing.maskScaleY = cornerDrawing.height / 394

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
      local barrier = components.newGroup(level)
      local barrierImage = "images/" .. config.type .. ".png"
      local barrierDrawing = display.newImageRect(barrier, barrierImage, config.width, config.height)

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
    local target = components.newGroup(level)
    local targetImage = "images/target-" .. config.type .. ".png"
    local targetDrawing = display.newImageRect(target, targetImage, config.width, config.height)

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
