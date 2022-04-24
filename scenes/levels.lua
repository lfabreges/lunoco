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

function scene:create(event)
  components.newBackground(self.view)

  local topBar = components.newTopBar(self.view, { goBack = goBack })

  self.worldProgressText = display.newText({
    text = "",
    fontSize = 20,
    parent = self.view,
    x = screenX + screenWidth - rightInset - 20,
    y = screenY + topInset + 30,
  })
  self.worldProgressText.anchorX = 1

  self.scrollView = components.newScrollView(self.view, {
    top = topBar.contentBounds.yMax,
    height = screenHeight - topBar.contentHeight,
    topPadding = 40,
    bottomPadding = 40,
  })
end

function scene:createContentView()
  local worldLevels = world:levels()
  local worldProgress = world:progress()
  local worldScores = world:scores()

  self.contentView = layouts.newGrid({ parent = self.scrollView, separator = (screenWidth - 240) / 3 })
  self.worldProgressText.text = i18n.t("progress", worldProgress)

  for _, level in ipairs(worldLevels) do
    local levelStack = layouts.newStack({ align = "center", parent = self.contentView, separator = 10 })
    local levelImageName, levelImageBaseDir = level:screenshotImage()

    local levelButton = components.newImageButton(
      levelStack,
      levelImageName,
      levelImageBaseDir,
      120,
      180,
      { onRelease = function() startLevel(level) end, scrollView = self.scrollView }
    )

    if worldScores[level.name] then
      local numberOfStars = worldScores[level.name].numberOfStars
      local startStack = layouts.newStack({ mode = "horizontal", parent = levelStack, separator = 5 })
      for starCount = 1, 3 do
        local isFullStar = numberOfStars >= starCount
        local star = components.newStar(startStack, 20, 20)
        star.fill.effect = not isFullStar and "filter.grayscale" or nil
      end
    end
  end

  if not world.isBuiltIn then
    components.newPlusButton(self.contentView, 120, 180, {
      onRelease = function() navigation.gotoLevelEditor(world:newLevel()) end,
      scrollView = self.scrollView,
    })
  end

  layouts.center(self.contentView, self.scrollView)
end

function scene:show(event)
  if event.phase == "will" then
    local isNewWorld = world and world ~= event.params.world
    world = event.params.world
    self:createContentView()
    if isNewWorld then
      self.scrollView:scrollTo("top", { time = 0 })
    end
  end
end

function scene:hide(event)
  if event.phase == "did" then
    transition.cancelAll()
    display.remove(self.contentView)
    self.contentView = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
