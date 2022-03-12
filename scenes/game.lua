local composer = require "composer"
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

local gameOver
local handleBallImpulseOnScreenTouch
local predictBallPathOnLateUpdate
local removePredictedBallPath

gameOver = function()
  local numberOfStars = 0

  if numberOfShots <= config.difficulty.three then
    numberOfStars = 3
  elseif numberOfShots <= config.difficulty.two then
    numberOfStars = 2
  elseif numberOfShots <= config.difficulty.one then
    numberOfStars = 1
  end

  composer.gotoScene("scenes.game-over", {
    effect = "fade",
    time = 500,
    params = {
      levelName = levelName,
      numberOfShots = numberOfShots,
      numberOfStars = numberOfStars,
    },
  })
end

handleBallImpulseOnScreenTouch = function(event)
  local _ballImpulseForce = { x = (event.xStart - event.x) * 3, y = (event.yStart - event.y) * 3 }
  ballImpulseForce = nil

  if (event.phase == "ended") then
    removePredictedBallPath()
    ball:setLinearVelocity(_ballImpulseForce.x, _ballImpulseForce.y)
    numberOfShots = numberOfShots + 1
    utils.playAudio(sounds.ball, 0.4)
  elseif (event.phase == "moved") then
    ballImpulseForce = _ballImpulseForce
  end

  return true
end

predictBallPathOnLateUpdate = function()
  if not ballImpulseForce then
    return false
  end

  local timeStepInterval = 0.1
  local gravityX, gravityY = physics.getGravity()

  removePredictedBallPath()
  predictedBallPath = display.newGroup()
  level:insert(predictedBallPath)

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

removePredictedBallPath = function()
  display.remove(predictedBallPath)
  predictedBallPath = nil
end

function scene:create(event)
  physics.start()
  physics.pause()
  physics.setScale(scale)
  physics.setGravity(0, 9.8)

  if utils.isSimulator() then
    -- physics.setDrawMode("hybrid")
  end

  levelName = event.params.levelName
  config = require ("levels." .. levelName)

  self:createBackground()
  level = display.newGroup()
  self.view:insert(level)
  self:createFrame()
  self:createObstacles()
  self:createTargets()
  self:createBall()
end

function scene:createBackground()
  local background = display.newRect(
    self.view,
    display.screenOriginX,
    display.screenOriginY,
    display.actualContentWidth,
    display.actualContentHeight
  )

  background.anchorX = 0
  background.anchorY = 0
  background:setFillColor(0.5)
end

function scene:createBall()
  ball = display.newImageRect(level, "images/ball.png", config.ball.width, config.ball.width)
  ball.x = config.ball.x
  ball.y = config.ball.y

  numberOfShots = 0

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
  local borderWidth = config.borderWidth
  local width = config.width
  local height = config.height
  local frameLeft = display.newImageRect(level, "images/frame-left.png", borderWidth, height)
  local frameTop = display.newImageRect(level, "images/frame-top.png", width, borderWidth)
  local frameRight= display.newImageRect(level, "images/frame-right.png", borderWidth, height)
  local frameBottom = display.newImageRect(level, "images/frame-bottom.png", width, borderWidth)
  local extraWidth = display.actualContentWidth + width
  local extraHeight = display.actualContentHeight + height
  local frameLeftExtra = display.newImageRect(level, "images/frame-extra.png", extraWidth, height)
  local frameTopExtra = display.newImageRect(level, "images/frame-extra.png", extraWidth, extraHeight)
  local frameRightExtra = display.newImageRect(level, "images/frame-extra.png", extraWidth, height)
  local frameBottomExtra = display.newImageRect(level, "images/frame-extra.png", extraWidth, extraHeight)

  frameLeft.type = "frame"
  frameLeft.x = frameLeft.width / 2
  frameLeft.y = height / 2
  frameTop.type = "frame"
  frameTop.x = width / 2
  frameTop.y = frameTop.height / 2
  frameRight.type = "frame"
  frameRight.x = width - frameRight.width / 2
  frameRight.y = height / 2
  frameBottom.type = "frame"
  frameBottom.x = width / 2
  frameBottom.y = height - frameBottom.height / 2
  frameLeftExtra.x = 0 - frameLeftExtra.width / 2
  frameLeftExtra.y = frameLeft.y
  frameTopExtra.x = frameTop.x
  frameTopExtra.y = 0 - frameTopExtra.height / 2
  frameRightExtra.x = width + frameRightExtra.width / 2
  frameRightExtra.y = frameRight.y
  frameBottomExtra.x = frameBottom.x
  frameBottomExtra.y = height + frameBottomExtra.height / 2

  local frameBodyParams = { density = 1.0, friction = 0.5, bounce = 0.5 }

  physics.addBody(frameLeft, "static", frameBodyParams)
  physics.addBody(frameTop, "static", frameBodyParams)
  physics.addBody(frameRight, "static", frameBodyParams)
  physics.addBody(frameBottom, "static", frameBodyParams)
