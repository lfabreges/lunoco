local json = require "json"

local defaultLocale = "en"
local locale = system.getPreference("ui", "language"):sub(1, 2):lower()

local function loadTranslations(locale)
  local filepath = system.pathForFile("locales/" .. locale .. ".json")
  if filepath then
    local content = json.decodeFile(filepath)
    if content then
      return content
    end
  end
  return {}
end

local translations = loadTranslations(defaultLocale)
local localizedTranslations = loadTranslations(locale)

for key, value in pairs(localizedTranslations) do
  translations[key] = value
end

local function i18n(key, ...)
  local translation = translations[key] or key
  return translation:format(...)
end

return i18n
