local composer = require "composer"
local multitouch = require "libraries.multitouch"
local utils = require "modules.utils"

local elements = nil
local level = nil
local scene = composer.newScene()

local function isWithinBounds(object, event)
  local bounds = object.contentBounds
  local x = event.x
  local y = event.y
	local isWithinBounds = true
	return bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
end

local function onMove(element, deltaX, deltaY)
  local elementBounds = element.contentBounds
  local levelBounds = elements.background.contentBounds
  deltaX = elementBounds.xMax + deltaX > levelBounds.xMax and levelBounds.xMax - elementBounds.xMax or deltaX
  deltaX = elementBounds.xMin + deltaX < levelBounds.xMin and levelBounds.xMin - elementBounds.xMin or deltaX
  deltaY = elementBounds.yMax + deltaY > levelBounds.yMax and levelBounds.yMax - elementBounds.yMax or deltaY
  deltaY = elementBounds.yMin + deltaY < levelBounds.yMin and levelBounds.yMin - elementBounds.yMin or deltaY
  element:translate(deltaX, deltaY)
end

function scene:create(event)
  level = event.params.level
  elements = level:createElements(self.view)

  multitouch.addMoveAndPinchListener(elements.ball, onMove)
end

function scene:show(event)
  if event.phase == "did" then
    if not utils.isSimulator() then
      system.activate("multitouch")
    end
  end
end

function scene:hide(event)
  if event.phase == "will" then
    if not utils.isSimulator() then
      system.deactivate("multitouch")
    end
  elseif event.phase == "did" then
    composer.removeScene("scenes.level-editor")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
