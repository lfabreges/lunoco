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
  object.category = isBuiltIn and "builtIn" or "user"
  object.isBuiltIn = isBuiltIn
  object.name = name

  setmetatable(object, self)
  self.__index = self

  return object
end

function worldClass:levels()
  if self._levels == nil then
    local configuration = utils.loadJson("worlds/" .. self.name .. ".json", self.baseDirectory)
    self._levels = configuration.levels
  end
  return self._levels
end

function worldClass:scores()
  local scores = loadScores()
  return scores[self.category] and scores[self.category][self.name] or {}
end

function worldClass:progress()
  local worldScores = self:scores()
  local worldLevels = self:levels()
  local numberOfLevels = #worldLevels
  local numberOfFinishedLevels = 0
  local totalNumberOfStars = 0
  local worldNumberOfStars = 3

  for _, levelName in pairs(worldLevels) do
    if worldScores[levelName] then
      local levelNumberOfStars = worldScores[levelName].numberOfStars
      numberOfFinishedLevels = numberOfFinishedLevels + 1
      totalNumberOfStars = totalNumberOfStars + levelNumberOfStars
      worldNumberOfStars = math.min(worldNumberOfStars, levelNumberOfStars)
    else
      worldNumberOfStars = 0
    end
  end

  local worldProgress = (numberOfFinishedLevels / numberOfLevels) * 25
  worldProgress = worldProgress + (totalNumberOfStars / (numberOfLevels * 3)) * 75

  return worldProgress, worldNumberOfStars
end

function worldClass:saveLevelScore(levelName, numberOfShots, numberOfStars)
  local scores = loadScores()
  scores[self.category] = scores[self.category] or {}
  scores[self.category][self.name] = scores[self.category][self.name] or {}

  local levelScore = scores[self.category][self.name][levelName]

  if not levelScore or levelScore.numberOfShots > numberOfShots then
    scores[self.category][self.name][levelName] = { numberOfShots = numberOfShots, numberOfStars = numberOfStars }
    saveScores(scores)
  end
end

return worldClass
