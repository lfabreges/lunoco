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

images.worldImageTexture = function(worldName)
  local texture = graphics.newTexture({ type = "canvas", width = 320, height = 120 })
  texture.anchorX = -0.5
  texture.anchorY = -0.5

  for levelNumber = 1, 5 do
    local levelName = string.format("%03d", levelNumber)
    local levelImageName = images.levelImageName(worldName, levelName, "screenshot")
    local levelImageBaseDir = system.DocumentsDirectory

    if not levelImageName then
      levelImageName = "images/level-unknown.png"
      levelImageBaseDir = system.ResourceDirectory
    end

    local levelImage = display.newImageRect(levelImageName, levelImageBaseDir, 80, 120)
    levelImage.anchorX = 0
    levelImage.anchorY = 0
    levelImage.x = (levelNumber - 1) * 60

    if levelNumber > 1 then
      levelImage.fill.effect = "filter.linearWipe"
      levelImage.fill.effect.direction = { -1, 0 }
      levelImage.fill.effect.smoothness = 0.75
      levelImage.fill.effect.progress = 0.5
    end

    texture:draw(levelImage)
  end

  texture:invalidate()
  return texture
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
