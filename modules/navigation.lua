local composer = require "composer"

local navigation = {}

local defaultEffect = "crossFade"
local defaultTime = 500

navigation.gotoCustomizeLevel = function(level)
  composer.gotoScene("scenes.customize-level", {
    effect = defaultEffect,
    time = defaultTime,
    params = { level = level },
  })
end

navigation.gotoElementImage = function(level, elementType, filename)
  composer.gotoScene("scenes.element-image", {
    effect = defaultEffect,
    time = defaultTime,
    params = { level = level, elementType = elementType, filename = filename },
  })
end

navigation.gotoLevelEditor = function(level)
  composer.gotoScene("scenes.level-editor", {
    effect = defaultEffect,
    time = defaultTime,
    params = { level = level },
  })
end

navigation.gotoLevels = function(world)
  composer.gotoScene("scenes.levels", {
    effect = defaultEffect,
    time = defaultTime,
    params = { world = world },
  })
end

navigation.gotoGame = function(level)
  composer.gotoScene("scenes.game", {
    effect = defaultEffect,
    time = defaultTime,
    params = { level = level },
  })
end

navigation.gotoWorlds = function()
  composer.gotoScene("scenes.worlds", {
    effect = defaultEffect,
    time = defaultTime,
  })
end

navigation.reloadGame = function(level)
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
      nextParams = { level = level },
    }
  })
end

navigation.showGameOver = function(level, numberOfShots, numberOfStars)
  composer.showOverlay("scenes.game-over", {
    isModal = true,
    effect = defaultEffect,
    time = defaultTime,
    params = {
      level = level,
      numberOfShots = numberOfShots,
      numberOfStars = numberOfStars,
    },
  })
end

return navigation
