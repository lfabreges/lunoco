local components = require "components"
local composer = require "composer"
local i18n = require "i18n"
local lfs = require "lfs"
local navigation = require "navigation"
local utils = require "utils"
local widget = require "widget"

local content = nil
local gameTitle = nil
local levelNames = {}
local numberOfLevels = 6
local scene = composer.newScene()
local scrollview = nil
local spaceWidth = (display.actualContentWidth - 240) / 3

if utils.isSimulator() then
  local levelsPath = system.pathForFile("levels", system.ResourceDirectory)
  local actualNumberOfLevels = 0

  for filename in lfs.dir(levelsPath) do
    if filename:match("^.+%.lua$") then
      actualNumberOfLevels = actualNumberOfLevels + 1
    end
  end

  assert(
    actualNumberOfLevels == numberOfLevels,
    "Expected 'numberOfLevels = " .. actualNumberOfLevels .. "' in scenes.levels"
  )
end

for levelNumber = 1, numberOfLevels do
  levelNames[levelNumber] = string.format("%03d", levelNumber)
end

local function startLevel(levelName)
  navigation.gotoGame(levelName)
end

function scene:create(event)
  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  components.newBackground(self.view)

  scrollview = widget.newScrollView({
    left = display.screenOriginX,
    top = display.screenOriginY,
    width = display.actualContentWidth,
    height = display.actualContentHeight,
    hideBackground = true,
    hideScrollBar = true,
    horizontalScrollDisabled = true,
    topPadding = topInset + spaceWidth,
    bottomPadding = bottomInset + spaceWidth,
    leftPadding = leftInset,
    rightPadding = rightInset,
  })

  self.view:insert(scrollview)

  gameTitle = display.newText({
    align = "center",
    text = i18n.t("title"),
    font = native.systemFontBold,
    fontSize = 40,
    x = scrollview.width * 0.5,
    y = 0,
  })

  gameTitle.anchorY = 0
  scrollview:insert(gameTitle)
end

function scene:show(event)
  if event.phase == "will" then
    local centerX = scrollview.width * 0.5
    local content = components.newGroup(scrollview)
    local scores = utils.loadScores()
    local y = gameTitle.contentHeight + spaceWidth

    for index, levelName in ipairs(levelNames) do
      local isEven = index % 2 == 0
      local levelImage = nil
      local levelImageName = utils.levelImageName(levelName, "screenshot")
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

      if scores[levelName] then
        local numberOfStars = scores[levelName].numberOfStars

        for starCount = 1, 3 do
          local isFullStar = numberOfStars >= starCount
          local starImage = "images/star-" .. (isFullStar and "full" or "empty") .. ".png"
          local star = display.newImageRect(content, starImage, 20, 20)
          local starMask = graphics.newMask("images/star-mask.png")

          star.anchorY = 0
          star.x = levelButton.x + (starCount - 2) * 25
          star.y = y + 190
          star:setMask(starMask)
          star.maskScaleX = star.width / 394
          star.maskScaleY = star.height / 394
        end
      end

      if isEven then
        y = y + 240
      end
    end
  end
end

function scene:hide(event)
  if event.phase == "did" then
    display.remove(content)
    content = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
