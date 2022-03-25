local components = require "components"
local composer = require "composer"
local widget = require "widget"

local elements = nil
local levelName = nil
local scene = composer.newScene()
local scrollview = nil

local function elementsTypesFromLevelConfig()
  local config = require ("levels." .. levelName)
  local elementsTypes = { "ball" }
  local hashset = {}

  for _, obstacle in pairs(config.obstacles) do
    hashset["obstacle-" .. obstacle.type] = true
  end
  for _, target in pairs(config.targets) do
    hashset["target-" .. target.type] = true
  end
  for elementType, _ in pairs(hashset) do
    table.insert(elementsTypes, elementType)
  end

  table.sort(elementsTypes)
  return elementsTypes
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
    topPadding = topInset + 20,
    bottomPadding = bottomInset + 20,
    leftPadding = leftInset,
    rightPadding = rightInset,
  })

  self.view:insert(scrollview)
end

function scene:createElements()
  local elementsTypes = elementsTypesFromLevelConfig()
  local y = 0

  elements = components.newGroup(scrollview)

  for _, elementType in ipairs(elementsTypes) do
    local element = nil
    local row = components.newGroup(elements)

    row.anchorX, row.anchorY = 0, 0
    row.x, row.y = 20, y

    if elementType == "ball" then
      element = components.newBall(row, levelName, 50, 50)
    elseif elementType == "obstacle-corner" then
      element = components.newObstacleCorner(row, levelName, 50, 50)
    elseif elementType:starts("obstacle-horizontal-barrier") then
      element = components.newObstacleBarrier(row, levelName, elementType:sub(10), 50, 20)
    elseif elementType:starts("obstacle-vertical-barrier") then
      element = components.newObstacleBarrier(row, levelName, elementType:sub(10), 20, 50)
    elseif elementType:starts("target-") then
      element = components.newTarget(row, levelName, elementType:sub(8), 50, 50)
    end

    if element then
      element.x = 25
      element.y = 25

      local selectPhotoButton = components.newButton(row, {
        label = "TODO",
        width = 100,
        onRelease = function()
          if media.hasSource(media.PhotoLibrary) then
            media.selectPhoto({ mediaSource = media.PhotoLibrary, listener = function(event)
              local photo = event.target
              composer.gotoScene("scenes.element-image", {
                params = {
                  elementType = elementType,
                  levelName = levelName,
                  photo = photo
                } })
            end })
          else
            -- TODO
            native.showAlert( "TODO", "This device does not have a photo library.", { "OK" } )
          end
        end
      })

      selectPhotoButton.x = 120
      selectPhotoButton.y = 25

      y = y + 70
    end
  end

  -- Les infos à récupérer pour chaque élément :
  -- Taille de l'objet (carré, rectangle, etc.)
  -- Forme de l'objet (peut remplacer la taille, j'ai directement les éléments avec la forme)
  -- Masque à appliquer s'il y en a un

  -- Afficher les éléments à partir des images de l'utilisateur
  -- Afficher un bouton pour sélectionner l'image par défaut, sélectionner une image, un pour prendre une photo
  -- Envoyer cela vers la scène de sélection de l'image, puis la sauvegarder
end

function scene:show(event)
  if event.phase == "will" then
    levelName = event.params.levelName
    self:createElements()
  elseif event.phase == "did" then
  end
end

function scene:hide(event)
  if event.phase == "did" then
    display.remove(elements)
    elements = nil
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)

return scene
