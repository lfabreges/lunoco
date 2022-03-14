local components = require "components"
local composer = require "composer"
local i18n = require "i18n"
local navigation = require "navigation"
local widget = require "widget"

local scene = composer.newScene()

local levelName = nil
local shouldResumeGame = false

local function resumeGame()
  shouldResumeGame = true
  composer.hideOverlay()
  return true
end

local function retryLevel()
  navigation.reloadGame(levelName)
  return true
end

function scene:create(event)
  components.newOverlayBackground(self.view)

  local resumeButton = widget.newButton({
    label = i18n("resume"),
    labelColor = { default = { 1.0 }, over = { 0.5 } },
    defaultFile = "images/button.png",
    overFile = "images/button-over.png",
    width = 160, height = 40,
    onRelease = resumeGame
  })

  resumeButton.x = display.contentCenterX
  resumeButton.y = display.contentCenterY - 30
  self.view:insert(resumeButton)

  local retryButton = widget.newButton({
    label = i18n("retry"),
    labelColor = { default = { 1.0 }, over = { 0.5 } },
    defaultFile = "images/button.png",
    overFile = "images/button-over.png",
    width = 160, height = 40,
    onRelease = retryLevel
  })

  retryButton.x = display.contentCenterX
  retryButton.y = display.contentCenterY + 30
  self.view:insert(retryButton)
end

function scene:show(event)
  if event.phase == "will" then
    levelName = event.params.levelName
    shouldResumeGame = false
  end
end

function scene:hide(event)
  if event.phase == "will" then
    if shouldResumeGame then
      event.parent:resume()
    end
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
