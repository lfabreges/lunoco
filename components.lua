local widget = require "widget"

local components = {}

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
