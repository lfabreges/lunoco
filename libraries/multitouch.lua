local multitouch = {}

local function calculateDistance(firstEvent, secondEvent)
  local distanceX = math.abs(firstEvent.x - secondEvent.x)
  local distanceY = math.abs(firstEvent.y - secondEvent.y)
  return math.sqrt(distanceX * distanceX + distanceY * distanceY)
end

local function calculateMiddle(firstEvent, secondEvent)
  return (firstEvent.x + secondEvent.x) * 0.5, (firstEvent.y + secondEvent.y) * 0.5
end

local function createEventListener(listener)
  local numberOfEvents = 0
  local touchEvents = {}

  local function onTouch(event)
    local isHandled = false

    if event.phase == "began" then
      table.insert(touchEvents, event)
      numberOfEvents = numberOfEvents + 1
      isHandled = listener({
        phase = "began",
        index = numberOfEvents,
        numberOfEvents = numberOfEvents,
        events = touchEvents,
      })

    elseif event.phase == "moved" then
      for index, touchEvent in ipairs(touchEvents) do
        if event.id == touchEvent.id then
          touchEvents[index] = event
          isHandled = listener({
            phase = "moved",
            index = index,
            numberOfEvents = numberOfEvents,
            events = touchEvents,
          })
          break
        end
      end

    elseif event.phase == "ended" or event.phase == "cancelled" then
      for index, touchEvent in ipairs(touchEvents) do
        if event.id == touchEvent.id then
          touchEvents[index] = event
          isHandled = listener({
            phase = event.phase,
            index = index,
            numberOfEvents = numberOfEvents,
            events = touchEvents,
          })
          numberOfEvents = numberOfEvents - 1
          table.remove(touchEvents, index)
          break
        end
      end
    end

    return isHandled
  end

  return onTouch
end

local function createMoveAndPinchListener(onMove, onPinch)
  local prevX
  local prevY
  local prevDistance

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
        display.getCurrentStage():setFocus(overlay)
        prevX, prevY = firstEvent.x, firstEvent.y
      elseif index == 2 then
        prevX, prevY = calculateMiddle(firstEvent, secondEvent)
        prevDistance = calculateDistance(firstEvent, secondEvent)
      end

    elseif phase == "moved" then
      local dx, dy
      if numberOfEvents == 1 then
        dx, dy = firstEvent.x - prevX, firstEvent.y - prevY
        prevX, prevY = firstEvent.x, firstEvent.y
      else
        local middleX, middleY = calculateMiddle(firstEvent, secondEvent)
        dx, dy = middleX - prevX, middleY - prevY
        prevX, prevY = middleX, middleY
      end
      if onMove then
        onMove(dx, dy)
      end

      if numberOfEvents > 1 then
        local distance = calculateDistance(firstEvent, secondEvent)
        local dDistance = distance - prevDistance
        prevDistance = distance
        if onPinch then
          onPinch(dDistance)
        end
      end

    elseif phase == "ended" or phase == "cancelled" then
      if numberOfEvents == 1 then
        display.getCurrentStage():setFocus(nil)
      elseif numberOfEvents == 2 then
        local remainingEvent = index == 1 and secondEvent or firstEvent
        prevX, prevY = remainingEvent.x, remainingEvent.y
      else
        local remainingEvent = index == 1 and secondEvent or firstEvent
        local thirdEvent = event.events[3]
        prevX, prevY = calculateMiddle(remainingEvent, thirdEvent)
        prevDistance = calculateDistance(remainingEvent, thirdEvent)
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
  local listener = createMoveAndPinchListener(onMove, onPinch)
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
