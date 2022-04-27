local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local layouts = require "modules.layouts"
local navigation = require "modules.navigation"

local level = nil
local scene = composer.newScene()
local screenX = display.screenOriginX
local screenY = display.screenOriginY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight
local shouldResumeGame = false

local function customizeLevel()
  navigation.gotoCustomizeLevel(level)
end

local function editLevel()
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

  local resumeButtonVortex = layouts.newVortex({ parent = self.view })
  components.newHitTestableSurface(resumeButtonVortex, resumeBackground)
  local resumeButtonImage = display.newImageRect("images/icons/resume.png", 40, 40)
  resumeButtonVortex:insert(resumeButtonImage)
  components.newObjectButton(resumeButtonVortex, { onRelease = resumeGame })
  layouts.align(resumeButtonVortex, "center", "center", resumeBackground)

  local actionGroup = components.newGroup(self.view)

  local retryButton = components.newCircleButton(actionGroup, "images/icons/reload.png", 40, {
    onRelease = retryLevel
  })
  retryButton.x = -75

  local menuButton = components.newCircleButton(actionGroup, "images/icons/menu.png", 40, {
    onRelease = gotoLevels
  })
  menuButton.y = -75

  local customizeButton = components.newCircleButton(actionGroup, "images/icons/customize.png", 40, {
    onRelease = customizeLevel
  })
  customizeButton.x = 75

  if not isLevelBuiltIn then
    local editLevelButton = components.newCircleButton(actionGroup, "images/icons/edit.png", 40, {
      onRelease = editLevel
    })
    editLevelButton.y = 75
  end

  layouts.align(actionGroup, "center", "center", remainingBackground)
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
