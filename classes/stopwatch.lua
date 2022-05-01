local stopwatchClass = {}

function stopwatchClass:new()
  local object = { _isRunning = false, _totalTime = 0 }
  setmetatable(object, self)
  self.__index = self
  return object
end

function stopwatchClass:isRunning()
  return self._isRunning
end

function stopwatchClass:pause()
  if self._isRunning then
    self._totalTime = self:totalTime()
    self._isRunning = false
  end
end

function stopwatchClass:start()
  self._startTime = system.getTimer()
  self._isRunning = true
end

function stopwatchClass:totalTime()
  return self._totalTime + (self._isRunning and (system.getTimer() - self._startTime) or 0)
end

return stopwatchClass
