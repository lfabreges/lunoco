local lfs = require "lfs"
local utils = require "modules.utils"

local images = {}
local levelImageNames = {}

local function loadLevelImageNames(world, levelName)
  if not levelImageNames[world.category] then
    levelImageNames[world.category] = {}
  end
  if not levelImageNames[world.category][world.name] then
    levelImageNames[world.category][world.name] = {}
  end
  if not levelImageNames[world.category][world.name][levelName] then
    levelImageNames[world.category][world.name][levelName] = {}
  else
    return levelImageNames[world.category][world.name][levelName]
  end

  local imageNames = levelImageNames[world.category][world.name][levelName]
  local levelDirectoryName = "elements/" .. world.category .. "/" .. world.name .. "/" .. levelName

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

images.levelImageName = function(world, levelName, imageName)
  local levelImageNames = loadLevelImageNames(world, levelName)
  return levelImageNames[imageName] and levelImageNames[imageName] or nil
end

images.removeLevelImage = function(world, levelName, imageName)
  local levelImageName = images.levelImageName(world, levelName, imageName)
  if levelImageName then
    local levelImageNames = loadLevelImageNames(world, levelName)
    local filepath = system.pathForFile(levelImageName, system.DocumentsDirectory)
    os.remove(filepath)
    levelImageNames[imageName] = nil
  end
end

images.saveLevelImage = function(object, world, levelName, imageName)
  utils.mkdir(system.DocumentsDirectory, "elements", world.category, world.name, levelName)

  local levelDirectoryName = "elements/" .. world.category .. "/" .. world.name .. "/" .. levelName
  local filename = levelDirectoryName .. "/" .. imageName .. ".nocache." .. math.random() .. ".png"
  display.save(object, { filename = filename, captureOffscreenArea = true })
  images.removeLevelImage(world, levelName, imageName)

  local levelImageNames = loadLevelImageNames(world, levelName)
  levelImageNames[imageName] = filename
end

return images
