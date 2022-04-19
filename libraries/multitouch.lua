local multitouch = {}

local function calculateDistances(firstEvent, secondEvent)
  local distanceX = math.abs(firstEvent.x - secondEvent.x)
  local distanceY = math.abs(firstEvent.y - secondEvent.y)
  local totalDistance = math.sqrt(distanceX * distanceX + distanceY * distanceY)
  return distanceX, distanceY, totalDistance
end

local function calculateMiddle(firstEvent, secondEvent)
  return (firstEvent.x + secondEvent.x) * 0.5, (firstEvent.y + secondEvent.y) * 0.5
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

local function createMoveAndPinchListener(object, onMove, onPinch)
  local previousX
  local previousY
  local previousDistanceX
  local previousDistanceY
  local previousTotalDistance

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
        previousX = firstEvent.x
        previousY = firstEvent.y
      elseif index == 2 then
        previousX, previousY = calculateMiddle(firstEvent, secondEvent)
        previousDistanceX, previousDistanceY, previousTotalDistance = calculateDistances(firstEvent, secondEvent)
      end

    elseif object.isFocus then
      if phase == "moved" then
        if numberOfEvents > 1 then
          local distanceX, distanceY, totalDistance = calculateDistances(firstEvent, secondEvent)
          local deltaDistanceX = distanceX - previousDistanceX
          local deltaDistanceY = distanceY - previousDistanceY
          local deltaTotalDistance = totalDistance - previousTotalDistance
          previousDistanceX = distanceX
          previousDistanceY = distanceY
          previousTotalDistance = totalDistance
          if onPinch then
            onPinch(object, deltaDistanceX, deltaDistanceY, deltaTotalDistance)
          end
        end

        local x, y
        if numberOfEvents == 1 then
          x = firstEvent.x
          y = firstEvent.y
        else
          x, y = calculateMiddle(firstEvent, secondEvent)
        end
        local deltaX = x - previousX
        local deltaY = y - previousY
        previousX = x
        previousY = y
        if onMove then
          onMove(object, deltaX, deltaY)
        end

      elseif phase == "ended" or phase == "cancelled" then
        if numberOfEvents == 1 then
          object.isFocus = false
          display.getCurrentStage():setFocus(nil)
        elseif numberOfEvents == 2 then
          local remainingEvent = index == 1 and secondEvent or firstEvent
          previousX = remainingEvent.x
          previousY = remainingEvent.y
        else
          local remainingEvent = index == 1 and secondEvent or firstEvent
          local thirdEvent = event.events[3]
          previousX, previousY = calculateMiddle(remainingEvent, thirdEvent)
          previousDistanceX, previousDistanceY, previousTotalDistance = calculateDistances(remainingEvent, thirdEvent)
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

multitouch.addMoveAndPinchListener = function(object, onMove, onPinch)
  local listener = createMoveAndPinchListener(object, onMove, onPinch)
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
