local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local multitouch = require "libraries.multitouch"
local navigation = require "modules.navigation"
local utils = require "modules.utils"

local backPhoto = nil
local backPhotoBackground = nil
local background = nil
local content = nil
local elementType = nil
local filename = nil
local frontContainer = nil
local frontPhoto = nil
local level = nil
local scene = composer.newScene()

local elements = {
  ["background"] = { width = 200, height = 306 },
  ["ball"] = { width = 200, height = 200, mask = "images/elements/ball-mask.png" },
  ["frame"] = { width = 200, height = 200 },
  ["obstacle-corner"] = { width = 200, height = 200, mask = "images/elements/corner-mask.png" },
  ["obstacle-horizontal-barrier"] = { width = 200, height = 50 },
  ["obstacle-horizontal-barrier-large"] = { width = 200, height = 50 },
  ["obstacle-vertical-barrier"] = { width = 75, height = 300 },
  ["obstacle-vertical-barrier-large"] = { width = 75, height = 300 },
  ["target-easy"] = { width = 200, height = 200 },
  ["target-normal"] = { width = 200, height = 200 },
  ["target-hard"] = { width = 200, height = 200 },
}

local function goBack()
  navigation.gotoCustomizeLevel(level)
end

local function onMove(deltaX, deltaY)
  local containerBounds = frontContainer.contentBounds
  local photoBounds = backPhoto.contentBounds
  deltaX = photoBounds.xMax + deltaX < containerBounds.xMax and containerBounds.xMax - photoBounds.xMax or deltaX
  deltaX = photoBounds.xMin + deltaX > containerBounds.xMin and containerBounds.xMin - photoBounds.xMin or deltaX
  deltaY = photoBounds.yMax + deltaY < containerBounds.yMax and containerBounds.yMax - photoBounds.yMax or deltaY
  deltaY = photoBounds.yMin + deltaY > containerBounds.yMin and containerBounds.yMin - photoBounds.yMin or deltaY
  backPhoto:translate(deltaX, deltaY)
  backPhotoBackground:translate(deltaX, deltaY)
  frontPhoto:translate(deltaX, deltaY)
end

local function onPinch(deltaDistanceX, deltaDistanceY)
  local minXScale = frontContainer.width / backPhoto.width
  local minYScale = frontContainer.height / backPhoto.height
  local xScale = math.min(4, math.max(minXScale, frontPhoto.xScale + deltaDistanceX / backPhoto.width))
  local yScale = math.min(4, math.max(minYScale, frontPhoto.yScale + deltaDistanceY / backPhoto.height))
  backPhoto.xScale = xScale
  backPhoto.yScale = yScale
  backPhotoBackground.xScale = xScale
  backPhotoBackground.yScale = yScale
  frontPhoto.xScale = xScale
  frontPhoto.yScale = yScale
end

local function saveImage()
  local b = frontContainer.contentBounds
  local elementCapture = display.captureBounds({ xMin = b.xMin, xMax = b.xMax - 1, yMin = b.yMin, yMax = b.yMax - 1 })
  level:saveImage(elementCapture, elementType)
  display.remove(elementCapture)
  navigation.gotoCustomizeLevel(level)
end

function scene:create(event)
  background = components.newBackground(self.view)
  content = components.newGroup(self.view)

  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  local cancelButton = components.newImageButton(self.view, "images/icons/cancel.png", 40, 40, { onRelease = goBack })
  cancelButton.anchorX = 0
  cancelButton.anchorY = 0
  cancelButton.x = background.contentBounds.xMin + leftInset + 20
  cancelButton.y = background.contentBounds.yMin + topInset + 20

  local saveButton = components.newImageButton(self.view, "images/icons/accept.png", 40, 40, { onRelease = saveImage })
  saveButton.anchorX = 1
  saveButton.anchorY = 0
  saveButton.x = background.contentBounds.xMax - rightInset - 20
  saveButton.y = background.contentBounds.yMin + topInset + 20
end

function scene:show(event)
  if event.phase == "will" then
    level = event.params.level
    elementType = event.params.elementType
    filename = event.params.filename

    local centerX = display.contentCenterX
    local centerY = display.contentCenterY
    local element = elements[elementType]

    backPhotoBackground = display.newRect(content, centerX, centerY, 1, 1)
    backPhoto = display.newImage(content, filename, system.TemporaryDirectory, centerX, centerY)

    local xScale = math.min(1, display.actualContentWidth / backPhoto.width)
    local yScale = math.min(1, display.actualContentHeight / backPhoto.height)
    local photoScale = math.max(xScale, yScale)

    backPhotoBackground.width = backPhoto.width
    backPhotoBackground.height = backPhoto.height
    backPhotoBackground.xScale = photoScale
    backPhotoBackground.yScale = photoScale
    backPhotoBackground:setFillColor(0)

    backPhoto.xScale = photoScale
    backPhoto.yScale = photoScale
    backPhoto.alpha = 0.25

    frontContainer = display.newContainer(content, element.width, element.height)
    frontContainer.x = centerX
    frontContainer.y = centerY

    frontPhoto = display.newImage(frontContainer, filename, system.TemporaryDirectory, 0, 0)
    frontPhoto.xScale = photoScale
    frontPhoto.yScale = photoScale

    if element.mask then
      local frontPhotoMask = graphics.newMask(element.mask)
      frontContainer:setMask(frontPhotoMask)
      frontContainer.maskScaleX = frontContainer.width / 394
      frontContainer.maskScaleY = frontContainer.height / 394
    end

    onPinch(0, 0)

  elseif event.phase == "did" then
    if not utils.isSimulator() then
      system.activate("multitouch")
    end
    multitouch.addMoveAndPinchListener(background, onMove, onPinch)
  end
end

function scene:hide(event)
  if event.phase == "will" then
    multitouch.removeMoveAndPinchListener(background)
    if not utils.isSimulator() then
      system.deactivate("multitouch")
    end
  elseif event.phase == "did" then
    transition.cancel()
    display.remove(backPhoto)
    display.remove(backPhotoBackground)
    display.remove(frontContainer)
    backPhoto = nil
    backPhotoBackground = nil
    frontContainer = nil
    frontPhoto = nil
    os.remove(system.pathForFile(filename, system.TemporaryDirectory))
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
