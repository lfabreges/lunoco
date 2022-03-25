local utils = require "utils"
local widget = require "widget"

local components = {}

local function elementImage(levelName, elementType, defaultImageName)
  local imageName = "level." .. levelName .. "." .. elementType .. ".png"
  if utils.fileExists(imageName, system.DocumentsDirectory) then
    return imageName, system.DocumentsDirectory
  else
    return defaultImageName, system.ResourceDirectory
  end
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

components.newBall = function(parent, levelName, width, height)
  local imageName, imageBaseDir = elementImage(levelName, "ball", "images/ball.png")
  local ball = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  local ballMask = graphics.newMask("images/ball-mask.png")
  ball:setMask(ballMask)
  ball.maskScaleX = ball.width / 394
  ball.maskScaleY = ball.height / 394
  return ball
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

components.newObstacleBarrier = function(parent, levelName, barrierType, width, height)
  local imageName, imageBaseDir = elementImage(
    levelName,
    "obstacle-" .. barrierType,
    "images/" .. barrierType .. ".png"
  )
  local barrier = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  return barrier
end

components.newObstacleCorner = function(parent, levelName, width, height)
  local imageName, imageBaseDir = elementImage(levelName, "obstacle-corner", "images/corner.png")
  local corner = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  local cornerMask = graphics.newMask("images/corner-mask.png")
  corner:setMask(cornerMask)
  corner.maskScaleX = corner.width / 394
  corner.maskScaleY = corner.height / 394
  return corner
end

components.newOverlayBackground = function(parent)
  local background = components.newBackground(parent)
  background:setFillColor(0, 0, 0, 0.9)
  return background
end

components.newTarget = function(parent, levelName, targetType, width, height)
  local imageName, imageBaseDir = elementImage(
    levelName,
    "target-" .. targetType,
    "images/target-" .. targetType .. ".png"
  )
  local target = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  return target
end

return components
