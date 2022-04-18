local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local navigation = require "modules.navigation"

local scene = composer.newScene()

local level = nil
local shouldResumeGame = false

local function gotoCustomizeLevel()
  navigation.gotoCustomizeLevel(level)
end

local function gotoLevels()
  navigation.gotoLevels(level.world)
end

local function resumeGame()
  shouldResumeGame = true
  composer.hideOverlay()
end

local function retryLevel()
  navigation.reloadGame(level)
end

function scene:create(event)
  local screenY = display.screenOriginY
  local screenHeight = display.actualContentHeight

  local resumeBackground = components.newBackground(self.view)
  resumeBackground.height = screenHeight * 0.4
  resumeBackground:setFillColor(1, 1, 1, 0.9)

  local remainingBackground = components.newBackground(self.view)
  remainingBackground.y = screenY + screenHeight * 0.4
  remainingBackground.height = screenHeight * 0.6
  remainingBackground:setFillColor(0, 0, 0, 0.9)

  local resumeButtonGroup = components.newGroup(self.view)
  local resumeButtonImage = display.newImageRect(resumeButtonGroup, "images/icons/resume.png", 40, 40)
  local resumeButtonArea = display.newRect(resumeButtonGroup, 0, 0, resumeBackground.width, resumeBackground.height)
  resumeButtonArea.isVisible = false
  resumeButtonArea.isHitTestable = true
  local resumeButton = components.newObjectButton(resumeButtonGroup, { onRelease = resumeGame })
  resumeButton.x = display.contentCenterX
  resumeButton.y = screenY + screenHeight * 0.2

  local retryButton = components.newTextButton(self.view, i18n.t("retry"), 160, 40, { onRelease = retryLevel })
  retryButton.x = display.contentCenterX
  retryButton.y = screenY + screenHeight * 0.7 - 60

  local levelsButton = components.newTextButton(self.view, i18n.t("levels"), 160, 40, { onRelease = gotoLevels })
  levelsButton.x = display.contentCenterX
  levelsButton.y = screenY + screenHeight * 0.7

  local customizeButton = components.newTextButton(self.view, i18n.t("customize"), 160, 40, {
    onRelease = gotoCustomizeLevel,
  })
  customizeButton.x = display.contentCenterX
  customizeButton.y = screenY + screenHeight * 0.7 + 60
end

function scene:show(event)
  if event.phase == "will" then
    level = event.params.level
    shouldResumeGame = false
  end
end

function scene:hide(event)
  if event.phase == "will" then
    if shouldResumeGame then
      event.parent:resume()
    end
  elseif event.phase == "did" then
    transition.cancel()
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
