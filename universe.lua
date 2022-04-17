local utils = require "modules.utils"

local universe = {}

local numberOfBuiltInWorlds = 2
local worldObject = {}
local worlds = nil

function worldObject:new(name, isBuiltIn)
  object = {
    baseDirectory = isBuiltIn and system.ResourceDirectory or system.DocumentsDirectory,
    category = isBuiltIn and "builtIn" or "user",
    isBuiltIn = isBuiltIn,
    name = name,
  }
  setmetatable(object, self)
  self.__index = self
  return object
end

function worldObject:levels()
  if self._levels == nil then
    local configuration = utils.loadJson("worlds/" .. self.name .. ".json", self.baseDirectory)
    self._levels = configuration.levels
  end
  return self._levels
end

universe.worlds = function()
  if worlds == nil then
    worlds = {}
    for worldNumber = 1, numberOfBuiltInWorlds do
      local worldName = string.format("%02d", worldNumber)
      worlds[worldNumber] = worldObject:new(worldName, true)
    end
  end
  return worlds
end

return universe
