local worldClass = require "classes.world"

local universe = {}

local numberOfBuiltInWorlds = 2
local worlds = nil

universe.worlds = function()
  if worlds == nil then
    worlds = {}
    for worldNumber = 1, numberOfBuiltInWorlds do
      local worldName = string.format("%02d", worldNumber)
      worlds[worldNumber] = worldClass:new(worldName, true)
    end
  end
  return worlds
end

return universe
