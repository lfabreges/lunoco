local components = require "components"
local composer = require "composer"
local lfs = require "lfs"
local utils = require "utils"
local widget = require "widget"

local scene = composer.newScene()

local function startLevel(levelName)
  composer.gotoScene("scenes.game", {
    effect = "crossFade",
    time = 500,
    params = { levelName = levelName },
  })
  return true
end

function scene:create(event)
  local spaceWidth = (display.actualContentWidth - 240) / 3
  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  components.newBackground(self.view)

  local scrollview = widget.newScrollView({
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

  local levelNames = {}
  local numberOfLevels = 4

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
    table.insert(levelNames, string.format("%03d", levelNumber))
  end

  local centerX = scrollview.width * 0.5
  local scores = utils.loadScores()
  local y = 0

  for index, levelName in ipairs(levelNames) do
    local group = display.newGroup()
    local isEven = math.fmod(index, 2) == 0
    local levelImage = nil

    if utils.fileExists("level." .. levelName .. ".png", system.DocumentsDirectory) then
      levelImage = display.newImageRect(group, "level." .. levelName .. ".png", system.DocumentsDirectory, 120, 180)
    else
      levelImage = display.newImageRect(group, "images/level-unknown.png", 120, 180)
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
    group:insert(levelButton)

    if scores[levelName] then
      local numberOfStars = scores[levelName].numberOfStars

      for starCount = 1, 3 do
        local isFullStar = numberOfStars >= starCount

        local star = components.newGroup(group)
        local starImage = "images/star-" .. (isFullStar and "full" or "empty") .. ".png"
        local starDrawing = display.newImageRect(star, starImage, 20, 20)
        local starMask = graphics.newMask("images/star-mask.png")

        star.anchorY = 0
        star.x = levelImage.x + (starCount - 2) * 25
        star.y = y + 180 + 20

        starDrawing:setMask(starMask)
        starDrawing.maskScaleX = starDrawing.width / 394
        starDrawing.maskScaleY = starDrawing.height / 394
      end
    end

    scrollview:insert(group)

    if isEven then
      y = y + 240
    end
  end
end

function scene:hide(event)
  if event.phase == "did" then
    composer.removeScene("scenes.levels")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("hide", scene)

return scene
