local composer = require "composer"
local utils = require "utils"

display.setStatusBar(display.HiddenStatusBar)

composer.gotoScene("scenes.levels")

if utils.isSimulator() then
  timer.performWithDelay(5000, utils.printMemoryUsage, -1)
end
