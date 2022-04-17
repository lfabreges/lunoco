local utils = require "modules.utils"

local resources = {}

local worldNames = nil

local numberOfLevels = {
  ["001"] = 10,
  ["002"] = 1,
}

resources.numberOfLevels = function(worldName)
  if worldName == "user" then
    local userWorldNumberOfLevels = 0
    if utils.fileExists("user", system.DocumentsDirectory) then
      local userWorldPath = system.pathForFile("user", system.DocumentsDirectory)
      for filename in lfs.dir(userWorldPath) do
        if filename:match("^%d+.json$") then
          userWorldNumberOfLevels = userWorldNumberOfLevels + 1
        end
      end
    end
    return userWorldNumberOfLevels
  else
    return numberOfLevels[worldName] or 0
  end
end

resources.worldNames = function()
  if worldNames == nil then
    worldNames = {}
    local worldNumber = 1
    for _ in pairs(numberOfLevels) do
      worldNames[worldNumber] = string.format("%03d", worldNumber)
      worldNumber = worldNumber + 1
    end
    worldNames[worldNumber] = "user"
  end
  return worldNames
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
