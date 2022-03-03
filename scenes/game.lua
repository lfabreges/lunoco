local composer = require "composer"

local ball = nil
local ballImpulseForce = nil
local borderWidth = 4
local config = nil
local level = nil
local predictedBallPath = nil
local scale = 30
local scene = composer.newScene()

local handleBallImpulseOnScreenTouch
local predictBallPathOnLateUpdate
local removePredictedBallPath

handleBallImpulseOnScreenTouch = function(event)
  local _ballImpulseForce = { x = (event.xStart - event.x) * 2, y = (event.yStart - event.y) * 2 }
  ballImpulseForce = nil

  if (event.phase == "ended") then
    removePredictedBallPath()
    ball:applyLinearImpulse(_ballImpulseForce.x / scale, _ballImpulseForce.y / scale, ball.x, ball.y)
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
  local velocityX, velocityY = ball:getLinearVelocity()

  removePredictedBallPath()
  predictedBallPath = display.newGroup()
  level:insert(predictedBallPath)

  local prevStepX = nil
  local prevStepY = nil

  for step = 0, 10, 1 do
    local time = step * timeStepInterval
    local accelerationX = ballImpulseForce.x / ball.mass
    local accelerationY = ballImpulseForce.y / ball.mass
    local stepX = ball.x + time * velocityX + time * accelerationX + 0.5 * gravityX * scale * (time * time)
    local stepY = ball.y + time * velocityY + time * accelerationY + 0.5 * gravityY * scale * (time * time)

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
  physics.setScale(scale);
  physics.setGravity(0, 9.8)
  -- physics.setDrawMode("hybrid");

  self:createBackground()

  config = {
    width = display.contentWidth,
    height = display.contentHeight,
  }

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
  background:setFillColor(.5)
end

function scene:createBall()
  ball = display.newImageRect(level, "images/ball.png", 40, 40)
  ball.x = display.contentWidth / 2
  ball.y = display.contentHeight / 2
  physics.addBody(ball, { radius = ball.width / 2 - 1, density = 1.0, friction = 0.3, bounce = 0.5 })
  ball.angularDamping = 1.5
  ball:setLinearVelocity(25, -60)
end

function scene:createFrame()
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

  frameLeft.x = frameLeft.width / 2
  frameLeft.y = height / 2
  frameTop.x = width / 2
  frameTop.y = frameTop.height / 2
  frameRight.x = width - frameRight.width / 2
  frameRight.y = height / 2
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
  local obstacleCorner = display.newImageRect(level, "images/obstacle-corner.png", 100, 100)
  local tobstacleCornerOutline = graphics.newOutline(2, "images/obstacle-corner-outline.png")
  obstacleCorner.x = level.x + borderWidth + obstacleCorner.width / 2
  obstacleCorner.y = level.y + config.height - borderWidth - obstacleCorner.height / 2

  physics.addBody(
    obstacleCorner,
    "static",
    { outline = tobstacleCornerOutline, density = 1.0, friction = 0.3, bounce = 0.5 }
  )
end

function scene:createTargets()
  local targetEasy = display.newImageRect(level, "images/target-easy.png", 60, 60)
  targetEasy.x = display.contentWidth / 3
  targetEasy.y = display.contentHeight / 2

  targetEasy.collision = function(self, event)
    transition.to(self, { time = 100, alpha = 0.1, onComplete = physics.removeBody } )
    targetEasy:removeEventListener("collision")
    return true
  end

  physics.addBody(targetEasy, "static", { density = 1.0, friction = 0.3, bounce = 0.5 })
  targetEasy:addEventListener("collision")
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
  end
end

function scene:hide(event)
  if event.phase == "did" then
    Runtime:removeEventListener("lateUpdate", predictBallPathOnLateUpdate)
    Runtime:removeEventListener("touch", handleBallImpulseOnScreenTouch)
    Runtime:removeEventListener("enterFrame", scene)
    physics.stop()
    composer.removeScene("game")
  end
end

function scene:destroy(event)
  config = nil
  ball = nil
  level = nil
  predictedBallPath = nil
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
