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

navigation.gotoElementImage = function(levelName, elementType, filename)
  composer.gotoScene("scenes.element-image", {
    effect = defaultEffect,
    time = defaultTime,
    params = { elementType = elementType, levelName = levelName, filename = filename },
  })
end

navigation.gotoLevels = function()
  composer.gotoScene("scenes.levels", { effect = defaultEffect, time = defaultTime })
end

navigation.gotoGame = function(levelName)
  composer.gotoScene("scenes.game", {
    effect = defaultEffect,
    time = defaultTime,
    params = { levelName = levelName },
  })
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
