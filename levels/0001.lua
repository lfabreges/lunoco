local borderWidth = 4
local width = 320
local height = 480
local unit = width / 40
local cornerWidth = unit * 10

return {
  borderWidth = borderWidth,
  width = width,
  height = height,
  ball = {
    x = width / 2,
    y = height - borderWidth - unit,
    width = unit * 4,
  },
  obstacles = {
    {
      type = "corner",
      x = borderWidth,
      y = height - borderWidth - cornerWidth,
      width = cornerWidth,
      height = cornerWidth,
    },
    {
      type = "corner",
      x = width - borderWidth - cornerWidth,
      y = height - borderWidth,
      width = cornerWidth,
      height = cornerWidth,
      rotation = 270,
    },
    {
      type = "corner",
      x = width - borderWidth,
      y = borderWidth + cornerWidth,
      width = cornerWidth,
      height = cornerWidth,
      rotation = 180,
    },
    {
      type = "horizontal-barrier",
      x = borderWidth,
      y = borderWidth + unit * 38,
      width = unit * 10,
      height = unit * 4,
    },
    {
      type = "horizontal-barrier-large",
      x = borderWidth + unit * 5,
      y = borderWidth + unit * 28,
      width = unit * 18,
      height = unit * 4,
    },
    {
      type = "horizontal-barrier-large",
      x = borderWidth + unit * 7,
      y = unit * 12,
      width = unit * 26,
      height = unit * 4,
    },
    {
      type = "vertical-barrier",
      x = borderWidth + unit * 29,
      y = borderWidth + unit * 20,
      width = unit * 4,
      height = unit * 18,
    },
  },
  targets = {
    {
      x = unit * 8,
      y = unit * 5,
      width = unit * 5,
      height = unit * 5,
    },
  },
}
