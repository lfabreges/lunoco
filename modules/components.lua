local utils = require "modules.utils"

local components = {}

local function isWithinBounds(object, event)
  local bounds = object.contentBounds
  local x = event.x
  local y = event.y
	local isWithinBounds = true
	return bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
end

components.newBackground = function(parent)
  local screenX = display.screenOriginX
  local screenY = display.screenOriginY
  local screenWidth = display.actualContentWidth
  local screenHeight = display.actualContentHeight
  local background = display.newRect(parent, screenX, screenY, screenWidth, screenHeight)
  background.anchorX = 0
  background.anchorY = 0
  display.setDefault("textureWrapX", "repeat")
  display.setDefault("textureWrapY", "repeat")
  background.fill = { type = "image", filename = "images/background.png" }
  display.setDefault("textureWrapX", "clampToEdge")
  display.setDefault("textureWrapY", "clampToEdge")
  return background
end

components.newTextButton = function(parent, text, width, height, options)
  local container = display.newContainer(parent, width, height)
  local rectangle = display.newRoundedRect(container, 0, 0, width - 2, height - 2, 5)
  rectangle.strokeWidth = 1
  rectangle:setFillColor(0.5, 0.5, 0.5, 0.25)
  rectangle:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  label = display.newText({ text = text, fontSize = height * 0.4, parent = container })
  return components.newObjectButton(container, options)
end

components.newImageButton = function(parent, imageName, imageBaseDir, width, height, options)
  if not options then
    options = height
    height = width
    width = imageBaseDir
    imageBaseDir = system.ResourceDirectory
  end
  local imageButton = display.newImageRect(parent, imageName, imageBaseDir, width, height)
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
        if options.scrollview and math.abs(event.y - event.yStart) > 5 then
          setDefaultState()
          options.scrollview:takeFocus(event)
        elseif not isWithinBounds(object, event) then
          setDefaultState()
        elseif not object.isOver then
          setOverState()
        end
      elseif event.phase == "ended" or event.phase == "cancelled" then
        if isWithinBounds(object, event) then
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
        display.getCurrentStage():setFocus(object, nil)
        object.isFocus = false
      end
    end
    return true
  end

  object:addEventListener("touch", onButtonTouch)
  return object
end

components.newGroup = function(parent)
  local group = display.newGroup()
  parent:insert(group)
  return group
end

components.newStar = function(parent, width, height)
  local star = display.newImageRect(parent, "images/star.png", width, height)
  local starMask = graphics.newMask("images/star-mask.png")
  star:setMask(starMask)
  star.maskScaleX = star.width / 394
  star.maskScaleY = star.height / 394
  return star
end

components.newTopBar = function(parent)
  local screenX = display.screenOriginX
  local screenY = display.screenOriginY
  local screenWidth = display.actualContentWidth
  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()
  local topBar = display.newRect(parent, screenX, screenY, screenWidth, topInset + 60)
  topBar.anchorX = 0
  topBar.anchorY = 0
  topBar.strokeWidth = 1
  topBar:setFillColor(0, 0, 0, 0.33)
  topBar:setStrokeColor(0.5, 0.5, 0.5, 0.75)
  return topBar
end

return components
