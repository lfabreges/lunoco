local lfs = require "lfs"
local utils = require "modules.utils"

local levelClass = {}

local min = math.min
local round = math.round

local elementDescriptors = {
  { family = "root", name = "background", width = 300, height = 460 },
  { family = "root", name = "ball", width = 30, height = 30, mask = "root-ball-mask.png" },
  { family = "root", name = "frame", width = 128, height = 128 },
  { family = "obstacle", name = "corner", width = 80, height = 80, mask = "obstacle-corner-mask.png" },
  { family = "obstacle", name = "horizontal-barrier", width = 80, height = 30 },
  { family = "obstacle", name = "horizontal-barrier-large", width = 150, height = 30 },
  { family = "obstacle", name = "vertical-barrier", width = 30, height = 80 },
  { family = "obstacle", name = "vertical-barrier-large", width = 30, height = 150 },
  { family = "target", name = "easy", width = 40, height = 40, minWidth = 30, minHeight = 30 },
  { family = "target", name = "normal", width = 40, height = 40, minWidth = 30, minHeight = 30 },
  { family = "target", name = "hard", width = 40, height = 40, minWidth = 30, minHeight = 30 },
}

for _, elementDescriptor in pairs(elementDescriptors) do
  elementDescriptor.mask = elementDescriptor.mask and ("images/elements/" .. elementDescriptor.mask) or nil
  elementDescriptor.minWidth = elementDescriptor.minWidth or elementDescriptor.width * 0.5
  elementDescriptor.minHeight = elementDescriptor.minHeight or elementDescriptor.height * 0.5
  elementDescriptor.maxWidth = elementDescriptor.maxWidth or elementDescriptor.width * 2
  elementDescriptor.maxHeight = elementDescriptor.maxHeight or elementDescriptor.height * 2

  elementDescriptor.size = function(maxWidth, maxHeight)
    if elementDescriptor.width >= elementDescriptor.height then
      return maxWidth, elementDescriptor.height * (maxWidth / elementDescriptor.width)
    else
      return elementDescriptor.width * (maxHeight / elementDescriptor.height), maxHeight
    end
  end
end

local function isObjectEqual(firstObject, secondObject)
  for key, value in pairs(firstObject) do
    if secondObject[key] == nil or secondObject[key] ~= value then
      return false
    end
  end
  for key, value in pairs(secondObject) do
    if firstObject[key] == nil or firstObject[key] ~= value then
      return false
    end
  end
  return true
end

local function isArrayEqual(firstArray, secondArray)
  if #firstArray ~= #secondArray then
    return false
  end
  for index, value in ipairs(firstArray) do
    if not isObjectEqual(value, secondArray[index]) then
      return false
    end
  end
  return true
end

function levelClass:new(world, name)
  local object = { name = name, world = world }
  object.directory = world.directory .. "/" .. name
  utils.makeDirectory(object.directory, system.DocumentsDirectory)
  setmetatable(object, self)
  self.__index = self
  return object
end

function levelClass:configuration()
  if self._configuration == nil then
    if self.world.isBuiltIn then
      self._configuration = utils.loadJson("worlds/" .. self.world.name .. "/" .. self.name .. ".json")
    else
      self._configuration = utils.loadJson(self.directory .. ".json", system.DocumentsDirectory)
    end
  end
  return self._configuration
end

function levelClass:createElements(parent)
  local configuration = self:configuration()
  local elements = { obstacles = {}, targets = {} }

  local frame = self:newElement(parent, "root", "frame", display.actualContentWidth, display.actualContentHeight)
  frame.anchorX = 0
  frame.anchorY = 0
  frame.x = display.screenOriginX
  frame.y = display.screenOriginY
  elements.frame = frame

  local background = self:newElement(parent, "root", "background")
  self:positionElement(background, 0, 0)
  elements.background = background

  for index, configuration in ipairs(configuration.obstacles) do
    local element = self:newElement(parent, "obstacle", configuration.name, configuration.width, configuration.height)
    self:positionElement(element, configuration.x, configuration.y)
    element.rotation = configuration.rotation or 0
    elements.obstacles[index] = element
  end

  for index, configuration in ipairs(configuration.targets) do
    local element = self:newElement(parent, "target", configuration.name, configuration.width, configuration.height)
    self:positionElement(element, configuration.x, configuration.y)
    elements.targets[index] = element
  end

  local ball = self:newElement(parent, "root", "ball")
  self:positionElement(ball, configuration.ball.x, configuration.ball.y)
  elements.ball = ball

  return elements
end

function levelClass:elementDescriptors()
  return elementDescriptors
end

function levelClass:delete()
  utils.removeFile(self.directory .. ".json", system.DocumentsDirectory)
  utils.removeFile(self.directory, system.DocumentsDirectory)
  self:deleteScores()
  self.world:deleteLevel(self)
end

function levelClass:deleteScores()
  local worldScores = self.world:scores()
  if worldScores[self.name] then
    worldScores[self.name] = nil
    self.world:saveScores(worldScores)
  end
end

function levelClass:image(imageFamily, imageName, defaultImageName)
  local fullImageName = utils.nestedGet(self:imageNames(), imageFamily, imageName)
  if fullImageName then
    return fullImageName, system.DocumentsDirectory, false
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
        local fullImageName, imageFamily, imageName = filename:match("^(([^-]+)-(.+)%.nocache%..+%.png)$")
        if fullImageName then
          utils.nestedSet(self._imageNames, imageFamily, imageName, self.directory .. "/" .. fullImageName)
        end
      end
    end
  end
  return self._imageNames
end

