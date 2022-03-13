local composer = require "composer"
local i18n = require "i18n"
local utils = require "utils"
local widget = require "widget"

local scene = composer.newScene()

local sounds = {
  starEmpty = audio.loadSound("sounds/star-empty.wav"),
  starFull = audio.loadSound("sounds/star-full.wav"),
}

function scene:create(event)
  local levelName = event.params.levelName
  local numberOfShots = event.params.numberOfShots

  local background = display.newRect(
    self.view,
    display.screenOriginX,
    display.screenOriginY,
    display.actualContentWidth,
    display.actualContentHeight
  )

  background.anchorX = 0
  background.anchorY = 0
  background:setFillColor(0.0)

  display.newText({
    align = "center",
    font = native.systemFontBold,
    fontSize = 25,
    parent = self.view,
    text = i18n("finished_in", numberOfShots),
    x = display.contentCenterX,
    y = display.contentCenterY / 2,
  })

  local function retry()
    composer.gotoScene("scenes.game", {
      effect = "crossFade",
      time = 500,
      params = { levelName = levelName }
    })
    return true
  end

  local retryButton = widget.newButton({
    label = i18n("retry"),
    labelColor = { default = { 1.0 }, over = { 0.5 } },
    defaultFile = "images/button.png",
    overFile = "images/button-over.png",
    width = 154, height = 40,
    onRelease = retry
  })

  retryButton.x = display.contentCenterX
  retryButton.y = display.contentCenterY + display.contentCenterY / 2
  self.view:insert(retryButton)
end


playAudio = function(sound, volume)
  local freeChannel = audio.findFreeChannel()
  audio.setVolume(volume or sound.volume, { channel = freeChannel })
  audio.play(sound.handle, { channel = freeChannel })
end

function scene:show(event)
  if event.phase == "did" then
    local numberOfStars = event.params.numberOfStars

    local function displayStars(event)
      local isFullStar = numberOfStars >= event.count

      local star = display.newGroup()
      self.view:insert(star)

      local starImage = "images/star-" .. (isFullStar and "full" or "empty") .. ".png"
      local starDrawing = display.newImageRect(star, "images/star-outline.png", 75, 75)
      local starOutline = display.newImageRect(star, starImage, 75, 75)

      star.x = display.contentCenterX + (event.count - 2) * 90
      star.y = display.contentCenterY

      utils.playAudio(isFullStar and sounds.starFull or sounds.starEmpty, 1.0)
    end

    timer.performWithDelay(1000, displayStars, 3, "displayStars")
  end
end

function scene:hide(event)
  if event.phase == "did" then
    audio.stop()
    timer.cancel("displayStars")
    composer.removeScene("scenes.game-over")
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
