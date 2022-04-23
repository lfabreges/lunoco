local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
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
  local centerX = self.scrollView.width * 0.5
  local isEven = false
  local spaceWidth = (screenWidth - 240) / 3
  local y = 0
  local worldLevels = world:levels()
  local worldProgress = world:progress()
  local worldScores = world:scores()

  self.contentView = components.newGroup(self.scrollView)
  self.worldProgressText.text = i18n.t("progress", worldProgress)

  for levelNumber, level in ipairs(worldLevels) do
    isEven = levelNumber % 2 == 0

    local levelImageName, levelImageBaseDir = level:image("screenshot", "images/level-unknown.png")

    local levelButton = components.newImageButton(
      self.contentView,
      levelImageName,
      levelImageBaseDir,
      120,
      180,
      { onRelease = function() startLevel(level) end, scrollView = self.scrollView }
    )
    levelButton.anchorY = 0
    levelButton.y = y
    levelButton.x = isEven and centerX + 60 + spaceWidth / 2 or centerX - 60 - spaceWidth / 2

    if worldScores[level.name] then
      local numberOfStars = worldScores[level.name].numberOfStars

      for starCount = 1, 3 do
        local isFullStar = numberOfStars >= starCount
        local star = components.newStar(self.contentView, 20, 20)
        star.anchorY = 0
        star.x = levelButton.x + (starCount - 2) * 25
        star.y = y + 190
        star.fill.effect = not isFullStar and "filter.grayscale" or nil
      end
    end

    if isEven then
      y = y + 240
    end
  end

  if not world.isBuiltIn then
    isEven = not isEven

    local newLevelGroup = components.newGroup(self.contentView)
    newLevelGroup.x = isEven and centerX + 60 + spaceWidth / 2 or centerX - 60 - spaceWidth / 2
    newLevelGroup.y = y + 90

    local newLevelBackground = display.newRoundedRect(newLevelGroup, 0, 0, 120, 180, 15)
    newLevelBackground.fill.effect = "generator.linearGradient"
    newLevelBackground.fill.effect.color1 = { 0.25, 0.25, 0.25, 0.75 }
    newLevelBackground.fill.effect.position1  = { 0, 0 }
    newLevelBackground.fill.effect.color2 = { 0.5, 0.5, 0.5, 0.25 }
    newLevelBackground.fill.effect.position2  = { 1, 1 }
    newLevelBackground.strokeWidth = 1
    newLevelBackground:setStrokeColor(0.5, 0.5, 0.5, 0.75)

    display.newImageRect(newLevelGroup, "images/icons/plus.png", 50, 50)

    components.newObjectButton(newLevelGroup, {
      onRelease = function()
        local level = world:newLevel()
        navigation.gotoLevelEditor(level)
      end,
      scrollView = self.scrollView,
    })
  end
end

function scene:show(event)
  if event.phase == "will" then
    local isNewWorld = world and world ~= event.params.world
    world = event.params.world

    if not self.contentView or isNewWorld then
      display.remove(self.contentView)
      self:createContentView()
      self.scrollView:scrollTo("top", { time = 0 })
    end
  end
end

function scene:hide(event)
  if event.phase == "did" then
    transition.cancelAll()
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
