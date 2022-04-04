local components = require "modules.components"
local composer = require "composer"
local elements = require "modules.elements"
local i18n = require "modules.i18n"
local navigation = require "modules.navigation"
local utils = require "modules.utils"
local widget = require "widget"

local elementView = nil
local levelName = nil
local scene = composer.newScene()
local scrollviews = {}
local selectedTab = 1
local soundView = nil
local tabBar = nil
local tabButtons = {}
local tabGroup = nil

local elementTypes = {
  "background",
  "frame",
  "ball",
  "obstacle-corner",
  "obstacle-horizontal-barrier",
  "obstacle-horizontal-barrier-large",
  "obstacle-vertical-barrier",
  "target-easy",
  "target-normal",
  "target-hard",
}

local function newElement(parent, elementType)
  local element = nil

  if elementType == "background" then
    element = elements.newBackground(parent, levelName, 32, 50)
  elseif elementType == "ball" then
    element = elements.newBall(parent, levelName, 50, 50)
  elseif elementType == "frame" then
    element = elements.newFrame(parent, levelName, 50, 50)
  elseif elementType == "obstacle-corner" then
    element = elements.newObstacleCorner(parent, levelName, 50, 50)
  elseif elementType:starts("obstacle-horizontal-barrier") then
    element = elements.newObstacleBarrier(parent, levelName, elementType:sub(10), 50, 20)
  elseif elementType:starts("obstacle-vertical-barrier") then
    element = elements.newObstacleBarrier(parent, levelName, elementType:sub(10), 20, 50)
  elseif elementType:starts("target-") then
    element = elements.newTarget(parent, levelName, elementType:sub(8), 50, 50)
  end

  return element
end

