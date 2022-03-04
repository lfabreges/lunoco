local borderWidth = 4
local width = display.contentWidth
local height = display.contentHeight

return {
  borderWidth = borderWidth,
  width = width,
  height = height,
  ball = {
    x = width / 2,
    y = height - borderWidth - 15,
    width = 30,
  },
  obstacles = {
    {
      type = "corner",
      x = borderWidth + 40,
      y = height - borderWidth - 40,
      width = 80,
      height = 80,
    },
    {
      type = "corner",
      x = width - borderWidth - 40,
      y = height - borderWidth - 40,
      width = 80,
      height = 80,
      rotation = 270,
    },
    {
      type = "corner",
      x = width - borderWidth - 40,
      y = borderWidth + 40,
      width = 80,
      height = 80,
      rotation = 180,
    },
    {
      type = "horizontal-barrier",
      x = borderWidth + 40,
      y = height - borderWidth - 140,
      width = 80,
      height = 30,
    },
    {
      type = "horizontal-barrier-large",
      x = borderWidth + 120,
      y = height - borderWidth - 220,
      width = 140,
      height = 30,
    },
    {
      type = "horizontal-barrier-large",
      x = borderWidth + 150,
      y = 100,
      width = 220,
      height = 30,
    },
    {
      type = "vertical-barrier",
      x = borderWidth + 250,
      y = height - borderWidth - 220,
      width = 30,
      height = 140,
    },
  },
  targets = {
    { x = 80, y = 50, width = 40, height = 40 },
  },
}
