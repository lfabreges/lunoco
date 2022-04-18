local utils = require "modules.utils"

local levelClass = {}

function levelClass:new(world, name)
  local object = {}
  object.name = name
  object.world = world
  setmetatable(object, self)
  self.__index = self
  return object
end

function levelClass:configuration()
  if self._configuration == nil then
    if self.world.isBuiltIn then
      self._configuration = utils.loadJson(
        "worlds/" .. self.world.name .. "/" .. self.name .. ".json",
        system.ResourceDirectory
      )
    else
      self._configuration = utils.loadJson(
        "worlds/user/" .. self.world.name .. "/" .. self.name .. ".json",
        system.DocumentsDirectory
      )
    end
  end
  return self._configuration
end

function levelClass:create(parent)
  -- TODO Création du niveau
  -- Ajout de la physique séparemment ?
  -- Travaille le système pour permettre de simplement la désactiver lors de l'édition d'un niveau
  -- Comment faire le lien entre la configuration et les objets réels ?
end

function levelClass:saveScore(numberOfShots, numberOfStars)
  local worldScores = self.world:scores()
  if worldScores[self.name] == nil or worldScores[self.name].numberOfShots > numberOfShots then
    worldScores[self.name] = { numberOfShots = numberOfShots, numberOfStars = numberOfStars }
    self.world:saveScores(worldScores)
  end
end

return levelClass
