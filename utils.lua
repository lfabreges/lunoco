local json = require "json"

local utils = {}

local environment = system.getInfo("environment")
local imagePaths = {}

utils.fileExists = function(filename, baseDirectory)
  baseDirectory = baseDirectory or system.ResourceDirectory
  local filepath = system.pathForFile(filename, baseDirectory)
  local file = io.open(filepath)
  if file then
    file:close()
    return true
  else
    return false
  end
end

utils.imagePath = function(imageName, imageBaseDir)
  imageBaseDir = imageBaseDir or system.DocumentsDirectory
  if imagePaths[imageBaseDir] then
    local basedirPaths = imagePaths[imageBaseDir]
    if basedirPaths[imageName] then
      local imagePath = basedirPaths[imageName]
      return imagePath.imageName, imagePath.imageBaseDir
    end
  end
  return imageName, imageBaseDir
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

utils.loadScores = function()
  return utils.loadJson("scores.json", system.DocumentsDirectory)
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

utils.saveImage = function(object, options)
  local imageName = options.filename
  local imageBaseDir = options.baseDir or system.DocumentsDirectory
  display.save(object, options)
  local noCacheImageName = "nocache." .. math.random() .. "." .. imageName
  options.filename = noCacheImageName
  options.baseDir = system.TemporaryDirectory
  display.save(object, options)
  imagePaths[imageBaseDir] = imagePaths[imageBaseDir] or {}
  imagePaths[imageBaseDir][imageName] = { imageName = options.filename, imageBaseDir = options.baseDir }
end

utils.saveJson = function(content, filename, baseDirectory)
  local filepath = system.pathForFile(filename, baseDirectory or system.ResourceDirectory)
  local file = io.open(filepath, "w")
  if file then
    file:write(json.encode(content))
    io.close(file)
  end
end

utils.saveScores = function(scores)
  utils.saveJson(scores, "scores.json", system.DocumentsDirectory)
end

return utils
