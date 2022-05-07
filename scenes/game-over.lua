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

local function newButton(parent, text, iconName, onRelease)
  return components.newTextButton(parent, i18n.t(text), iconName, 240, 40, { onRelease = onRelease })
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

  if mode == "classic" then
    self:createClassic()
  elseif mode == "speedrun" then
    self:createSpeedrun()
  end
end

function scene:createClassic()
  local finishedInText = display.newText({ text = i18n.p("finished_in", data.numberOfShots), fontSize = 30 })

  scene.score = components.newScore(self.view, 75, data.numberOfStars)
  for starCount = 1, 3 do
    scene.score[starCount].alpha = 0
  end

  local actionStack = layouts.newStack({ separator = 10 })
  newButton(actionStack, "retry", "reload", retryLevel)
  newButton(actionStack, "menu", "menu", gotoLevels)

  local contentHeight = finishedInText.contentHeight + scene.score.contentHeight + actionStack.contentHeight
  local separator = (display.contentHeight - contentHeight) / 4
  local stack = layouts.newStack({ align = "center", parent = self.view, separator = separator })
  stack:insert(finishedInText)
  stack:insert(scene.score)
  stack:insert(actionStack)
  layouts.align(stack, "center", "center", display.getCurrentStage())
end

function scene:createSpeedrun()
  local speedruns = level.world:speedruns()

  local runTime = data.stopwatch:totalTime()
  local runTimeText = components.newRunTimeText(self.view, runTime)

  local numberOfStars = 3
  local texts = {}

  for _, level in pairs(data.levels) do
    numberOfStars = math.min(numberOfStars, level.numberOfStars)
  end

  for index = 0, 3 do
    if numberOfStars < index then
      texts[index] = display.newImageRect("images/icons/cancel.png", 20, 20)
    else
      local referenceTime = utils.nestedGet(speedruns, tostring(index), "levels", level.name, "endTime")
      if referenceTime then
        local deltaTime = runTime - referenceTime
        local minutes, seconds, milliseconds = utils.splitTime(deltaTime)
        texts[index] = display.newText({
          text = (deltaTime < 0 and "-" or "+") .. i18n.t("time", minutes, seconds, milliseconds),
          fontSize = 14,
        })
        if deltaTime > 0 then
          texts[index]:setFillColor(1, 0.25, 0.25)
        elseif deltaTime < 0 then
          texts[index]:setFillColor(0.42, 0.74, 0.40)
        end
      else
        texts[index] = display.newImageRect("images/icons/accept.png", 20, 20)
      end
    end
  end

  local speedrunBoard = components.newSpeedrunBoard(self.view, 260, texts)
  local actionStack = layouts.newStack({ separator = 10 })

  if not isLastLevel() then
    newButton(actionStack, "next-level", "next", gotoNextLevel)
  end

  newButton(actionStack, "retry", "reload", retryLevel)

  if isLastLevel() then
    newButton(actionStack, "menu", "menu", gotoLevels)
  else
    newButton(actionStack, "abort", "cancel", gotoLevels)
  end

  local contentHeight = runTimeText.contentHeight + speedrunBoard.contentHeight + actionStack.contentHeight
  local separator = (display.contentHeight - contentHeight) / 4
  local stack = layouts.newStack({ align = "center", parent = self.view, separator = separator })
  stack:insert(runTimeText)
  stack:insert(speedrunBoard)
  stack:insert(actionStack)
  layouts.align(stack, "center", "center", display.getCurrentStage())
end

function scene:saveScore()
  if mode == "classic" then
    level:saveScore(data.numberOfShots, data.numberOfStars)
  elseif mode == "speedrun" then
    level:saveScore(data.levels[level.name].numberOfShots, data.levels[level.name].numberOfStars)
    if isLastLevel() then
      level.world:saveSpeedrun(data.stopwatch:totalTime(), data.levels)
    end
  end
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
    self:saveScore()
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
