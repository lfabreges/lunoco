local components = require "components"
local composer = require "composer"
local i18n = require "i18n"
local lfs = require "lfs"
local navigation = require "navigation"
local utils = require "utils"
local widget = require "widget"

local content = nil
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

  local gameTitle = display.newText({
    align = "center",
    text = i18n("title"),
    font = native.systemFontBold,
    fontSize = 40,
    x = scrollview.width * 0.5,
    y = 20,
  })

  scrollview:insert(gameTitle)
end

function scene:show(event)
  if event.phase == "will" then
    local centerX = scrollview.width * 0.5
    local content = components.newGroup(scrollview)
    local scores = utils.loadScores()
    local y = 80

    for index, levelName in ipairs(levelNames) do
      local isEven = index % 2 == 0
      local levelImage = nil
      local levelImageName = "level." .. levelName .. ".png"

      if utils.fileExists(levelImageName, system.DocumentsDirectory) then
        levelImage = display.newImageRect(content, levelImageName, system.DocumentsDirectory, 120, 180)
      else
        levelImage = display.newImageRect(content, "images/level-unknown.png", 120, 180)
      end

      levelImage.anchorY = 0
      levelImage.y = y

      if isEven then
        levelImage.x = centerX + 60 + spaceWidth / 2
      else
        levelImage.x = centerX - 60 - spaceWidth / 2
      end

      local function onLevelButtonEvent(event)
        if event.phase == "ended" then
          startLevel(levelName)
        elseif event.phase == "moved" then
          if math.abs(event.y - event.yStart) > 5 then
            scrollview:takeFocus(event)
          end
        end
      end

      local levelButton = widget.newButton({
        shape = "rect",
        width = 120,
        height = 180,
        fillColor = { default = { 0, 0, 0, 0.01 }, over = { 0, 0, 0, 0.5 } },
        onEvent = onLevelButtonEvent,
      })

      levelButton.anchorY = 0
      levelButton.x = levelImage.x
      levelButton.y = levelImage.y
      content:insert(levelButton)

      if scores[levelName] then
        local numberOfStars = scores[levelName].numberOfStars

        for starCount = 1, 3 do
          local isFullStar = numberOfStars >= starCount
          local starImage = "images/star-" .. (isFullStar and "full" or "empty") .. ".png"
          local star = display.newImageRect(content, starImage, 20, 20)
          local starMask = graphics.newMask("images/star-mask.png")

          star.anchorY = 0
          star.x = levelImage.x + (starCount - 2) * 25
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
