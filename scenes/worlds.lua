local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local images = require "modules.images"
local navigation = require "modules.navigation"
local resources = require "resources"
local score = require "modules.score"
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
    topPadding = topInset + 40,
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
    local y = 100

    content = components.newGroup(scrollview)

    for worldNumber = 1, resources.numberOfWorlds() do
      local worldName = string.format("%03d", worldNumber)
      local worldProgress, worldNumberOfStars = score.worldProgress(worldName)
      local worldTexture = images.worldImageTexture(worldName)

      local worldButton = components.newImageButton(
        content,
        worldTexture.filename,
        worldTexture.baseDir,
        280,
        105,
        { onRelease = function() navigation.gotoLevels(worldName) end, scrollview = scrollview }
      )
      worldButton.anchorY = 0
      worldButton.y = y
      worldButton.x = scrollview.width * 0.5
      worldTexture:releaseSelf()

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

