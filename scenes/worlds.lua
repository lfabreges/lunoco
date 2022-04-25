local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local navigation = require "modules.navigation"
local universeClass = require "classes.universe"
local utils = require "modules.utils"

local scene = composer.newScene()
local screenX = display.screenOriginX
local screenY = display.screenOriginY
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight
local universe = universeClass:new(1)

function scene:create(event)
  components.newBackground(self.view)
  self.scrollView = components.newScrollView(self.view, { topPadding = 50, bottomPadding = 40 })

  local titleGroup = components.newGroup(self.scrollView)

  local gameIcon = display.newImageRect(titleGroup, "images/icon.png", 60, 60)
  gameIcon.anchorX = 0
  gameIcon.anchorY = 0

  local gameTitle = display.newText({
    text = i18n.t("title"),
    font = native.systemFontBold,
    fontSize = 40,
    parent = titleGroup,
    x = gameIcon.width + 20,
    y = gameIcon.height / 2,
  })
  gameTitle.anchorX = 0

  titleGroup.x = screenWidth / 2 - titleGroup.contentWidth / 2
end

function scene:createContentView()
  local centerX = self.scrollView.width * 0.5
  local y = 110
  local worlds = universe:worlds()

  self.contentView = components.newGroup(self.scrollView)

  for _, world in ipairs(worlds) do
    local worldLevels = world:levels()
    local worldProgress, worldNumberOfStars = world:progress()

    local worldButtonContainer = display.newContainer(self.contentView, 280, 105)
    worldButtonContainer.anchorChildren = false
    worldButtonContainer.anchorX = 0
    worldButtonContainer.anchorY = 0
    worldButtonContainer.x = centerX - 140
    worldButtonContainer.y = y

    for levelNumber = 1, 5 do
      local level = worldLevels[levelNumber]
      if level then
        local levelImageName, levelImageBaseDir = level:screenshotImage()
        local levelImage = display.newImageRect(worldButtonContainer, levelImageName, levelImageBaseDir, 70, 105)
        levelImage.anchorX = 0
        levelImage.anchorY = 0
        levelImage.x = (levelNumber - 1) * 52.5
        if levelNumber > 1 then
          levelImage.fill.effect = "filter.linearWipe"
          levelImage.fill.effect.direction = { -1, 0 }
          levelImage.fill.effect.smoothness = 0.75
          levelImage.fill.effect.progress = 0.5
        end
      else
        components.newHitTestableSurface(worldButtonContainer)
        break
      end
    end

    local worldButton = components.newObjectButton(worldButtonContainer, {
      onRelease = function() navigation.gotoLevels(world) end,
      scrollView = self.scrollView,
    })

    local worldProgressText = display.newText({
      text = i18n.t("progress", worldProgress),
      fontSize = 20,
      parent = self.contentView,
      x = centerX - worldButton.contentWidth * 0.5,
      y = y + worldButton.height + 10,
    })
    worldProgressText.anchorX = 0
    worldProgressText.anchorY = 0

    if worldNumberOfStars > 0 then
      for starCount = 1, 3 do
        local isFullStar = worldNumberOfStars >= starCount
        local star = components.newStar(self.contentView, 20, 20)
        star.anchorX = 1
        star.anchorY = 0
        star.x = centerX + worldButton.contentWidth * 0.5 + (starCount - 3) * 25
        star.y = worldProgressText.y
        star.fill.effect = not isFullStar and "filter.grayscale" or nil
      end
    end

    y = worldProgressText.y + worldProgressText.contentHeight + 30
  end

  local newWorlButton = components.newPlusButton(self.contentView, 278, 103, {
    onRelease = function() navigation.gotoLevelEditor(universe:newWorld():newLevel()) end,
    scrollView = self.scrollView,
  })
  newWorlButton.x = centerX
  newWorlButton.y = y + 52.5
end

function scene:show(event)
  if event.phase == "will" then
    self:createContentView()
  end
end

function scene:hide(event)
  if event.phase == "did" then
    transition.cancelAll()
    display.remove(self.contentView)
    self.contentView = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene

