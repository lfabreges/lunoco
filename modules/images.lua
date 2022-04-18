local lfs = require "lfs"
local utils = require "modules.utils"

local images = {}
local levelImageNames = {}

local function loadLevelImageNames(level)
  local imageNames = utils.nestedGet(levelImageNames, level.world.type, level.world.name, level.name)

  if imageNames then
    return imageNames
  else
    imageNames = utils.nestedSet(levelImageNames, level.world.type, level.world.name, level.name, {})
  end

  local levelDirectoryName = "elements/" .. level.world.type .. "/" .. level.world.name .. "/" .. level.name

  if utils.fileExists(levelDirectoryName, system.DocumentsDirectory) then
    local path = system.pathForFile(levelDirectoryName, system.DocumentsDirectory)
    for filename in lfs.dir(path) do
      local noCacheName, imageName = filename:match("^((.+)%.nocache%..+%.png)$")
      if noCacheName then
        imageNames[imageName] = levelDirectoryName .. "/" .. noCacheName
      end
    end
  end

  return imageNames
end

images.levelImageName = function(level, imageName)
  local levelImageNames = loadLevelImageNames(level)
  return levelImageNames[imageName] and levelImageNames[imageName] or nil
end

images.removeLevelImage = function(level, imageName)
  local levelImageName = images.levelImageName(level, imageName)
  if levelImageName then
    local levelImageNames = loadLevelImageNames(level)
    local filepath = system.pathForFile(levelImageName, system.DocumentsDirectory)
    os.remove(filepath)
    levelImageNames[imageName] = nil
  end
end

images.saveLevelImage = function(object, level, imageName)
  utils.mkdir(system.DocumentsDirectory, "elements", level.world.type, level.world.name, level.name)

  local levelDirectoryName = "elements/" .. level.world.type .. "/" .. level.world.name .. "/" .. level.name
  local filename = levelDirectoryName .. "/" .. imageName .. ".nocache." .. math.random() .. ".png"
  display.save(object, { filename = filename, captureOffscreenArea = true })
  images.removeLevelImage(level, imageName)

  local levelImageNames = loadLevelImageNames(level)
  levelImageNames[imageName] = filename
end

return images
