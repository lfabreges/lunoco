local components = require "modules.components"
local composer = require "composer"
local multitouch = require "libraries.multitouch"
local utils = require "modules.utils"
local widget = require "widget"

local elements = nil
local level = nil
local levelView = nil
local max = math.max
local min = math.min
local scene = composer.newScene()
local selectedElement = nil
local sideBar = nil

local elementDefaults = {
  ["obstacle-corner"] = {
    width = 80,
    height = 80,
    minWidth = 40,
    minHeight = 40,
    maxWidth = 150,
    maxHeight = 150,
    canRotate = true,
  },
  ["obstacle-horizontal-barrier"] = {
    width = 100,
    height = 30,
    minWidth = 30,
    minHeight = 30,
    maxWidth = 150,
    maxHeight = 60,
  },
  ["obstacle-horizontal-barrier-large"] = {
    width = 150,
    height = 30,
    minWidth = 100,
    minHeight = 30,
    maxWidth = 300,
    maxHeight = 120,
  },
  ["obstacle-vertical-barrier"] = {
    width = 30,
    height = 100,
    minWidth = 30,
    minHeight = 30,
    maxWidth = 60,
    maxHeight = 150,
  },
  ["obstacle-vertical-barrier-large"] = {
    width = 30,
    height = 200,
    minWidth = 30,
    minHeight = 100,
    maxWidth = 150,
    maxHeight = 460,
  },
  ["target-easy"] = {
    width = 40,
    height = 40,
    minWidth = 30,
    minHeight = 30,
    maxWidth = 80,
    maxHeight = 80,
  },
  ["target-normal"] = {
    width = 40,
    height = 40,
    minWidth = 30,
    minHeight = 30,
    maxWidth = 80,
    maxHeight = 80,
  },
  ["target-hard"] = {
    width = 40,
    height = 40,
    minWidth = 30,
    minHeight = 30,
    maxWidth = 80,
    maxHeight = 80,
  },
}

local elementTypes = {
  "obstacle-corner",
  "obstacle-horizontal-barrier",
  "obstacle-horizontal-barrier-large",
  "obstacle-vertical-barrier",
  "obstacle-vertical-barrier-large",
  "target-easy",
  "target-normal",
  "target-hard",
}

local function clearElementSelection()
  if selectedElement then
    display.remove(selectedElement.handle)
    selectedElement.handle = nil
    selectedElement = nil
  end
end

local function newElement(parent, elementType)
  if elementType == "obstacle-corner" then
    return level:newObstacleCorner(parent, 50, 50)
  elseif elementType:starts("obstacle-horizontal-barrier") then
    return level:newObstacleBarrier(parent, elementType:sub(10), 50, 20)
  elseif elementType:starts("obstacle-vertical-barrier") then
    return level:newObstacleBarrier(parent, elementType:sub(10), 20, 50)
  elseif elementType:starts("target-") then
    return level:newTarget(parent, elementType:sub(8), 50, 50)
  end
end

local function onBlur(event)
end

local function onFocus(event)
  local element = event.target.element
  element.xStart = element.x
  element.yStart = element.y
  element.xDeltaCorrection = 0
  element.yDeltaCorrection = 0
  element.contentWidthStart = element.contentWidth
  element.contentHeightStart = element.contentHeight
end

local function onMoveAndPinch(event)
  local element = event.target.element
  local defaults = elementDefaults[element.family .. "-" .. element.type]
  local xDeltaCorrection = 0
  local yDeltaCorrection = 0

  if event.xDistanceDelta and (element.family == "obstacle" or element.family == "target") then
    local minWidth = defaults.minWidth
    local maxWidth = defaults.maxWidth
    local minHeight = defaults.minHeight
    local maxHeight = defaults.maxHeight
    local newWidth = min(maxWidth, max(minWidth, element.contentWidthStart + event.xDistanceDelta))
    local newHeight = min(maxHeight, max(minHeight, element.contentHeightStart + event.yDistanceDelta))
    newWidth = newWidth - newWidth % 5
    newHeight = newHeight - newHeight % 5

    element.xScale = newWidth / element.width
    element.yScale = newHeight / element.height
    element.xDeltaCorrection = (element.anchorX - 0.5) * (newWidth - element.contentWidthStart)
    element.yDeltaCorrection = (element.anchorY - 0.5) * (newHeight - element.contentHeightStart)

    element.handle.path.width = element.contentWidth + 40
    element.handle.path.height = element.contentHeight + 40
  end

  element.x = element.xStart + event.xDelta + element.xDeltaCorrection
  element.y = element.yStart + event.yDelta + element.yDeltaCorrection
  element.x = element.x - element.x % 5
  element.y = element.y - element.y % 5

  local elementBounds = element.contentBounds
  local levelBounds = elements.background.contentBounds

  if elementBounds.xMax > levelBounds.xMax then
    element.x = element.x - (elementBounds.xMax - levelBounds.xMax)
  elseif elementBounds.xMin < levelBounds.xMin then
    element.x = element.x - (elementBounds.xMin - levelBounds.xMin)
  end
  if elementBounds.yMax > levelBounds.yMax then
    element.y = element.y - (elementBounds.yMax - levelBounds.yMax)
  elseif elementBounds.yMin < levelBounds.yMin then
    element.y = element.y - (elementBounds.yMin - levelBounds.yMin)
  end

  element.handle.x = element.contentBounds.xMin + element.contentWidth * 0.5
  element.handle.y = element.contentBounds.yMin + element.contentHeight * 0.5
