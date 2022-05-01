local layouts = require "modules.layouts"
local utils = require "modules.utils"
local widget = require "widget"

local components = {}

local screenX = display.screenOriginX
local screenY = display.screenOriginY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight
local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

components.fillWithBackground = function(object)
  display.setDefault("textureWrapX", "repeat")
  display.setDefault("textureWrapY", "repeat")
  object.fill = { type = "image", filename = "images/background.png" }
  display.setDefault("textureWrapX", "clampToEdge")
  display.setDefault("textureWrapY", "clampToEdge")
end

components.newBackground = function(parent)
  local background = display.newRect(screenX, screenY, screenWidth, screenHeight)
  parent:insert(background)
  background.anchorX = 0
  background.anchorY = 0
  components.fillWithBackground(background)
  return background
end

components.newCircleButton = function(parent, imageName, size, options)
  local vortex = layouts.newVortex()
  local circle = display.newCircle(0, 0, size)
  circle:setFillColor(0, 0, 0, 0)
  circle.isHitTestable = true
  circle.strokeWidth = 1
  vortex:insert(circle)
  local image = display.newImageRect(imageName, size, size)
  vortex:insert(image)
  local button = components.newObjectButton(vortex, options)
  parent:insert(button)
  return button
end

components.newEmptyShape = function(parent, width, height)
  local emptyShape = display.newRect(parent, 0, 0, width, height)
  emptyShape.fill.effect = "generator.linearGradient"
  emptyShape.fill.effect.color1 = { 0.25, 0.25, 0.25, 0.75 }
  emptyShape.fill.effect.position1  = { 0, 0 }
  emptyShape.fill.effect.color2 = { 0.5, 0.5, 0.5, 0.25 }
  emptyShape.fill.effect.position2  = { 1, 1 }
  emptyShape.strokeWidth = 1
  emptyShape:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  return emptyShape
end

components.newFrame = function(parent, width, height)
  local frame = display.newRoundedRect(0, 0, width - 2, height - 2, 5)
  frame.strokeWidth = 1
  parent:insert(frame)
  frame:setFillColor(0.5, 0.5, 0.5, 0.25)
  frame:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  return frame
end

components.newGroup = function(parent)
  local group = display.newGroup()
  parent:insert(group)
  return group
end

components.newHitTestableSurface = function(parent, reference)
  reference = reference or parent
  local surface = display.newRect(0, 0, reference.contentWidth, reference.contentHeight)
  surface.isVisible = false
  surface.isHitTestable = true
  parent:insert(surface)
  layouts.align(surface, "left", "top", reference)
  return surface
end

components.newImageButton = function(parent, imageName, imageBaseDir, width, height, options)
  if not options then
    options = height
    height = width
    width = imageBaseDir
    imageBaseDir = system.ResourceDirectory
  end
  local imageButton = display.newImageRect(imageName, imageBaseDir, width, height)
  parent:insert(imageButton)
  return components.newObjectButton(imageButton, options)
end

components.newObjectButton = function(object, options)
  local function setDefaultState()
    if object.isOver then
      object.isOver = false
      transition.to(object, { alpha = 1.0, time = 100 })
    end
  end

  local function setOverState()
    if not object.isOver then
      object.isOver = true
      transition.to(object, { alpha = 0.2, time = 100 })
    end
  end

  local function onButtonTouch(event)
    if event.phase == "began" then
      display.getCurrentStage():setFocus(object, event.id)
      object.isFocus = true
      setOverState()
      if options.onEvent then
        options.onEvent(event)
      elseif options.onPress then
        options.onPress(event)
      end
    elseif object.isFocus then
      if event.phase == "moved" then
        if options.scrollView and math.abs(event.y - event.yStart) > 5 then
          setDefaultState()
          options.scrollView:takeFocus(event)
        elseif not utils.isEventWithinBounds(object, event) then
          setDefaultState()
        elseif not object.isOver then
          setOverState()
        end
      elseif event.phase == "ended" or event.phase == "cancelled" then
        if utils.isEventWithinBounds(object, event) then
          if options.onEvent then
            options.onEvent(event)
          elseif options.onRelease then
            options.onRelease(event)
          end
        elseif options.onEvent then
          event.phase = "cancelled"
          options.onEvent(event)
        end
        setDefaultState()
        object.isFocus = false
        display.getCurrentStage():setFocus(object, nil)
      end
    end
    return true
  end

  object:addEventListener("touch", onButtonTouch)
  return object
end

components.newPlusButton = function(parent, width, height, options)
  local plusButtonGroup = components.newGroup(parent)
  components.newEmptyShape(plusButtonGroup, width, height)
  display.newImageRect(plusButtonGroup, "images/icons/plus.png", 50, 50)
  return components.newObjectButton(plusButtonGroup, options)
