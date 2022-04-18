local utils = require "modules.utils"

local cachedScores = nil
local worldClass = {}

local function loadScores()
  cachedScores = cachedScores or utils.loadJson("scores.json", system.DocumentsDirectory)
  return cachedScores
end

local function saveScores(scores)
  utils.saveJson(scores, "scores.json", system.DocumentsDirectory)
  cachedScores = scores
end

function worldClass:new(name, isBuiltIn)
  local object = {}
  object.baseDirectory = isBuiltIn and system.ResourceDirectory or system.DocumentsDirectory
  object.isBuiltIn = isBuiltIn
  object.name = name
  object.type = isBuiltIn and "builtIn" or "user"
  setmetatable(object, self)
  self.__index = self
  return object
end

function worldClass:levelConfiguration(levelName)
  return utils.loadJson("worlds/" .. self.name .. "/" .. levelName .. ".json", self.baseDirectory)
end

function worldClass:levelNames()
  if self._levelNames == nil then
    local configuration = utils.loadJson("worlds/" .. self.name .. ".json", self.baseDirectory)
    self._levelNames = configuration.levels
  end
  return self._levelNames
end

function worldClass:scores()
  return utils.nestedGetOrDefault(loadScores(), self.type, self.name, {})
end

function worldClass:progress()
  local scores = self:scores()
  local levelNames = self:levelNames()
  local numberOfLevels = #levelNames
  local numberOfFinishedLevels = 0
  local totalNumberOfStars = 0
  local worldNumberOfStars = 3

  for _, levelName in pairs(levelNames) do
    if scores[levelName] then
      local levelNumberOfStars = scores[levelName].numberOfStars
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

function worldClass:saveLevelScore(levelName, numberOfShots, numberOfStars)
  local scores = loadScores()
  local levelScore = utils.nestedGetOrSet(scores, self.type, self.name, levelName, {})
  if levelScore.numberOfShots == nil or levelScore.numberOfShots > numberOfShots then
    levelScore.numberOfShots = numberOfShots
    levelScore.numberOfStars = numberOfStars
    saveScores(scores)
  end
end

return worldClass
