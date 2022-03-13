local json = require "json"

local utils = {}

local environment = system.getInfo("environment")

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
