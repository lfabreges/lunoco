local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local layouts = require "modules.layouts"
local navigation = require "modules.navigation"

local data = nil
local level = nil
local mode = nil
local scene = composer.newScene()
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

local function newButton(parent, text, iconName, onRelease)
  return components.newTextButton(parent, i18n.t(text), iconName, 240, 40, { onRelease = onRelease })
end

local function resumeGame()
  shouldResumeGame = true
  composer.hideOverlay()
end

local function retryLevel()
  navigation.reloadGame(level, mode, data)
end

function scene:create(event)
  level = event.params.level
  mode = event.params.mode
  data = event.params.data

  local isLevelBuiltIn = level.world.isBuiltIn

  local resumeBackground = components.newBackground(self.view)
  resumeBackground.height = display.actualContentHeight * 0.33
  resumeBackground:setFillColor(1, 1, 1, 0.9)

  local resumeButtonVortex = layouts.newVortex({ parent = self.view })
  components.newHitTestableSurface(resumeButtonVortex, resumeBackground)
  local resumeButtonImage = display.newImageRect("images/icons/resume.png", 40, 40)
  resumeButtonVortex:insert(resumeButtonImage)
  components.newObjectButton(resumeButtonVortex, { onRelease = resumeGame })
  layouts.align(resumeButtonVortex, "center", "center", resumeBackground)

  local remainingBackground = components.newBackground(self.view)
  remainingBackground.y = display.screenOriginY + resumeBackground.height
  remainingBackground.height = display.actualContentHeight - resumeBackground.height
  remainingBackground:setFillColor(0, 0, 0, 0.9)

  local stackElements = {}

  if mode == "speedrun" then
    stackElements[#stackElements + 1] = components.newRunTimeText(self.view, data.stopwatch:totalTime())
  end

  local actionStack = layouts.newStack({ separator = 10 })
  stackElements[#stackElements + 1] = actionStack

  newButton(actionStack, "retry", "reload", retryLevel)

  if mode == "classic" then
    newButton(actionStack, "menu", "menu", gotoLevels)
    newButton(actionStack, "customize", "customize", customizeLevel)
    if not isLevelBuiltIn then
      newButton(actionStack, "edit", "edit", editLevel)
    end
  elseif mode == "speedrun" then
    newButton(actionStack, "abort", "cancel", gotoLevels)
  end

  local contentHeight = 0

  for _, stackElement in pairs(stackElements) do
    contentHeight = contentHeight + stackElement.contentHeight
  end

  local stageRemainingHeight = display.getCurrentStage().contentBounds.yMax - remainingBackground.contentBounds.yMin
  local separator = (stageRemainingHeight - contentHeight) / (#stackElements + 1)
  local stack = layouts.newStack({ align = "center", parent = self.view, separator = separator })

  for _, stackElement in ipairs(stackElements) do
    stack:insert(stackElement)
  end

  layouts.align(stack, "center", "center", remainingBackground)
  stack.y = stack.y - (remainingBackground.contentBounds.yMax - display.getCurrentStage().contentBounds.yMax) * 0.5
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
