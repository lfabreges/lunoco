local composer = require "composer"

local navigation = {}

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
      effect = "crossFade",
      time = 500,
      nextParams = {
        levelName = levelName
      }
    }
  })
end

return navigation
