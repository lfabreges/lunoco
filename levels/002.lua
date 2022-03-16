local borderWidth = 4
local width = 320
local height = 480
local unit = width / 40
local cornerWidth = unit * 10

return {
  stars = {
    one = 6,
    two = 4,
    three = 2,
  },
  borderWidth = borderWidth,
  width = width,
  height = height,
  ball = {
    x = width / 2,
    y = borderWidth + unit * 6,
    width = unit * 4,
  },
  obstacles = {
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
      x = borderWidth + cornerWidth,
      y = borderWidth,
      width = cornerWidth,
      height = cornerWidth,
      rotation = 90,
    },
    {
      type = "horizontal-barrier",
      x = borderWidth,
      y = borderWidth + unit * 34,
      width = unit * 12,
      height = unit * 4,
    },
    {
      type = "horizontal-barrier-large",
      x = borderWidth + unit * 12,
      y = borderWidth + unit * 8,
      width = unit * 22,
      height = unit * 4,
    },
    {
      type = "vertical-barrier",
      x = borderWidth + unit * 18,
      y = borderWidth + unit * 27,
      width = unit * 4,
      height = unit * 18,
    },
  },
  targets = {
    {
      type = "easy",
      x = borderWidth + unit * 4,
      y = borderWidth + unit * 50,
      width = unit * 5,
      height = unit * 5,
    },
    {
      type = "normal",
      x = borderWidth + unit * 30,
      y = borderWidth + unit * 40,
      width = unit * 5,
      height = unit * 5,
    },
    {
      type = "hard",
      x = borderWidth + unit * 7,
      y = borderWidth + unit * 27,
      width = unit * 5,
      height = unit * 5,
    },
    {
      type = "hard",
      x = borderWidth + unit * 32,
      y = borderWidth + unit * 24,
      width = unit * 5,
      height = unit * 5,
    },
  },
}
