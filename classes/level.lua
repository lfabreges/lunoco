local lfs = require "lfs"
local utils = require "modules.utils"

local levelClass = {}

function levelClass:new(world, name)
  local object = {}
  object.name = name
  object.world = world
  setmetatable(object, self)
  self.__index = self
  return object
end

function levelClass:configuration()
  if self._configuration == nil then
    if self.world.isBuiltIn then
      self._configuration = utils.loadJson(
        "worlds/" .. self.world.name .. "/" .. self.name .. ".json",
        system.ResourceDirectory
      )
    else
      self._configuration = utils.loadJson(
        "worlds/user/" .. self.world.name .. "/" .. self.name .. ".json",
        system.DocumentsDirectory
      )
    end
  end
  return self._configuration
end

function levelClass:elementImageNames()
  if self._elementImageNames == nil then
    self._elementImageNames = {}
    local levelDirectoryName = "worlds/" .. self.world.type .. "/" .. self.world.name .. "/" .. self.name
    if utils.fileExists(levelDirectoryName, system.DocumentsDirectory) then
      local path = system.pathForFile(levelDirectoryName, system.DocumentsDirectory)
      for filename in lfs.dir(path) do
        local imageName, elementType = filename:match("^((.+)%.nocache%..+%.png)$")
        if imageName then
          self._elementImageNames[elementType] = levelDirectoryName .. "/" .. imageName
        end
      end
    end
  end
  return self._elementImageNames
end

function levelClass:elementImage(elementType, defaultElementImageName)
  local elementImageNames = self:elementImageNames()
  if elementImageNames[elementType] then
    return elementImageNames[elementType], system.DocumentsDirectory, false
  else
    return defaultElementImageName, system.ResourceDirectory, true
  end
end

function levelClass:removeElementImage(elementType)
  local elementImageNames = self:elementImageNames()
  if elementImageNames[elementType] then
    local filepath = system.pathForFile(elementImageNames[elementType], system.DocumentsDirectory)
    os.remove(filepath)
    elementImageNames[elementType] = nil
  end
end

function levelClass:saveElementImage(object, elementType)
  utils.mkdir(system.DocumentsDirectory, "worlds", self.world.type, self.world.name, self.name)
  local levelDirectoryName = "worlds/" .. self.world.type .. "/" .. self.world.name .. "/" .. self.name
  local filename = levelDirectoryName .. "/" .. elementType .. ".nocache." .. math.random() .. ".png"
  display.save(object, { filename = filename, captureOffscreenArea = true })
  self:removeElementImage(elementType)
  local elementImageNames = self:elementImageNames()
  elementImageNames[elementType] = filename
end

function levelClass:newBackground(parent, width, height)
  local imageName, imageBaseDir, isDefault = self:elementImage("background", "images/elements/background.png")
  local background = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  background.isDefault = isDefault
  return background
end

function levelClass:newBall(parent, width, height)
  local imageName, imageBaseDir, isDefault = self:elementImage("ball", "images/elements/ball.png")
  local ball = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  local ballMask = graphics.newMask("images/elements/ball-mask.png")
  ball:setMask(ballMask)
  ball.maskScaleX = ball.width / 394
  ball.maskScaleY = ball.height / 394
  ball.isDefault = isDefault
  return ball
end

function levelClass:newFrame(parent, width, height)
  local imageName, imageBaseDir, isDefault = self:elementImage("frame", "images/elements/frame.png")
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

function levelClass:newObstacleBarrier(parent, barrierType, width, height)
  local imageName, imageBaseDir, isDefault = self:elementImage(
    "obstacle-" .. barrierType,
    "images/elements/" .. barrierType .. ".png"
  )
  local barrier = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  barrier.isDefault = isDefault
  return barrier
end

function levelClass:newObstacleCorner(parent, width, height)
  local imageName, imageBaseDir, isDefault = self:elementImage("obstacle-corner", "images/elements/corner.png")
  local corner = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  local cornerMask = graphics.newMask("images/elements/corner-mask.png")
  corner:setMask(cornerMask)
  corner.maskScaleX = corner.width / 394
  corner.maskScaleY = corner.height / 394
  corner.isDefault = isDefault
  return corner
end

function levelClass:newTarget(parent, targetType, width, height)
  local imageName, imageBaseDir, isDefault = self:elementImage(
    "target-" .. targetType,
    "images/elements/target-" .. targetType .. ".png"
  )
  local target = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  target.isDefault = isDefault
  return target
end

function levelClass:saveScore(numberOfShots, numberOfStars)
  local worldScores = self.world:scores()
  if worldScores[self.name] == nil or worldScores[self.name].numberOfShots > numberOfShots then
    worldScores[self.name] = { numberOfShots = numberOfShots, numberOfStars = numberOfStars }
    self.world:saveScores(worldScores)
  end
end

return levelClass
