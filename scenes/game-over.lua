local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local navigation = require "modules.navigation"
local utils = require "modules.utils"

local finishedInText = nil
local level = nil
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
  local star = components.newStar(stars, 75, 75)
  star.x = display.contentCenterX + (event.count - 2) * 90
  star.y = display.contentCenterY
  star.fill.effect = not isFullStar and "filter.grayscale" or nil
  utils.playAudio(isFullStar and sounds.starFull or sounds.starEmpty, 1.0)
end

local function gotoLevels()
  navigation.gotoLevels(level.world)
end

local function retryLevel()
  navigation.reloadGame(level)
end

function scene:create(event)
  local background = components.newBackground(self.view)
  background:setFillColor(0, 0, 0, 0.9)

  finishedInText = display.newText({
    align = "center",
    text = "",
    fontSize = 25,
    parent = self.view,
    x = display.contentCenterX,
    y = display.contentCenterY / 2,
  })

  local retryButton = components.newTextButton(self.view, i18n.t("retry"), 120, 40, { onRelease = retryLevel })
  retryButton.x = display.contentCenterX - 70
  retryButton.y = display.contentCenterY + display.contentCenterY / 2

  local levelsButton = components.newTextButton(self.view, i18n.t("levels"), 120, 40, { onRelease = gotoLevels })
  levelsButton.x = display.contentCenterX + 70
  levelsButton.y = display.contentCenterY + display.contentCenterY / 2
end

function scene:show(event)
  if event.phase == "will" then
    level = event.params.level
    numberOfShots = event.params.numberOfShots
    numberOfStars = event.params.numberOfStars
    finishedInText.text = i18n.p("finished_in", numberOfShots)
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
    transition.cancel()
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
