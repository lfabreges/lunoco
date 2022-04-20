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
local max = math.max
local min = math.min
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

local function onFocus(event)
  local objects = { backPhoto, backPhotoBackground, frontPhoto }
  for index = 1, 3 do
    local object = objects[index]
    object.xStart = object.x
    object.yStart = object.y
    object.widthStart = object.width
    object.heightStart = object.height
  end
end

local function onMove(event)
  local containerBounds = frontContainer.contentBounds

  backPhoto.x = backPhoto.xStart + event.xDelta
  backPhoto.y = backPhoto.yStart + event.yDelta

  local backPhotoBounds = backPhoto.contentBounds
  local deltaX = 0
  local deltaY = 0

  if backPhotoBounds.xMax < containerBounds.xMax then
    deltaX = containerBounds.xMax - backPhotoBounds.xMax
  elseif backPhotoBounds.xMin > containerBounds.xMin then
    deltaX = containerBounds.xMin - backPhotoBounds.xMin
  end

  if backPhotoBounds.yMax < containerBounds.yMax then
    deltaY = containerBounds.yMax - backPhotoBounds.yMax
  elseif backPhotoBounds.yMin > containerBounds.yMin then
    deltaY = containerBounds.yMin - backPhotoBounds.yMin
  end

  backPhoto.x = backPhoto.x + deltaX
  backPhoto.y = backPhoto.y + deltaY
  backPhotoBackground.x = backPhotoBackground.xStart + event.xDelta + deltaX
  backPhotoBackground.y = backPhotoBackground.yStart + event.yDelta + deltaY
  frontPhoto.x = frontPhoto.xStart + event.xDelta + deltaX
  frontPhoto.y = frontPhoto.yStart + event.yDelta + deltaY
end

local function onPinch(event)
  backPhoto.width = max(frontContainer.width, backPhoto.widthStart + event.xDelta)
  backPhoto.height = max(frontContainer.height, backPhoto.heightStart + event.yDelta)
  backPhotoBackground.width = backPhoto.width
  backPhotoBackground.height = backPhoto.height
  frontPhoto.width = backPhoto.width
  frontPhoto.height = backPhoto.height
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

    local xScale = min(1, display.actualContentWidth / backPhoto.width)
    local yScale = min(1, display.actualContentHeight / backPhoto.height)
    local photoScale = max(xScale, yScale)

    frontContainer = display.newContainer(content, element.width, element.height)
    frontContainer.x = centerX
    frontContainer.y = centerY

    backPhoto.width = max(frontContainer.width, backPhoto.width * photoScale)
    backPhoto.height = max(frontContainer.height, backPhoto.height * photoScale)
    backPhoto.alpha = 0.25

    backPhotoBackground.width = backPhoto.width
    backPhotoBackground.height = backPhoto.height
    backPhotoBackground:setFillColor(0)

    frontPhoto = display.newImage(frontContainer, filename, system.TemporaryDirectory, 0, 0)
    frontPhoto.width = backPhoto.width
    frontPhoto.height = backPhoto.height

    if element.mask then
      local frontPhotoMask = graphics.newMask(element.mask)
      frontContainer:setMask(frontPhotoMask)
      frontContainer.maskScaleX = frontContainer.width / 394
      frontContainer.maskScaleY = frontContainer.height / 394
    end

  elseif event.phase == "did" then
    utils.activateMultitouch()
    multitouch.addMoveAndPinchListener(background, { onFocus = onFocus, onMove = onMove, onPinch = onPinch })
  end
end

function scene:hide(event)
  if event.phase == "will" then
    multitouch.removeMoveAndPinchListener(background)
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
    os.remove(system.pathForFile(filename, system.TemporaryDirectory))
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
