local levelClass = require "classes.level"
local utils = require "modules.utils"

local worldClass = {}

function worldClass:new(universe, name, isBuiltIn)
  local object = { isBuiltIn = isBuiltIn, name = name, universe = universe }
  local category = isBuiltIn and "builtIn" or "user"
  object.directory = "worlds/" .. category .. "/" .. name
  utils.makeDirectory(object.directory, system.DocumentsDirectory)
  setmetatable(object, self)
  self.__index = self
  return object
end

function worldClass:configuration()
  if self._configuration == nil then
    if self.isBuiltIn then
      self._configuration = utils.loadJson("worlds/" .. self.name .. ".json")
    else
      self._configuration = utils.loadJson(self.directory .. ".json", system.DocumentsDirectory)
    end
    if not self._configuration.levels then
      self._configuration.levels = {}
    end
  end
  return self._configuration
end

function worldClass:deleteLevel(level)
  if not self.isBuiltIn then
    local configuration = self:configuration()
    local levelIndex = table.indexOf(configuration.levels, level.name)
    if levelIndex then
      table.remove(configuration.levels, levelIndex)
      if self._levels then
        table.remove(self._levels, levelIndex)
      end
    end
    if #configuration.levels > 0 then
      utils.saveJson(configuration, self.directory .. ".json", system.DocumentsDirectory)
    else
      utils.removeFile(self.directory .. ".json", system.DocumentsDirectory)
      utils.removeFile(self.directory, system.DocumentsDirectory)
      self.universe:deleteWorld(self)
    end
  end
end

function worldClass:levels()
  if self._levels == nil then
    self._levels = {}
    local configuration = self:configuration()
    for index = 1, #configuration.levels do
      self._levels[index] = levelClass:new(self, configuration.levels[index])
    end
  end
  return self._levels
end

function worldClass:newLevel()
  local levels = self:levels()
  local newLevelNumber = 1

  for _, level in pairs(levels) do
    local levelNumber = tonumber(level.name)
    if levelNumber >= newLevelNumber then
      newLevelNumber = levelNumber + 1
    end
  end

  local newLevel = levelClass:new(self, tostring(newLevelNumber))

  local newLevelConfiguration = newLevel:configuration()
  newLevelConfiguration.ball = { x = 150, y = 460 }
  newLevelConfiguration.stars = { one = 6, two = 4, three = 2 }
  newLevelConfiguration.obstacles = {}
  newLevelConfiguration.targets = {}

  return newLevel
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
      worldNumberOfStars = -1
    end
  end

  local progress = (numberOfFinishedLevels / numberOfLevels) * 25 + (totalNumberOfStars / (numberOfLevels * 3)) * 75
  return progress, worldNumberOfStars
end

function worldClass:saveLevel(level)
  if not self.isBuiltIn then
    local configuration = self:configuration()
    local levelIndex = table.indexOf(configuration.levels, level.name)
    if not levelIndex then
      levelIndex = #configuration.levels + 1
      configuration.levels[levelIndex] = level.name
      utils.saveJson(configuration, self.directory .. ".json", system.DocumentsDirectory)
      if self._levels then
        self._levels[levelIndex] = level
      end
      if levelIndex == 1 then
        self.universe:saveWorld(self)
      end
    end
  end
end

function worldClass:saveScores(scores)
  utils.saveJson(scores, self.directory .. "/scores.json", system.DocumentsDirectory)
  self._scores = scores
end

function worldClass:saveSpeedrun(runTime, levels)
  local speedruns = self:speedruns()
  local numberOfStars = 3
  local shouldSaveSpeedrun = false
  for _, level in pairs(levels) do
    numberOfStars = math.min(numberOfStars, level.numberOfStars)
  end
  for index = numberOfStars, 0, -1 do
    local speedrun = speedruns[tostring(index)]
    if speedrun == nil or speedrun.runTime > runTime then
      speedruns[tostring(index)] = { runTime = runTime, levels = levels }
      shouldSaveSpeedrun = true
    end
  end
  if shouldSaveSpeedrun then
    utils.saveJson(speedruns, self.directory .. "/speedruns.json", system.DocumentsDirectory)
    self._speedruns = speedruns
  end
end

function worldClass:scores()
  if self._scores == nil then
    self._scores = utils.loadJson(self.directory .. "/scores.json", system.DocumentsDirectory)
  end
  return self._scores
end

function worldClass:speedruns()
  if self._speedruns == nil then
    self._speedruns = utils.loadJson(self.directory .. "/speedruns.json", system.DocumentsDirectory)
  end
  return self._speedruns
end

return worldClass
