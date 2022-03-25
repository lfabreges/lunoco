local components = require "components"
local composer = require "composer"
local i18n = require "i18n"
local navigation = require "navigation"

local scene = composer.newScene()

local levelName = nil
local shouldResumeGame = false

local function gotoCustomizeLevel()
  navigation.gotoCustomizeLevel(levelName)
  return true
end

local function gotoLevels()
  navigation.gotoLevels()
  return true
end

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

  local resumeButton = components.newButton(self.view, { label = i18n("resume"), onRelease = resumeGame })
  resumeButton.x = display.contentCenterX
  resumeButton.y = display.contentCenterY - 90

  local retryButton = components.newButton(self.view, { label = i18n("retry"), onRelease = retryLevel })
  retryButton.x = display.contentCenterX
  retryButton.y = display.contentCenterY - 30

  local levelsButton = components.newButton(self.view, { label = i18n("levels"), onRelease = gotoLevels })
  levelsButton.x = display.contentCenterX
  levelsButton.y = display.contentCenterY + 30

  local customizeButton = components.newButton(self.view, { label = i18n("customize"), onRelease = gotoCustomizeLevel })
  customizeButton.x = display.contentCenterX
  customizeButton.y = display.contentCenterY + 90
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
