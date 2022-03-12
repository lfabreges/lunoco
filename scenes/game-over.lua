local composer = require "composer"
local utils = require "utils"

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
  background.alpha = 0.75
  background:setFillColor(0.0)
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
    timer.cancel("displayStars")
    composer.removeScene("game-over")
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
