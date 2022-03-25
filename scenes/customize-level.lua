local components = require "components"
local composer = require "composer"
local widget = require "widget"

local elements = nil
local levelName = nil
local scene = composer.newScene()
local scrollview = nil

local function elementsFromLevelConfig()
  local config = require ("levels." .. levelName)
  local elements = { "ball" }
  local hashset = {}

  for _, obstacle in pairs(config.obstacles) do
    hashset["obstacle-" .. obstacle.type] = true
  end
  for _, target in pairs(config.targets) do
    hashset["target-" .. target.type] = true
  end
  for element, _ in pairs(hashset) do
    table.insert(elements, element)
  end

  table.sort(elements)
  return elements
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
    topPadding = topInset,
    bottomPadding = bottomInset,
    leftPadding = leftInset,
    rightPadding = rightInset,
  })

  self.view:insert(scrollview)
end

function scene:createElements()
  local elements = elementsFromLevelConfig()

  for _, element in ipairs(elements) do
    print(element)
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
