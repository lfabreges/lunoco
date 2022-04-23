local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local navigation = require "modules.navigation"
local widget = require "widget"

local content = nil
local scene = composer.newScene()
local screenX = display.screenOriginX
local screenY = display.screenOriginY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight
local scrollview = nil
local world = nil
local worldProgressText = nil

local function goBack()
  navigation.gotoWorlds()
end

local function startLevel(level)
  navigation.gotoGame(level)
end

function scene:create(event)
  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  components.newBackground(self.view)

  local topBar = components.newTopBar(self.view)

  local goBackButton = components.newImageButton(self.view, "images/icons/back.png", 40, 40, { onRelease = goBack })
  goBackButton.anchorX = 0
  goBackButton.x = screenX + leftInset + 20
  goBackButton.y = screenY + topInset + 30

  worldProgressText = display.newText({
    text = "",
    fontSize = 20,
    parent = self.view,
    x = screenX + screenWidth - rightInset - 20,
    y = screenY + topInset + 30,
  })
  worldProgressText.anchorX = 1

  scrollview = widget.newScrollView({
    left = screenX,
    top = topBar.y + topBar.height,
    width = screenWidth,
    height = screenHeight - topBar.height,
    hideBackground = true,
    hideScrollBar = true,
    horizontalScrollDisabled = true,
    topPadding = topInset + 40,
    bottomPadding = bottomInset + 40,
    leftPadding = leftInset,
    rightPadding = rightInset,
  })

  self.view:insert(scrollview)
end

function scene:show(event)
  if event.phase == "will" then
    local isNewWorld = world and world ~= event.params.world
    world = event.params.world

    local centerX = scrollview.width * 0.5
    local isEven = false
    local spaceWidth = (screenWidth - 240) / 3
    local y = 0
    local worldLevels = world:levels()
    local worldProgress = world:progress()
    local worldScores = world:scores()

    content = components.newGroup(scrollview)
    worldProgressText.text = i18n.t("progress", worldProgress)

    for levelNumber, level in ipairs(worldLevels) do
      isEven = levelNumber % 2 == 0

      local levelImageName, levelImageBaseDir = level:image("screenshot", "images/level-unknown.png")

      local levelButton = components.newImageButton(
        content,
        levelImageName,
        levelImageBaseDir,
        120,
        180,
        { onRelease = function() startLevel(level) end, scrollview = scrollview }
      )

      levelButton.anchorY = 0
      levelButton.y = y
      levelButton.x = isEven and centerX + 60 + spaceWidth / 2 or centerX - 60 - spaceWidth / 2

      if worldScores[level.name] then
        local numberOfStars = worldScores[level.name].numberOfStars

        for starCount = 1, 3 do
          local isFullStar = numberOfStars >= starCount
          local star = components.newStar(content, 20, 20)
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

      local newLevelGroup = components.newGroup(content)
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
        scrollview = scrollview,
      })
    end

    if isNewWorld then
      scrollview:scrollTo("top", { time = 0 })
    end
  end
end

function scene:hide(event)
  if event.phase == "did" then
    transition.cancelAll()
    display.remove(content)
    content = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
