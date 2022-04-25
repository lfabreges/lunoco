local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local layouts = require "modules.layouts"
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

  local titleStack = layouts.newStack({
    align = "center",
    mode = "horizontal",
    parent = self.scrollView,
    separator = 20,
  })
  local gameIcon = display.newImageRect("images/icon.png", 60, 60)
  titleStack:insert(gameIcon)
  local gameTitle = display.newText({ text = i18n.t("title"), font = native.systemFontBold, fontSize = 40 })
  titleStack:insert(gameTitle)
  layouts.alignCenter(titleStack, self.scrollView)
end

function scene:createContentView()
  local worlds = universe:worlds()

  self.contentView = layouts.newStack({ parent = self.scrollView, separator = 30 })
  self.contentView.y = 110

  for _, world in ipairs(worlds) do
    local worldLevels = world:levels()
    local worldProgress, worldNumberOfStars = world:progress()
    local worldStack = layouts.newStack({ parent = self.contentView, separator = 10 })

    local worldButtonContainer = display.newContainer(280, 105)
    worldStack:insert(worldButtonContainer)
    worldButtonContainer.anchorChildren = false

    for levelNumber = 1, 5 do
      local level = worldLevels[levelNumber]
      local levelImage = nil
      if level then
        local levelImageName, levelImageBaseDir = level:screenshotImage()
        levelImage = display.newImageRect(worldButtonContainer, levelImageName, levelImageBaseDir, 70, 105)
      else
        levelImage = components.newEmptyShape(worldButtonContainer, 70, 105)
      end
      levelImage.anchorX = 0
      levelImage.anchorY = 0
      levelImage.x = (levelNumber - 1) * 52.5
      if levelNumber > 1 then
        local levelMask = graphics.newMask("images/level-mask.png")
        levelImage:setMask(levelMask)
        levelImage.isHitTestMasked = false
        levelImage.maskScaleX = levelImage.width / 274
        levelImage.maskScaleY = levelImage.height / 414
      end
    end

    components.newObjectButton(worldButtonContainer, {
      onRelease = function() navigation.gotoLevels(world) end,
      scrollView = self.scrollView,
    })

    local worldProgressGroup = components.newGroup(worldStack)

    local worldProgressText = display.newText({ text = i18n.t("progress", worldProgress), fontSize = 20 })
    worldProgressGroup:insert(worldProgressText)
    layouts.alignHorizontal(worldProgressText, "left", worldButtonContainer)

    if worldNumberOfStars > -1 then
      local worldScore = components.newScore(worldProgressGroup, 20, worldNumberOfStars)
      layouts.alignHorizontal(worldScore, "right", worldButtonContainer)
      layouts.alignVertical(worldScore, "center", worldProgressText)
    end
  end

  local newWorlButton = components.newPlusButton(self.contentView, 278, 103, {
    onRelease = function() navigation.gotoLevelEditor(universe:newWorld():newLevel()) end,
    scrollView = self.scrollView,
  })

  layouts.alignCenter(self.contentView, self.scrollView)
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

