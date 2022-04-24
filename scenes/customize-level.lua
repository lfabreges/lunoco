local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local layouts = require "modules.layouts"
local navigation = require "modules.navigation"
local utils = require "modules.utils"

local level = nil
local scene = composer.newScene()
local screenX = display.screenOriginX
local screenY = display.screenOriginY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight

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

local function goBack()
  navigation.gotoGame(level)
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
  self.contentView = layouts.newStack({ parent = self.scrollView, separator = 20 })

  local levelConfiguration = level:configuration()
  local elementDescriptors = level:elementDescriptors()
  local levelElements = {}
  local levelElementDescriptors = {}

  for _, configuration in pairs(levelConfiguration.obstacles) do
    utils.nestedSet(levelElements, "obstacle", configuration.name, true)
  end
  for _, configuration in pairs(levelConfiguration.targets) do
    utils.nestedSet(levelElements, "target", configuration.name, true)
  end
  for _, elementDescriptor in ipairs(elementDescriptors) do
    if   elementDescriptor.family == "root"
      or utils.nestedGet(levelElements, elementDescriptor.family, elementDescriptor.name)
    then
      levelElementDescriptors[#levelElementDescriptors + 1] = elementDescriptor
    end
  end

  for _, elementDescriptor in ipairs(levelElementDescriptors) do
    local elementFamily = elementDescriptor.family
    local elementName = elementDescriptor.name
    local elementGroup = components.newGroup(self.contentView)

    local elementText = display.newText({
      text = i18n.t(elementFamily .. "-" .. elementName),
      font = native.systemFont,
      fontSize = 20,
      parent = elementGroup,
      x = 20,
      y = 0,
    })
    elementText.anchorX = 0
    elementText.anchorY = 0

    local elementFrame = newFrame(elementGroup, 20, elementText.height + 50, 78, 78)

    local elementWidth, elementHeight = elementDescriptor.size(50, 50)
    local element = level:newElement(elementGroup, elementFamily, elementName, elementWidth, elementHeight)
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
      navigation.gotoElementImage(level, elementDescriptor, filename)
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
            level:removeImage(elementFamily, elementName)
            local defaultElement = level:newElement(elementGroup, elementFamily, elementName, width, height)
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
