local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
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

local elementDefaults = {
  ["obstacle-corner"] = {
    width = 80,
    height = 80,
    minWidth = 40,
    minHeight = 40,
    maxWidth = 150,
    maxHeight = 150,
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
    maxWidth = 250,
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
    maxHeight = 350,
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

local function goBack()
  if #level.world:levels() == 0 then
    navigation.gotoWorlds()
  else
    navigation.gotoLevels(level.world)
  end
end

local function deleteLevel()
  level:delete()
  goBack()
end

local function newButton(parent, x, y, content, options)
  local group = components.newGroup(parent)
  group.x = x
  group.y = y

  local frame = display.newRoundedRect(group, 0, 0, 78, 78, 5)
  frame.anchorX = 0
  frame.anchorY = 0
  frame:setFillColor(0.5, 0.5, 0.5, 0.25)
  frame:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  frame.strokeWidth = 1

  local contentGroup = components.newGroup(group)

  local background = display.newRect(contentGroup, frame.x, frame.y, frame.width, frame.height)
  background.anchorX = frame.anchorX
  background.anchorY = frame.anchorY
  background.isVisible = false
  background.isHitTestable = true

  contentGroup:insert(content)
  content.x = frame.x + frame.contentWidth * 0.5
  content.y = frame.y + frame.contentWidth * 0.5

  components.newObjectButton(contentGroup, options)

  return group
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
  local defaults = elementDefaults[element.family .. "-" .. element.type] or {}

  if element.family ~= "root" then
    if event.xDistanceDelta then
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

  local middleGround = display.newRect(self.view, screenX, screenY, screenWidth, screenHeight)
  middleGround.anchorX = 0
  middleGround.anchorY = 0
  middleGround.isVisible = false
  middleGround.isHitTestable = true

  scene.toolBarGroup = components.newGroup(self.view)
  scene:createHelp()
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

  local helpFrame = display.newRoundedRect(
    self.help,
    elements.background.contentBounds.xMin + elements.background.contentWidth * 0.5,
    elements.background.contentBounds.yMin + 20,
    elements.background.contentWidth - 40,
    160,
    10
  )
  display.setDefault("textureWrapX", "repeat")
  display.setDefault("textureWrapY", "repeat")
  helpFrame.anchorY = 0
  helpFrame.fill = { type = "image", filename = "images/background.png" }
  helpFrame.fill.a = 0.5
  helpFrame.strokeWidth = 1
  display.setDefault("textureWrapX", "clampToEdge")
  display.setDefault("textureWrapY", "clampToEdge")

  local helpContentGroup = components.newGroup(self.help)

  local helpIcon = display.newImageRect(helpContentGroup, "images/icons/tap.png", 40, 40)
  helpIcon.anchorY = 0
  helpIcon.x = 0
  helpIcon.y = 0

  local helpText = display.newText({
    align = "center",
    text = i18n.t("level-editor-help"),
    fontSize = 14,
    parent = helpContentGroup,
    x = 0,
    y = helpIcon.contentHeight + 10,
    width = helpFrame.contentWidth - 20,
  })
  helpText.anchorY = 0

  helpFrame.path.height = helpContentGroup.contentHeight + 40
  helpContentGroup.x = helpFrame.x
  helpContentGroup.y = helpFrame.contentBounds.yMin + 20
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

  sideBar.toggle = function()
    if sideBar.isOpened then
      sideBar.close()
    else
      sideBar.open()
    end
  end

  local sideBarBackground = display.newRoundedRect(sideBar, -10, 0, sideBarWidth + 10, screenHeight, 10)
  sideBarBackground.anchorX = 0
  sideBarBackground.anchorY = 0
  sideBarBackground.alpha = 0.9
  sideBarBackground:addEventListener("tap", function() return true end)
  sideBarBackground:addEventListener("touch", function() return true end)

  display.setDefault("textureWrapX", "repeat")
  display.setDefault("textureWrapY", "repeat")
  sideBarBackground.fill = { type = "image", filename = "images/background.png" }
  display.setDefault("textureWrapX", "clampToEdge")
  display.setDefault("textureWrapY", "clampToEdge")

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
          sideBar.toggle()
        elseif sideBar.isOpened then
          sideBar.open()
        else
          sideBar.close()
        end
      end
    end
  end)

  local scrollView = components.newScrollView(sideBar, {
    left = 0,
    top = 0,
    width = sideBarWidth - 10,
    height = sideBarBackground.contentHeight,
    topPadding = 10,
    bottomPadding = 10,
  })

  local scrollViewContent = components.newGroup(scrollView)
  local bottomGroup = components.newGroup(scrollViewContent)

  local pickerWheelGroup = components.newGroup(scrollViewContent)
  pickerWheelGroup.alpha = 0

  local cancelButtonIcon = display.newImageRect("images/icons/cancel.png", 35, 35)
  local cancelButton = newButton(scrollViewContent, 10, 0, cancelButtonIcon, { onRelease = goBack })

  local acceptButtonIcon = display.newImageRect("images/icons/accept.png", 35, 35)
  local acceptButton = newButton(scrollViewContent, 100, 0, acceptButtonIcon, { onRelease = saveAndGoBack })

  local playButtonIcon = display.newImageRect("images/icons/resume.png", 30, 30)
  local playButton = newButton(
    scrollViewContent,
    100,
    cancelButton.y + cancelButton.contentHeight + 10,
    playButtonIcon,
    { onRelease = saveAndPlay }
  )

  local starImage = components.newStar(self.view, 35, 35)

  local starButton = newButton(scrollViewContent, 10, playButton.y, starImage, { onRelease = function(event)
    local self = event.target
    self.isPressed = not self.isPressed and true or false
    if self.isPressed then
      starImage.fill.effect = "filter.grayscale"
      transition.to(bottomGroup, { y = 220, time = 100 })
      transition.to(pickerWheelGroup, {
        alpha = 1,
        delay = 100,
        time = 100,
        onComplete = function()
          scrollView:setScrollHeight(scrollViewContent.contentHeight)
        end
      })
    else
      starImage.fill.effect = nil
      transition.to(pickerWheelGroup, { alpha = 0, time = 100 })
      transition.to(bottomGroup, {
        y = 0,
        delay = 100,
        time = 100,
        onComplete = function()
          scrollView:setScrollHeight(scrollViewContent.contentHeight)
        end
      })
    end
  end })

  local pickerWheelFrame = display.newRoundedRect(
    pickerWheelGroup,
    10,
    playButton.y + playButton.contentHeight + 10,
    168,
    210,
    5
  )
  pickerWheelFrame.anchorX = 0
  pickerWheelFrame.anchorY = 0
  pickerWheelFrame:setFillColor(0.5, 0.5, 0.5, 0.25)
  pickerWheelFrame:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  pickerWheelFrame.strokeWidth = 1

  local configuration = level:configuration()
  local pickerWheel

  local pickerWheelColumns = {
    { startIndex = configuration.stars.one, labels = { 1, 2, 3, 4, 5, 6, 7, 8, 9 } },
    { startIndex = configuration.stars.two, labels = { 1, 2, 3, 4, 5, 6, 7, 8, 9 } },
    { startIndex = configuration.stars.three, labels = { 1, 2, 3, 4, 5, 6, 7, 8, 9 } },
  }

  pickerWheel = widget.newPickerWheel({
    left = 20,
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

  local y = playButton.y + playButton.contentHeight + 20
  local sideBarSeparatorTop = display.newLine(bottomGroup, 20, y, 170, y)
  sideBarSeparatorTop:setStrokeColor(0.5, 0.5, 0.5, 0.75)

  local elementY = 0
  local elementGroup = components.newGroup(bottomGroup)
  elementGroup.y = y + 20

  for index, elementType in ipairs(elementTypes) do
    local isEven = index % 2 == 0
    local element = newElement(self.view, elementType)

    local elementButton = newButton(elementGroup, isEven and 100 or 10, elementY, element, {
      onRelease = function()
        local newElement = scene:newLevelElement(elementType)
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

    elementY = isEven and elementY + elementButton.contentHeight + 10 or elementY
  end

  y = elementGroup.y + elementGroup.contentHeight + 20
  local sideBarSeparatorBottom = display.newLine(bottomGroup, 20, y, 170, y)
  sideBarSeparatorBottom:setStrokeColor(0.5, 0.5, 0.5, 0.75)

  y = y + 20

  local confirmDeleteButton
  local deleteButtonIcon = display.newImageRect("images/icons/trash.png", 30, 30)

  newButton(bottomGroup, 10, y, deleteButtonIcon, { onRelease = function()
    confirmDeleteButton.showConfirm = not confirmDeleteButton.showConfirm
    transition.to(confirmDeleteButton, { alpha = confirmDeleteButton.showConfirm and 1 or 0, time = 100 })
  end })

  local confirmDeleteButtonGroup = display.newGroup()

  local confirmDeleteButtonBackground = display.newRoundedRect(confirmDeleteButtonGroup, 0, 0, 78, 78, 5)
  confirmDeleteButtonBackground:setFillColor(0.67, 0.2, 0.2, 0.75)

  local confirmDeleteButtonText = display.newText({
    align = "center",
    text = i18n.t("click-here-to-confirm"),
    fontSize = 14,
    parent = confirmDeleteButtonGroup,
    width = 70,
  })
  confirmDeleteButton = newButton(bottomGroup, 100, y, confirmDeleteButtonGroup, { onRelease = deleteLevel })
  confirmDeleteButton.alpha = 0
end

function scene:configureElement(element)
  element:addEventListener("touch", function(event)
    if event.phase == "began" then
      if selectedElement == element then
        return false
      end

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

function scene:newLevelElement(elementType)
  local element = newElement(levelView, elementType)
  local defaults = elementDefaults[elementType]

  element.xScale = defaults.width / element.width
  element.yScale = defaults.height / element.height
  level:positionElement(element, 150 - element.contentWidth * 0.5, 230 - element.contentHeight * 0.5)
  scene:configureElement(element)

  if elementType:starts("target-") then
    elements.targets[#elements.targets + 1] = element
  else
    elements.obstacles[#elements.obstacles + 1] = element
  end

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

    local toolBarFrame = display.newRoundedRect(selectedElement.toolBar, 0, 0, 1, 38, 10)
    display.setDefault("textureWrapX", "repeat")
    display.setDefault("textureWrapY", "repeat")
    toolBarFrame.fill = { type = "image", filename = "images/background.png" }
    toolBarFrame.fill.a = 0.5
    toolBarFrame.strokeWidth = 1
    display.setDefault("textureWrapX", "clampToEdge")
    display.setDefault("textureWrapY", "clampToEdge")

    local toolBarContent = components.newGroup(selectedElement.toolBar)

    local elementNameText = display.newText({
      text = i18n.t((element.family == "root" and "" or (element.family .. "-")) .. element.type),
      fontSize = 14,
      parent = toolBarContent,
    })
    elementNameText.anchorX = 0

    local x = elementNameText.x + elementNameText.width

    if element.family == "obstacle" and element.type == "corner" then
      x = x + 20
      local separator = display.newLine(toolBarContent, x, -8, x, 8)
      separator.anchorX = 0

      x = x + 20
      local rotateRightIcon = display.newImageRect(toolBarContent, "images/icons/rotate-right.png", 20, 20)
      rotateRightIcon.anchorX = 0
      rotateRightIcon.x = x

      local rotateRightButton = components.newObjectButton(rotateRightIcon, { onRelease = function()
        element.rotation = (element.rotation + 90) % 360
        return true
      end})
      rotateRightButton:addEventListener("tap", function() return true end)

      x = x + rotateRightButton.contentWidth
    end

    if element.family == "obstacle" or element.family == "target" then
      x = x + 20
      local separator = display.newLine(toolBarContent, x, -8, x, 8)
      separator.anchorX = 0

      local deleteIcon = display.newImageRect(toolBarContent, "images/icons/trash.png", 20, 20)
      deleteIcon.anchorX = 0
      deleteIcon.x = x + 20

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

    toolBarFrame.path.width = toolBarContent.contentWidth + 40
    toolBarContent.x = -toolBarContent.contentWidth * 0.5

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