local function elementTypesFromLevelConfig()
  local config = require ("levels." .. levelName)
  local hashSet = { ["background"] = true, ["frame"] = true, ["ball"] = true }
  local levelElementTypes = {}

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

  for index = 1, #elementTypes do
    local elementType = elementTypes[index]
    if hashSet[elementType] then
      levelElementTypes[#levelElementTypes + 1] = elementType
    end
  end

  return levelElementTypes
end

local function goBack()
  navigation.gotoGame(levelName)
end

local function selectTab(index)
  if index ~= selectedTab then
    transition.to(tabGroup, { time = 100, x = (index - 1) * -display.actualContentWidth })
    tabButtons[selectedTab].fill.effect = "filter.grayscale"
    tabButtons[index].fill.effect = nil
    selectedTab = index
  else
    scrollviews[index]:scrollTo("top", {})
  end
end

function scene:create(event)
  local screenX = display.screenOriginX
  local screenY = display.screenOriginY
  local screenWidth = display.actualContentWidth
  local screenHeight = display.actualContentHeight
  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  components.newBackground(self.view)

  local topBar = display.newRect(self.view, screenX, screenY, screenWidth, topInset + 60)
  topBar.anchorX = 0
  topBar.anchorY = 0
  topBar:setFillColor(0.15)

  local goBackButton = components.newImageButton(self.view, "images/icons/back.png", 40, 40, { onRelease = goBack })
  goBackButton.anchorX = 0
  goBackButton.anchorY = 0
  goBackButton.x = screenX + leftInset + 20
  goBackButton.y = screenY + topInset + 10

  --[[
  tabBar = display.newRect(self.view, screenX, screenY + screenHeight, screenWidth, bottomInset + 60)
  tabBar.anchorX = 0
  tabBar.anchorY = 1
  tabBar:setFillColor(0.15)

  tabButtons[1] = components.newImageButton(
    self.view,
    "images/icons/photo.png",
    40,
    40,
    { onRelease = function() selectTab(1) end }
  )
  tabButtons[1].x = screenX + screenWidth / 4
  tabButtons[1].y = tabBar.y - bottomInset - (tabBar.height - bottomInset) / 2

  tabButtons[2] = components.newImageButton(
    self.view,
    "images/icons/sound.png",
    40,
    40,
    { onRelease = function() selectTab(2) end }
  )
  tabButtons[2].x = screenX + screenWidth - screenWidth / 4
  tabButtons[2].y = tabButtons[1].y
  tabButtons[2].fill.effect = "filter.grayscale"
  ]]

  tabGroup = components.newGroup(self.view)

  -- TODO passer à deux pour intégrer l'onglet sons
  for index = 1, 1 do
    scrollviews[index] = widget.newScrollView({
      left = screenX + (index - 1) * screenWidth,
      top = topBar.y + topBar.height,
      width = screenWidth,
      height = screenHeight - topBar.height, -- - tabBar.height,
      hideBackground = true,
      hideScrollBar = true,
      horizontalScrollDisabled = true,
      topPadding = 20,
      bottomPadding = 20,
      leftPadding = leftInset,
      rightPadding = rightInset,
    })
    tabGroup:insert(scrollviews[index])
  end
end

function scene:createElementView()
  local elementTypes = elementTypesFromLevelConfig()
  local y = 0

  elementView = components.newGroup(scrollviews[1])

  for _, elementType in ipairs(elementTypes) do
    local elementGroup = components.newGroup(elementView)

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

    local elementFrame = display.newRoundedRect(elementGroup, 60, elementText.height + 50, 80, 80, 10)
    local element = newElement(elementGroup, elementType)

    if not element then
      display.remove(elementGroup)
    else
      elementGroup.y = y
      elementFrame:setFillColor(0.5)
      element.x = elementFrame.x
      element.y = elementFrame.y

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
          "images/icons/photo.png",
          40,
          40,
          { onRelease = onSelectPhotoButton, scrollview = scrollviews[1] }
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
          { onRelease = onTakePhotoButton, scrollview = scrollviews[1] }
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
          defaultElement.x = element.x
          defaultElement.y = element.y
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
          { onRelease = onRemoveCustomizationButton, scrollview = scrollviews[1] }
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

function scene:createSoundView()
  soundView = components.newGroup(scrollviews[2])
  --[[
  local playButton = components.newImageButton(
    soundView,
    "images/icons/sound.png",
    40,
    40,
    { onRelease = function()
      media.playSound("newRecording.aif", system.DocumentsDirectory)
    end }
  )
  playButton.x = 40
  playButton.y = 100

  local filePath = system.pathForFile("newRecording.aif", system.DocumentsDirectory)
  local recording = media.newRecording(filePath)

  local recordButton = components.newImageButton(
    soundView,
    "images/icons/accept.png",
    40,
    40,
    { onEvent = function(event)
        if event.phase == "began" then
          recording:startRecording()
        elseif event.phase == "ended" or event.phase == "cancelled" then
          recording:stopRecording()
        end
      end
    }
  )
  recordButton.x = 100
  recordButton.y = 100
  ]]
end

function scene:show(event)
  if event.phase == "will" then
    local isNewLevel = levelName and levelName ~= event.params.levelName
    levelName = event.params.levelName

    self:createElementView()
    -- self:createSoundView()

    if isNewLevel then
      scrollviews[1]:scrollTo("top", { time = 0 })
      --[[
      local scrollSoundsTabToTop = function() scrollviews[2]:scrollTo("top", { time = 0 }) end
      scrollviews[1]:scrollTo("top", { time = 0, onComplete = scrollSoundsTabToTop })

      if selectedTab ~= 1 then
        tabButtons[selectedTab].fill.effect = "filter.grayscale"
        tabButtons[1].fill.effect = nil
        selectedTab = 1
        tabGroup.x = 0
      end
      ]]
    end
  end
end

function scene:hide(event)
  if event.phase == "did" then
    transition.cancel()
    display.remove(elementView)
    display.remove(soundView)
    elementView = nil
    soundView = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
