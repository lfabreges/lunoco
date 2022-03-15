local components = require "components"
local composer = require "composer"
local i18n = require "i18n"
local navigation = require "navigation"
local utils = require "utils"
local widget = require "widget"

local finishedInText = nil
local levelName = nil
local numberOfShots = nil
local numberOfStars = nil
local scene = composer.newScene()
local stars = nil

local sounds = {
  starEmpty = audio.loadSound("sounds/star-empty.wav"),
  starFull = audio.loadSound("sounds/star-full.wav"),
}

local function displayStars(event)
  local isFullStar = numberOfStars >= event.count

  local star = components.newGroup(stars)
  local starImage = "images/star-" .. (isFullStar and "full" or "empty") .. ".png"
  local starDrawing = display.newImageRect(star, "images/star-outline.png", 75, 75)
  local starOutline = display.newImageRect(star, starImage, 75, 75)

  star.x = display.contentCenterX + (event.count - 2) * 90
  star.y = display.contentCenterY

  utils.playAudio(isFullStar and sounds.starFull or sounds.starEmpty, 1.0)
end

local function gotoLevels()
  navigation.gotoLevels()
  return true
end

local function retryLevel()
  navigation.reloadGame(levelName)
  return true
end

function scene:create(event)
  components.newOverlayBackground(self.view)

  finishedInText = display.newText({
    align = "center",
    text = "",
    font = native.systemFontBold,
    fontSize = 25,
    parent = self.view,
    x = display.contentCenterX,
    y = display.contentCenterY / 2,
  })

  local retryButton = widget.newButton({
    label = i18n("retry"),
    labelColor = { default = { 1.0 }, over = { 0.5 } },
    defaultFile = "images/button.png",
    overFile = "images/button-over.png",
    width = 120, height = 40,
    onRelease = retryLevel
  })

  retryButton.x = display.contentCenterX - 70
  retryButton.y = display.contentCenterY + display.contentCenterY / 2
  self.view:insert(retryButton)

  local levelsButton = widget.newButton({
    label = i18n("levels"),
    labelColor = { default = { 1.0 }, over = { 0.5 } },
    defaultFile = "images/button.png",
    overFile = "images/button-over.png",
    width = 120, height = 40,
    onRelease = gotoLevels
  })

  levelsButton.x = display.contentCenterX + 70
  levelsButton.y = display.contentCenterY + display.contentCenterY / 2
  self.view:insert(levelsButton)
end

function scene:show(event)
  if event.phase == "will" then
    levelName = event.params.levelName
    numberOfShots = event.params.numberOfShots
    numberOfStars = event.params.numberOfStars
    finishedInText.text = i18n("finished_in", numberOfShots)
    stars = components.newGroup(self.view)
  elseif event.phase == "did" then
    timer.performWithDelay(500, displayStars, 3, "displayStars")
  end
end

function scene:hide(event)
  if event.phase == "will" then
    timer.cancel("displayStars")
    audio.stop()
  elseif event.phase == "did" then
    display.remove(stars)
    stars = nil
  end
end

function scene:destroy(event)
  for key, _ in pairs(sounds) do
    audio.dispose(sounds[key])
    sounds[key] = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
