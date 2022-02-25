local composer = require "composer"
local physics = require "physics"

local ballImpulseForce = nil
local scale = 30
local scene = composer.newScene()

local onLateUpdate
local onScreenTouch
local predictBallPath
local removePredictedBallPath

onScreenTouch = function(event)
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

onLateUpdate = function()
  if ballImpulseForce then
    predictBallPath()
  end
end

predictBallPath = function()
  local timeStepInterval = 0.1
  local gx, gy = physics.getGravity()
  local vx, vy = scene.ball:getLinearVelocity()

  removePredictedBallPath()
  scene.predictedBallPath = display.newGroup()
  scene.predictedBallPath.x = scene.ball.x
  scene.predictedBallPath.y = scene.ball.y

  for step = 0, 10, 1 do
    local time = step * timeStepInterval
    local stepX = time * vx + (time * ballImpulseForce.x) / scene.ball.mass + 0.5 * gx * scale * (time * time)
    local stepY = time * vy + (time * ballImpulseForce.y) / scene.ball.mass + 0.5 * gy * scale * (time * time)
    display.newCircle(scene.predictedBallPath, stepX, stepY, 2)
  end
end

removePredictedBallPath = function()
  display.remove(scene.predictedBallPath)
  scene.predictedBallPath = nil
end

function scene:create(event)
  physics.start()
  physics.pause()
  physics.setScale(30);
  physics.setGravity(0, 9.8)
  -- physics.setDrawMode("hybrid")

  self:createBackground()
  self:createFrame()
  self:createBall()

  -- TODO Ajouter dans sa propre fonction
  local targetEasy = display.newImageRect(self.view, "target-easy.png", 60, 60)
  local targetEasyOutline = graphics.newOutline(2, "target-easy.png")
  targetEasy.x = display.contentWidth / 3
  targetEasy.y = display.contentHeight / 2
  physics.addBody(targetEasy, "static", { outline = targetEasyOutline, density = 1.0, friction = 0.3, bounce = 0.5 })
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
  self.ball = display.newImageRect(self.view, "ball.png", 40, 40)
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

function scene:createFrame()
  local frame = display.newImageRect(self.view, "frame.png", display.contentWidth, display.contentHeight)

  frame.x = display.contentCenterX
  frame.y = display.contentCenterY

  local halfScreenWidth = display.contentWidth / 2 - 4
  local halfScreenHeight = display.contentHeight / 2 - 4

  physics.addBody(frame, "static", {
    chain = {
      -halfScreenWidth, -halfScreenHeight,
      halfScreenWidth, -halfScreenHeight,
      halfScreenWidth, halfScreenHeight,
      -halfScreenWidth, halfScreenHeight,
    },
    connectFirstAndLastChainVertex = true,
    density = 1.0,
    friction = 0.5,
    bounce = 0.5,
  })
end

function scene:show(event)
  if event.phase == "did" then
    Runtime:addEventListener("touch", onScreenTouch)
    Runtime:addEventListener("lateUpdate", onLateUpdate)
    physics.start()
  end
end

function scene:hide(event)
  if event.phase == "will" then
    Runtime:removeEventListener("lateUpdate", onLateUpdate)
    Runtime:removeEventListener("touch", onScreenTouch)
    physics.stop()
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
