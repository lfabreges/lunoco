local composer = require "composer"

local scene = composer.newScene()

function scene:create(event)
  local screenX = display.screenOriginX
  local screenY = display.screenOriginY
  local screenWidth = display.actualContentWidth
  local screenHeight = display.actualContentHeight

  -- Carré de 200 x 200

  local overlayTop = display.newRect(self.view, screenX, screenY, screenWidth, screenHeight)

  local background = display.newRect(self.view, screenX, screenY, screenWidth, screenHeight)
  background.anchorX = 0
  background.anchorY = 0
  background:setFillColor(0.25)

  -- Display an obstacle
  -- Select a photo when clicking on it
  -- Sélectionner un encart avec le outline
  -- Sauvegarder la partie qui nous intéresse
  -- L'utiliser dans le jeu
end

function scene:show(event)
  if event.phase == "did" then
    local function onComplete(event)
      local photo = event.target
      if photo then

      end
    end

    if media.hasSource(media.PhotoLibrary) then
      media.selectPhoto({ mediaSource = media.PhotoLibrary, listener = onComplete })
    else
      -- TODO
      native.showAlert( "TODO", "This device does not have a photo library.", { "OK" } )
    end
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)

return scene