local components = require "modules.components"
local composer = require "composer"
local images = require "modules.images"
local navigation = require "modules.navigation"
local resources = require "resources"
local score = require "modules.score"
local widget = require "widget"

local content = nil
local scene = composer.newScene()
local scrollview = nil
local worldName = nil

local function goBack()
  navigation.gotoWorlds()
end

local function startLevel(levelName)
  navigation.gotoGame(worldName, levelName)
end

function scene:create(event)
  local screenX = display.screenOriginX
  local screenY = display.screenOriginY
  local screenWidth = display.actualContentWidth
  local screenHeight = display.actualContentHeight
  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  components.newBackground(self.view)

  local topBar = display.newRect(self.view, screenX, screenY, screenWidth, topInset + 60)
  topBar.anchorX = 0
  topBar.anchorY = 0
  topBar:setFillColor(0, 0, 0, 0.33)

  local goBackButton = components.newImageButton(self.view, "images/icons/back.png", 40, 40, { onRelease = goBack })
  goBackButton.anchorX = 0
  goBackButton.anchorY = 0
  goBackButton.x = screenX + leftInset + 20
  goBackButton.y = screenY + topInset + 10

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
    worldName = event.params.worldName

    local centerX = scrollview.width * 0.5
    local spaceWidth = (display.actualContentWidth - 240) / 3
    local y = 0
    local worldScores = score.worldScores(worldName)

    content = components.newGroup(scrollview)

    for levelNumber = 1, resources.numberOfLevels(worldName) do
      local isEven = levelNumber % 2 == 0
      local levelName = string.format("%03d", levelNumber)
      local levelImage = nil
      local levelImageName = images.levelImageName(worldName, levelName, "screenshot")
      local levelImageBaseDir = system.DocumentsDirectory

      if not levelImageName then
        levelImageName = "images/level-unknown.png"
        levelImageBaseDir = system.ResourceDirectory
      end

      local levelButton = components.newImageButton(
        content,
        levelImageName,
        levelImageBaseDir,
        120,
        180,
        { onRelease = function() startLevel(levelName) end, scrollview = scrollview }
      )

      levelButton.anchorY = 0
      levelButton.y = y
      levelButton.x = isEven and centerX + 60 + spaceWidth / 2 or centerX - 60 - spaceWidth / 2

      if worldScores[levelName] then
        local numberOfStars = worldScores[levelName].numberOfStars

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

    scrollview:scrollTo("top", { time = 0 })
  end
end

function scene:hide(event)
  if event.phase == "did" then
    transition.cancel()
    display.remove(content)
    content = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
