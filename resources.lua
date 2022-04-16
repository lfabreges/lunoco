local utils = require "modules.utils"

local resources = {}

local numberOfWorlds = nil
local numberOfLevels = {
  ["001"] = 10,
  ["002"] = 1,
}

resources.numberOfLevels = function(worldName)
  return numberOfLevels[worldName] or 0
end

resources.numberOfWorlds = function()
  if numberOfWorlds == nil then
    numberOfWorlds = 0
    for _ in pairs(numberOfLevels) do
      numberOfWorlds = numberOfWorlds + 1
    end
  end
  return numberOfWorlds
end

resources.validateNumberOfLevels = function()
  local isValid = true

  if utils.isSimulator() then
    local worldsPath = system.pathForFile("worlds", system.ResourceDirectory)

    for worldName in lfs.dir(worldsPath) do
      if worldName:match("^%d+$") then
        local actualNumberOfLevels = 0
        local worldDirectoryPath = system.pathForFile("worlds/" .. worldName, system.ResourceDirectory)

        for filename in lfs.dir(worldDirectoryPath) do
          if filename:match("^%d+.json$") then
            actualNumberOfLevels = actualNumberOfLevels + 1
          end
        end

        if not numberOfLevels[worldName] or numberOfLevels[worldName] ~= actualNumberOfLevels then
          print("ERROR: Expected 'numberOfLevels[" .. worldName .. "] = " .. actualNumberOfLevels)
          isValid = false
        end
      end
    end
  end

  return isValid
end

return resources
