local composer = require "composer"
local multitouch = require "libraries.multitouch"

local scene = composer.newScene()

function scene:create(event)
  local screenX = display.screenOriginX
  local screenY = display.screenOriginY
  local screenWidth = display.actualContentWidth
  local screenHeight = display.actualContentHeight

  local background = display.newRect(self.view, screenX, screenY, screenWidth, screenHeight)
  background.anchorX = 0
  background.anchorY = 0
  background:setFillColor(0.5)
end

function scene:show(event)
  if event.phase == "did" then
    system.activate("multitouch")

    local photo = event.params.photo
    local screenX = display.screenOriginX
    local screenY = display.screenOriginY
    local screenWidth = display.actualContentWidth
    local screenHeight = display.actualContentHeight

    display.save(photo, {
      filename = "element-image.png",
      baseDir = system.TemporaryDirectory,
      captureOffscreenArea = true,
    })

    local width = photo.width
    local height = photo.height

    display.remove(photo)

    local backPhoto = display.newImageRect(self.view, "element-image.png", system.TemporaryDirectory, width, height)
    backPhoto.x = display.contentCenterX
    backPhoto.y = display.contentCenterY

    local overlay = display.newRect(self.view, screenX, screenY, screenWidth, screenHeight)
    overlay.anchorX = 0
    overlay.anchorY = 0
    overlay:setFillColor(0, 0, 0, 0.5)

    -- TODO Aux bonnes coordonnées de l'élément
    -- Avec un masque pour les éléments qui le nécessite
    local frontContainer = display.newContainer(self.view, 200, 200)
    frontContainer.x = display.contentCenterX
    frontContainer.y = display.contentCenterY

    local frontPhoto = display.newImageRect(
      frontContainer,
      "element-image.png",
      system.TemporaryDirectory,
      width,
      height
    )

    local minX = frontContainer.x - frontContainer.width / 2
    local minY = frontContainer.y - frontContainer.height / 2
    local maxX = frontContainer.x + frontContainer.width / 2
    local maxY = frontContainer.y + frontContainer.height / 2
    local minXScale = frontContainer.width / width
    local minYScale = frontContainer.height / height
    local maxScale = 4

    local function onMove(deltaX, deltaY)
      local bounds = backPhoto.contentBounds
      deltaX = bounds.xMax + deltaX < maxX and maxX - bounds.xMax or deltaX
      deltaX = bounds.xMin + deltaX > minX and minX - bounds.xMin or deltaX
      deltaY = bounds.yMax + deltaY < maxY and maxY - bounds.yMax or deltaY
      deltaY = bounds.yMin + deltaY > minY and minY - bounds.yMin or deltaY
      backPhoto.x, backPhoto.y = backPhoto.x + deltaX, backPhoto.y + deltaY
      frontPhoto.x, frontPhoto.y = frontPhoto.x + deltaX, frontPhoto.y + deltaY
    end

    local function onPinch(deltaDistanceX, deltaDistanceY)
      local xScale = math.min(maxScale, math.max(minXScale, frontPhoto.xScale + deltaDistanceX / 200))
      local yScale = math.min(maxScale, math.max(minYScale, frontPhoto.yScale + deltaDistanceY / 200))
      frontPhoto.xScale, backPhoto.xScale = xScale, xScale
      frontPhoto.yScale, backPhoto.yScale = yScale, yScale
    end

    onPinch(0, 0)

    multitouch.addMoveAndPinchListener(overlay, onMove, onPinch)
  end
end

function scene:hide(event)
  if event.phase == "will" then
    system.deactivate("multitouch")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
