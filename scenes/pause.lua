local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local navigation = require "modules.navigation"

local level = nil
local scene = composer.newScene()
local screenX = display.screenOriginX
local screenY = display.screenOriginY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight
local shouldResumeGame = false

local function gotoCustomizeLevel()
  navigation.gotoCustomizeLevel(level)
end

local function gotoLevelEditor()
  navigation.gotoLevelEditor(level)
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
  level = event.params.level
  shouldResumeGame = false

  local isLevelBuiltIn = level.world.isBuiltIn

  local resumeBackground = components.newBackground(self.view)
  resumeBackground.height = screenHeight * 0.33
  resumeBackground:setFillColor(1, 1, 1, 0.9)

  local remainingBackground = components.newBackground(self.view)
  remainingBackground.y = screenY + resumeBackground.height
  remainingBackground.height = screenHeight - resumeBackground.height
  remainingBackground:setFillColor(0, 0, 0, 0.9)

  local resumeButtonGroup = components.newGroup(self.view)
  local resumeButtonImage = display.newImageRect(resumeButtonGroup, "images/icons/resume.png", 40, 40)
  local resumeButtonArea = display.newRect(resumeButtonGroup, 0, 0, resumeBackground.width, resumeBackground.height)
  resumeButtonArea.isVisible = false
  resumeButtonArea.isHitTestable = true
  local resumeButton = components.newObjectButton(resumeButtonGroup, { onRelease = resumeGame })
  resumeButton.x = display.contentCenterX
  resumeButton.y = screenY + resumeBackground.height * 0.5

  local retryButton = components.newTextButton(
    self.view,
    i18n.t("retry"),
    160,
    40,
    { onRelease = retryLevel }
  )
  retryButton.x = display.contentCenterX
  retryButton.y = remainingBackground.y + remainingBackground.height * 0.5 - (isLevelBuiltIn and 60 or 90)

  local levelsButton = components.newTextButton(
    self.view,
    i18n.t("levels"),
    160,
    40,
    { onRelease = gotoLevels }
  )
  levelsButton.x = display.contentCenterX
  levelsButton.y = retryButton.y + 60

  local customizeButton = components.newTextButton(
    self.view,
    i18n.t("customize"),
    160,
    40,
    { onRelease = gotoCustomizeLevel }
  )
  customizeButton.x = display.contentCenterX
  customizeButton.y = levelsButton.y + 60

  if not isLevelBuiltIn then
    local editButton = components.newTextButton(
      self.view,
      i18n.t("edit"),
      160,
      40,
      { onRelease = gotoLevelEditor }
    )
    editButton.x = display.contentCenterX
    editButton.y = customizeButton.y + 60
  end
end

function scene:hide(event)
  if event.phase == "will" then
    if shouldResumeGame then
      event.parent:resume()
    end
  elseif event.phase == "did" then
    transition.cancelAll()
    composer.removeScene("scenes.pause")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("hide", scene)

return scene
