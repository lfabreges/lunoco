local components = require "components"
local composer = require "composer"
local i18n = require "i18n"
local navigation = require "navigation"
local utils = require "utils"
local widget = require "widget"

local elements = nil
local levelName = nil
local scene = composer.newScene()
local scrollview = nil

local function newElement(parent, elementType)
  local element = nil

  if elementType == "ball" then
    element = components.newBall(parent, levelName, 50, 50)
  elseif elementType == "frame" then
    element = components.newFrame(parent, levelName, 50, 50)
  elseif elementType == "obstacle-corner" then
    element = components.newObstacleCorner(parent, levelName, 50, 50)
  elseif elementType:starts("obstacle-horizontal-barrier") then
    element = components.newObstacleBarrier(parent, levelName, elementType:sub(10), 50, 20)
  elseif elementType:starts("obstacle-vertical-barrier") then
    element = components.newObstacleBarrier(parent, levelName, elementType:sub(10), 20, 50)
  elseif elementType:starts("target-") then
    element = components.newTarget(parent, levelName, elementType:sub(8), 50, 50)
  end

  return element
end

local function elementsTypesFromLevelConfig()
  local config = require ("levels." .. levelName)
  local elementsTypes = { "ball", "frame" }
  local hashset = {}

  for _, obstacle in pairs(config.obstacles) do
    hashset["obstacle-" .. obstacle.type] = true
  end
  for _, target in pairs(config.targets) do
    hashset["target-" .. target.type] = true
  end
  for elementType, _ in pairs(hashset) do
    table.insert(elementsTypes, elementType)
  end

  table.sort(elementsTypes)
  return elementsTypes
end

local function goBack()
  navigation.gotoGame(levelName)
end

function scene:create(event)
  local background = components.newBackground(self.view)
  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  local goBackButton = components.newImageButton(self.view, "images/icons/back.png", 40, 40, { onRelease = goBack })
  goBackButton.anchorX = 0
  goBackButton.anchorY = 0
  goBackButton.x = background.contentBounds.xMin + leftInset + 20
  goBackButton.y = background.contentBounds.yMin + topInset + 20

  scrollview = widget.newScrollView({
    left = display.screenOriginX,
    top = goBackButton.contentBounds.yMax + 20,
    width = display.actualContentWidth,
    height = display.actualContentHeight - goBackButton.height - 40,
    hideBackground = true,
    hideScrollBar = true,
    horizontalScrollDisabled = true,
    topPadding = 0,
    bottomPadding = bottomInset + 20,
    leftPadding = leftInset,
    rightPadding = rightInset,
  })

  self.view:insert(scrollview)
end

function scene:createElements()
  local elementsTypes = elementsTypesFromLevelConfig()
  local y = 0

  elements = components.newGroup(scrollview)

  for _, elementType in ipairs(elementsTypes) do
    local elementGroup = components.newGroup(elements)

    local elementText = display.newText({
      text = i18n.t(elementType),
      font = native.systemFont,
      fontSize = 20,
      parent = elementGroup,
      x = 20,
      y = 0,
    })

    elementText.anchorX, elementText.anchorY = 0, 0

    local elementFrame = display.newRoundedRect(elementGroup, 60, elementText.height + 50, 80, 80, 10)
    local element = newElement(elementGroup, elementType)

    if not element then
      display.remove(elementGroup)
    else
      elementGroup.y = y
      elementFrame:setFillColor(0.5)
      element.x, element.y = elementFrame.x, elementFrame.y

      local x = elementFrame.x + elementFrame.width / 2 + 20

      if media.hasSource(media.PhotoLibrary) then
        local function onSelectPhotoButton(event)
          media.selectPhoto({ mediaSource = media.PhotoLibrary, listener = function(event)
            if event.completed then
              navigation.gotoElementImage(levelName, elementType, event.target)
            end
          end })
        end

        local selectPhotoButton = components.newImageButton(
          elementGroup,
          "images/icons/select-photo.png",
          40,
          40,
          { onRelease = onSelectPhotoButton, scrollview = scrollview }
        )

        selectPhotoButton.anchorX = 0
        selectPhotoButton.x = x
        selectPhotoButton.y = element.y

        x = x + selectPhotoButton.width + 20
      end

      if media.hasSource(media.Camera) then
        local function onTakePhotoButton(event)
          media.capturePhoto({ listener = function(event)
            if event.completed then
              navigation.gotoElementImage(levelName, elementType, event.target)
            end
          end })
        end

        local takePhotoButton = components.newImageButton(
          elementGroup,
          "images/icons/take-photo.png",
          40,
          40,
          { onRelease = onTakePhotoButton, scrollview = scrollview }
        )

        takePhotoButton.anchorX = 0
        takePhotoButton.x = x
        takePhotoButton.y = element.y

        x = x + takePhotoButton.width + 20
      end

      if not element.isDefault then
        local removeCustomizationButton

        local function onRemoveCustomizationButton(event)
          utils.removeLevelImage(levelName, elementType)
          local defaultElement = newElement(elementGroup, elementType)
          defaultElement.x, defaultElement.y = element.x, element.y
          defaultElement.alpha = 0
          transition.to(defaultElement, { time = 500, alpha = 1 } )
          transition.to(element, { time = 500, alpha = 0, onComplete = function() display.remove(element) end } )
          display.remove(removeCustomizationButton)
        end

        removeCustomizationButton = components.newImageButton(
          elementGroup,
          "images/icons/cancel.png",
          40,
          40,
          { onRelease = onRemoveCustomizationButton, scrollview = scrollview }
        )

        removeCustomizationButton.anchorX = 0
        removeCustomizationButton.x = x
        removeCustomizationButton.y = element.y

        x = x + removeCustomizationButton.width + 20
      end

      y = y + elementGroup.height + 20
    end
  end
end

function scene:show(event)
  if event.phase == "will" then
    local isNewLevel = levelName and levelName ~= event.params.levelName
    levelName = event.params.levelName
    self:createElements()
    if isNewLevel then
      scrollview:scrollTo("top", { time = 0 })
    end
  end
end

function scene:hide(event)
  if event.phase == "did" then
    transition.cancel()
    display.remove(elements)
    elements = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
