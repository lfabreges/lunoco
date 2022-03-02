local composer = require "composer"
local physics = require "physics"

local ballImpulseForce = nil
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
    scene.ball:applyLinearImpulse(_ballImpulseForce.x / scale, _ballImpulseForce.y / scale, scene.ball.x, scene.ball.y)
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
  local velocityX, velocityY = scene.ball:getLinearVelocity()

  removePredictedBallPath()
  scene.predictedBallPath = display.newGroup()
  scene.level:insert(scene.predictedBallPath)

  local prevStepX = nil
  local prevStepY = nil

  for step = 0, 10, 1 do
    local time = step * timeStepInterval
    local accelerationX = ballImpulseForce.x / scene.ball.mass
    local accelerationY = ballImpulseForce.y / scene.ball.mass
    local stepX = scene.ball.x + time * velocityX + time * accelerationX + 0.5 * gravityX * scale * (time * time)
    local stepY = scene.ball.y + time * velocityY + time * accelerationY + 0.5 * gravityY * scale * (time * time)

    if step > 0 and physics.rayCast(prevStepX, prevStepY, stepX, stepY, "any") then
      break
    end

    prevStepX = stepX
    prevStepY = stepY

    display.newCircle(scene.predictedBallPath, stepX, stepY, 2)
  end

  return false
end

removePredictedBallPath = function()
  display.remove(scene.predictedBallPath)
  scene.predictedBallPath = nil
end

function scene:create(event)
  physics.start()
  physics.pause()
  physics.setScale(scale);
  physics.setGravity(0, 9.8)
  -- physics.setDrawMode("hybrid")

  self:createBackground()

  self.config = {
    width = display.contentWidth,
    height = display.contentHeight,
  }

  self.level = display.newGroup()
  self.view:insert(self.level)

  self:createFrame(self.config.width, self.config.height)
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
  self.ball = display.newImageRect(self.level, "images/ball.png", 40, 40)
  self.ball.x = display.contentWidth / 2
  self.ball.y = display.contentHeight / 2

  physics.addBody(self.ball, {
    radius = self.ball.width / 2 - 1,
    density = 1.0,
    friction = 0.3,
    bounce = 0.5,
  })

  self.ball.angularDamping = 1.5
  self.ball:setLinearVelocity(25, -60)
end

function scene:createFrame(width, height)
  local frameLeft = display.newImageRect(self.level, "images/frame-left.png", 4, height)
  local frameTop = display.newImageRect(self.level, "images/frame-top.png", width, 4)
  local frameRight= display.newImageRect(self.level, "images/frame-right.png", 4, height)
  local frameBottom = display.newImageRect(self.level, "images/frame-bottom.png", width, 4)

  frameLeft.x = frameLeft.width / 2
  frameLeft.y = height / 2
  frameTop.x = width / 2
  frameTop.y = frameTop.height / 2
  frameRight.x = width - frameRight.width / 2
  frameRight.y = height / 2
  frameBottom.x = width / 2
  frameBottom.y = height - frameBottom.height / 2

  local frameBodyParams = { density = 1.0, friction = 0.5, bounce = 0.5 }

  physics.addBody(frameLeft, "static", frameBodyParams)
  physics.addBody(frameTop, "static", frameBodyParams)
  physics.addBody(frameRight, "static", frameBodyParams)
  physics.addBody(frameBottom, "static", frameBodyParams)
end

function scene:createTargets()
  local targetEasy = display.newImageRect(self.level, "images/target-easy.png", 60, 60)
  local targetEasyOutline = graphics.newOutline(2, "images/target-easy.png")
  targetEasy.x = display.contentWidth / 3
  targetEasy.y = display.contentHeight / 2

  targetEasy.collision = function(self, event)
    transition.to(self, { time = 100, alpha = 0.1, onComplete = physics.removeBody } )
    targetEasy:removeEventListener("collision")
    return true
  end

  physics.addBody(targetEasy, "static", { outline = targetEasyOutline, density = 1.0, friction = 0.3, bounce = 0.5 })
  targetEasy:addEventListener("collision")
end

function scene:enterFrame()
  local config = self.config
  local level = self.level

  if config.width <= display.safeActualContentWidth then
    level.x = display.safeScreenOriginX + (display.safeActualContentWidth - config.width) / 2
  else
    local dx = display.contentCenterX - level.x - self.ball.x
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
    local dy = display.contentCenterY - level.y - self.ball.y
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
  package.loaded[physics] = nil
  physics = nil
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
