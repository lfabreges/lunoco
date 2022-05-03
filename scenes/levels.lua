local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local layouts = require "modules.layouts"
local navigation = require "modules.navigation"

local scene = composer.newScene()
local screenX = display.screenOriginX
local screenY = display.screenOriginY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight
local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()
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

  self.separator = (screenWidth - 240) / 3
  self.scrollViews = {}

  for index = 1, 2 do
    self.scrollViews[index] = components.newScrollView(self.tabs, {
      top = self.topBar.contentBounds.yMax,
      height = tabBar.contentBounds.yMin - self.topBar.contentBounds.yMax,
      topPadding = self.separator,
      bottomPadding = self.separator,
    })
  end

  self.tabs:addEventListener("select", function(event)
    if event.index == event.previous then
      self.scrollViews[event.index]:scrollTo("top", { time = event.time })
    end
  end)
end

function scene:createMenuView()
  self.menuView = layouts.newGrid({ parent = self.scrollViews[1], separator = self.separator })

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
      { onRelease = function() startLevel(level) end, scrollView = self.scrollViews[1] }
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
      scrollView = self.scrollViews[1],
    })
  end

  layouts.alignHorizontal(self.menuView, "center", self.scrollViews[1])
end

function scene:createSpeedrunView()
  self.scrollViews[2]:setIsLocked(true)
  self.speedrunView = layouts.newStack({ parent = self.scrollViews[2], separator = 15 })

  local speedruns = world:speedruns()
  local width = screenWidth - self.separator * 2

  local board = display.newGroup()
  local frame = components.newFrame(board, width, 0)
  local stack = layouts.newStack({ align = "center", parent = board, separator = 10 })

  for numberOfStars = 0, 3 do
    local group = display.newGroup()

    local score = components.newScore(group, 20, numberOfStars)
    layouts.alignHorizontal(score, "left", frame)
    score.x = score.x + 10

    local time = display.newText({ text = "00:12", fontSize = 14 })
    group:insert(time)
    layouts.alignHorizontal(time, "right", frame)
    time.x = time.x - 10
    layouts.alignVertical(time, "center", score)

    stack:insert(group)

    if numberOfStars < 3 then
      local separator = display.newLine(0, 0, frame.contentWidth - 20, 0)
      separator:setStrokeColor(0.5, 0.5, 0.5, 0.75)
      stack:insert(separator)
      separator.y = separator.y + (separator.contentHeight - separator.strokeWidth) * 0.5
    end
  end

  frame.path.height = stack.contentHeight + 20
  layouts.align(stack, "center", "center", frame)
  self.speedrunView:insert(board)

  components.newTextButton(self.speedrunView, i18n.t("start-speedrun"), "go", width, 40, {
    onRelease = startSpeedrun,
  })

  layouts.alignHorizontal(self.speedrunView, "center", self.scrollViews[2])
end

function scene:show(event)
  if event.phase == "will" then
    local isNewWorld = world and world ~= event.params.world
    world = event.params.world

    local progress = world:progress()
    self.progressText.text = i18n.t("progress", progress)

    self:createMenuView()
    self:createSpeedrunView()

    if isNewWorld then
      self.tabs:select(1, { time = 0 })
      self.scrollViews[1]:scrollTo("top", { time = 0 })
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
