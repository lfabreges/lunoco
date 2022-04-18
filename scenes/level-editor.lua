local composer = require "composer"

local elements = nil
local level = nil
local scene = composer.newScene()

function scene:create(event)
  level = event.params.level
  elements = level:createElements(self.view)

  elements.ball.touch = function(ball, event)
    if event.phase == "began" then
      display.getCurrentStage():setFocus(ball)
      ball.isFocus = true
    elseif ball.isFocus then
      if event.phase == "moved" then
        ball.width = ball.width + 1
      elseif event.phase == "ended" or event.phase == "cancelled" then
        display.getCurrentStage():setFocus(nil)
        ball.isFocus = false
      end
    end
  end
end

function scene:show(event)
  if event.phase == "did" then
    elements.ball:addEventListener("touch")
  end
end

function scene:hide(event)
  if event.phase == "did" then
    composer.removeScene("scenes.level-editor")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
