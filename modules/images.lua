local lfs = require "lfs"
local utils = require "modules.utils"

local images = {}
local levelImageNames = {}

local function loadLevelImageNames(worldName, levelName)
  if levelImageNames[worldName] then
    if levelImageNames[worldName][levelName] then
      return levelImageNames[worldName][levelName]
    else
      levelImageNames[worldName][levelName] = {}
    end
  else
    levelImageNames[worldName] = { [levelName] = {} }
  end

  local levelDirectoryName = worldName .. "/" .. levelName

  if utils.fileExists(levelDirectoryName, system.DocumentsDirectory) then
    local path = system.pathForFile(levelDirectoryName, system.DocumentsDirectory)
    for filename in lfs.dir(path) do
      local noCacheName, imageName = filename:match("^((.+)%.nocache%..+%.png)$")
      if noCacheName then
        levelImageNames[worldName][levelName][imageName] = levelDirectoryName .. "/" .. noCacheName
      end
    end
  end

  return levelImageNames[worldName][levelName]
end

images.levelImageName = function(worldName, levelName, imageName)
  local levelImageNames = loadLevelImageNames(worldName, levelName)
  return levelImageNames[imageName] and levelImageNames[imageName] or nil
end

images.worldImageName = function(worldName)
end

images.removeLevelImage = function(worldName, levelName, imageName)
  local levelImageName = images.levelImageName(worldName, levelName, imageName)
  if levelImageName then
    local levelImageNames = loadLevelImageNames(worldName, levelName)
    local filepath = system.pathForFile(levelImageName, system.DocumentsDirectory)
    os.remove(filepath)
    levelImageNames[imageName] = nil
  end
end

images.saveLevelImage = function(object, worldName, levelName, imageName)
  local levelImageNames = loadLevelImageNames(worldName, levelName)
  local levelDirectoryName = worldName .. "/" .. levelName
  local levelDirectoryPath = system.pathForFile(levelDirectoryName, system.DocumentsDirectory)
  lfs.mkdir(levelDirectoryPath)
  local filename = levelDirectoryName .. "/" .. imageName .. ".nocache." .. math.random() .. ".png"
  display.save(object, { filename = filename, captureOffscreenArea = true })
  images.removeLevelImage(worldName, levelName, imageName)
  levelImageNames[imageName] = filename
end

return images
