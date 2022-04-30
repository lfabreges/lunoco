local layouts = {}

local max = math.max
local min = math.min

layouts.align = function(object, horizontalAlign, verticalAlign, reference)
  reference = reference or object.parent
  if horizontalAlign then
    object.x = object.x + (reference.contentBounds.xMin - object.contentBounds.xMin)
    if horizontalAlign == "center" then
      object.x = object.x + reference.contentWidth * 0.5 - object.contentWidth * 0.5
    elseif horizontalAlign == "right" then
      object.x = object.x + reference.contentWidth - object.contentWidth
    end
  end
  if verticalAlign then
    object.y = object.y + (reference.contentBounds.yMin - object.contentBounds.yMin)
    if verticalAlign == "center" then
      object.y = object.y + reference.contentHeight * 0.5 - object.contentHeight * 0.5
    elseif verticalAlign == "bottom" then
      object.y = object.y + reference.contentHeight - object.contentHeight
    end
  end
end

layouts.alignCenter = function(object, reference)
  layouts.align(object, "center", nil, reference)
end

layouts.alignHorizontal = function(object, horizontalAlign, reference)
  layouts.align(object, horizontalAlign, nil, reference)
end

layouts.alignVertical = function(object, verticalAlign, reference)
  layouts.align(object, nil, verticalAlign, reference)
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
  options.separator = options.separator or 0

  if options.mode == "horizontal" then
    options.align = options.align == "center" and "center" or options.align == "right" and "right" or "left"
  else
    options.align = options.align == "center" and "center" or options.align == "bottom" and "bottom" or "top"
  end

  local stack = display.newGroup()

  if options.parent then
    options.parent:insert(stack)
  end

  local align = nil
  local insert = stack.insert
  local shouldAlignNextFrame = false

  align = function()
    for index = 1, stack.numChildren do
      local child = stack[index]
      if options.mode == "horizontal" then
        layouts.align(child, nil, options.align)
      else
        layouts.align(child, options.align, nil)
      end
    end
    shouldAlignNextFrame = false
    Runtime:removeEventListener("enterFrame", align)
  end

  function stack:insert(child)
    local previousChild = stack[stack.numChildren]
    insert(self, child)
    child.anchorX = 0
    child.anchorY = 0
    child.anchorChildren = true
    if previousChild then
      layouts.align(child, "left", "top", previousChild)
      if options.mode == "horizontal" then
        child.x = child.x + previousChild.contentWidth + options.separator
      else
        child.y = child.y + previousChild.contentHeight + options.separator
      end
      if not shouldAlignNextFrame then
        Runtime:addEventListener("enterFrame", align)
        shouldAlignNextFrame = true
      end
    end
  end

  stack:addEventListener("finalize", function()
    Runtime:removeEventListener("enterFrame", align)
  end)

  return stack
end

layouts.newTabs = function(options)
  options = options or {}

  local tabs = display.newGroup()
  local view = display.newGroup()
  tabs:insert(view)

  if options.parent then
    options.parent:insert(tabs)
  end

  local selectedTab = options.selectedTab or 1
  view.x = (1 - selectedTab) * display.actualContentWidth

  function tabs:insert(child)
    local index = view.numChildren
    view:insert(child)
    child.x = child.x + index * display.actualContentWidth
  end

  function tabs:selectedTab()
    return selectedTab
  end

  function tabs:select(index, selectOptions)
    selectOptions = selectOptions or {}

    local previousSelectedTab = selectedTab
    local time = selectOptions.time or 100

    if previousSelectedTab ~= index then
      local x = (1 - index) * display.actualContentWidth
      if time == 0 then
        view.x = x
      else
        transition.to(view, { x = x, time = time })
      end
      selectedTab = index
    end

    self:dispatchEvent({ name = "select", index = index, previous = previousSelectedTab, time = time })
  end

  view:addEventListener("finalize", function()
    transition.cancel(view)
  end)

  return tabs
end

layouts.newVortex = function(options)
  options = options or {}

  local vortex = display.newGroup()

  if options.parent then
    options.parent:insert(vortex)
  end

  local align = nil
  local insert = vortex.insert
  local shouldAlignNextFrame = false

  align = function()
    for index = 1, vortex.numChildren do
      local child = vortex[index]
      layouts.align(child, "center", "center")
    end
    shouldAlignNextFrame = false
    Runtime:removeEventListener("enterFrame", align)
  end

  function vortex:insert(child)
    local previousChild = vortex[vortex.numChildren]
    insert(self, child)
    if previousChild then
      layouts.align(child, "left", "top", previousChild)
      if not shouldAlignNextFrame then
        Runtime:addEventListener("enterFrame", align)
        shouldAlignNextFrame = true
      end
    end
  end

  vortex:addEventListener("finalize", function()
    Runtime:removeEventListener("enterFrame", align)
  end)

  return vortex
end

return layouts
