local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local layouts = require "modules.layouts"
local navigation = require "modules.navigation"
local utils = require "modules.utils"

local data = nil
local level = nil
local mode = nil
local scene = composer.newScene()

local sounds = {
  starEmpty = audio.loadSound("sounds/star-empty.wav"),
  starFull = audio.loadSound("sounds/star-full.wav"),
}

local function isLastLevel()
  local levels = level.world:levels()
  return levels[#levels].name == level.name
end

local function gotoLevels()
  navigation.gotoLevels(level.world)
end

local function gotoNextLevel()
  local levels = level.world:levels()
  local index = table.indexOf(levels, level) or 0
  navigation.reloadGame(levels[index + 1], mode, data)
end

local function retryLevel()
  navigation.reloadGame(level, mode, data)
end

function scene:create(event)
  level = event.params.level
  mode = event.params.mode
  data = event.params.data

  local background = components.newBackground(self.view)
  background:setFillColor(0, 0, 0, 0.9)

  local stack = layouts.newStack({ align = "center", parent = self.view, separator = 60 })

  if mode == "classic" then
    local finishedInText = display.newText({ text = i18n.p("finished_in", data.numberOfShots), fontSize = 30 })
    stack:insert(finishedInText)

    scene.score = components.newScore(stack, 75, data.numberOfStars)

    for starCount = 1, 3 do
      scene.score[starCount].alpha = 0
    end
  elseif mode == "speedrun" then
    -- TODO Afficher le tableau des temps
  end

  local actionStack = layouts.newStack({ parent = stack, separator = 10 })

  if mode == "speedrun" and not isLastLevel() then
    components.newTextButton(actionStack, i18n.t("next"), "next", 240, 40, { onRelease = gotoNextLevel })
  end

  components.newTextButton(actionStack, i18n.t("retry"), "reload", 240, 40, { onRelease = retryLevel })

  if mode == "classic" or isLastLevel() then
    components.newTextButton(actionStack, i18n.t("menu"), "menu", 240, 40, { onRelease = gotoLevels })
  elseif mode == "speedrun" then
    components.newTextButton(actionStack, i18n.t("abort"), "cancel", 240, 40, { onRelease = gotoLevels })
  end

  layouts.align(stack, "center", "center")
end

function scene:show(event)
  if event.phase == "did" then
    if mode == "classic" then
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
