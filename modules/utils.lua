local json = require "json"
local lfs = require "lfs"

local utils = {}

local environment = system.getInfo("environment")
local platform = system.getInfo("platform")

utils.activateMultitouch = function()
  if not utils.isSimulator() then
    system.activate("multitouch")
  end
end

utils.deactivateMultitouch = function()
  if not utils.isSimulator() then
    system.deactivate("multitouch")
  end
end

utils.fileExists = function(filename, baseDirectory)
  local filepath = system.pathForFile(filename, baseDirectory)
  return os.rename(filepath, filepath) and true or false
end

utils.isAndroid = function()
  return platform == "android"
end

utils.isEventWithinBounds = function(object, event)
  local bounds = object.contentBounds
  local x = event.x
  local y = event.y
	return bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
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

utils.makeDirectory = function(directoryName, baseDirectory)
  local baseDirectoryPath = system.pathForFile(nil, baseDirectory)
  lfs.chdir(baseDirectoryPath)
  for entryname in string.gmatch(directoryName, "([^/]+)") do
    lfs.mkdir(entryname)
    lfs.chdir(entryname)
  end
end


utils.nestedGet = function(object, ...)
  local numberOfArguments = select("#", ...)
  local nestedValue = object
  for index = 1, numberOfArguments do
    if type(nestedValue) ~= "table" then
      return nil
    end
    nestedValue = nestedValue[select(index, ...)]
  end
  return nestedValue
end

utils.nestedGetOrDefault = function(object, ...)
  local numberOfArguments = select("#", ...)
  local value = utils.nestedGet(object, unpack({ ... }, 1, numberOfArguments - 1))
  return value or select(numberOfArguments, ...)
end

utils.nestedGetOrSet = function(object, ...)
  local numberOfArguments = select("#", ...)
  local value = utils.nestedGet(object, unpack({ ... }, 1, numberOfArguments - 1))
  return value or utils.nestedSet(object, unpack({ ... }))
end

utils.nestedSet = function(object, ...)
  local numberOfArguments = select("#", ...)
  local nestedFieldName = select(numberOfArguments - 1, ...)
  local value = select(numberOfArguments, ...)
  local nestedObject = object
  for index = 1, numberOfArguments - 2 do
    local argument = select(index, ...)
    if nestedObject[argument] == nil then
      nestedObject[argument] = {}
    end
    nestedObject = nestedObject[argument]
  end
  nestedObject[nestedFieldName] = value
  return value
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

utils.removeFile = function(filename, baseDirectory)
  local filepath = system.pathForFile(filename, baseDirectory)
  local filemode = lfs.attributes(filepath, "mode")
  if filemode == "file" then
    os.remove(filepath)
  elseif filemode == "directory" then
    for entryname in lfs.dir(filepath) do
      if entryname ~= "." and entryname ~= ".." then
        utils.removeFile(filename .. "/" .. entryname, baseDirectory)
      end
    end
    os.remove(filepath)
  end
end

utils.saveJson = function(content, filename, baseDirectory)
  local filepath = system.pathForFile(filename, baseDirectory or system.ResourceDirectory)
  local file = io.open(filepath, "w")
  if file then
    file:write(json.prettify(content))
    io.close(file)
  end
end

return utils
