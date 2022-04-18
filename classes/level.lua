local lfs = require "lfs"
local utils = require "modules.utils"

local levelClass = {}

function levelClass:new(world, name)
  local object = { name = name, world = world }
  object.directory = world.directory .. "/" .. name
  utils.mkdir(system.DocumentsDirectory, object.directory)
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
    -- TODO A voir si à positionner ailleurs ?
    -- Poser une fonction de validation ?
    if not self._configuration.ball then
      self._configuration.ball = { x = 150, y = 460 }
    end
    if not self._configuration.stars then
      self._configuration.stars = { one = 6, two = 4, three = 2 }
    end
    if not self._configuration.obstacles then
      self._configuration.obstacles = {}
    end
    if not self._configuration.targets then
      self._configuration.targets = {}
    end
  end
  return self._configuration
end

function levelClass:image(imageName, defaultImageName)
  local imageNames = self:imageNames()
  if imageNames[imageName] then
    return imageNames[imageName], system.DocumentsDirectory, false
  else
    return defaultImageName, system.ResourceDirectory, true
  end
end

function levelClass:imageNames()
  if self._imageNames == nil then
    self._imageNames = {}
    if utils.fileExists(self.directory, system.DocumentsDirectory) then
      local path = system.pathForFile(self.directory, system.DocumentsDirectory)
      for filename in lfs.dir(path) do
        local nocacheImageName, imageName = filename:match("^((.+)%.nocache%..+%.png)$")
        if nocacheImageName then
          self._imageNames[imageName] = self.directory .. "/" .. nocacheImageName
        end
      end
    end
  end
  return self._imageNames
end

function levelClass:removeImage(imageName)
  local imageNames = self:imageNames()
  if imageNames[imageName] then
    local filepath = system.pathForFile(imageNames[imageName], system.DocumentsDirectory)
    os.remove(filepath)
    imageNames[imageName] = nil
  end
end

function levelClass:saveImage(object, imageName)
  local filename = self.directory .. "/" .. imageName .. ".nocache." .. math.random() .. ".png"
  display.save(object, { filename = filename, captureOffscreenArea = true })
  self:removeImage(imageName)
  local imageNames = self:imageNames()
  imageNames[imageName] = filename
end

function levelClass:saveScore(numberOfShots, numberOfStars)
  local worldScores = self.world:scores()
  if worldScores[self.name] == nil or worldScores[self.name].numberOfShots > numberOfShots then
    worldScores[self.name] = { numberOfShots = numberOfShots, numberOfStars = numberOfStars }
    self.world:saveScores(worldScores)
  end
end

function levelClass:createElements(parent)
  local configuration = self:configuration()
  local elements = { obstacles = {}, targets = {} }

  local frame = self:newFrame(parent, display.actualContentWidth, display.actualContentHeight)
  frame.anchorX = 0
  frame.anchorY = 0
  frame.x = display.screenOriginX
  frame.y = display.screenOriginY
  elements.frame = frame

  local background = self:newBackground(parent, 300, 460)
  background.anchorX = 0
  background.anchorY = 0
  background:translate(10, 10)
  elements.background = background

  for index, configuration in ipairs(configuration.obstacles) do
    if configuration.type == "corner" then
      local corner = self:newObstacleCorner(parent, configuration.width, configuration.height)
      corner.x = 10 + configuration.x + corner.width / 2
      corner.y = 10 + configuration.y + corner.height / 2
      corner.rotation = configuration.rotation
      corner.type = configuration.type
      elements.obstacles[index] = corner
    elseif configuration.type:starts("horizontal-barrier") or configuration.type:starts("vertical-barrier") then
      local barrier = self:newObstacleBarrier(parent, configuration.type, configuration.width, configuration.height)
      barrier.anchorChildren = true
      barrier.anchorX = 0
      barrier.anchorY = 0
      barrier.x = 10 + configuration.x
      barrier.y = 10 + configuration.y
      barrier.type = configuration.type
      elements.obstacles[index] = barrier
    end
  end

  for index, configuration in ipairs(configuration.targets) do
    local target = self:newTarget(parent, configuration.type, configuration.width, configuration.height)
    target.anchorChildren = true
    target.anchorX = 0
    target.anchorY = 0
    target.x = 10 + configuration.x
    target.y = 10 + configuration.y
    target.type = configuration.type
    elements.targets[index] = target
  end

  local ball = self:newBall(parent, 30, 30)
  ball.x = 10 + configuration.ball.x
  ball.y = 10 + configuration.ball.y - 15
  elements.ball = ball

  return elements
end

function levelClass:createConfiguration(elements)
  local configuration = { obstacles = {}, targets = {} }

  configuration.ball = {
    x = elements.ball.x - 10,
    y = elements.ball.y + 5,
  }

  for index = 1, #elements.obstacles do
    local obstacle = elements.obstacles[index]
    if obstacle.type == "corner" then
      configuration.obstacles[index] = {
        type = obstacle.type,
        x = obstacle.x - 10 - obstacle.width / 2,
        y = obstacle.y - 10 - obstacle.height / 2,
        width = obstacle.width,
        height = obstacle.height,
        rotation = obstacle.rotation,
      }
    elseif obstacle.type:starts("horizontal-barrier") or obstacle.type:starts("vertical-barrier") then
      configuration.obstacles[index] = {
        type = obstacle.type,
        x = obstacle.x - 10,
        y = obstacle.y - 10,
        width = obstacle.width,
        height = obstacle.height,
      }
    end
  end

  for index = 1, #elements.targets do
    local target = elements.targets[index]
    configuration.targets[index] = {
      type = target.type,
      x = target.x - 10,
      y = target.y - 10,
      width = target.width,
      height = target.height,
    }
  end

  return configuration
end

function levelClass:newBackground(parent, width, height)
  local imageName, imageBaseDir, isDefault = self:image("background", "images/elements/background.png")
  local background = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  background.isDefault = isDefault
  return background
end

function levelClass:newBall(parent, width, height)
  local imageName, imageBaseDir, isDefault = self:image("ball", "images/elements/ball.png")
  local ball = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  local ballMask = graphics.newMask("images/elements/ball-mask.png")
  ball:setMask(ballMask)
  ball.maskScaleX = ball.width / 394
  ball.maskScaleY = ball.height / 394
  ball.isDefault = isDefault
  return ball
end

function levelClass:newFrame(parent, width, height)
  local imageName, imageBaseDir, isDefault = self:image("frame", "images/elements/frame.png")
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
  local imageName, imageBaseDir, isDefault = self:image(
    "obstacle-" .. barrierType,
    "images/elements/" .. barrierType .. ".png"
  )
  local barrier = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  barrier.isDefault = isDefault
  return barrier
end

function levelClass:newObstacleCorner(parent, width, height)
  local imageName, imageBaseDir, isDefault = self:image("obstacle-corner", "images/elements/corner.png")
  local corner = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  local cornerMask = graphics.newMask("images/elements/corner-mask.png")
  corner:setMask(cornerMask)
  corner.maskScaleX = corner.width / 394
  corner.maskScaleY = corner.height / 394
  corner.isDefault = isDefault
  return corner
end

function levelClass:newTarget(parent, targetType, width, height)
  local imageName, imageBaseDir, isDefault = self:image(
    "target-" .. targetType,
    "images/elements/target-" .. targetType .. ".png"
  )
  local target = display.newImageRect(parent, imageName, imageBaseDir, width, height)
  target.isDefault = isDefault
  return target
end

return levelClass
