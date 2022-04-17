local universe = require "universe"
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

score.loadWorldScores = function(world)
  local scores = score.loadScores()
  return scores[world.category] and scores[world.category][world.name] or {}
end

score.saveLevelScoreIfBetter = function(world, levelName, numberOfShots, numberOfStars)
  local scores = score.loadScores()
  scores[world.category] = scores[world.category] or {}
  scores[world.category][world.name] = scores[world.category][world.name] or {}
  local worldScores = scores[world.category][world.name]
  if not worldScores[levelName] or worldScores[levelName].numberOfShots > numberOfShots then
    worldScores[levelName] = { numberOfShots = numberOfShots, numberOfStars = numberOfStars }
    score.saveScores(scores)
  end
end

score.worldProgress = function(world)
  local worldScores = score.loadWorldScores(world)
  local worldLevels = world:levels()
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

return score
