local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local layouts = require "modules.layouts"
local navigation = require "modules.navigation"
local utils = require "modules.utils"

local level = nil
local numberOfShots = nil
local numberOfStars = nil
local scene = composer.newScene()

local sounds = {
  starEmpty = audio.loadSound("sounds/star-empty.wav"),
  starFull = audio.loadSound("sounds/star-full.wav"),
}

local function gotoLevels()
  navigation.gotoLevels(level.world)
end

local function retryLevel()
  navigation.reloadGame(level)
end

function scene:create(event)
  level = event.params.level
  numberOfShots = event.params.numberOfShots
  numberOfStars = event.params.numberOfStars

  local background = components.newBackground(self.view)
  background:setFillColor(0, 0, 0, 0.9)

  local stack = layouts.newStack({ align = "center", parent = self.view, separator = 60 })

  local finishedInText = display.newText({ text = i18n.p("finished_in", numberOfShots), fontSize = 30 })
  stack:insert(finishedInText)

  scene.score = components.newScore(stack, 75, numberOfStars)

  for starCount = 1, 3 do
    scene.score[starCount].alpha = 0
  end

  local actionStack = layouts.newStack({ mode = "horizontal", parent = stack, separator = 40 })
  components.newCircleButton(actionStack, "images/icons/reload.png", 40, { onRelease = retryLevel })
  components.newCircleButton(actionStack, "images/icons/menu.png", 40, { onRelease = gotoLevels })

  layouts.align(stack, "center", "center")
end

function scene:show(event)
  if event.phase == "did" then
    timer.performWithDelay(
      500,
      function(event)
        local star = scene.score[event.count]
        transition.to(scene.score[event.count], { alpha = 1, time = 100 })
        utils.playAudio(star.isFullStar and sounds.starFull or sounds.starEmpty, 1.0)
      end,
      3,
      "displayStars"
    )
  end
end

function scene:hide(event)
  if event.phase == "will" then
    timer.cancel("displayStars")
    audio.stop()
  elseif event.phase == "did" then
    transition.cancelAll()
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
