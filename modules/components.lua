local utils = require "modules.utils"
local widget = require "widget"

local components = {}

local screenX = display.screenOriginX
local screenY = display.screenOriginY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight
local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

components.newBackground = function(parent)
  local background = display.newRect(screenX, screenY, screenWidth, screenHeight)
  parent:insert(background)
  background.anchorX = 0
  background.anchorY = 0
  display.setDefault("textureWrapX", "repeat")
  display.setDefault("textureWrapY", "repeat")
  background.fill = { type = "image", filename = "images/background.png" }
  display.setDefault("textureWrapX", "clampToEdge")
  display.setDefault("textureWrapY", "clampToEdge")
  return background
end

-- TODO A positionner au bon endroit
components.newFrame = function(parent, width, height)
  local frame = display.newRoundedRect(0, 0, width - 2, height - 2, 5)
  frame.strokeWidth = 1
  parent:insert(frame)
  frame:setFillColor(0.5, 0.5, 0.5, 0.25)
  frame:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  return frame
end

components.newGroup = function(parent, anchorChildren)
  local group = display.newGroup()
  group.anchorChildren = anchorChildren or false
  parent:insert(group)
  return group
end

-- TODO A garder comme cela ?
components.newHitTestableSurface = function(parent, reference)
  local surface = display.newRect(parent, reference.x, reference.y, reference.width, reference.height)
  surface.anchorX = reference.anchorX
  surface.anchorY = reference.anchorY
  surface.xScale = reference.xScale
  surface.yScale = reference.yScale
  surface.isVisible = false
  surface.isHitTestable = true
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
  local plusButtonGroup = components.newGroup(parent, true)
  local plusButtonBackground = display.newRect(plusButtonGroup, 0, 0, width, height)
  plusButtonBackground.fill.effect = "generator.linearGradient"
  plusButtonBackground.fill.effect.color1 = { 0.25, 0.25, 0.25, 0.75 }
  plusButtonBackground.fill.effect.position1  = { 0, 0 }
  plusButtonBackground.fill.effect.color2 = { 0.5, 0.5, 0.5, 0.25 }
  plusButtonBackground.fill.effect.position2  = { 1, 1 }
  plusButtonBackground.strokeWidth = 1
  plusButtonBackground:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  display.newImageRect(plusButtonGroup, "images/icons/plus.png", 50, 50)
  return components.newObjectButton(plusButtonGroup, options)
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
    topPadding = topInset + (options.topPadding or 0),
    bottomPadding = bottomInset + (options.bottomPadding or 0),
  })
  parent:insert(scrollView)
  return scrollView
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
    goBackButton.anchorY = 0
    goBackButton.x = screenX + leftInset + 20
    goBackButton.y = screenY + topInset + 10
  end

  return topBar
end

return components
