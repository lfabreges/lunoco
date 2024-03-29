local i18n = require "modules.i18n"
local layouts = require "modules.layouts"
local utils = require "modules.utils"
local widget = require "widget"

local components = {}

components.fillWithBackground = function(object)
  display.setDefault("textureWrapX", "repeat")
  display.setDefault("textureWrapY", "repeat")
  object.fill = { type = "image", filename = "images/background.png" }
  display.setDefault("textureWrapX", "clampToEdge")
  display.setDefault("textureWrapY", "clampToEdge")
end

components.newBackground = function(parent)
  local background = display.newRect(
    display.screenOriginX,
    display.screenOriginY,
    display.actualContentWidth,
    display.actualContentHeight
  )
  parent:insert(background)
  background.anchorX = 0
  background.anchorY = 0
  components.fillWithBackground(background)
  return background
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

components.newRunTimeText = function(parent, runTime)
  local stack = layouts.newStack({ align = "center", mode = "horizontal", parent = parent, separator = 20 })
  local icon = display.newImageRect("images/icons/speedrun.png", 45, 45)
  stack:insert(icon)
  local minutes, seconds, milliseconds = utils.splitTime(runTime)
  local text = display.newText({ text = i18n.t("time", minutes, seconds, milliseconds), fontSize = 40 })
  stack:insert(text)
  return stack
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
    left = options.left or display.screenOriginX,
    top = options.top or display.screenOriginY,
    width = options.width or display.actualContentWidth,
    height = options.height or display.actualContentHeight,
    hideBackground = true,
    hideScrollBar = true,
    horizontalScrollDisabled = true,
    topPadding = options.topPadding or 0,
    bottomPadding = options.bottomPadding or 0,
  })
  parent:insert(scrollView)
  return scrollView
end

components.newSpeedrunBoard = function(parent, width, texts)
  local board = display.newGroup()
  local frame = components.newFrame(board, width, 0)
  local stack = layouts.newStack({ align = "center", parent = board, separator = 6 })

  for numberOfStars = 0, 3 do
    local group = display.newGroup()

    local score = components.newScore(group, 20, numberOfStars)
    layouts.alignHorizontal(score, "left", frame)
    score.x = score.x + 10

    local text = texts[numberOfStars]
    group:insert(text)
    layouts.alignHorizontal(text, "right", frame)
    text.x = text.x - 10
    layouts.alignVertical(text, "center", score)

    stack:insert(group)

    if numberOfStars < 3 then
      local separator = display.newLine(0, 0, frame.contentWidth - 20, 0)
      separator:setStrokeColor(0.5, 0.5, 0.5, 0.75)
      stack:insert(separator)
      separator.y = separator.y + (separator.contentHeight - separator.strokeWidth) * 0.5
    end
  end

  frame.path.height = stack.contentHeight + 20
  layouts.align(stack, "center", "center", frame)
  parent:insert(board)

  return board
end

components.newTabBar = function(parent, tabs, icons)
  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  local tabBar = components.newGroup(parent)
  tabBar.x = display.screenOriginX
  tabBar.y = display.screenOriginY + display.actualContentHeight - bottomInset - 60

  local background = display.newRect(tabBar, 0, 0, display.actualContentWidth, bottomInset + 60)
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

components.newTextButton = function(parent, text, iconName, width, height, options)
  if not options then
    options = height
    height = width
    width = iconName
    iconName = nil
  end

  local group = display.newGroup()

  local rectangle = display.newRoundedRect(group, 0, 0, width - 2, height - 2, 5)
  rectangle.strokeWidth = 1
  rectangle:setFillColor(0.21, 0.51, 0.83, 0.75)
  rectangle:setStrokeColor(1, 1, 1, 0.75)

  if iconName then
    local surface = display.newRect(group, 0, 0, width, height)
    surface.isVisible = false
    surface.isHitTestable = true

    local iconSize = height * 0.7
    local icon = display.newImageRect(group, "images/icons/" .. iconName .. ".png", iconSize, iconSize)
    layouts.alignHorizontal(icon, "left", surface)

    rectangle.path.width = rectangle.path.width - 15 - iconSize
    layouts.alignHorizontal(rectangle, "left", icon)
    rectangle.x = rectangle.x + icon.contentWidth + 15
  end

  local label = display.newText({ text = text, fontSize = height * 0.4, parent = group })
  label.x = rectangle.x

  parent:insert(group)
  return components.newObjectButton(group, options)
end

components.newTopBar = function(parent, options)
  options = options or {}

  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()
  local topBar = components.newGroup(parent)

  local background = display.newRect(
    topBar,
    display.screenOriginX,
    display.screenOriginY,
    display.actualContentWidth,
    topInset + 60
  )
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
    goBackButton.x = display.screenOriginX + leftInset + 20
    goBackButton.y = display.screenOriginY + topInset + 30
  end

  function topBar:insertRight(object)
    topBar:insert(object)
    object.anchorX = 1
    object.x = background.contentBounds.xMax - rightInset - 20
    object.y = display.screenOriginY + topInset + 30
  end

  return topBar
end

return components
