local resources = require "resources"
local utils = require "modules.utils"

local score = {}

local cachedScores = nil

score.loadScores = function()
  cachedScores = cachedScores or utils.loadJson("scores.json", system.DocumentsDirectory)
  return cachedScores
end

score.saveScores = function(scores)
  utils.saveJson(scores, "scores.json", system.DocumentsDirectory)
  cachedScores = scores
end

score.worldScores = function(worldName)
  return score.loadScores()[worldName] or {}
end

score.worldProgress = function(worldName)
  local worldScores = score.worldScores(worldName)
  local numberOfLevels = resources.numberOfLevels(worldName)
  local numberOfFinishedLevels = 0
  local totalNumberOfStars = 0
  local worldNumberOfStars = 3

  for levelNumber = 1, numberOfLevels do
    local levelName = string.format("%03d", levelNumber)
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

return score
