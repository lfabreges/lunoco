local multitouch = {}

local abs = math.abs

local function calculateDistanceDelta(firstEvent, secondEvent)
  local xDistanceStart = abs(firstEvent.xStart - secondEvent.xStart)
  local yDistanceStart = abs(firstEvent.yStart - secondEvent.yStart)
  local xDistance = abs(firstEvent.x - secondEvent.x)
  local yDistance = abs(firstEvent.y - secondEvent.y)
  return xDistance - xDistanceStart, yDistance - yDistanceStart
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
  local xDistanceCumulated
  local yDistanceCumulated
  local xMoveStart
  local yMoveStart

  local function updateDistanceCumulated(oldFirstEvent, oldSecondEvent, newFirstEvent, newSecondEvent)
    local xOldDistanceDelta, yOldDistanceDelta = calculateDistanceDelta(oldFirstEvent, oldSecondEvent)
    local xNewDistanceDelta, yNewDistanceDelta = calculateDistanceDelta(newFirstEvent, newSecondEvent)
    xDistanceCumulated = xDistanceCumulated + xOldDistanceDelta - xNewDistanceDelta
    yDistanceCumulated = yDistanceCumulated + yOldDistanceDelta - yNewDistanceDelta
  end

  local function updateMoveStart(oldFirstEvent, oldSecondEvent, newFirstEvent, newSecondEvent)
    local xOldMiddle, yOldMiddle = calculateMiddle(oldFirstEvent, oldSecondEvent)
    local xNewMiddle, yNewMiddle = calculateMiddle(newFirstEvent, newSecondEvent)
    xMoveStart = xMoveStart + xNewMiddle - xOldMiddle
    yMoveStart = yMoveStart + yNewMiddle - yOldMiddle
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
        xDistanceCumulated = 0
        yDistanceCumulated = 0
        xMoveStart = firstEvent.x
        yMoveStart = firstEvent.y
        if options.onFocus then
          options.onFocus({ target = object })
        end
      elseif index == 2 then
        updateMoveStart(firstEvent, firstEvent, firstEvent, secondEvent)
        updateDistanceCumulated(firstEvent, firstEvent, firstEvent, secondEvent)
      end
    elseif object.isFocus then
      if phase == "moved" then
        if options.onMoveAndPinch then
          if numberOfEvents == 1 then
            options.onMoveAndPinch({
              xDelta = firstEvent.x - xMoveStart,
              yDelta = firstEvent.y - yMoveStart,
              target = object,
            })
          else
            local xMiddle, yMiddle = calculateMiddle(firstEvent, secondEvent)
            local xDistanceDelta, yDistanceDelta = calculateDistanceDelta(firstEvent, secondEvent)
            options.onMoveAndPinch({
              xDelta = xMiddle - xMoveStart,
              yDelta = yMiddle - yMoveStart,
              xDistanceDelta = xDistanceDelta + xDistanceCumulated,
              yDistanceDelta = yDistanceDelta + yDistanceCumulated,
              target = object,
            })
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
          updateMoveStart(firstEvent, secondEvent, remainingEvent, otherEvent)
          updateDistanceCumulated(firstEvent, secondEvent, remainingEvent, otherEvent)
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
