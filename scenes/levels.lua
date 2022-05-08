local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local layouts = require "modules.layouts"
local navigation = require "modules.navigation"
local utils = require "modules.utils"

local scene = composer.newScene()
local world = nil

local function goBack()
  navigation.gotoWorlds()
end

local function startLevel(level)
  navigation.gotoGame(level)
end

local function startSpeedrun()
  local levels = world:levels()
  if levels[1] then
    navigation.gotoGame(levels[1], "speedrun")
  end
end

function scene:create(event)
  components.newBackground(self.view)

  self.topBar = components.newTopBar(self.view, { goBack = goBack })
  self.progressText = display.newText({ text = "", fontSize = 20 })
  self.topBar:insertRight(self.progressText)

  self.tabs = layouts.newTabs({ parent = self.view })
  local tabBar = components.newTabBar(self.view, self.tabs, { "menu", "speedrun" })

  self.separator = (display.actualContentWidth - 240) / 3

  self.menuScrollView = components.newScrollView(self.tabs, {
    top = self.topBar.contentBounds.yMax,
    height = tabBar.contentBounds.yMin - self.topBar.contentBounds.yMax,
    topPadding = self.separator,
    bottomPadding = self.separator,
  })

  self.tabs:addEventListener("select", function(event)
    if event.index == 1 and event.index == event.previous then
      self.menuScrollView:scrollTo("top", { time = event.time })
    end
  end)
end

function scene:createMenuView()
  self.menuView = layouts.newGrid({ parent = self.menuScrollView, separator = self.separator })

  local levels = world:levels()
  local scores = world:scores()

  for _, level in ipairs(levels) do
    local levelStack = layouts.newStack({ align = "center", parent = self.menuView, separator = 10 })
    local levelImageName, levelImageBaseDir = level:screenshotImage()

    local levelButton = components.newImageButton(
      levelStack,
      levelImageName,
      levelImageBaseDir,
      120,
      180,
      { onRelease = function() startLevel(level) end, scrollView = self.menuScrollView }
    )

    if scores[level.name] then
      components.newScore(levelStack, 20, scores[level.name].numberOfStars)
    else
      local filler = display.newRect(0, 0, 1, 20)
      filler.isVisible = false
      levelStack:insert(filler)
    end
  end

  if not world.isBuiltIn then
    components.newPlusButton(self.menuView, 120, 180, {
      onRelease = function() navigation.gotoLevelEditor(world:newLevel()) end,
      scrollView = self.menuScrollView,
    })
  end

  layouts.alignHorizontal(self.menuView, "center", self.menuScrollView)
end

function scene:createSpeedrunView()
  self.speedrunView = layouts.newStack({ separator = 15 })

  local speedruns = world:speedruns()
  local width = display.actualContentWidth - self.separator * 2
  local texts = {}

  for index = 0, 3 do
    if speedruns[tostring(index)] then
      local speedrun = speedruns[tostring(index)]
      local minutes, seconds, milliseconds = utils.splitTime(speedrun.runTime)
      texts[index] = display.newText({ text = i18n.t("time", minutes, seconds, milliseconds), fontSize = 14 })
    else
      texts[index] = display.newText({ text = i18n.t("no-time"), fontSize = 14 })
    end
  end

  components.newSpeedrunBoard(self.speedrunView, width, texts)
  components.newTextButton(self.speedrunView, i18n.t("start-speedrun"), width, 40, { onRelease = startSpeedrun })

  layouts.alignHorizontal(self.speedrunView, "center")
  self.speedrunView.y = self.topBar.contentBounds.yMax + self.separator
  self.tabs:insert(self.speedrunView)
end

function scene:show(event)
  if event.phase == "will" then
    world = event.params.world

    local progress = world:progress()
    self.progressText.text = i18n.t("progress", progress)

    self:createMenuView()
    self:createSpeedrunView()

    if composer.getSceneName("previous") == "scenes.worlds" then
      self.tabs:select(1, { time = 0 })
      self.menuScrollView:scrollTo("top", { time = 0 })
    end
  end
end

function scene:hide(event)
  if event.phase == "did" then
    transition.cancelAll()
    display.remove(self.menuView)
    display.remove(self.speedrunView)
    self.menuView = nil
    self.speedrunView = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
