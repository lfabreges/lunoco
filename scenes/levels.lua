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
  local screenX = display.screenOriginX
  local screenY = display.screenOriginY
  local screenWidth = display.actualContentWidth
  local screenHeight = display.actualContentHeight
  local spaceWidth = (display.actualContentWidth - 240) / 3

  local background = display.newRect(self.view, screenX, screenY, screenWidth, screenHeight)
  background.anchorX = 0
  background.anchorY = 0
  background:setFillColor(0.25)

  local scrollview = widget.newScrollView({
    left = display.safeScreenOriginX,
    top = display.safeScreenOriginY,
    width = display.safeActualContentWidth,
    height = display.safeActualContentHeight,
    hideBackground = true,
    hideScrollBar = true,
    topPadding = spaceWidth,
    bottomPadding = spaceWidth,
    leftPadding = 0,
    rightPadding = 0,
  })

  self.view:insert(scrollview)

  local levelNames = {}
  local levelsPath = system.pathForFile("levels", system.ResourceDirectory)

  for filename in lfs.dir(levelsPath) do
    local levelName = filename:match("^(.+)%.lua$")
    if levelName then
      table.insert(levelNames, levelName)
    end
  end

  table.sort(levelNames)

  local scores = utils.loadScores()
  local y = 0

  for index, levelName in ipairs(levelNames) do
    local group = display.newGroup()
    local isEven = math.fmod(index, 2) == 0
    local levelImage = display.newImageRect(group, "levels/" .. levelName .. ".png", 120, 180)

    levelImage.anchorY = 0
    levelImage.y = y

    if isEven then
      levelImage.x = display.contentCenterX + 60 + spaceWidth / 2
    else
      levelImage.x = display.contentCenterX - 60 - spaceWidth / 2
    end

    local levelButton = widget.newButton({
      shape = "rect",
      width = 120,
      height = 180,
      fillColor = { default = { 0, 0, 0, 0.01 }, over = { 0, 0, 0, 0.5 } },
      onRelease = function() startLevel(levelName) end
    })

    levelButton.anchorY = 0
    levelButton.x = levelImage.x
    levelButton.y = levelImage.y
    group:insert(levelButton)

    local numberOfStars = 0

    if scores[levelName] then
      numberOfStars = scores[levelName].numberOfStars
    end

    for starCount = 1, 3 do
      local isFullStar = numberOfStars >= starCount

      local star = components.newGroup(group)
      local starImage = "images/star-" .. (isFullStar and "full" or "empty") .. ".png"
      local starDrawing = display.newImageRect(star, "images/star-outline.png", 20, 20)
      local starOutline = display.newImageRect(star, starImage, 20, 20)

      star.anchorY = 0
      star.x = levelImage.x + (starCount - 2) * 25
      star.y = y + 180 + 20
    end

    scrollview:insert(group)

    if isEven then
      y = y + 220 + spaceWidth
    end
  end
end

function scene:hide(event)
  if event.phase == "did" then
    -- TODO Gérer proprement la mise à jour des étoiles plutôt que de tout supprimer
    composer.removeScene("scenes.levels")
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("hide", scene)

return scene
