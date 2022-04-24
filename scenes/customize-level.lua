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

  for _, descriptor in ipairs(levelElementDescriptors) do
    local family = descriptor.family
    local name = descriptor.name
    local width, height = descriptor.size(50, 50)

    local primaryStack = layouts.newStack({ parent = self.contentView, separator = 10 })
    primaryStack.x = 20

    local text = display.newText({ text = i18n.t(family .. "-" .. name), font = native.systemFont, fontSize = 20 })
    primaryStack:insert(text)

    local secondaryStack = layouts.newStack({ mode = "horizontal", parent = primaryStack, separator = 5 })

    local elementBlackHole = layouts.newBlackHole({ parent = secondaryStack })
    components.newFrame(elementBlackHole, 80, 80)
    local element = level:newElement(elementBlackHole, family, name, width, height)

    local customizeBlackHole = layouts.newBlackHole({ parent = secondaryStack })
    components.newFrame(customizeBlackHole, 124, 80)
    local customizeStack = layouts.newStack({ mode = "horizontal", parent = customizeBlackHole, separator = 14 })

    local onCapturePhotoOrSelectPhotoComplete = function(filename)
      navigation.gotoElementImage(level, descriptor, filename)
    end
    components.newImageButton(customizeStack, "images/icons/photo.png", 40, 40, {
      onRelease = function() selectPhoto(onCapturePhotoOrSelectPhotoComplete) end,
      scrollView = self.scrollView,
    })
    components.newImageButton(customizeStack, "images/icons/take-photo.png", 40, 40, {
      onRelease = function() capturePhoto(onCapturePhotoOrSelectPhotoComplete) end,
      scrollView = self.scrollView,
    })

    if not element.isDefault then
      local removeBlackHole = layouts.newBlackHole({ parent = secondaryStack })
      local removeFrame = components.newFrame(removeBlackHole, 66, 80)
      components.newImageButton(removeBlackHole, "images/icons/trash.png", 40, 40, {
        onRelease = function(event)
          level:removeImage(family, name)
          local defaultElement = level:newElement(elementBlackHole, family, name, width, height)
          transition.from(defaultElement, { time = 500, alpha = 0 } )
          transition.to(element, { time = 500, alpha = 0, onComplete = function() display.remove(element) end })
          display.remove(removeFrame)
          display.remove(event.target)
        end,
        scrollView = self.scrollView,
      })
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
