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

    -- TODO à personnaliser en fonction de l'élément
    local minScale = math.max(200 / width, 200 / height)
    local maxScale = 4

     -- TODO Ajouter ensuite les limites sur le move pour garder l'image en visu

    local function onMove(dx, dy)
      frontPhoto.x, frontPhoto.y = frontPhoto.x + dx, frontPhoto.y + dy
      backPhoto.x, backPhoto.y = backPhoto.x + dx, backPhoto.y + dy
    end

    local function onPinch(dDistance)
      local scale = math.min(maxScale, math.max(minScale, frontPhoto.xScale + dDistance / 200))
      frontPhoto.xScale, frontPhoto.yScale = scale, scale
      backPhoto.xScale, backPhoto.yScale = scale, scale
    end

    multitouch.addMoveAndPinchListener(overlay, onMove, onPinch)
    onPinch(0)
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
