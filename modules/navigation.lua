local composer = require "composer"

local navigation = {}

local defaultEffect = "crossFade"
local defaultTime = 500

navigation.gotoCustomizeLevel = function(worldName, levelName)
  composer.gotoScene("scenes.customize-level", {
    effect = defaultEffect,
    time = defaultTime,
    params = { worldName = worldName, levelName = levelName },
  })
end

navigation.gotoElementImage = function(worldName, levelName, elementType, filename)
  composer.gotoScene("scenes.element-image", {
    effect = defaultEffect,
    time = defaultTime,
    params = { worldName = worldName, levelName = levelName, elementType = elementType, filename = filename },
  })
end

navigation.gotoLevels = function(worldName)
  composer.gotoScene("scenes.levels", {
    effect = defaultEffect,
    time = defaultTime,
    params = { worldName = worldName },
  })
end

navigation.gotoGame = function(worldName, levelName)
  composer.gotoScene("scenes.game", {
    effect = defaultEffect,
    time = defaultTime,
    params = { worldName = worldName, levelName = levelName },
  })
end

navigation.gotoWorlds = function()
  composer.gotoScene("scenes.worlds", {
    effect = defaultEffect,
    time = defaultTime,
  })
end

navigation.reloadGame = function(worldName, levelName)
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
      nextParams = { worldName = worldName, levelName = levelName },
    }
  })
end

return navigation
