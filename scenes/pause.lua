local composer = require "composer"
local i18n = require "i18n"
local widget = require "widget"

local scene = composer.newScene()

function scene:create(event)
  local background = display.newRect(
    self.view,
    display.screenOriginX,
    display.screenOriginY,
    display.actualContentWidth,
    display.actualContentHeight
  )

  background.anchorX = 0
  background.anchorY = 0
  background.alpha = 0.8
  background:setFillColor(0.0)

  local function resume()
    composer.hideOverlay()
    return true
  end

  local resumeButton = widget.newButton({
    label = i18n("resume"),
    labelColor = { default = { 1.0 }, over = { 0.5 } },
    defaultFile = "images/button.png",
    overFile = "images/button-over.png",
    width = 160, height = 40,
    onRelease = resume
  })

  resumeButton.x = display.contentCenterX
  resumeButton.y = display.contentCenterY
  self.view:insert(resumeButton)
end

function scene:show(event)
  if event.phase == "did" then
  end
end

function scene:hide(event)
  if event.phase == "will" then
    event.parent:resume()
  end
end

function scene:destroy(event)
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
