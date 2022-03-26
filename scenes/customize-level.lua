local components = require "components"
local composer = require "composer"
local i18n = require "i18n"
local navigation = require "navigation"
local widget = require "widget"

local elements = nil
local levelName = nil
local scene = composer.newScene()
local scrollview = nil

local function newElement(parent, elementType)
  local element = nil

  if elementType == "ball" then
    element = components.newBall(parent, levelName, 50, 50)
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
  local elementsTypes = { "ball" }
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

  local goBackButton = components.newButton(self.view, { label = i18n("back"), width = 40, onRelease = goBack })
  goBackButton.anchorX = 0
  goBackButton.anchorY = 0
  goBackButton.x = background.contentBounds.xMin + leftInset + 20
  goBackButton.y = background.contentBounds.yMin + topInset + 20

  scrollview = widget.newScrollView({
    left = display.screenOriginX,
    top = goBackButton.contentBounds.yMax + 20,
    width = display.actualContentWidth,
    height = display.actualContentHeight,
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
    local row = components.newGroup(elements)
    row.anchorX, row.anchorY = 0, 0
    row.x, row.y = 15, y

    local element = newElement(row, elementType)

    if element then
      element.x, element.y = 25, 25

      local x = 70

      if media.hasSource(media.PhotoLibrary) then
        local function onSelectPhotoButton(event)
          if event.phase == "ended" then
            media.selectPhoto({ mediaSource = media.PhotoLibrary, listener = function(event)
              if event.target then
                navigation.gotoElementImage(levelName, elementType, event.target)
              end
            end })
          elseif event.phase == "moved" then
            if math.abs(event.y - event.yStart) > 5 then
              scrollview:takeFocus(event)
            end
          end
        end

        local selectPhotoButton = components.newButton(row, {
          label = i18n("select_photo"),
          width = 80,
          onEvent = onSelectPhotoButton,
        })

        selectPhotoButton.anchorX = 0
        selectPhotoButton.x = x
        selectPhotoButton.y = 25

        x = x + selectPhotoButton.width + 10
      end

      if media.hasSource(media.Camera) then
        local function onTakePhotoButton(event)
          if event.phase == "ended" then
            media.capturePhoto({ listener = function(event)
              if event.target then
                navigation.gotoElementImage(levelName, elementType, event.target)
              end
            end })
          elseif event.phase == "moved" then
            if math.abs(event.y - event.yStart) > 5 then
              scrollview:takeFocus(event)
            end
          end
        end

        local takePhotoButton = components.newButton(row, {
          label = i18n("take_photo"),
          width = 80,
          onEvent = onTakePhotoButton,
        })

        takePhotoButton.anchorX = 0
        takePhotoButton.x = x
        takePhotoButton.y = 25

        x = x + takePhotoButton.width + 10
      end

      if not element.isDefault then
        local removeCustomizationButton

        local function onRemoveCustomizationButton(event)
          if event.phase == "ended" then
            local filename = "level." .. levelName .. "." .. elementType .. ".png"
            local filepath = system.pathForFile(filename, system.DocumentsDirectory)
            os.remove(filepath)
            local defaultElement = newElement(row, elementType)
            defaultElement.x, defaultElement.y = element.x, element.y
            defaultElement.alpha = 0
            transition.to(defaultElement, { time = 500, alpha = 1 } )
            transition.to(element, { time = 500, alpha = 0, onComplete = function() display.remove(element) end } )
            display.remove(removeCustomizationButton)
          elseif event.phase == "moved" then
            if math.abs(event.y - event.yStart) > 5 then
              scrollview:takeFocus(event)
            end
          end
        end

        removeCustomizationButton = components.newButton(row, {
          label = i18n("cancel"),
          width = 40,
          onEvent = onRemoveCustomizationButton,
        })

        removeCustomizationButton.anchorX = 0
        removeCustomizationButton.x = x
        removeCustomizationButton.y = 25

        x = x + removeCustomizationButton.width + 10
      end

      y = y + 70
    end
  end
end

function scene:show(event)
  if event.phase == "will" then
    levelName = event.params.levelName
    self:createElements()
  elseif event.phase == "did" then
  end
end

function scene:hide(event)
  if event.phase == "did" then
    display.remove(elements)
    elements = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
