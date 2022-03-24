local composer = require "composer"

display.setStatusBar(display.HiddenStatusBar)

--[[if media.hasSource(media.PhotoLibrary) then
  -- media.selectPhoto({ mediaSource = media.PhotoLibrary, listener = onComplete })
  local photo = display.newImageRect("images/frame.png", system.ResourceDirectory, 300, 200)
  composer.gotoScene("scenes.element-image", { params = { photo = photo } })
else
  -- TODO
  native.showAlert( "TODO", "This device does not have a photo library.", { "OK" } )
end]]

composer.gotoScene("scenes.levels")
