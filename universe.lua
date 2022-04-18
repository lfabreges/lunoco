local lfs = require "lfs"
local utils = require "modules.utils"
local worldClass = require "classes.world"

local universe = {}

local numberOfBuiltInWorlds = 2
local worlds = nil

universe.newWorld = function()
  local worlds = universe.worlds()
  local newWorldNumber = 1

  for _, world in pairs(worlds) do
    if not world.isBuiltIn then
      local worldNumber = tonumber(world.name)
      if worldNumber >= newWorldNumber then
        newWorldNumber = worldNumber + 1
      end
    end
  end

  return worldClass:new(tostring(newWorldNumber), false)
end

universe.worlds = function()
  if not worlds then
    worlds = {}

    for worldNumber = 1, numberOfBuiltInWorlds do
      local worldName = string.format("%02d", worldNumber)
      worlds[worldNumber] = worldClass:new(worldName, true)
    end

    if utils.fileExists("worlds", system.DocumentsDirectory) then
      local userWorldsDirectoryPath = system.pathForFile("worlds", system.DocumentsDirectory)
      for filename in lfs.dir(userWorldsDirectoryPath) do
        local worldName = filename:match("^(%d+)%.json$")
        if worldName then
          worlds[#worlds + 1] = worldClass:new(worldName, false)
        end
      end
    end
  end

  return worlds
end

return universe
