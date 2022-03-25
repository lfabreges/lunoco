local composer = require "composer"

local navigation = {}

local defaultEffect = "crossFade"
local defaultTime = 500

navigation.gotoCustomizeLevel = function(levelName)
  composer.gotoScene("scenes.customize-level", {
    effect = defaultEffect,
    time = defaultTime,
    params = { levelName = levelName },
  })
end

navigation.gotoLevels = function()
  composer.gotoScene("scenes.levels", { effect = defaultEffect, time = defaultTime })
end

navigation.reloadGame = function(levelName)
  composer.hideOverlay()

  local screenCapture = display.captureScreen()
  screenCapture.anchorX = 0
  screenCapture.anchorY = 0
  screenCapture.x = display.screenOriginX
  screenCapture.y = display.screenOriginY

  composer.gotoScene("scenes.cutscene", {
    params = {
      screenCapture = screenCapture,
      nextScene = "scenes.game",
      effect = defaultEffect,
      time = defaultTime,
      nextParams = {
        levelName = levelName
      }
    }
  })
end

return navigation
