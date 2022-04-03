local utils = require "modules.utils"
local widget = require "widget"

local components = {}

local function isWithinBounds(object, event)
  local bounds = object.contentBounds
  local x, y = event.x, event.y
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
  background:setFillColor(0.25)
  return background
end

components.newButton = function(parent, options)
  local buttonOptions = {
    labelColor = { default = { 1.0 }, over = { 0.5 } },
    width = 160,
    height = 40,
    shape = "roundedRect",
    cornerRadius = 2,
    fillColor = { default = { 0.14, 0.19, 0.4, 1 }, over = { 0.14, 0.19, 0.4, 0.4 } },
    strokeColor = { default = { 1, 1, 1, 1 }, over = { 1, 1, 1, 0.5 } },
    strokeWidth = 2,
  }

  for key, value in pairs(options) do
    buttonOptions[key] = value
  end

  local button = widget.newButton(buttonOptions)
  parent:insert(button)
  return button
end

components.newImageButton = function(parent, imageName, imageBaseDir, width, height, options)
  if not options then
    options = height
    height = width
    width = imageBaseDir
    imageBaseDir = system.ResourceDirectory
  end

  local imageButton = display.newImageRect(parent, imageName, imageBaseDir, width, height)

  local function setDefaultState()
    if imageButton.isOver then
      imageButton.isOver = false
      transition.to(imageButton, { alpha = 1.0, time = 50 })
    end
  end

  local function setOverState()
    if not imageButton.isOver then
      imageButton.isOver = true
      transition.to(imageButton, { alpha = 0.2, time = 50 })
    end
  end

  local function onButtonTouch(event)
    if event.phase == "began" then
      display.getCurrentStage():setFocus(imageButton, event.id)
      setOverState()
      if options.onPress and not options.onEvent then
        options.onPress(event)
      end
    elseif event.phase == "moved" then
      if options.scrollview and math.abs(event.y - event.yStart) > 5 then
        setDefaultState()
        options.scrollview:takeFocus(event)
      elseif not isWithinBounds(imageButton, event) then
        setDefaultState()
      elseif not imageButton.isOver then
        setOverState()
      end
    elseif event.phase == "ended" or event.phase == "cancelled" then
      if isWithinBounds(imageButton, event) then
        if options.onRelease and not options.onEvent then
          options.onRelease(event)
        end
      end
      setDefaultState()
      display.getCurrentStage():setFocus(nil)
    end
    if options.onEvent and not options.onPress and not options.onRelease then
      if not isWithinBounds(imageButton, event) and event.phase == "ended" then
        event.phase = "cancelled"
      end
      options.onEvent(event)
    end
    return true
  end

  imageButton:addEventListener("touch", onButtonTouch)
  return imageButton
end

components.newGroup = function(parent)
  local group = display.newGroup()
  parent:insert(group)
  return group
end

components.newOverlayBackground = function(parent)
  local background = components.newBackground(parent)
  background:setFillColor(0, 0, 0, 0.9)
  return background
end

return components
