local borderWidth = 4
local width = display.contentWidth
local height = display.contentHeight

return {
  borderWidth = borderWidth,
  width = width,
  height = height,
  obstacles = {
    {
      type = "corner",
      x = borderWidth + 50,
      y = height - borderWidth - 50,
      width = 100,
      height = 100,
    },
    {
      type = "corner",
      x = width - borderWidth - 50,
      y = height - borderWidth - 50,
      width = 100,
      height = 100,
      rotation = 270,
    },
    {
      type = "corner",
      x = width - borderWidth - 50,
      y = borderWidth + 50,
      width = 100,
      height = 100,
      rotation = 180,
    },
  },
  targets = {
    { x = 140, y = 120, width = 50, height = 50 },
  },
}