function levelClass:newElement(parent, family, name, width, height)
  local elementDescriptor = nil
  local defaultImageName = "images/elements/" .. family .. "-" .. name .. ".png"
  local imageName, imageBaseDir, isDefault = self:image(family, name, defaultImageName)
  local element = nil

  for index = 1, #elementDescriptors do
    elementDescriptor = elementDescriptors[index]
    if elementDescriptor.family == family and elementDescriptor.name == name then
      break
    end
  end

  width = width or elementDescriptor.width
  height = height or elementDescriptor.height

  if family == "root" and name == "frame" then
    element = display.newContainer(width, height)
    local imageWidth = min(128, width)
    local imageHeight = min(128, height)
    for x = 0, width, 128 do
      for y = 0, height, 128 do
        local frameImage = display.newImageRect(element, imageName, imageBaseDir, imageWidth, imageHeight)
        frameImage:translate(-width / 2 + x + imageWidth / 2, -height / 2 + y + imageHeight / 2)
        frameImage.xScale = x % 256 == 0 and 1 or -1
        frameImage.yScale = y % 256 == 0 and 1 or -1
      end
    end
  else
    element = display.newImageRect(imageName, imageBaseDir, width, height)
  end

  element.descriptor = elementDescriptor
  element.isDefault = isDefault
  element.family = family
  element.name = name
  parent:insert(element)

  if elementDescriptor.mask then
    local mask = graphics.newMask(elementDescriptor.mask)
    element:setMask(mask)
    element.isHitTestMasked = false
    element.maskScaleX = element.width / 394
    element.maskScaleY = element.height / 394
  end

  return element
end

function levelClass:positionElement(element, x, y)
  if element.family == "root" and element.name == "ball" then
    element.x = 10 + x
    element.y = 10 + y - element.contentHeight * 0.5
  elseif element.family == "obstacle" and element.name == "corner" then
    element.x = 10 + x + element.contentWidth * 0.5
    element.y = 10 + y + element.contentHeight * 0.5
  else
    element.anchorX = 0
    element.anchorY = 0
    element.x = 10 + x
    element.y = 10 + y
  end
end

function levelClass:removeImage(imageFamily, imageName)
  local imageNames = self:imageNames()
  local fullImageName = utils.nestedGet(imageNames, imageFamily, imageName)
  if fullImageName then
    utils.removeFile(fullImageName, system.DocumentsDirectory)
    imageNames[imageFamily][imageName] = nil
  end
end

function levelClass:save(elements, stars)
  local newConfiguration = { obstacles = {}, stars = stars, targets = {} }

  newConfiguration.ball = {
    x = round(elements.ball.contentBounds.xMin + elements.ball.contentWidth * 0.5 - 10),
    y = round(elements.ball.contentBounds.yMax - 10),
  }

  for index = 1, #elements.obstacles do
    local obstacle = elements.obstacles[index]
    newConfiguration.obstacles[index] = {
      name = obstacle.name,
      x = round(obstacle.contentBounds.xMin - 10),
      y = round(obstacle.contentBounds.yMin - 10),
      width = round(obstacle.contentWidth),
      height = round(obstacle.contentHeight),
      rotation = obstacle.rotation ~= 0 and round(obstacle.rotation) or nil,
    }
  end

  for index = 1, #elements.targets do
    local target = elements.targets[index]
    newConfiguration.targets[index] = {
      name = target.name,
      x = round(target.contentBounds.xMin - 10),
      y = round(target.contentBounds.yMin - 10),
      width = round(target.contentWidth),
      height = round(target.contentHeight),
    }
  end

  local oldConfiguration = self:configuration()
  local hasChanges = false

  hasChanges = hasChanges or not isObjectEqual(oldConfiguration.ball, newConfiguration.ball)
  hasChanges = hasChanges or not isObjectEqual(oldConfiguration.stars, newConfiguration.stars)
  hasChanges = hasChanges or not isArrayEqual(oldConfiguration.obstacles, newConfiguration.obstacles)
  hasChanges = hasChanges or not isArrayEqual(oldConfiguration.targets, newConfiguration.targets)

  if hasChanges then
    utils.saveJson(newConfiguration, self.directory .. ".json", system.DocumentsDirectory)
    self._configuration = newConfiguration
    self:deleteScores()
    self:takeScreenshot()
    self.world:saveLevel(self)
  end
end

function levelClass:saveScore(numberOfShots, numberOfStars)
  local worldScores = self.world:scores()
  if worldScores[self.name] == nil or worldScores[self.name].numberOfShots > numberOfShots then
    worldScores[self.name] = { numberOfShots = numberOfShots, numberOfStars = numberOfStars }
    self.world:saveScores(worldScores)
  end
end

function levelClass:saveImage(object, imageFamily, imageName)
  local filename = self.directory .. "/" .. imageFamily .. "-" .. imageName .. ".nocache." .. math.random() .. ".png"
  display.save(object, { filename = filename, captureOffscreenArea = true })
  self:removeImage(imageFamily, imageName)
  utils.nestedSet(self:imageNames(), imageFamily, imageName, filename)
end

function levelClass:screenshotImage()
  local levelImageName, levelImageBaseDir, isDefault = self:image("level", "screenshot")
  if isDefault then
    self:takeScreenshot()
    return self:image("level", "screenshot")
  else
    return levelImageName, levelImageBaseDir, isDefault
  end
end

function levelClass:takeScreenshot()
  local screenshotContainer = display.newContainer(320, 480)
  screenshotContainer.anchorX = 0
  screenshotContainer.anchorY = 0
  screenshotContainer.anchorChildren = false
  local elements = self:createElements(screenshotContainer)
  local screenshot = display.capture(screenshotContainer, { captureOffscreenArea = true })
  screenshot:scale(0.33, 0.33)
  self:saveImage(screenshot, "level", "screenshot")
  display.remove(screenshot)
  display.remove(screenshotContainer)
end

return levelClass
