local components = require "modules.components"
local composer = require "composer"
local i18n = require "modules.i18n"
local lfs = require "lfs"
local navigation = require "modules.navigation"
local utils = require "modules.utils"
local widget = require "widget"

local content = nil
local gameTitle = nil
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

  gameTitle = display.newText({
    align = "center",
    text = i18n.t("title"),
    font = native.systemFontBold,
    fontSize = 40,
    x = scrollview.width * 0.5,
    y = 0,
  })

  gameTitle.anchorY = 0
  scrollview:insert(gameTitle)
end

function scene:show(event)
  if event.phase == "will" then
    local y = gameTitle.contentHeight + 40

    content = components.newGroup(scrollview)

    for worldNumber = 1, numberOfWorlds do
      local worldName = string.format("%03d", worldNumber)
      -- TODO Image du monde
      -- Prendre les images de tous les niveaux et les étaler comme un jeu de carte
      local levelImage = nil
      --local levelImageName = images.levelImageName(levelName, "screenshot")
      -- local levelImageBaseDir = system.DocumentsDirectory

      if not levelImageName then
        levelImageName = "images/level-unknown.png"
        levelImageBaseDir = system.ResourceDirectory
      end

      local levelButton = components.newImageButton(
        content,
        levelImageName,
        levelImageBaseDir,
        120,
        180,
        { onRelease = function() navigation.gotoLevels(worldName) end, scrollview = scrollview }
      )

      levelButton.anchorY = 0
      levelButton.y = y
      levelButton.x = scrollview.width * 0.5

      y = y + 240
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

