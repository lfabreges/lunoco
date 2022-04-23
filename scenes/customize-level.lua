local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local navigation = require "modules.navigation"
local utils = require "modules.utils"

local level = nil
local scene = composer.newScene()
local screenX = display.screenOriginX
local screenY = display.screenOriginY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight

local customizableElementTypes = {
  "background",
  "frame",
  "ball",
  "obstacle-corner",
  "obstacle-horizontal-barrier",
  "obstacle-horizontal-barrier-large",
  "obstacle-vertical-barrier",
  "obstacle-vertical-barrier-large",
  "target-easy",
  "target-normal",
  "target-hard",
}

local function captureAndSelectPhotoOptions(onComplete)
  local filename = "element-image." .. math.random() .. ".png"
  local options = {}

  if utils.isAndroid() then
    options.destination = { filename = filename, baseDir = system.TemporaryDirectory }
    options.listener = function(event)
      if event.completed and utils.fileExists(filename, system.TemporaryDirectory) then
        onComplete(filename)
      end
    end
  else
    options.listener = function(event)
      if event.completed then
        local photo = event.target
        photo.xScale = display.actualContentWidth / display.pixelWidth
        photo.yScale = photo.xScale
        display.save(photo, { filename = filename, baseDir = system.TemporaryDirectory, captureOffscreenArea = true })
        display.remove(photo)
        onComplete(filename)
      end
    end
  end

  return options
end

local function capturePhoto(onComplete, shouldRequestAppPermission)
  local hasAccessToCamera, hasCamera = media.hasSource(media.Camera)
  shouldRequestAppPermission = shouldRequestAppPermission == nil and true or shouldRequestAppPermission

  if hasAccessToCamera then
    local options = captureAndSelectPhotoOptions(onComplete)
    media.capturePhoto(options)
  elseif shouldRequestAppPermission and hasCamera and native.canShowPopup("requestAppPermission") then
    native.showPopup("requestAppPermission", {
      appPermission = "Camera",
      listener = function() capturePhoto(onComplete, false) end,
    })
  else
    native.showAlert(i18n.t("permission-denied"), i18n.t("permission-denied-camera"), { i18n.t("ok") })
  end
end

