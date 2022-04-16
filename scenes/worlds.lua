local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local images = require "modules.images"
local lfs = require "lfs"
local navigation = require "modules.navigation"
local utils = require "modules.utils"
local widget = require "widget"

local content = nil
local numberOfWorlds = 2
local scene = composer.newScene()
local scrollview = nil

if utils.isSimulator() then
  local worldsPath = system.pathForFile("worlds", system.ResourceDirectory)
  local actualNumberOfWorlds = 0

  for filename in lfs.dir(worldsPath) do
    if filename:match("^%d+$") then
      actualNumberOfWorlds = actualNumberOfWorlds + 1
    end
  end

  assert(
    actualNumberOfWorlds == numberOfWorlds,
    "Expected 'numberOfWorlds = " .. actualNumberOfWorlds .. "' in scenes.worlds"
  )
end

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

    for worldNumber = 1, numberOfWorlds do
      local worldName = string.format("%03d", worldNumber)
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

      y = y + 150
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