end

components.newScore = function(parent, size, numberOfStars)
  local stack = layouts.newStack({ mode = "horizontal", parent = parent, separator = size * 0.25 })
  for starCount = 1, 3 do
    local isFullStar = numberOfStars >= starCount
    local star = components.newStar(stack, size, size)
    star.fill.effect = not isFullStar and "filter.grayscale" or nil
    star.isFullStar = isFullStar
  end
  return stack
end

components.newStar = function(parent, width, height)
  local star = display.newImageRect("images/star.png", width, height)
  parent:insert(star)
  return star
end

components.newScrollView = function(parent, options)
  local scrollView = widget.newScrollView({
    left = options.left or screenX,
    top = options.top or screenY,
    width = options.width or screenWidth,
    height = options.height or screenHeight,
    hideBackground = true,
    hideScrollBar = true,
    horizontalScrollDisabled = true,
    topPadding = options.topPadding or 0,
    bottomPadding = options.bottomPadding or 0,
  })
  parent:insert(scrollView)
  return scrollView
end

components.newTabBar = function(parent, tabs, icons)
  local tabBar = components.newGroup(parent)
  tabBar.x = screenX
  tabBar.y = screenY + screenHeight - bottomInset - 60

  local background = display.newRect(tabBar, 0, 0, screenWidth, bottomInset + 60)
  background.anchorX = 0
  background.anchorY = 0
  background.strokeWidth = 1
  background:setFillColor(0, 0, 0, 0.33)
  background:setStrokeColor(0.5, 0.5, 0.5, 0.75)

  local iconImages = {}
  local selectedTab = tabs:selectedTab()
  local spaceSize = display.actualContentWidth / #icons

  for index, icon in ipairs(icons) do
    local buttonGroup = components.newGroup(tabBar)
    iconImages[index] = display.newImageRect(buttonGroup, "images/icons/" .. icon .. ".png", 40, 40)
    components.newObjectButton(buttonGroup, { onRelease = function() tabs:select(index) end })
    iconImages[index].alpha = selectedTab == index and 1 or 0.2
    buttonGroup.x = (index - 1) * spaceSize + spaceSize * 0.5
    buttonGroup.y = 30
  end

  local function onSelect(event)
    if event.index ~= event.previous then
      if event.time == 0 then
        iconImages[event.previous].alpha = 0.2
        iconImages[event.index].alpha = 1
      else
        transition.to(iconImages[event.previous], { alpha = 0.2, time = event.time })
        transition.to(iconImages[event.index], { alpha = 1, time = event.time })
      end
    end
  end

  tabs:addEventListener("select", onSelect)
  tabBar:addEventListener("finalize", function() tabs:removeEventListener("select", onSelect) end)

  return tabBar
end

components.newTextButton = function(parent, text, width, height, options)
  local container = display.newContainer(width, height)
  parent:insert(container)
  local rectangle = display.newRoundedRect(container, 0, 0, width - 2, height - 2, 5)
  rectangle.fill.effect = "generator.linearGradient"
  rectangle.fill.effect.color1 = { 0.24, 0.60, 0.79, 1 }
  rectangle.fill.effect.position1  = { 0, 0 }
  rectangle.fill.effect.color2 = { 0.15, 0.39, 0.52, 1 }
  rectangle.fill.effect.position2  = { 1, 1 }
  rectangle.strokeWidth = 1
  rectangle:setStrokeColor(1, 1, 1, 0.75)
  label = display.newText({ text = text, fontSize = height * 0.4, parent = container })
  return components.newObjectButton(container, options)
end

components.newTopBar = function(parent, options)
  options = options or {}

  local topBar = components.newGroup(parent)

  local background = display.newRect(topBar, screenX, screenY, screenWidth, topInset + 60)
  background.anchorX = 0
  background.anchorY = 0
  background.strokeWidth = 1
  background:setFillColor(0, 0, 0, 0.33)
  background:setStrokeColor(0.5, 0.5, 0.5, 0.75)

  if options.goBack then
    local goBackButton = components.newImageButton(
      topBar,
      "images/icons/back.png",
      40,
      40,
      { onRelease = options.goBack }
    )
    goBackButton.anchorX = 0
    goBackButton.x = screenX + leftInset + 20
    goBackButton.y = screenY + topInset + 30
  end

  function topBar:insertRight(object)
    topBar:insert(object)
    object.anchorX = 1
    object.x = background.contentBounds.xMax - rightInset - 20
    object.y = screenY + topInset + 30
  end

  return topBar
end

return components