local function elementTypesFromLevelConfiguration()
  local configuration = level:configuration()
  local levelElementTypeSet = { ["background"] = true, ["frame"] = true, ["ball"] = true }
  local elementTypes = {}

  for _, elementConfiguration in pairs(configuration.obstacles) do
    levelElementTypeSet["obstacle-" .. elementConfiguration.type] = true
  end
  for _, elementConfiguration in pairs(configuration.targets) do
    levelElementTypeSet["target-" .. elementConfiguration.type] = true
  end
  for _, elementType in ipairs(customizableElementTypes) do
    if levelElementTypeSet[elementType] then
      elementTypes[#elementTypes + 1] = elementType
    end
  end

  return elementTypes
end

local function goBack()
  navigation.gotoGame(level)
end

local function newElement(parent, elementType)
  local element = nil

  if elementType == "background" then
    element = level:newBackground(parent, 32, 50)
  elseif elementType == "ball" then
    element = level:newBall(parent, 50, 50)
  elseif elementType == "frame" then
    element = level:newFrame(parent, 50, 50)
  elseif elementType == "obstacle-corner" then
    element = level:newObstacleCorner(parent, 50, 50)
  elseif elementType:starts("obstacle-horizontal-barrier") then
    element = level:newObstacleBarrier(parent, elementType:sub(10), 50, 20)
  elseif elementType:starts("obstacle-vertical-barrier") then
    element = level:newObstacleBarrier(parent, elementType:sub(10), 20, 50)
  elseif elementType:starts("target-") then
    element = level:newTarget(parent, elementType:sub(8), 50, 50)
  end

  return element
end

local function newFrame(parent, x, y, width, height)
  local frame = display.newRoundedRect(x, y, width, height, 5)
  parent:insert(frame)
  frame.anchorX = 0
  frame:setFillColor(0.5, 0.5, 0.5, 0.25)
  frame:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  frame.strokeWidth = 1
  return frame
end

local function selectPhoto(onComplete)
  if media.hasSource(media.PhotoLibrary) then
    local options = captureAndSelectPhotoOptions(onComplete)
    options.mediaSource = media.PhotoLibrary
    media.selectPhoto(options)
  else
    native.showAlert(i18n.t("permission-denied"), i18n.t("permission-denied-photo-library"), { i18n.t("ok") })
  end
end

function scene:create(event)
  components.newBackground(self.view)

  local topBar = components.newTopBar(self.view, { goBack = goBack })

  self.scrollView = components.newScrollView(self.view, {
    top = topBar.contentBounds.yMax,
    height = screenHeight - topBar.contentHeight,
    topPadding = 20,
    bottomPadding = 20,
  })
end

function scene:createContentView()
  local elementTypes = elementTypesFromLevelConfiguration()
  local y = 0

  self.contentView = components.newGroup(self.scrollView)

  for _, elementType in ipairs(elementTypes) do
    local elementGroup = components.newGroup(self.contentView)
    elementGroup.y = y

    local elementText = display.newText({
      text = i18n.t(elementType),
      font = native.systemFont,
      fontSize = 20,
      parent = elementGroup,
      x = 20,
      y = 0,
    })
    elementText.anchorX = 0
    elementText.anchorY = 0

    local elementFrame = newFrame(elementGroup, 20, elementText.height + 50, 78, 78)

    local element = newElement(elementGroup, elementType)
    element.x = elementFrame.x + elementFrame.width / 2
    element.y = elementFrame.y

    local customizeButtonsFrame = newFrame(
      elementGroup,
      elementFrame.x + elementFrame.width + 5,
      element.y,
      122,
      78
    )

    local onCapturePhotoOrSelectPhotoComplete = function(filename)
      navigation.gotoElementImage(level, elementType, filename)
    end

    local selectPhotoButton = components.newImageButton(
      elementGroup,
      "images/icons/photo.png",
      40,
      40,
      {
        onRelease = function() selectPhoto(onCapturePhotoOrSelectPhotoComplete) end,
        scrollView = self.scrollView
      }
    )
    selectPhotoButton.anchorX = 0
    selectPhotoButton.x = customizeButtonsFrame.x + 14
    selectPhotoButton.y = element.y

    local takePhotoButton = components.newImageButton(
      elementGroup,
      "images/icons/take-photo.png",
      40,
      40,
      {
        onRelease = function() capturePhoto(onCapturePhotoOrSelectPhotoComplete) end,
        scrollView = self.scrollView
      }
    )
    takePhotoButton.anchorX = 0
    takePhotoButton.x = selectPhotoButton.x + selectPhotoButton.width + 14
    takePhotoButton.y = element.y

    if not element.isDefault then
      local removeCustomizationButtonFrame = newFrame(
        elementGroup,
        customizeButtonsFrame.x + customizeButtonsFrame.width + 5,
        element.y,
        64,
        78
      )

      local removeCustomizationButton

      removeCustomizationButton = components.newImageButton(
        elementGroup,
        "images/icons/trash.png",
        40,
        40,
        {
          onRelease = function()
            level:removeImage(elementType)
            local defaultElement = newElement(elementGroup, elementType)
            defaultElement.x = element.x
            defaultElement.y = element.y
            defaultElement.alpha = 0
            transition.to(defaultElement, { time = 500, alpha = 1 } )
            transition.to(element, { time = 500, alpha = 0, onComplete = function() display.remove(element) end } )
            display.remove(removeCustomizationButtonFrame)
            display.remove(removeCustomizationButton)
          end,
          scrollView = self.scrollView
        }
      )
      removeCustomizationButton.x = removeCustomizationButtonFrame.x + removeCustomizationButtonFrame.width / 2
      removeCustomizationButton.y = element.y
    end

    y = y + elementGroup.height + 20
  end
end

function scene:show(event)
  if event.phase == "will" then
    local isNewLevel = level and level ~= event.params.level
    level = event.params.level
    self:createContentView()
    if isNewLevel then
      self.scrollView:scrollTo("top", { time = 0 })
    end
  end
end

function scene:hide(event)
  if event.phase == "did" then
    transition.cancelAll()
    display.remove(self.contentView)
    self.contentView = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
