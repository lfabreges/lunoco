local composer = require "composer"

local config = nil
local level = nil
local scene = composer.newScene()

function scene:create(event)
  level = event.params.level
  config = level:configuration()
end

function scene:hide(event)
  if event.phase == "did" then
    composer.removeScene("scenes.level-editor")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("hide", scene)

return scene
