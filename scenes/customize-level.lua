local components = require "modules.components"
local composer = require "composer"
local elements = require "modules.elements"
local i18n = require "modules.i18n"
local images = require "modules.images"
local navigation = require "modules.navigation"
local utils = require "modules.utils"
local widget = require "widget"

local elementView = nil
local levelName = nil
local scene = composer.newScene()
local scrollview = nil
local world = nil

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

local function elementTypesFromLevelConfig()
  local config = world:levelConfiguration(levelName)
  local hashSet = { ["background"] = true, ["frame"] = true, ["ball"] = true }
  local elementTypes = {}

  if config.obstacles then
    for index = 1, #config.obstacles do
      local obstacle = config.obstacles[index]
      hashSet["obstacle-" .. obstacle.type] = true
    end
  end

  if config.targets then
    for index = 1, #config.targets do
      local target = config.targets[index]
      hashSet["target-" .. target.type] = true
    end
  end

  for index = 1, #customizableElementTypes do
    local elementType = customizableElementTypes[index]
    if hashSet[elementType] then
      elementTypes[#elementTypes + 1] = elementType
    end
  end

  return elementTypes
end

local function goBack()
  navigation.gotoGame(world, levelName)
end

local function newElement(parent, elementType)
  local element = nil

  if elementType == "background" then
    element = elements.newBackground(parent, world, levelName, 32, 50)
  elseif elementType == "ball" then
    element = elements.newBall(parent, world, levelName, 50, 50)
  elseif elementType == "frame" then
    element = elements.newFrame(parent, world, levelName, 50, 50)
  elseif elementType == "obstacle-corner" then
    element = elements.newObstacleCorner(parent, world, levelName, 50, 50)
  elseif elementType:starts("obstacle-horizontal-barrier") then
    element = elements.newObstacleBarrier(parent, world, levelName, elementType:sub(10), 50, 20)
  elseif elementType:starts("obstacle-vertical-barrier") then
    element = elements.newObstacleBarrier(parent, world, levelName, elementType:sub(10), 20, 50)
  elseif elementType:starts("target-") then
    element = elements.newTarget(parent, world, levelName, elementType:sub(8), 50, 50)
  end

  return element
end

local function newFrame(parent, x, y, width, height)
  local frame = display.newRoundedRect(parent, x, y, width, height, 5)
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
  local screenX = display.screenOriginX
  local screenY = display.screenOriginY
  local screenWidth = display.actualContentWidth
  local screenHeight = display.actualContentHeight
  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  components.newBackground(self.view)

  local topBar = components.newTopBar(self.view)

  local goBackButton = components.newImageButton(self.view, "images/icons/back.png", 40, 40, { onRelease = goBack })
  goBackButton.anchorX = 0
  goBackButton.anchorY = 0
  goBackButton.x = screenX + leftInset + 20
  goBackButton.y = screenY + topInset + 10

  scrollview = widget.newScrollView({
    left = screenX,
    top = topBar.y + topBar.height,
    width = screenWidth,
    height = screenHeight - topBar.height,
    hideBackground = true,
    hideScrollBar = true,
    horizontalScrollDisabled = true,
    topPadding = 20,
    bottomPadding = 20,
    leftPadding = leftInset,
    rightPadding = rightInset,
  })

  self.view:insert(scrollview)
end

function scene:createElementView()
  local elementTypes = elementTypesFromLevelConfig()
  local y = 0

  elementView = components.newGroup(scrollview)

  for _, elementType in ipairs(elementTypes) do
    if table.indexOf(customizableElementTypes, elementType) ~= nil then
      local elementGroup = components.newGroup(elementView)
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
        navigation.gotoElementImage(world, levelName, elementType, filename)
      end

      local selectPhotoButton = components.newImageButton(
        elementGroup,
        "images/icons/photo.png",
        40,
        40,
        {
          onRelease = function() selectPhoto(onCapturePhotoOrSelectPhotoComplete) end,
          scrollview = scrollview
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
          scrollview = scrollview
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
              images.removeLevelImage(world, levelName, elementType)
              local defaultElement = newElement(elementGroup, elementType)
              defaultElement.x = element.x
              defaultElement.y = element.y
              defaultElement.alpha = 0
              transition.to(defaultElement, { time = 500, alpha = 1 } )
              transition.to(element, { time = 500, alpha = 0, onComplete = function() display.remove(element) end } )
              display.remove(removeCustomizationButtonFrame)
              display.remove(removeCustomizationButton)
            end,
            scrollview = scrollview
          }
        )
        removeCustomizationButton.x = removeCustomizationButtonFrame.x + removeCustomizationButtonFrame.width / 2
        removeCustomizationButton.y = element.y
      end

      y = y + elementGroup.height + 20
    end
  end
end

function scene:show(event)
  if event.phase == "will" then
    local isNewLevel = false

    if world and levelName then
      isNewLevel = world ~= event.params.world or levelName ~= event.params.levelName
    end

    world = event.params.world
    levelName = event.params.levelName

    self:createElementView()

    if isNewLevel then
      scrollview:scrollTo("top", { time = 0 })
    end
  end
end

function scene:hide(event)
  if event.phase == "did" then
    transition.cancel()
    display.remove(elementView)
    elementView = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
