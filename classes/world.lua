local levelClass = require "classes.level"
local utils = require "modules.utils"

local worldClass = {}

function worldClass:new(name, isBuiltIn)
  local object = { isBuiltIn = isBuiltIn, name = name }
  local category = isBuiltIn and "builtIn" or "user"
  object.directory = "worlds/" .. category .. "/" .. name
  utils.mkdir(system.DocumentsDirectory, object.directory)
  setmetatable(object, self)
  self.__index = self
  return object
end

function worldClass:levels()
  if self._levels == nil then
    self._levels = {}
    local configuration
    if self.isBuiltIn then
      configuration = utils.loadJson("worlds/" .. self.name .. ".json", system.ResourceDirectory)
    else
      configuration = utils.loadJson("worlds/user/" .. self.name .. ".json", system.DocumentsDirectory)
    end
    for index = 1, #configuration.levels do
      self._levels[index] = levelClass:new(self, configuration.levels[index])
    end
  end
  return self._levels
end

function worldClass:scores()
  if self._scores == nil then
    self._scores = utils.loadJson(self.directory .. "/scores.json", system.DocumentsDirectory)
  end
  return self._scores
end

function worldClass:saveScores(scores)
  utils.saveJson(scores, self.directory .. "/scores.json", system.DocumentsDirectory)
  self._scores = scores
end

function worldClass:progress()
  local scores = self:scores()
  local levels = self:levels()
  local numberOfLevels = #levels
  local numberOfFinishedLevels = 0
  local totalNumberOfStars = 0
  local worldNumberOfStars = 3

  for _, level in pairs(levels) do
    if scores[level.name] then
      local levelNumberOfStars = scores[level.name].numberOfStars
      numberOfFinishedLevels = numberOfFinishedLevels + 1
      totalNumberOfStars = totalNumberOfStars + levelNumberOfStars
      worldNumberOfStars = math.min(worldNumberOfStars, levelNumberOfStars)
    else
      worldNumberOfStars = 0
    end
  end

  local progress = (numberOfFinishedLevels / numberOfLevels) * 25 + (totalNumberOfStars / (numberOfLevels * 3)) * 75
  return progress, worldNumberOfStars
end

return worldClass
