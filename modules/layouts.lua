local layouts = {}

layouts.alignCenter = function(object, reference)
  local anchorX = object.anchorChildren == false and 0 or object.anchorX
  reference = reference or object.parent
  object.x = reference.contentWidth * 0.5 + (anchorX - 0.5) * object.contentWidth
end

layouts.alignLeft = function(object, reference)
  local anchorX = object.anchorChildren == false and 0 or object.anchorX
  reference = reference or object.parent
  object.x = anchorX * object.contentWidth
end

layouts.alignMiddle = function(object, reference)
  local anchorY = object.anchorChildren == false and 0 or object.anchorY
  reference = reference or object.parent
  object.y = reference.contentHeight * 0.5 + (anchorY - 0.5) * object.contentHeight
end

layouts.alignTop = function(object, reference)
  local anchorY = object.anchorChildren == false and 0 or object.anchorY
  reference = reference or object.parent
  object.y = anchorY * object.contentHeight
end

layouts.newBlackHole = function(options)
  options = options or {}

  local blackHole = display.newGroup()

  if options.parent then
    options.parent:insert(blackHole)
  end

  local align = nil
  local insert = blackHole.insert
  local shouldAlignNextFrame = false

  align = function()
    for index = 1, blackHole.numChildren do
      local child = blackHole[index]
      layouts.alignCenter(child)
      layouts.alignMiddle(child)
    end
    shouldAlignNextFrame = false
    Runtime:removeEventListener("enterFrame", align)
  end

  function blackHole:insert(child)
    if not shouldAlignNextFrame then
      Runtime:addEventListener("enterFrame", align)
      shouldAlignNextFrame = true
    end
    layouts.alignLeft(child, self)
    layouts.alignTop(child, self)
    insert(self, child)
  end

  blackHole:addEventListener("finalize", function()
    Runtime:removeEventListener("enterFrame", align)
  end)

  return blackHole
end

layouts.newGrid = function(options)
  options = options or {}
  options.mode = options.mode == "horizontal" and "horizontal" or "vertical"
  options.separator = options.separator or 0
  options.size = options.size or 2

  local grid = display.newGroup()

  if options.parent then
    options.parent:insert(grid)
  end

  local insert = grid.insert
  local primaryStack = layouts.newStack({ mode = options.mode, separator = options.separator })
  local secondaryStack = nil
  local secondaryStackMode = options.mode == "horizontal" and "vertical" or "horizontal"

  insert(grid, primaryStack)

  function grid:insert(child)
    if secondaryStack == nil or secondaryStack.numChildren == options.size then
      secondaryStack = layouts.newStack({ mode = secondaryStackMode, separator = options.separator })
      primaryStack:insert(secondaryStack)
    end
    secondaryStack:insert(child)
  end

  return grid
end

layouts.newStack = function(options)
  options = options or {}
  options.mode = options.mode == "horizontal" and "horizontal" or "vertical"
  options.separator = options.separator or 0

  if options.mode == "horizontal" then
    options.align = (
         options.align == "center" and "center"
      or options.align == "bottom" and "bottom"
      or "top"
    )
  else
    options.align = (
         options.align == "center" and "center"
      or options.align == "right" and "right"
      or "left"
    )
  end

  local stack = display.newGroup()

  if options.parent then
    options.parent:insert(stack)
  end

  local align = nil
  local insert = stack.insert
  local keys = nil
  local shouldAlignNextFrame = false

  if options.mode == "vertical" then
    keys = {
      alignAxis = "x",
      alignContentSize = "contentWidth",
      alignStart = "left",
      axis = "y",
      contentSize = "contentHeight",
    }
  else
    keys = {
      alignAxis = "y",
      alignContentSize = "contentHeight",
      alignStart = "top",
      axis = "x",
      contentSize = "contentWidth"
    }
  end

  align = function()
    local alignContentSize = stack[keys.alignContentSize]
    for index = 1, stack.numChildren do
      local child = stack[index]
      local difference = alignContentSize - child[keys.alignContentSize]
      local delta = options.align == "center" and difference * 0.5 or difference
      child[keys.alignAxis] = child[keys.alignAxis] + delta
    end
    shouldAlignNextFrame = false
    Runtime:removeEventListener("enterFrame", align)
  end

  function stack:insert(child)
    local previousChild = stack[stack.numChildren]
    if previousChild then
      child[keys.axis] = previousChild[keys.axis] + previousChild[keys.contentSize] + options.separator
      if options.align ~= keys.alignStart and not shouldAlignNextFrame then
        Runtime:addEventListener("enterFrame", align)
        shouldAlignNextFrame = true
      end
    end
    child.anchorX = 0
    child.anchorY = 0
    insert(self, child)
  end

  stack:addEventListener("finalize", function()
    Runtime:removeEventListener("enterFrame", align)
  end)

  return stack
end

return layouts
