local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local images = require "modules.images"
local navigation = require "modules.navigation"
local universe = require "universe"
local widget = require "widget"

local content = nil
local scene = composer.newScene()
local scrollview = nil

function scene:create(event)
  local topInset, leftInset, bottomInset, rightInset = display.getSafeAreaInsets()

  components.newBackground(self.view)

  scrollview = widget.newScrollView({
    left = display.screenOriginX,
    top = display.screenOriginY,
    width = display.actualContentWidth,
    height = display.actualContentHeight,
    hideBackground = true,
    hideScrollBar = true,
    horizontalScrollDisabled = true,
    topPadding = topInset + 50,
    bottomPadding = bottomInset + 40,
    leftPadding = leftInset,
    rightPadding = rightInset,
  })

  self.view:insert(scrollview)

  local titleGroup = components.newGroup(scrollview)

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
  titleGroup.x = display.actualContentWidth / 2 - titleGroup.contentWidth / 2
end

function scene:show(event)
  if event.phase == "will" then
    local y = 110
    local worlds = universe.worlds()

    content = components.newGroup(scrollview)

    for _, world in ipairs(worlds) do
      local worldLevelNames = world:levelNames()
      local worldProgress, worldNumberOfStars = world:progress()
      local worldButtonContainer = display.newContainer(content, 280, 105)

      for levelNumber = 1, 5 do
        -- TODO Pour traiter le cas où le niveau n'existe pas un peu mieux
        local levelName = worldLevelNames[levelNumber] or "unknown"
        local levelImageName = images.levelImageName(world, levelName, "screenshot")
        local levelImageBaseDir = system.DocumentsDirectory

        if not levelImageName then
          levelImageName = "images/level-unknown.png"
          levelImageBaseDir = system.ResourceDirectory
        end

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
      end

      local worldButton = components.newObjectButton(worldButtonContainer, {
        onRelease = function() navigation.gotoLevels(world) end,
        scrollview = scrollview,
      })
      worldButton.anchorChildren = false
      worldButton.anchorX = 0
      worldButton.anchorY = 0
      worldButton.x = scrollview.width * 0.5 - 140
      worldButton.y = y

      local worldProgressText = display.newText({
        text = i18n.t("progress", worldProgress),
        fontSize = 20,
        parent = content,
        x = scrollview.width * 0.5 - worldButton.contentWidth / 2,
        y = y + worldButton.height + 10,
      })
      worldProgressText.anchorX = 0
      worldProgressText.anchorY = 0

      if worldNumberOfStars > 0 then
        for starCount = 1, 3 do
          local isFullStar = worldNumberOfStars >= starCount
          local star = components.newStar(content, 20, 20)
          star.anchorX = 1
          star.anchorY = 0
          star.x = scrollview.width * 0.5 + worldButton.contentWidth / 2 + (starCount - 3) * 25
          star.y = worldProgressText.y
          star.fill.effect = not isFullStar and "filter.grayscale" or nil
        end
      end

      y = worldProgressText.y + worldProgressText.contentHeight + 30
    end

    local newWorldContainer = display.newContainer(content ,280, 105)
    newWorldContainer.anchorY = 0
    newWorldContainer.x = scrollview.width * 0.5
    newWorldContainer.y = y

    local newWorldBackground = display.newRoundedRect(newWorldContainer, 0, 0, 278, 103, 15)
    newWorldBackground.fill.effect = "generator.linearGradient"
    newWorldBackground.fill.effect.color1 = { 0.25, 0.25, 0.25, 0.75 }
    newWorldBackground.fill.effect.position1  = { 0, 0 }
    newWorldBackground.fill.effect.color2 = { 0.5, 0.5, 0.5, 0.25 }
    newWorldBackground.fill.effect.position2  = { 1, 1 }
    newWorldBackground.strokeWidth = 1
    newWorldBackground:setStrokeColor(0.5, 0.5, 0.5, 0.75)

    display.newImageRect(newWorldContainer, "images/icons/plus.png", 50, 50)

    components.newObjectButton(newWorldContainer, {
      onRelease = function()
        local world = universe.newWorld()
        navigation.gotoLevelEditor(world, "1")
      end,
      scrollview = scrollview,
    })
  end
end

function scene:hide(event)
  if event.phase == "did" then
    transition.cancel()
    display.remove(content)
    content = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene

