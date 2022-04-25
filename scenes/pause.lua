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

  local resumeButtonVortex = layouts.newVortex({ parent = self.view })
  components.newHitTestableSurface(resumeButtonVortex, resumeBackground)
  local resumeButtonImage = display.newImageRect("images/icons/resume.png", 40, 40)
  resumeButtonVortex:insert(resumeButtonImage)
  components.newObjectButton(resumeButtonVortex, { onRelease = resumeGame })
  layouts.align(resumeButtonVortex, "center", "center", resumeBackground)

  local actionStack = layouts.newStack({ parent = self.view, separator = 20 })

  components.newTextButton(actionStack, i18n.t("retry"), 160, 40, { onRelease = retryLevel })
  components.newTextButton(actionStack, i18n.t("levels"), 160, 40, { onRelease = gotoLevels })
  components.newTextButton(actionStack, i18n.t("customize"), 160, 40, { onRelease = gotoCustomizeLevel })

  if not isLevelBuiltIn then
    components.newTextButton(actionStack, i18n.t("edit-level"), 160, 40, { onRelease = gotoLevelEditor })
  end

  layouts.align(actionStack, "center", "center", remainingBackground)
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
