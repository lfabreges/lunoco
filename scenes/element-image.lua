local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local multitouch = require "modules.multitouch"
local navigation = require "modules.navigation"
local utils = require "modules.utils"

local backPhoto = nil
local backPhotoBackground = nil
local background = nil
local content = nil
local elementDescriptor = nil
local filename = nil
local frontContainer = nil
local frontPhoto = nil
local level = nil
local max = math.max
local min = math.min
local scene = composer.newScene()

local function goBack()
  navigation.gotoCustomizeLevel(level)
end

local function onFocus(event)
  local objects = { backPhoto, backPhotoBackground, frontPhoto }
  for index = 1, 3 do
    local object = objects[index]
    object.xStart = object.x
    object.yStart = object.y
    object.xScaleStart = object.xScale
    object.yScaleStart = object.yScale
  end
end

local function onMovePinchRotate(event)
  if event.xDistanceDelta then
    local minXScale = frontContainer.width / backPhoto.width
    local minYScale = frontContainer.height / backPhoto.height
    local xScale = min(4, max(minXScale, backPhoto.xScaleStart + event.xDistanceDelta / backPhoto.width))
    local yScale = min(4, max(minYScale, backPhoto.yScaleStart + event.yDistanceDelta / backPhoto.height))
    backPhoto.xScale = xScale
    backPhoto.yScale = yScale
    backPhotoBackground.xScale = xScale
    backPhotoBackground.yScale = yScale
    frontPhoto.xScale = xScale
    frontPhoto.yScale = yScale
  end

  backPhoto.x = backPhoto.xStart + event.xDelta
  backPhoto.y = backPhoto.yStart + event.yDelta

  local backPhotoBounds = backPhoto.contentBounds
  local containerBounds = frontContainer.contentBounds
  local xDeltaCorrection = 0
  local yDeltaCorrection = 0

  if backPhotoBounds.xMax < containerBounds.xMax then
    xDeltaCorrection = containerBounds.xMax - backPhotoBounds.xMax
  elseif backPhotoBounds.xMin > containerBounds.xMin then
    xDeltaCorrection = containerBounds.xMin - backPhotoBounds.xMin
  end
  if backPhotoBounds.yMax < containerBounds.yMax then
    yDeltaCorrection = containerBounds.yMax - backPhotoBounds.yMax
  elseif backPhotoBounds.yMin > containerBounds.yMin then
    yDeltaCorrection = containerBounds.yMin - backPhotoBounds.yMin
  end

  backPhoto.x = backPhoto.x + xDeltaCorrection
  backPhoto.y = backPhoto.y + yDeltaCorrection
  backPhotoBackground.x = backPhotoBackground.xStart + event.xDelta + xDeltaCorrection
  backPhotoBackground.y = backPhotoBackground.yStart + event.yDelta + yDeltaCorrection
  frontPhoto.x = frontPhoto.xStart + event.xDelta + xDeltaCorrection
  frontPhoto.y = frontPhoto.yStart + event.yDelta + yDeltaCorrection
end

local function saveImage()
  local b = frontContainer.contentBounds
  local elementCapture = display.captureBounds({ xMin = b.xMin, xMax = b.xMax - 1, yMin = b.yMin, yMax = b.yMax - 1 })
  level:saveImage(elementCapture, elementDescriptor.family, elementDescriptor.name)
  display.remove(elementCapture)
  navigation.gotoCustomizeLevel(level)
end

function scene:create(event)
  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  background = components.newBackground(self.view)
  content = components.newGroup(self.view)

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
    elementDescriptor = event.params.elementDescriptor
    filename = event.params.filename

    local centerX = display.contentCenterX
    local centerY = display.contentCenterY

    backPhotoBackground = display.newRect(content, centerX, centerY, 1, 1)
    backPhoto = display.newImage(content, filename, system.TemporaryDirectory, centerX, centerY)

    local xScale = min(1, display.actualContentWidth / backPhoto.width)
    local yScale = min(1, display.actualContentHeight / backPhoto.height)
    local photoScale = max(xScale, yScale)

    backPhoto.xScale = photoScale
    backPhoto.yScale = photoScale
    backPhoto.alpha = 0.25

    backPhotoBackground.width = backPhoto.width
    backPhotoBackground.height = backPhoto.height
    backPhotoBackground.xScale = photoScale
    backPhotoBackground.yScale = photoScale
    backPhotoBackground:setFillColor(0)

    local elementWidth, elementHeight = elementDescriptor.size(250, 300)
    frontContainer = display.newContainer(content, elementWidth, elementHeight)
    frontContainer.x = centerX
    frontContainer.y = centerY

    frontPhoto = display.newImage(frontContainer, filename, system.TemporaryDirectory, 0, 0)
    frontPhoto.xScale = photoScale
    frontPhoto.yScale = photoScale

    if elementDescriptor.mask then
      local frontPhotoMask = graphics.newMask(elementDescriptor.mask)
      frontContainer:setMask(frontPhotoMask)
      frontContainer.maskScaleX = frontContainer.width / 394
      frontContainer.maskScaleY = frontContainer.height / 394
    end

  elseif event.phase == "did" then
    utils.activateMultitouch()
    multitouch.addMovePinchRotateListener(background, { onFocus = onFocus, onMovePinchRotate = onMovePinchRotate })
  end
end

function scene:hide(event)
  if event.phase == "will" then
    multitouch.removeMovePinchRotateListener(background)
    utils.deactivateMultitouch()
  elseif event.phase == "did" then
    transition.cancelAll()
    display.remove(backPhoto)
    display.remove(backPhotoBackground)
    display.remove(frontContainer)
    backPhoto = nil
    backPhotoBackground = nil
    frontContainer = nil
    frontPhoto = nil
    utils.removeFile(filename, system.TemporaryDirectory)
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
