local multitouch = {}

local abs = math.abs
local sqrt = math.sqrt

local function calculateDistance(firstEvent, secondEvent)
  local startDistanceX = abs(firstEvent.xStart - secondEvent.xStart)
  local startDistanceY = abs(firstEvent.yStart - secondEvent.yStart)
  local currentDistanceX = abs(firstEvent.x - secondEvent.x)
  local currentDistanceY = abs(firstEvent.y - secondEvent.y)
  return currentDistanceX - startDistanceX, currentDistanceY - startDistanceY
end

local function calculateMiddle(firstCoordinates, secondCoordinates)
  return (firstCoordinates.x + secondCoordinates.x) * 0.5, (firstCoordinates.y + secondCoordinates.y) * 0.5
end

local function createEventListener(listener)
  local numberOfEvents = 0
  local touchEvents = {}

  local function callListener(event, index)
    return listener({
      phase = event.phase,
      index = index,
      numberOfEvents = numberOfEvents,
      events = touchEvents,
    })
  end

  local function onTouch(event)
    local isHandled = false
    if event.phase == "began" then
      numberOfEvents = #touchEvents + 1
      touchEvents[numberOfEvents] = event
      isHandled = callListener(event, numberOfEvents)
    else
      local currentEventIndex = nil
      for index = 1, numberOfEvents do
        if event.id == touchEvents[index].id then
          currentEventIndex = index
          break
        end
      end
      if currentEventIndex then
        touchEvents[currentEventIndex] = event
        isHandled = callListener(event, currentEventIndex)
        if event.phase == "ended" or event.phase == "cancelled" then
          numberOfEvents = numberOfEvents - 1
          table.remove(touchEvents, currentEventIndex)
        end
      end
    end
    return isHandled
  end

  return onTouch
end

local function createMoveAndPinchListener(object, options)
  local cumulatedDistanceX
  local cumulatedDistanceY
  local middleStartX
  local middleStartY

  local function updateCumulatedDistance(oldFirstEvent, oldSecondEvent, newFirstEvent, newSecondEvent)
    local oldDistanceX, oldDistanceY = calculateDistance(oldFirstEvent, oldSecondEvent)
    local newDistanceX, newDistanceY = calculateDistance(newFirstEvent, newSecondEvent)
    cumulatedDistanceX = cumulatedDistanceX + oldDistanceX - newDistanceX
    cumulatedDistanceY = cumulatedDistanceY + oldDistanceY - newDistanceY
  end

  local function updateMiddleStart(oldFirstEvent, oldSecondEvent, newFirstEvent, newSecondEvent)
    local oldMiddleX, oldMiddleY = calculateMiddle(oldFirstEvent, oldSecondEvent)
    local newMiddleX, newMiddleY = calculateMiddle(newFirstEvent, newSecondEvent)
    middleStartX = middleStartX + newMiddleX - oldMiddleX
    middleStartY = middleStartY + newMiddleY - oldMiddleY
  end

  local function onMultitouch(event)
    local phase = event.phase
    local index = event.index
    local numberOfEvents = event.numberOfEvents
    local firstEvent = event.events[1]
    local secondEvent = event.events[2]

    if index > 2 then
      return true
    end

    if phase == "began" then
      if index == 1 then
        display.getCurrentStage():setFocus(object)
        object.isFocus = true
        cumulatedDistanceX = 0
        cumulatedDistanceY = 0
        middleStartX = firstEvent.x
        middleStartY = firstEvent.y
        if options.onFocus then
          options.onFocus({ target = object })
        end
      elseif index == 2 then
        updateMiddleStart(firstEvent, firstEvent, firstEvent, secondEvent)
        updateCumulatedDistance(firstEvent, firstEvent, firstEvent, secondEvent)
      end
    elseif object.isFocus then
      if phase == "moved" then
        if options.onPinch and numberOfEvents > 1 then
          local x, y = calculateDistance(firstEvent, secondEvent)
          x = x + cumulatedDistanceX
          y = y + cumulatedDistanceY
          local total = sqrt(x * x + y * y)
          options.onPinch({ x = x, y = y, total = total, target = object })
        end
        if options.onMove then
          if numberOfEvents == 1 then
            options.onMove({ x = firstEvent.x - middleStartX, y = firstEvent.y - middleStartY, target = object })
          else
            local middleX, middleY = calculateMiddle(firstEvent, secondEvent)
            options.onMove({ x = middleX - middleStartX, y = middleY - middleStartY, target = object })
          end
        end
      elseif phase == "ended" or phase == "cancelled" then
        if numberOfEvents == 1 then
          display.getCurrentStage():setFocus(nil)
          object.isFocus = false
          if options.onBlur then
            options.onBlur({ target = object })
          end
        else
          local remainingEvent = index == 1 and secondEvent or firstEvent
          local otherEvent = numberOfEvents == 2 and remainingEvent or event.events[3]
          updateMiddleStart(firstEvent, secondEvent, remainingEvent, otherEvent)
          updateCumulatedDistance(firstEvent, secondEvent, remainingEvent, otherEvent)
        end
      end
    end

    return true
  end

  return onMultitouch
end

multitouch.addEventListener = function(object, listener)
  local eventListener = createEventListener(listener)
  object:addEventListener("touch", eventListener)
  object.multitouchEventListeners = object.multitouchEventListeners or {}
  object.multitouchEventListeners[listener] = eventListener
end

multitouch.removeEventListener = function(object, listener)
  if (object.multitouchEventListeners and object.multitouchEventListeners[listener]) then
    object:removeEventListener("touch", object.multitouchEventListeners[listener])
    object.multitouchEventListeners[listener] = nil
  end
end

multitouch.addMoveAndPinchListener = function(object, options)
  local listener = createMoveAndPinchListener(object, options)
  multitouch.removeMoveAndPinchListener(object)
  multitouch.addEventListener(object, listener)
  object.multitouchMoveAndPinchListener = listener
end

multitouch.removeMoveAndPinchListener = function(object)
  if object.multitouchMoveAndPinchListener then
    multitouch.removeEventListener(object, object.multitouchMoveAndPinchListener)
    object.multitouchMoveAndPinchListener = nil
  end
end

return multitouch
