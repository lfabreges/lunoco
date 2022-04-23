local layouts = {}

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

  local stack = display.newGroup()

  if options.parent then
    options.parent:insert(stack)
  end

  local insert = stack.insert

  function stack:insert(child)
    local previousChild = stack[stack.numChildren]
    if options.mode == "vertical" then
      child.y = previousChild and (previousChild.y + previousChild.contentHeight + options.separator) or 0
    else
      child.x = previousChild and (previousChild.x + previousChild.contentWidth + options.separator) or 0
    end
    child.anchorX = 0
    child.anchorY = 0
    insert(self, child)
  end

  return stack
end

return layouts
