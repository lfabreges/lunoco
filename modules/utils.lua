local json = require "json"
local lfs = require "lfs"

local utils = {}

local environment = system.getInfo("environment")
local platform = system.getInfo("platform")

utils.fileExists = function(filename, baseDirectory)
  local filepath = system.pathForFile(filename, baseDirectory)
  return os.rename(filepath, filepath) and true or false
end

utils.isAndroid = function()
  return platform == "android"
end

utils.isSimulator = function()
  return environment == "simulator"
end

utils.loadLevelConfig = function(worldName, levelName)
  return utils.loadJson("worlds/" .. worldName .. "/" .. levelName .. ".json")
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
    file:write(json.prettify(content))
    io.close(file)
  end
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

return utils
