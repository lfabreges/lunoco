local composer = require "composer"

local scene = composer.newScene()

function scene:show(event)
  if event.phase == "will" then
    self.view:insert(event.params.screenCapture)
  elseif event.phase == "did" then
    local params = event.params

    local function gotoScene()
      composer.gotoScene(params.nextScene, {
        effect = params.effect,
        time = params.time,
        params = params.nextParams,
      })
    end

    timer.performWithDelay(0, gotoScene)
  end
end

function scene:hide(event)
  if event.phase == "did" then
    composer.removeScene("scenes.cutscene")
  end
end

scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
