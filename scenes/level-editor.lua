local components = require "modules.components"
local composer = require "composer"
local multitouch = require "libraries.multitouch"
local utils = require "modules.utils"
local widget = require "widget"

local elementBar = nil
local elements = nil
local level = nil
local levelView = nil
local max = math.max
local min = math.min
local scene = composer.newScene()

local elementDefaults = {
  ["obstacle-corner"] = {
    width = 80,
    height = 80,
    minWidth = 40,
    minHeight = 40,
    maxWidth = 150,
    maxHeight = 150,
    canRotate = true,
    shouldMaintainAspectRatio = true,
  },
  ["obstacle-horizontal-barrier"] = {
    width = 100,
    height = 30,
    minWidth = 20,
    minHeight = 10,
    maxWidth = 150,
    maxHeight = 60,
  },
  ["obstacle-horizontal-barrier-large"] = {
    width = 150,
    height = 30,
    minWidth = 100,
    minHeight = 20,
    maxWidth = 300,
    maxHeight = 120,
  },
  ["obstacle-vertical-barrier"] = {
    width = 30,
    height = 100,
    minWidth = 10,
    minHeight = 20,
    maxWidth = 60,
    maxHeight = 150,
  },
  ["obstacle-vertical-barrier-large"] = {
    width = 30,
    height = 200,
    minWidth = 20,
    minHeight = 100,
    maxWidth = 150,
    maxHeight = 460,
  },
  ["target-easy"] = {
    width = 40,
    height = 40,
    minWidth = 20,
    minHeight = 20,
    maxWidth = 120,
    maxHeight = 120,
  },
  ["target-normal"] = {
    width = 40,
    height = 40,
    minWidth = 20,
    minHeight = 20,
    maxWidth = 120,
    maxHeight = 120,
  },
  ["target-hard"] = {
    width = 40,
    height = 40,
    minWidth = 20,
    minHeight = 20,
    maxWidth = 120,
    maxHeight = 120,
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
  local element = event.target
  element.xStart = element.x
  element.yStart = element.y
  element.widthStart = element.width
  element.heightStart = element.height
end

local function onMove(event)
  local element = event.target
  element.x = element.xStart + event.xDelta
  element.y = element.yStart + event.yDelta

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
end

local function onPinch(event)
  local element = event.target
  local defaults = elementDefaults[element.family .. "-" .. element.type]
  local x = defaults.shouldMaintainAspectRatio and event.totalDelta or event.xDelta
  local y = defaults.shouldMaintainAspectRatio and event.totalDelta or event.yDelta

  element.width = max(defaults.minWidth, min(defaults.maxWidth, element.widthStart + x))
  element.height = max(defaults.minHeight, min(defaults.maxHeight, element.heightStart + y))
  element.maskScaleX = element.maskScaleX and element.width / 394 or 0
  element.maskScaleY = element.maskScaleY and element.height / 394 or 0
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

  scene:createElementBar()

  -- TODO Pour du debug uniquement ? Sinon gérer le cancel dans le hide
  --[[timer.performWithDelay(5000, function()
    local configuration = level:createConfiguration(elements)
    utils.saveJson(configuration, level.world.directory .. "/" .. level.name .. ".json", system.DocumentsDirectory)

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
    utils.saveJson(worldConfig, level.world.directory .. ".json", system.DocumentsDirectory)
  end, -1)]]
end

function scene:createElementBar()
  local middleGround = display.newRect(self.view, 0, 0, display.actualContentWidth, display.actualContentHeight)
  middleGround.anchorX = 0
  middleGround.anchorY = 0
  middleGround.isVisible = false
  middleGround.isHitTestable = true

  middleGround:addEventListener("tap", function(event)
    if event.numTaps == 2 and not elementBar.isOpened then
      elementBar.open()
    end
    return true
  end)

  middleGround:addEventListener("touch", function(event)
    if event.phase == "began" and elementBar.isOpened then
      elementBar.close()
    end
    return false
  end)

  elementBar = components.newGroup(self.view)

  local elementBarBackground = components.newBackground(elementBar)
  elementBarBackground.width = 106
  elementBarBackground:addEventListener("tap", function() return true end)
  elementBarBackground:addEventListener("touch", function() return true end)

  local elementBarHandle = components.newGroup(elementBar)
  elementBarHandle.x = elementBarBackground.x + 100
  elementBarHandle.y = display.contentCenterY

  local elementBarHandleBackground = display.newRect(elementBarHandle, 1, 0, 10, elementBarBackground.height)
  elementBarHandleBackground.isVisible = false
  elementBarHandleBackground.isHitTestable = true

  local elementBarHandleOne = display.newLine(elementBarHandle, -1, -15, -1, 15)
  local elementBarHandleTwo = display.newLine(elementBarHandle, 1, -15, 1, 15)
  elementBarHandleOne:setStrokeColor(0.75, 0.75, 0.75, 1)
  elementBarHandleTwo:setStrokeColor(0.75, 0.75, 0.75, 1)

  local elementBarMinX = elementBar.x - elementBarBackground.width + elementBarHandleBackground.width
  local elementBarMaxX = elementBar.x

  elementBar.x = elementBarMinX
  elementBar.isOpened = false

  elementBar.open = function()
    transition.to(elementBar, { x = elementBarMaxX, time = 100 })
    elementBar.isOpened = true
  end

  elementBar.close = function()
    transition.to(elementBar, { x = elementBarMinX, time = 100 })
    elementBar.isOpened = false
  end

  elementBar.toggle = function()
    if elementBar.isOpened then
      elementBar.close()
    else
      elementBar.open()
    end
  end

  elementBarHandleBackground:addEventListener("touch", function(event)
    if event.phase == "began" then
      transition.cancel(elementBar)
      display.getCurrentStage():setFocus(elementBarHandleBackground, event.id)
      elementBarHandleBackground.isFocus = true
      elementBar.xStart = elementBar.x
    elseif elementBarHandleBackground.isFocus then
      if event.phase == "moved" then
        local x = elementBar.xStart + (event.x - event.xStart)
        elementBar.x = x < elementBarMinX and elementBarMinX or x > elementBarMaxX and elementBarMaxX or x
      elseif event.phase == "ended" or event.phase == "cancelled" then
        display.getCurrentStage():setFocus(elementBarHandleBackground, nil)
        elementBarHandleBackground.isFocus = false
        if math.abs(elementBar.x - elementBar.xStart) > 20 then
          elementBar.toggle()
        elseif elementBar.isOpened then
          elementBar.open()
        else
          elementBar.close()
        end
      end
    end
  end)

  local screenY = display.screenOriginY
  local screenHeight = display.actualContentHeight

  local scrollview = widget.newScrollView({
    left = elementBarBackground.x,
    top = elementBarBackground.y,
    width = elementBarBackground.width - 10,
    height = elementBarBackground.height,
    hideBackground = true,
    hideScrollBar = true,
    horizontalScrollDisabled = true,
    topPadding = 10 + (elements.background.y - screenY),
    bottomPadding = 10 + (screenY + screenHeight) - (elements.background.y + elements.background.height),
  })

  elementBar:insert(scrollview)

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
  multitouch.addMoveAndPinchListener(element, {
    onBlur = onBlur,
    onFocus = onFocus,
    onMove = onMove,
    onPinch = (element.family == "obstacle" or element.family == "target") and onPinch or nil,
  })
end

function scene:newLevelElement(elementType)
  local element = newElement(levelView, elementType)
  local defaults = elementDefaults[elementType]

  element.width = defaults.width
  element.height = defaults.height
  element.maskScaleX = element.maskScaleX and element.width / 394 or 0
  element.maskScaleY = element.maskScaleY and element.height / 394 or 0

  level:positionElement(element, 150 - element.width * 0.5, 230 - element.height * 0.5)

  if elementType:starts("target-") then
    elements.targets[#elements.targets + 1] = element
  else
    elements.obstacles[#elements.obstacles + 1] = element
  end

  transition.from(element, { alpha = 0, time = 100 })
  self:configureElement(element)
end

-- TODO

-- Pour la selection, lorsque l'utilisateur clique sur un élément il est sélectionné, à ce moment
-- un marchingAnts est affiché autour de l'élément à parti d'un rounded Rect transparent
-- qui vient se calquer sur le contentBounds, légèrement plus grand

-- Lorsqu'un élément est sélectionné, il faut la possibilité de pouvoir le supprimer, à voir comment
-- faire au mieux. En tapant à côté la sélection est perdue
-- Par exemple une petite barre s'affiche à droite de l'élément, à gauche lorsqu'il est trop à droite
-- Cela permet de locker l'élément pour ne plus le bouger, cela permet de le supprimer, etc.

-- Reste à pouvoir sauvegarder le niveau, le supprimer et configurer le nombre de coups pour les étoiles

-- Permettre le pinch plus large lorsqu'un item est sélectionné ?
-- Difficile sinon parfois d'aller chercher l'élément pour ensuite le manipuler lorsqu'il est petit

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
