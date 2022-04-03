local json = require "json"
local lfs = require "lfs"

local utils = {}

local environment = system.getInfo("environment")
local levelsImageNames = {}

local function loadLevelImageNames(levelName)
  if levelsImageNames[levelName] then
    return levelsImageNames[levelName]
  end
  levelsImageNames[levelName] = {}
  if utils.fileExists(levelName, system.DocumentsDirectory) then
    local path = system.pathForFile(levelName, system.DocumentsDirectory)
    for filename in lfs.dir(path) do
      local noCacheName, imageName = filename:match("^((.+)%.nocache%..+%.png)$")
      if noCacheName then
        levelsImageNames[levelName][imageName] = noCacheName
      end
    end
  end
  return levelsImageNames[levelName]
end

utils.fileExists = function(filename, baseDirectory)
  local filepath = system.pathForFile(filename, baseDirectory)
  return os.rename(filepath, filepath) and true or false
end

utils.isSimulator = function()
  return environment == "simulator"
end

utils.loadJson = function(filename, baseDirectory)
  local filepath = system.pathForFile(filename, baseDirectory or system.ResourceDirectory)
  if filepath then
    local content = json.decodeFile(filepath)
    if content then
      return content
    end
  end
  return {}
end

utils.saveJson = function(content, filename, baseDirectory)
  local filepath = system.pathForFile(filename, baseDirectory or system.ResourceDirectory)
  local file = io.open(filepath, "w")
  if file then
    file:write(json.encode(content))
    io.close(file)
  end
end

utils.loadScores = function()
  return utils.loadJson("scores.json", system.DocumentsDirectory)
end

utils.saveScores = function(scores)
  utils.saveJson(scores, "scores.json", system.DocumentsDirectory)
end

utils.playAudio = function(handle, volume)
  local freeChannel = audio.findFreeChannel()
  audio.setVolume(volume or 1.0, { channel = freeChannel })
  audio.play(handle, { channel = freeChannel })
end

utils.printMemoryUsage = function()
  local systemMemoryUsed = collectgarbage("count") / 1000
  local textureMemoryUsed = system.getInfo("textureMemoryUsed") / 1000000
  print("System", "Memory Used:", string.format("%.03f", systemMemoryUsed), "Mb")
  print("Texture", "Memory Used:", string.format("%.03f", textureMemoryUsed), "Mb")
end

utils.levelImageName = function(levelName, imageName)
  local levelImageNames = loadLevelImageNames(levelName)
  local levelImageName = levelImageNames[imageName] and levelName .. "/" .. levelImageNames[imageName] or nil
  return levelImageName
end

utils.removeLevelImage = function(levelName, imageName)
  local levelImageName = utils.levelImageName(levelName, imageName)
  if levelImageName then
    local levelImageNames = loadLevelImageNames(levelName)
    local filepath = system.pathForFile(levelImageName, system.DocumentsDirectory)
    os.remove(filepath)
    levelImageNames[imageName] = nil
  end
end

utils.saveLevelImage = function(object, levelName, imageName)
  local levelImageNames = loadLevelImageNames(levelName)
  local filename = imageName .. ".nocache." .. math.random() .. ".png"
  local levelDirectory = system.pathForFile(levelName, system.DocumentsDirectory)
  lfs.mkdir(levelDirectory)
  display.save(object, { filename = levelName .. "/" .. filename, captureOffscreenArea = true })
  utils.removeLevelImage(levelName, imageName)
  levelImageNames[imageName] = filename
end

return utils
