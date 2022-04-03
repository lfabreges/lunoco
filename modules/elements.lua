local utils = require "modules.utils"

local elements = {}

local function elementImage(levelName, elementType, defaultImageName)
  local imageName = utils.levelImageName(levelName, elementType)
  if imageName then
    return imageName, system.DocumentsDirectory, false
  else
    return defaultImageName, system.ResourceDirectory, true
  end
end

elements.newBackground = function(parent, levelName, width, height)
  local imageName, imageBaseDir, isDefault = elementImage(levelName, "background", "images/elements/background.png")
  local background = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  background.isDefault = isDefault
  return background
end

elements.newBall = function(parent, levelName, width, height)
  local imageName, imageBaseDir, isDefault = elementImage(levelName, "ball", "images/elements/ball.png")
  local ball = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  local ballMask = graphics.newMask("images/elements/ball-mask.png")
  ball:setMask(ballMask)
  ball.maskScaleX = ball.width / 394
  ball.maskScaleY = ball.height / 394
  ball.isDefault = isDefault
  return ball
end

elements.newFrame = function(parent, levelName, width, height)
  local imageName, imageBaseDir, isDefault = elementImage(levelName, "frame", "images/elements/frame.png")
  local frame = display.newContainer(parent, width, height)
  local imageWidth = math.min(128, width)
  local imageHeight = math.min(128, height)

  for x = 0, width, 128 do
    for y = 0, height, 128 do
      local frameImage = display.newImageRect(frame, imageName, imageBaseDir, imageWidth, imageHeight)
      frameImage:translate(-width / 2 + x + imageWidth / 2, -height / 2 + y + imageHeight / 2)
      frameImage.xScale = x % 256 == 0 and 1 or -1
      frameImage.yScale = y % 256 == 0 and 1 or -1
    end
  end

  frame.isDefault = isDefault

  return frame
end

elements.newObstacleBarrier = function(parent, levelName, barrierType, width, height)
  local imageName, imageBaseDir, isDefault = elementImage(
    levelName,
    "obstacle-" .. barrierType,
    "images/elements/" .. barrierType .. ".png"
  )
  local barrier = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  barrier.isDefault = isDefault
  return barrier
end

elements.newObstacleCorner = function(parent, levelName, width, height)
  local imageName, imageBaseDir, isDefault = elementImage(levelName, "obstacle-corner", "images/elements/corner.png")
  local corner = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  local cornerMask = graphics.newMask("images/elements/corner-mask.png")
  corner:setMask(cornerMask)
  corner.maskScaleX = corner.width / 394
  corner.maskScaleY = corner.height / 394
  corner.isDefault = isDefault
  return corner
end

elements.newTarget = function(parent, levelName, targetType, width, height)
  local imageName, imageBaseDir, isDefault = elementImage(
    levelName,
    "target-" .. targetType,
    "images/elements/target-" .. targetType .. ".png"
  )
  local target = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  target.isDefault = isDefault
  return target
end

return elements
