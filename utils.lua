local utils = {}

local environment = system.getInfo("environment")

utils.isSimulator = function()
  return environment == "simulator"
end

utils.playAudio = function(handle, volume)
  local freeChannel = audio.findFreeChannel()
  audio.setVolume(volume or 1.0, { channel = freeChannel })
  audio.play(handle, { channel = freeChannel })
end

return utils
