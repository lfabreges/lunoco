local composer = require "composer"
local lfs = require "lfs"
local utils = require "modules.utils"

math.randomseed(os.time())

display.setStatusBar(display.HiddenStatusBar)
native.setProperty("androidSystemUiVisibility", "immersiveSticky")
native.setProperty("preferredScreenEdgesDeferringSystemGestures", true)

local version = utils.loadJson("version.json", system.DocumentsDirectory)

if version.number == nil then
  local oldScores = utils.loadJson("scores.json", system.DocumentsDirectory)
  local newScores = { ["builtIn"] = { ["01"] = {} } }
  for levelName, levelScore in pairs(oldScores) do
    if levelName:match("^%d+$") then
      local levelNumber = tonumber(levelName)
      newScores["builtIn"]["01"][string.format("%02d", levelNumber)] = levelScore
    end
  end
  utils.saveJson(newScores, "scores.json", system.DocumentsDirectory)

  utils.mkdir(system.DocumentsDirectory, "elements", "builtIn", "01")
  for levelNumber = 1, 10 do
    local levelName = string.format("%03d", levelNumber)
    if utils.fileExists(levelName, system.DocumentsDirectory) then
      local oldFilePath = system.pathForFile(levelName, system.DocumentsDirectory)
      local newFilePath = system.pathForFile(
        "elements/builtIn/01/" .. string.format("%02d", levelNumber),
        system.DocumentsDirectory
      )
      os.rename(oldFilePath, newFilePath)
    end
  end

  version.number = 2
  utils.saveJson(version, "version.json", system.DocumentsDirectory)
end

composer.gotoScene("scenes.worlds")

if utils.isSimulator() then
  timer.performWithDelay(5000, utils.printMemoryUsage, -1)
end
