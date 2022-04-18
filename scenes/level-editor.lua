local composer = require "composer"

local config = nil
local levelName = nil
local scene = composer.newScene()
local world = nil

function scene:create(event)
  world = event.params.world
  levelName = event.params.levelName
  config = world:levelConfiguration(levelName)
end

function scene:hide(event)
  if event.phase == "did" then
    composer.removeScene("scenes.level-editor")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("hide", scene)

return scene
