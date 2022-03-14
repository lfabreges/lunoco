local json = require "json"
local utils = require "utils"

local defaultLocale = "en"
local locale = system.getPreference("ui", "language"):sub(1, 2):lower()

local function loadTranslations(locale)
  return utils.loadJson("locales/" .. locale .. ".json")
end

local translations = loadTranslations(defaultLocale)

-- TODO Add supported locales here
if locale == "" then
  local localizedTranslations = loadTranslations(locale)
  for key, value in pairs(localizedTranslations) do
    translations[key] = value
  end
end

local function i18n(key, ...)
  local translation = translations[key] or key
  return translation:format(...)
end

return i18n
