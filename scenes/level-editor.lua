local components = require "modules.components"
local composer = require "composer"
local multitouch = require "libraries.multitouch"
local utils = require "modules.utils"
local widget = require "widget"

local elements = nil
local level = nil
local levelView = nil
local scene = composer.newScene()

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

local function onMove(element, deltaX, deltaY)
  local elementBounds = element.contentBounds
  local levelBounds = elements.background.contentBounds
  deltaX = elementBounds.xMax + deltaX > levelBounds.xMax and levelBounds.xMax - elementBounds.xMax or deltaX
  deltaX = elementBounds.xMin + deltaX < levelBounds.xMin and levelBounds.xMin - elementBounds.xMin or deltaX
  deltaY = elementBounds.yMax + deltaY > levelBounds.yMax and levelBounds.yMax - elementBounds.yMax or deltaY
  deltaY = elementBounds.yMin + deltaY < levelBounds.yMin and levelBounds.yMin - elementBounds.yMin or deltaY
  element:translate(deltaX, deltaY)
end

function scene:create(event)
  level = event.params.level

  levelView = components.newGroup(self.view)
  elements = level:createElements(levelView)

  -- TODO Configurer tous les touch, etc. en auto à la création mais aussi à l'ajout, etc.
  multitouch.addMoveAndPinchListener(elements.ball, onMove)

  scene:createElementBar()
end

function scene:createElementBar()
  local elementBar = components.newGroup(self.view)
  local screenY = display.screenOriginY
  local screenHeight = display.actualContentHeight

  local elementBarBackground = components.newBackground(elementBar)
  elementBarBackground.width = 106

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

  elementBarHandleBackground:addEventListener("touch", function(event)
    if event.phase == "began" or (event.phase == "moved" and not elementBarHandleBackground.isFocus) then
      transition.cancel(elementBar)
      display.getCurrentStage():setFocus(elementBarHandleBackground, event.id)
      elementBarHandleBackground.isFocus = true
      elementBar.xStart = elementBar.x
      elementBar.touchEventXStart = event.x
    elseif elementBarHandleBackground.isFocus then
      if event.phase == "moved" then
        local x = elementBar.xStart + (event.x - elementBar.touchEventXStart)
        elementBar.x = x < elementBarMinX and elementBarMinX or x > elementBarMaxX and elementBarMaxX or x
      elseif event.phase == "ended" or event.phase == "cancelled" then
        display.getCurrentStage():setFocus(elementBarHandleBackground, nil)
        elementBarHandleBackground.isFocus = false
        local deltaX = elementBar.x - elementBar.xStart
        local xEnd = deltaX > 20 and elementBarMaxX or deltaX < -20 and elementBarMinX or elementBar.xStart
        transition.to(elementBar, { x = xEnd, time = 100 })
      end
    end
  end)

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
      onRelease = function()
        print("bob")
      end,
      scrollview = scrollview,
    })

    y = y + frame.height + 10
  end
end

-- TODO Afficher la barre des éléments avec un swipe, avec un double tap (pareil pour fermer)
-- Ajouter un indicateur visuel au bord pour montrer que l'on peut swipe

-- Pour la selection, lorsque l'utilisateur clique sur un élément il est sélectionné, à ce moment
-- un marchingAnts est affiché autour de l'élément à parti d'un rounded Rect transparent
-- qui vient se calquer sur le contentBounds, légèrement plus grand

-- Lorsqu'un élément est sélectionné, il faut la possibilité de pouvoir le supprimer, à voir comment
-- faire au mieux. En tapant à côté la sélection est perdue

function scene:show(event)
  if event.phase == "did" then
    if not utils.isSimulator() then
      system.activate("multitouch")
    end
  end
end

function scene:hide(event)
  if event.phase == "will" then
    if not utils.isSimulator() then
      system.deactivate("multitouch")
    end
  elseif event.phase == "did" then
    transition.cancelAll()
    composer.removeScene("scenes.level-editor")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
