local composer = require "composer"

local navigation = {}

local defaultEffect = "crossFade"
local defaultTime = 500

navigation.gotoCustomizeLevel = function(world, levelName)
  composer.gotoScene("scenes.customize-level", {
    effect = defaultEffect,
    time = defaultTime,
    params = { world = world, levelName = levelName },
  })
end

navigation.gotoElementImage = function(world, levelName, elementType, filename)
  composer.gotoScene("scenes.element-image", {
    effect = defaultEffect,
    time = defaultTime,
    params = { world = world, levelName = levelName, elementType = elementType, filename = filename },
  })
end

navigation.gotoLevels = function(world)
  composer.gotoScene("scenes.levels", {
    effect = defaultEffect,
    time = defaultTime,
    params = { world = world },
  })
end

navigation.gotoGame = function(world, levelName)
  composer.gotoScene("scenes.game", {
    effect = defaultEffect,
    time = defaultTime,
    params = { world = world, levelName = levelName },
  })
end

navigation.gotoWorlds = function()
  composer.gotoScene("scenes.worlds", {
    effect = defaultEffect,
    time = defaultTime,
  })
end

navigation.reloadGame = function(world, levelName)
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
      nextParams = { world = world, levelName = levelName },
    }
  })
end

return navigation