end

function scene:createObstacles()
  for _, config in ipairs(config.obstacles) do
    if config.type == "corner" then
      local corner = display.newGroup()
      level:insert(corner)

      local cornerDrawing = display.newImageRect(corner, "images/corner.png", config.width, config.height)
      local cornerOutline = display.newImageRect(corner, "images/corner-outline.png", config.width, config.height)

      corner.type = "corner"
      corner.anchorChildren = true
      corner.anchorX = 0
      corner.anchorY = 0
      corner.x = config.x
      corner.y = config.y
      corner.rotation = config.rotation

      local chain = {
        -50, -50,
        -49, -44,
        -47, -38,
        -45, -33,
        -41, -26,
        -35, -17,
        -27, -7,
        -20, 1,
        -4, 18,
        5, 26,
        19, 37,
        29, 43,
        37, 47,
        44, 49,
        50, 50,
        -50, 50,
      }

      local scaledChain = {}

      for i = 1, #chain, 2 do
        scaledChain[i] = chain[i] * config.width / 100
        scaledChain[i + 1] = chain[i + 1] * config.height / 100
      end

      physics.addBody(
        corner,
        "static",
        {
          density = 1.0,
          friction = 0.3,
          bounce = 0.5,
          connectFirstAndLastChainVertex = true,
          chain = scaledChain
        }
      )
    elseif config.type:starts("horizontal-barrier") or config.type:starts("vertical-barrier") then
      local barrier = display.newGroup()
      level:insert(barrier)

      local barrierImage = "images/" .. config.type .. ".png"
      local barrierDrawing = display.newImageRect(barrier, barrierImage, config.width, config.height)
      local barrierOutlineImage =  "images/" .. config.type .. "-outline.png"
      local barrierOutline = display.newImageRect(barrier, barrierOutlineImage, config.width, config.height)

      barrier.type = "barrier"
      barrier.anchorChildren = true
      barrier.anchorX = 0
      barrier.anchorY = 0
      barrier.x = config.x
      barrier.y = config.y

      physics.addBody(barrier, "static", { density = 1.0, friction = 0.3, bounce = 0.5 })
    end
  end
end

function scene:createTargets()
  local numberOfTargets = 0

  for _, config in ipairs(config.targets) do
    local target = display.newGroup()
    level:insert(target)

    local targetImage = "images/target-" .. config.type .. ".png"
    local targetDrawing = display.newImageRect(target, targetImage, config.width, config.height)
    local targetOutline = display.newImageRect(target, "images/target-outline.png", config.width, config.height)

    target.type = "target"
    target.anchorChildren = true
    target.anchorX = 0
    target.anchorY = 0
    target.x = config.x
    target.y = config.y

    local targetResistance = 5

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

function scene:enterFrame()
  if config.width <= display.safeActualContentWidth then
    level.x = display.safeScreenOriginX + (display.safeActualContentWidth - config.width) / 2
  else
    local dx = display.contentCenterX - level.x - ball.x
    level.x = level.x + dx
    if level.x > display.safeScreenOriginX then
      level.x = display.safeScreenOriginX
    elseif level.x + config.width < display.safeScreenOriginX + display.safeActualContentWidth then
      level.x = display.safeScreenOriginX + display.safeActualContentWidth - config.width
    end
  end

  if config.height <= display.safeActualContentHeight then
    level.y = display.safeScreenOriginY + (display.safeActualContentHeight - config.height) / 2
  else
    local dy = display.contentCenterY - level.y - ball.y
    level.y = level.y + dy
    if level.y > display.safeScreenOriginY then
      level.y = display.safeScreenOriginY
    elseif level.y + config.height < display.safeScreenOriginY + display.safeActualContentHeight then
      level.y = display.safeScreenOriginY + display.safeActualContentHeight - config.height
    end
  end
end

function scene:show(event)
  if event.phase == "did" then
    Runtime:addEventListener("enterFrame", scene)
    Runtime:addEventListener("touch", handleBallImpulseOnScreenTouch)
    Runtime:addEventListener("lateUpdate", predictBallPathOnLateUpdate)
    physics.start()

    --[[
    if utils.isSimulator() then
      timer.performWithDelay(
        100,
        function()
          display.save(self.view, { baseDir = system.TemporaryDirectory, filename = levelName .. ".png" })
        end
      )
    end
    ]]
  end
end

function scene:hide(event)
  if event.phase == "did" then
    Runtime:removeEventListener("lateUpdate", predictBallPathOnLateUpdate)
    Runtime:removeEventListener("touch", handleBallImpulseOnScreenTouch)
    Runtime:removeEventListener("enterFrame", scene)

    audio.stop()
    physics.stop()

    composer.removeScene("scenes.game")
  end
end

function scene:destroy(event)
  config = nil
  ball = nil
  level = nil
  predictedBallPath = nil

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
