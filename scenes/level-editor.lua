local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local layouts = require "modules.layouts"
local multitouch = require "libraries.multitouch"
local navigation = require "modules.navigation"
local utils = require "modules.utils"
local widget = require "widget"

local elements = nil
local level = nil
local levelView = nil
local max = math.max
local min = math.min
local scene = composer.newScene()
local screenX = display.screenOriginX
local screenY = display.screenOriginY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight
local selectedElement = nil
local sideBar = nil
local stars = {}
local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

local function goBack()
  if #level.world:levels() == 0 then
    navigation.gotoWorlds()
  else
    navigation.gotoLevels(level.world)
  end
end

-- TODO A garder ici ?
local function deleteLevel()
  level:delete()
  goBack()
end

local function newButton(parent, content, options)
  local buttonGroup = components.newGroup(parent)
  local frame = components.newFrame(buttonGroup, 80, 80)
  local contentGroup = components.newGroup(buttonGroup)
  components.newHitTestableSurface(contentGroup, frame)
  contentGroup:insert(content)
  components.newObjectButton(contentGroup, options)
  return buttonGroup
end

local function newFrame(parent, width, height)
  local frame = display.newRoundedRect(0, 0, width, height, 10)
  parent:insert(frame)
  components.fillWithBackground(frame)
  frame.fill.a = 0.5
  frame.strokeWidth = 1
  return frame
end

local function onFocus(event)
  local element = event.target.element
  element.contentWidthStart = element.contentWidth
  element.contentHeightStart = element.contentHeight
  element.xStart = element.x
  element.yStart = element.y
  element.xDeltaCorrection = 0
  element.yDeltaCorrection = 0
end

local function onMovePinchRotate(event)
  local element = event.target.element

  if element.family ~= "root" then
    if event.xDistanceDelta then
      local minWidth = element.descriptor.minWidth
      local maxWidth = element.descriptor.maxWidth
      local minHeight = element.descriptor.minHeight
      local maxHeight = element.descriptor.maxHeight
      local newWidth = min(maxWidth, max(minWidth, element.contentWidthStart + event.xDistanceDelta))
      local newHeight = min(maxHeight, max(minHeight, element.contentHeightStart + event.yDistanceDelta))
      newWidth = newWidth - newWidth % 5
      newHeight = newHeight - newHeight % 5

      element.xScale = newWidth / element.width
      element.yScale = newHeight / element.height
      element.xDeltaCorrection = (element.anchorX - 0.5) * (element.contentWidth - element.contentWidthStart)
      element.yDeltaCorrection = (element.anchorY - 0.5) * (element.contentHeight - element.contentHeightStart)

      element.handle.path.width = element.contentWidth + 40
      element.handle.path.height = element.contentHeight + 40
    end
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

  element.handle.x, element.handle.y = element:localToContent(0, 0)

  local toolBarPosition = element.toolBar.position()
  if element.toolBar.y ~= toolBarPosition then
    element.toolBar.alpha = 0
    element.toolBar.y = toolBarPosition
    transition.to(element.toolBar, { alpha = 1, time = 100 })
  end
end

local function removeHelp()
  if scene.help then
    transition.fadeOut(scene.help, { onComplete = function()
      display.remove(scene.help)
      scene.help = nil
    end})
  end
end

local function save()
  local configuration = level:configuration()
  level:save(elements, {
    one = stars[1] or configuration.stars.one,
    two = stars[2] or configuration.stars.two,
    three = stars[3] or configuration.stars.three,
  })
end

local function saveAndGoBack()
  save()
  goBack()
end

-- TODO Garder saveAndPlay ou non ?
local function saveAndPlay()
  save()
  navigation.gotoGame(level)
end

function scene:create(event)
  level = event.params.level
  levelView = components.newGroup(self.view)
  elements = level:createElements(levelView)

  scene:configureElement(elements.ball)
  for _, element in pairs(elements.obstacles) do
    scene:configureElement(element)
  end
  for _, element in pairs(elements.targets) do
    scene:configureElement(element)
  end

  local middleGround = components.newHitTestableSurface(self.view, elements.frame)

  scene.toolBarGroup = components.newGroup(self.view)

  if #elements.obstacles == 0 and #elements.targets == 0 then
    scene:createHelp()
  end

  scene:createSideBar()

  middleGround:addEventListener("touch", function(event)
    if event.phase == "began" then
      removeHelp()
      if selectedElement and not utils.isEventWithinBounds(selectedElement.handle, event) then
        scene:selectElement(nil)
      end
      if sideBar.isOpened then
        sideBar.close()
      end
    end
    return false
  end)

  elements.frame:addEventListener("tap", function(event)
    if event.numTaps == 2 and not sideBar.isOpened then
      sideBar.open()
    end
    return true
  end)
