local composer = require "composer"
local game = require "modules.game"

local level = nil
local objects = nil
local scene = composer.newScene()

function scene:create(event)
  level = event.params.level
  objects = game.createLevel(self.view, level)
  physics.setGravity(0, 0)

  objects.ball.touch = function(ball, event)
    if event.phase == "began" then
      display.getCurrentStage():setFocus(ball)
      ball.isFocus = true
    elseif ball.isFocus then
      if event.phase == "moved" then
        -- ball:translate(0, -1)
      elseif event.phase == "ended" or event.phase == "cancelled" then
        display.getCurrentStage():setFocus(nil)
        ball.isFocus = false
      end
    end
  end
end

function scene:show(event)
  if event.phase == "did" then
    objects.ball:addEventListener("touch")
    physics.start()
  end
end

function scene:hide(event)
  if event.phase == "did" then
    physics.stop()
    composer.removeScene("scenes.level-editor")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
