local lfs = require "lfs"
local utils = require "modules.utils"
local worldClass = require "classes.world"

local universeClass = {}

function universeClass:new(numberOfBuiltInWorlds)
  local object = { numberOfBuiltInWorlds = numberOfBuiltInWorlds }
  setmetatable(object, self)
  self.__index = self
  return object
end

function universeClass:newWorld()
  local worlds = self:worlds()
  local newWorldNumber = 1

  for _, world in pairs(worlds) do
    if not world.isBuiltIn then
      local worldNumber = tonumber(world.name)
      if worldNumber >= newWorldNumber then
        newWorldNumber = worldNumber + 1
      end
    end
  end

  return worldClass:new(self, tostring(newWorldNumber), false)
end

function universeClass:saveWorld(world)
  if self._worlds and not table.indexOf(self._worlds, world) then
    self._worlds[#self._worlds + 1] = world
  end
end

function universeClass:worlds()
  if not self._worlds then
    self._worlds = {}

    for worldNumber = 1, self.numberOfBuiltInWorlds do
      local worldName = string.format("%02d", worldNumber)
      self._worlds[worldNumber] = worldClass:new(self, worldName, true)
    end

    if utils.fileExists("worlds/user", system.DocumentsDirectory) then
      local userWorldsDirectoryPath = system.pathForFile("worlds/user", system.DocumentsDirectory)
      for filename in lfs.dir(userWorldsDirectoryPath) do
        local worldName = filename:match("^(%d+)%.json$")
        if worldName then
          self._worlds[#self._worlds + 1] = worldClass:new(self, worldName, false)
        end
      end
    end
  end

  return self._worlds
end

return universeClass
