local composer = require "composer"
local lfs = require "lfs"
local utils = require "modules.utils"

math.randomseed(os.time())

display.setStatusBar(display.HiddenStatusBar)
native.setProperty("androidSystemUiVisibility", "immersiveSticky")
native.setProperty("preferredScreenEdgesDeferringSystemGestures", true)

local version = utils.loadJson("version.json", system.DocumentsDirectory)

if version.number == nil then
  utils.saveScores({ ["001"] = utils.loadScores() })

  local firstWorldTemporaryPath = system.pathForFile("_001", system.DocumentsDirectory)
  lfs.mkdir(firstWorldTemporaryPath)

  for levelNumber = 1, 10 do
    local levelName = string.format("%03d", levelNumber)
    if utils.fileExists(levelName, system.DocumentsDirectory) then
      local oldFilePath = system.pathForFile(levelName, system.DocumentsDirectory)
      local newFilePath = system.pathForFile("_001" .. "/" .. levelName, system.DocumentsDirectory)
      os.rename(oldFilePath, newFilePath)
    end
  end

  local firstWorldPath = system.pathForFile("001", system.DocumentsDirectory)
  os.rename(firstWorldTemporaryPath, firstWorldPath)

  version.number = 2
  utils.saveJson(version, "version.json", system.DocumentsDirectory)
end

composer.gotoScene("scenes.worlds")

if utils.isSimulator() then
  timer.performWithDelay(5000, utils.printMemoryUsage, -1)
end
