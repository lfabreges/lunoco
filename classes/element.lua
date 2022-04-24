local utils = require "modules.utils"

local elementClass = {}

local elements = {
  { family = "root", name = "background", width = 300, height = 460 },
  { family = "root", name = "ball", width = 30, height = 30, mask = "images/elements/ball-mask.png" },
  { family = "root", name = "frame", width = display.actualContentWidth, height = display.actualContentHeight },
  { family = "obstacle", name = "corner", width = 80, height = 80, mask = "images/elements/corner-mask.png" },
  { family = "obstacle", name = "horizontal-barrier", width = 80, height = 30 },
  { family = "obstacle", name = "horizontal-barrier-large", width = 150, height = 30 },
  { family = "obstacle", name = "vertical-barrier", width = 30, height = 80 },
  { family = "obstacle", name = "vertical-barrier-large", width = 30, height = 150 },
  { family = "target", name = "easy", width = 40, height = 40, minScale = 0.75 },
  { family = "target", name = "normal", width = 40, height = 40, minScale = 0.75 },
  { family = "target", name = "hard", width = 40, height = 40, minScale = 0.75 },
}

local configurations = {}
utils.forEach(elements, function(element) utils.nestedSed(configurations, element.family, element.name, element) end)

local function newFrame(parent, imageName, imageBaseDir, width, height)
  local frame = display.newContainer(width, height)
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
  return frame
end

function elementClass:new(parent, level, family, name, width, height)
  local configuration = configurations[family][name]
  local imageShortName = (family ~= "root" and (family .. "-") or "") .. name
  local defaultImageName = "images/elements/" .. (family == "target" and "target-" or "") .. name .. ".png"
  local imageName, imageBaseDir, isDefault = level:image(imageShortName, defaultImageName)
  local element

  if imageShortName == "root-frame" then
    element = newFrame(parent, imageName, imageBaseDir, width, height)
  else
    display.newImageRect(imageName, imageBaseDir, width, height)
  end

  element.isDefault = isDefault
  element.family = family
  element.name = name
  parent:insert(element)

  if configuration.mask then
    local mask = graphics.newMask(configuration.mask)
    element:setMask(mask)
    element.isHitTestMasked = false
    element.maskScaleX = element.width / 394
    element.maskScaleY = element.height / 394
  end

  return element
end

-- TODO Ajouter une méthode resize tenant compte des limites
-- etc.

return elementClass