end

function scene:create(event)
  level = event.params.level

  levelView = components.newGroup(self.view)
  elements = level:createElements(levelView)
  self:configureElement(elements.ball)

  for _, element in pairs(elements.obstacles) do
    self:configureElement(element)
  end
  for _, element in pairs(elements.targets) do
    self:configureElement(element)
  end

  scene:createSideBar()

  elements.frame:addEventListener("tap", function(event)
    if event.numTaps == 2 and not sideBar.isOpened then
      sideBar.open()
    end
    return true
  end)

  -- TODO Pour du debug uniquement ? Sinon gérer le cancel dans le hide
  timer.performWithDelay(5000, function()
    local configuration = level:createConfiguration(elements)
    local json = require "json"
    print(json.prettify(configuration))
    --[[utils.saveJson(configuration, level.world.directory .. "/" .. level.name .. ".json", system.DocumentsDirectory)

    local worldConfig = utils.loadJson(level.world.directory .. ".json", system.DocumentsDirectory)
    worldConfig.levels = worldConfig.levels or {}

    local levelIndex = nil

    for index, levelName in ipairs(worldConfig.levels) do
      if levelName == level.name then
        levelIndex = index
        break
      end
    end

    worldConfig.levels[levelIndex or #worldConfig.levels + 1] = level.name
    utils.saveJson(worldConfig, level.world.directory .. ".json", system.DocumentsDirectory)]]
  end, -1)
end

function scene:createSideBar()
  local middleGround = display.newRect(self.view, 0, 0, display.actualContentWidth, display.actualContentHeight)
  middleGround.anchorX = 0
  middleGround.anchorY = 0
  middleGround.isVisible = false
  middleGround.isHitTestable = true

  middleGround:addEventListener("touch", function(event)
    if event.phase == "began" then
      if selectedElement and not utils.isEventWithinBounds(selectedElement.handle, event) then
        clearElementSelection()
      end
      if sideBar.isOpened then
        sideBar.close()
      end
    end
    return false
  end)

  sideBar = components.newGroup(self.view)

  local sideBarBackground = components.newBackground(sideBar)
  sideBarBackground.width = 106
  sideBarBackground:addEventListener("tap", function() return true end)
  sideBarBackground:addEventListener("touch", function() return true end)

  local sideBarHandle = components.newGroup(sideBar)
  sideBarHandle.x = sideBarBackground.x + 100
  sideBarHandle.y = display.contentCenterY

  local sideBarHandleBackground = display.newRect(sideBarHandle, 1, 0, 10, sideBarBackground.height)
  sideBarHandleBackground.isVisible = false
  sideBarHandleBackground.isHitTestable = true

  local sideBarHandleOne = display.newLine(sideBarHandle, -1, -15, -1, 15)
  local sideBarHandleTwo = display.newLine(sideBarHandle, 1, -15, 1, 15)
  sideBarHandleOne:setStrokeColor(0.75, 0.75, 0.75, 1)
  sideBarHandleTwo:setStrokeColor(0.75, 0.75, 0.75, 1)

  local sideBarMinX = sideBar.x - sideBarBackground.width + sideBarHandleBackground.width
  local sideBarMaxX = sideBar.x

  sideBar.x = sideBarMinX
  sideBar.isOpened = false

  sideBar.open = function()
    transition.to(sideBar, { x = sideBarMaxX, time = 100 })
    sideBar.isOpened = true
  end

  sideBar.close = function()
    transition.to(sideBar, { x = sideBarMinX, time = 100 })
    sideBar.isOpened = false
  end

  sideBar.toggle = function()
    if sideBar.isOpened then
      sideBar.close()
    else
      sideBar.open()
    end
  end

  sideBarHandleBackground:addEventListener("touch", function(event)
    if event.phase == "began" then
      transition.cancel(sideBar)
      display.getCurrentStage():setFocus(sideBarHandleBackground, event.id)
      sideBarHandleBackground.isFocus = true
      sideBar.xStart = sideBar.x
    elseif sideBarHandleBackground.isFocus then
      if event.phase == "moved" then
        local x = sideBar.xStart + (event.x - event.xStart)
        sideBar.x = x < sideBarMinX and sideBarMinX or x > sideBarMaxX and sideBarMaxX or x
      elseif event.phase == "ended" or event.phase == "cancelled" then
        display.getCurrentStage():setFocus(sideBarHandleBackground, nil)
        sideBarHandleBackground.isFocus = false
        if math.abs(sideBar.x - sideBar.xStart) > 20 then
          sideBar.toggle()
        elseif sideBar.isOpened then
          sideBar.open()
        else
          sideBar.close()
        end
      end
    end
  end)

  local screenY = display.screenOriginY
  local screenHeight = display.actualContentHeight

  local scrollview = widget.newScrollView({
    left = sideBarBackground.x,
    top = sideBarBackground.y,
    width = sideBarBackground.width - 10,
    height = sideBarBackground.height,
    hideBackground = true,
    hideScrollBar = true,
    horizontalScrollDisabled = true,
    topPadding = 10 + (elements.background.y - screenY),
    bottomPadding = 10 + (screenY + screenHeight) - (elements.background.y + elements.background.height),
  })

  sideBar:insert(scrollview)

  local scrollviewContent = components.newGroup(scrollview)
  local y = 0

  for _, elementType in ipairs(elementTypes) do
    local frame = display.newRoundedRect(scrollviewContent, 10, y, 78, 78, 5)
    frame.anchorX = 0
    frame.anchorY = 0
    frame:setFillColor(0.5, 0.5, 0.5, 0.25)
    frame:setStrokeColor(0.5, 0.5, 0.5, 0.75)
    frame.strokeWidth = 1

    local elementGroup = components.newGroup(scrollviewContent)

    local elementBackground = display.newRect(elementGroup, frame.x, frame.y, frame.width, frame.height)
    elementBackground.anchorX = frame.anchorX
    elementBackground.anchorY = frame.anchorY
    elementBackground.isVisible = false
    elementBackground.isHitTestable = true

    local element = newElement(elementGroup, elementType)
    element.x = frame.x + frame.width * 0.5
    element.y = frame.y + frame.height * 0.5

    local elementButton = components.newObjectButton(elementGroup, {
      onRelease = function() scene:newLevelElement(elementType) end,
      scrollview = scrollview,
    })

    y = y + frame.height + 10
  end
end

function scene:configureElement(element)
  element:addEventListener("touch", function(event)
    if event.phase == "began" then
      if selectedElement == element then
        return false
      end

      clearElementSelection()

      local handle = display.newRoundedRect(
        levelView,
        element.contentBounds.xMin + element.contentWidth * 0.5,
        element.contentBounds.yMin + element.contentHeight * 0.5,
        element.contentWidth + 40,
        element.contentHeight + 40,
        10
      )

      display.setDefault("textureWrapX", "repeat")
      display.setDefault("textureWrapY", "repeat")
      handle.fill = { type = "image", filename = "images/background.png" }
      handle.fill.a = 0.5
      handle.strokeWidth = 1
      display.setDefault("textureWrapX", "clampToEdge")
      display.setDefault("textureWrapY", "clampToEdge")

      element:toFront()
      selectedElement = element
      selectedElement.handle = handle
      handle.element = element

      handle:addEventListener("tap", function() return true end)
      multitouch.addMoveAndPinchListener(handle, { onFocus = onFocus, onMoveAndPinch = onMoveAndPinch })

      event.target = handle
      handle:dispatchEvent(event)
    end
    return true
  end)
  element:addEventListener("tap", function() return true end)
end

function scene:newLevelElement(elementType)
  local element = newElement(levelView, elementType)
  local defaults = elementDefaults[elementType]

  element.xScale = defaults.width / element.width
  element.yScale = defaults.height / element.height
  level:positionElement(element, 150 - element.contentWidth * 0.5, 230 - element.contentHeight * 0.5)

  if elementType:starts("target-") then
    elements.targets[#elements.targets + 1] = element
  else
    elements.obstacles[#elements.obstacles + 1] = element
  end

  transition.from(element, { alpha = 0, time = 100 })
  self:configureElement(element)
end

-- TODO

-- Ajouter peut-être un swipe à 3 doigts pour ouvrir la barre latérale ?
-- Avec le double tap elle s'ouvrait trop souvent sans le vouloir
-- Et avec une largeur de 10 sur un petit téléphone pas évident de la récupérer

-- Lorsqu'un élément est sélectionné, il faut la possibilité de pouvoir le supprimer, à voir comment
-- faire au mieux. En tapant à côté la sélection est perdue
-- Par exemple une petite barre s'affiche à droite de l'élément, à gauche lorsqu'il est trop à droite
-- Cela permet de locker l'élément pour ne plus le bouger, cela permet de le supprimer, etc.

-- Reste à pouvoir sauvegarder le niveau, le supprimer et configurer le nombre de coups pour les étoiles

function scene:show(event)
  if event.phase == "did" then
    utils.activateMultitouch()
  end
end

function scene:hide(event)
  if event.phase == "will" then
    utils.deactivateMultitouch()
  elseif event.phase == "did" then
    transition.cancelAll()
    composer.removeScene("scenes.level-editor")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
