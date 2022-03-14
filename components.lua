local components = {}

components.newOverlayBackground = function(parent)
  local background = display.newRect(
    parent,
    display.screenOriginX,
    display.screenOriginY,
    display.actualContentWidth,
    display.actualContentHeight
  )

  background.anchorX = 0
  background.anchorY = 0
  background.alpha = 0.8
  background:setFillColor(0.0)

  return background
end

return components