end

function scene:createHelp()
  self.help = components.newGroup(self.view)

  local helpFrame = newFrame(self.help, 260, 0)
  local helpContentStack = layouts.newStack({ align = "center", parent = self.help, separator = 10 })

  local helpIcon = display.newImageRect("images/icons/tap.png", 40, 40)
  helpContentStack:insert(helpIcon)

  local helpText = display.newText({
    align = "center",
    text = i18n.t("level-editor-help"),
    fontSize = 14,
    width = helpFrame.contentWidth - 20,
  })
  helpContentStack:insert(helpText)

  helpFrame.path.height = helpContentStack.contentHeight + 40
  layouts.align(helpContentStack, "center", "center", helpFrame)
  layouts.align(self.help, "center", "top", elements.background)
  self.help.y = self.help.y + 20
end

function scene:createSideBar()
  local sideBarWidth = 196
  local sideBarMinX = max(screenX + 10, 0) - sideBarWidth
  local sideBarMaxX = screenX

  sideBar = components.newGroup(self.view)
  sideBar.x = sideBarMinX
  sideBar.y = screenY
  sideBar.isOpened = false

  sideBar.open = function()
    transition.to(sideBar, { x = sideBarMaxX, time = 100 })
    sideBar.isOpened = true
  end

  sideBar.close = function()
    transition.to(sideBar, { x = sideBarMinX, time = 100 })
    sideBar.isOpened = false
  end

  local sideBarBackground = display.newRoundedRect(sideBar, -10, 0, sideBarWidth + 10, screenHeight, 10)
  sideBarBackground.anchorX = 0
  sideBarBackground.anchorY = 0
  sideBarBackground.alpha = 0.9
  sideBarBackground:addEventListener("tap", function() return true end)
  sideBarBackground:addEventListener("touch", function() return true end)
  components.fillWithBackground(sideBarBackground)

  local sideBarHandle = components.newGroup(sideBar)
  sideBarHandle.x = sideBarWidth - 6
  sideBarHandle.y = sideBarBackground.height * 0.5

  local sideBarHandleBackground = display.newRect(sideBarHandle, 1, 0, 10, sideBarBackground.height)
  sideBarHandleBackground.isVisible = false
  sideBarHandleBackground.isHitTestable = true

  local sideBarHandleOne = display.newLine(sideBarHandle, -1, -15, -1, 15)
  local sideBarHandleTwo = display.newLine(sideBarHandle, 1, -15, 1, 15)
  sideBarHandleOne:setStrokeColor(0.75, 0.75, 0.75, 1)
  sideBarHandleTwo:setStrokeColor(0.75, 0.75, 0.75, 1)

  sideBarHandleBackground:addEventListener("touch", function(event)
    if event.phase == "began" then
      removeHelp()
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
          sideBar[sideBar.isOpened and "close" or "open"]()
        else
          sideBar[sideBar.isOpened and "open" or "close"]()
        end
      end
    end
  end)

  local scrollView = components.newScrollView(sideBar, {
    left = 0,
    top = 0,
    width = sideBarWidth - 10,
    height = sideBarBackground.contentHeight,
    topPadding = topInset + 10,
    bottomPadding = bottomInset + 10,
  })

  local scrollViewStack = layouts.newStack({ align = "center", parent = scrollView, separator = 20 })

  local actionGrid = layouts.newGrid({ parent = scrollViewStack, separator = 10 })
  local cancelButtonIcon = display.newImageRect("images/icons/cancel.png", 35, 35)
  local acceptButtonIcon = display.newImageRect("images/icons/accept.png", 35, 35)
  newButton(actionGrid, cancelButtonIcon, { onRelease = goBack })
  newButton(actionGrid, acceptButtonIcon, { onRelease = saveAndGoBack })

  local separator = display.newLine(0, 0, 150, 0)
  separator:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  scrollViewStack:insert(separator)
  separator.y = separator.y + (separator.contentHeight - separator.strokeWidth) * 0.5

  local elementDescriptors = level:elementDescriptors()
  local elementGrid = layouts.newGrid({ parent = scrollViewStack, separator = 10 })

  for _, elementDescriptor in ipairs(elementDescriptors) do
    if elementDescriptor.family ~= "root" then
      local elementWidth, elementHeight = elementDescriptor.size(50, 50)
      local elementFamily = elementDescriptor.family
      local elementName = elementDescriptor.name
      local element = level:newElement(self.view, elementFamily, elementName, elementWidth, elementHeight)
      newButton(elementGrid, element, {
        onRelease = function()
          local newElement = scene:newLevelElement(elementFamily, elementName)
          local fromX = (newElement.anchorX - element.anchorX) * element.contentWidth
          local fromY = (newElement.anchorY - element.anchorX) * element.contentHeight
          fromX, fromY = element:localToContent(fromX, fromY)
          transition.from(newElement, {
            xScale = element.width / newElement.width,
            yScale = element.height / newElement.height,
            x = fromX,
            y = fromY,
            time = 100,
          })
        end,
        scrollView = scrollView,
      })
    end
  end

  local separator = display.newLine(0, 0, 150, 0)
  separator:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  scrollViewStack:insert(separator)
  separator.y = separator.y + (separator.contentHeight - separator.strokeWidth) * 0.5

  local pickerWheelGroup = components.newGroup(scrollViewStack)

  local pickerWheelFrame = components.newFrame(pickerWheelGroup, 170, 210)
  pickerWheelFrame.anchorX = 0
  pickerWheelFrame.anchorY = 0

  local configuration = level:configuration()
  local pickerWheel = nil

  local pickerWheelColumns = {
    { startIndex = configuration.stars.one, labels = { 1, 2, 3, 4, 5, 6, 7, 8, 9 } },
    { startIndex = configuration.stars.two, labels = { 1, 2, 3, 4, 5, 6, 7, 8, 9 } },
    { startIndex = configuration.stars.three, labels = { 1, 2, 3, 4, 5, 6, 7, 8, 9 } },
  }

  pickerWheel = widget.newPickerWheel({
    left = 10,
    top = pickerWheelFrame.y + 40,
    columns = pickerWheelColumns,
    style = "resizable",
    width = 150,
    rowHeight = 32,
    columnColor = { 0, 0, 0, 0 },
    fontColor = { 1, 1, 1, 0.5 },
    fontColorSelected = { 1, 1, 1 },
    fontSize = 14,
    sheet = graphics.newImageSheet("images/pickerwheel.png", { width = 1, height = 1, numFrames = 1 }),
		middleSpanTopFrame = 1,
		middleSpanBottomFrame = 1,
		middleSpanOffset = 0,
    onValueSelected = function(event)
      local values = pickerWheel:getValues()
      local newValue = tonumber(pickerWheelColumns[event.column].labels[event.row])
      stars[event.column] = newValue
      for column = 1, 3 do
        local value = tonumber(values[column].value)
        if (column < event.column and value < newValue) or (column > event.column and value > newValue) then
          pickerWheel:selectValue(column, newValue)
        end
      end
    end,
  })
  pickerWheelGroup:insert(pickerWheel)

  for index = 1, 3 do
    local columnWidth = pickerWheel.contentWidth / 3
    local columnStarImage = components.newStar(pickerWheelGroup, 20, 20)
    columnStarImage.anchorY = 0
    columnStarImage.x = pickerWheelFrame.x + 10 + (index - 1) * columnWidth + columnWidth * 0.5
    columnStarImage.y = pickerWheelFrame.y + 10
  end

  local separator = display.newLine(0, 0, 150, 0)
  separator:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  scrollViewStack:insert(separator)
  separator.y = separator.y + (separator.contentHeight - separator.strokeWidth) * 0.5

  local deleteGrid = layouts.newGrid({ parent = scrollViewStack, separator = 10 })
  local deleteButtonIcon = display.newImageRect("images/icons/trash.png", 35, 35)
  local confirmDeleteButton = nil

  newButton(deleteGrid, deleteButtonIcon, { onRelease = function(event)
    local deleteButton = event.target
    deleteButton.isPressed = not deleteButton.isPressed
    transition.to(confirmDeleteButton, { alpha = deleteButton.isPressed and 1 or 0, time = 100 })
  end })

  local confirmDeleteButtonVortex = layouts.newVortex()
  local confirmDeleteButtonBackground = display.newRoundedRect(0, 0, 78, 78, 5)
  confirmDeleteButtonVortex:insert(confirmDeleteButtonBackground)
  confirmDeleteButtonBackground:setFillColor(0.67, 0.2, 0.2, 0.75)

  local confirmDeleteButtonText = display.newText({
    align = "center",
    text = i18n.t("click-here-to-confirm"),
    fontSize = 14,
    width = 70,
  })
  confirmDeleteButtonVortex:insert(confirmDeleteButtonText)

  confirmDeleteButton = newButton(deleteGrid, confirmDeleteButtonVortex, { onRelease = deleteLevel })
  confirmDeleteButton.alpha = 0

  layouts.alignCenter(scrollViewStack, scrollView)
