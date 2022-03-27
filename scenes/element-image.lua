local components = require "components"
local composer = require "composer"
local i18n = require "i18n"
local multitouch = require "libraries.multitouch"
local navigation = require "navigation"
local utils = require "utils"

local backPhoto = nil
local background = nil
local content = nil
local elementType = nil
local frontContainer = nil
local frontPhoto = nil
local levelName = nil
local scene = composer.newScene()

local elements = {
  ["ball"] = { width = 200, height = 200, mask = "images/ball-mask.png" },
  ["obstacle-corner"] = { width = 200, height = 200, mask = "images/corner-mask.png" },
  ["obstacle-horizontal-barrier"] = { width = 200, height = 50 },
  ["obstacle-horizontal-barrier-large"] = { width = 200, height = 50 },
  ["obstacle-vertical-barrier"] = { width = 75, height = 300 },
  ["target-easy"] = { width = 200, height = 200 },
  ["target-normal"] = { width = 200, height = 200 },
  ["target-hard"] = { width = 200, height = 200 },
}

local function goBack()
  navigation.gotoCustomizeLevel(levelName)
end

local function onMove(deltaX, deltaY)
  local containerBounds = frontContainer.contentBounds
  local photoBounds = backPhoto.contentBounds

  deltaX = photoBounds.xMax + deltaX < containerBounds.xMax and containerBounds.xMax - photoBounds.xMax or deltaX
  deltaX = photoBounds.xMin + deltaX > containerBounds.xMin and containerBounds.xMin - photoBounds.xMin or deltaX
  deltaY = photoBounds.yMax + deltaY < containerBounds.yMax and containerBounds.yMax - photoBounds.yMax or deltaY
  deltaY = photoBounds.yMin + deltaY > containerBounds.yMin and containerBounds.yMin - photoBounds.yMin or deltaY

  backPhoto.x = backPhoto.x + deltaX
  backPhoto.y = backPhoto.y + deltaY
  frontPhoto.x = frontPhoto.x + deltaX
  frontPhoto.y = frontPhoto.y + deltaY
end

local function onPinch(deltaDistanceX, deltaDistanceY)
  local minXScale = frontContainer.width / backPhoto.width
  local minYScale = frontContainer.height / backPhoto.height
  local xScale = math.min(4, math.max(minXScale, frontPhoto.xScale + deltaDistanceX / 400))
  local yScale = math.min(4, math.max(minYScale, frontPhoto.yScale + deltaDistanceY / 400))
  frontPhoto.xScale, backPhoto.xScale = xScale, xScale
  frontPhoto.yScale, backPhoto.yScale = yScale, yScale
end

local function saveImage()
  utils.saveImage(frontContainer, { filename = "level." .. levelName .. "." .. elementType .. ".png" })
  navigation.gotoCustomizeLevel(levelName)
end

function scene:create(event)
  background = components.newBackground(self.view)
  content = components.newGroup(self.view)

  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  local cancelButton = components.newImageButton(self.view, "images/cancel.png", 40, 40, { onRelease = goBack })
  cancelButton.anchorX = 0
  cancelButton.anchorY = 0
  cancelButton.x = background.contentBounds.xMin + leftInset + 20
  cancelButton.y = background.contentBounds.yMin + topInset + 20

  local saveButton = components.newImageButton(self.view, "images/accept.png", 40, 40, { onRelease = saveImage })
  saveButton.anchorX = 1
  saveButton.anchorY = 0
  saveButton.x = background.contentBounds.xMax - rightInset - 20
  saveButton.y = background.contentBounds.yMin + topInset + 20
end

function scene:show(event)
  if event.phase == "will" then
    elementType = event.params.elementType
    levelName = event.params.levelName

    local element = elements[elementType]
    local photo = event.params.photo
    local photoScale = display.actualContentWidth / display.pixelWidth
    local photoWidth = photo.width
    local photoHeight = photo.height

    photo.xScale = photoScale
    photo.yScale = photoScale

    local photoName = "element-image." .. math.random() .. ".png"
    display.save(photo, { filename = photoName, baseDir = system.TemporaryDirectory, captureOffscreenArea = true })
    display.remove(photo)

    backPhoto = display.newImageRect(content, photoName, system.TemporaryDirectory, photoWidth, photoHeight)
    backPhoto.x = display.contentCenterX
    backPhoto.y = display.contentCenterY
    backPhoto.alpha = 0.1

    frontContainer = display.newContainer(content, element.width, element.height)
    frontContainer.x = display.contentCenterX
    frontContainer.y = display.contentCenterY

    frontPhoto = display.newImageRect(
      frontContainer,
      photoName,
      system.TemporaryDirectory,
      backPhoto.width,
      backPhoto.height
    )

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
    display.remove(backPhoto)
    display.remove(frontContainer)
    backPhoto = nil
    frontContainer = nil
    frontPhoto = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
