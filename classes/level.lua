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
    self._configuration = utils.loadJson(
      "worlds/" .. self.world.name .. "/" .. self.name .. ".json",
      self.world.baseDirectory
    )
  end
  return self._configuration
end

function levelClass:create(parent)
  -- TODO Création du niveau
  -- Ajout de la physique séparemment ?
  -- Travaille le système pour permettre de simplement la désactiver lors de l'édition d'un niveau
  -- Comment faire le lien entre la configuration et les objets réels ?
end

return levelClass