end

function scene:configureElement(element)
  element:addEventListener("touch", function(event)
    if event.phase == "began" then
      if selectedElement == element then
        return false
      end

      local handle = newFrame(levelView, element.contentWidth + 40, element.contentHeight + 40)
      layouts.align(handle, "center", "center", element)

      element:toFront()
      element.handle = handle
      handle.element = element
      scene:selectElement(element)

      multitouch.addMovePinchRotateListener(handle, {
        onFocus = onFocus,
        onMovePinchRotate = onMovePinchRotate,
      })

      event.target = handle
      handle:dispatchEvent(event)
    end
    return true
  end)

  element:addEventListener("tap", function() return true end)
end

function scene:newLevelElement(elementFamily, elementName)
  local element = level:newElement(levelView, elementFamily, elementName)
  level:positionElement(element, 150 - element.contentWidth * 0.5, 230 - element.contentHeight * 0.5)
  scene:configureElement(element)
  local configurationField = elementFamily .. "s"
  elements[configurationField][#elements[configurationField] + 1] = element
  return element
end

function scene:selectElement(element)
  if selectedElement == element then
    return
  end

  if not element or selectedElement ~= element then
    if selectedElement then
      display.remove(selectedElement.handle)
      display.remove(selectedElement.toolBar)
      selectedElement.handle = nil
      selectedElement.toolBar = nil
      selectedElement = nil
    end
  end

  if element then
    selectedElement = element
    selectedElement.toolBar = components.newGroup(scene.toolBarGroup)
    selectedElement.toolBar.x = elements.background.contentBounds.xMin + elements.background.contentWidth * 0.5
    selectedElement.toolBar.yBottom =  elements.background.contentBounds.yMax - 40
    selectedElement.toolBar.yTop = elements.background.contentBounds.yMin + 40
    selectedElement.toolBar.position = function()
      local _, handleCenterY = selectedElement.handle:localToContent(0, 0)
      if handleCenterY < display.contentCenterY then
        return selectedElement.toolBar.yBottom
      else
        return selectedElement.toolBar.yTop
      end
    end
    selectedElement.toolBar.y = selectedElement.toolBar.position()

    local toolBarFrame = newFrame(selectedElement.toolBar, 0, 38)
    local toolBarStack = layouts.newStack({
      align = "center",
      mode = "horizontal",
      parent = selectedElement.toolBar,
      separator = 20,
    })

    local elementNameText = display.newText({ text = i18n.t(element.family .. "-" .. element.name), fontSize = 14 })
    toolBarStack:insert(elementNameText)

    if element.family == "obstacle" and element.name == "corner" then
      local separator = display.newLine(0, -8, 0, 8)
      toolBarStack:insert(separator)

      local rotateRightIcon = display.newImageRect("images/icons/rotate-right.png", 20, 20)
      toolBarStack:insert(rotateRightIcon)

      local rotateRightButton = components.newObjectButton(rotateRightIcon, { onRelease = function()
        element.rotation = (element.rotation + 90) % 360
        return true
      end})
      rotateRightButton:addEventListener("tap", function() return true end)
    end

    if element.family == "obstacle" or element.family == "target" then
      local separator = display.newLine(0, -8, 0, 8)
      toolBarStack:insert(separator)

      local deleteIcon = display.newImageRect("images/icons/trash.png", 20, 20)
      toolBarStack:insert(deleteIcon)

      local deleteButton = components.newObjectButton(deleteIcon, { onRelease = function()
        scene:selectElement(nil)
        display.remove(element)
        local objects = element.family == "obstacle" and elements.obstacles or elements.targets
        local index = table.indexOf(objects, element)
        table.remove(objects, index)
        return true
      end})
      deleteButton:addEventListener("tap", function() return true end)
    end

    toolBarFrame.path.width = toolBarStack.contentWidth + 40
    layouts.align(toolBarStack, "center", "center", toolBarFrame)
    transition.from(selectedElement.toolBar, { alpha = 0, time = 100 })
  end
end

function scene:show(event)
  if event.phase == "did" then
    utils.activateMultitouch()
    timer.performWithDelay(3000, removeHelp, "removeHelp")
  end
end

function scene:hide(event)
  if event.phase == "will" then
    utils.deactivateMultitouch()
  elseif event.phase == "did" then
    timer.cancel("removeHelp")
    transition.cancelAll()
    composer.removeScene("scenes.level-editor")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
