local json = require "json"
local lfs = require "lfs"
local utils = require "utils"

local defaultLocale = "en"
local locale = system.getPreference("ui", "language"):sub(1, 2):lower()
local supportedLocales = { "en", "fr" }

local function isLocaleSupported(locale)
  for _, supportedLocale in ipairs(supportedLocales) do
    if locale == supportedLocale then
      return true
    end
  end
  return false
end

local function loadTranslations(locale)
  return utils.loadJson("locales/" .. locale .. ".json")
end

if utils.isSimulator() then
  local localesPath = system.pathForFile("locales", system.ResourceDirectory)
  for filename in lfs.dir(localesPath) do
    local actualSupportedLocale = filename:match("^(.+)%.json$")
    if actualSupportedLocale then
      assert(
        isLocaleSupported(actualSupportedLocale),
        "'" .. actualSupportedLocale .. "' should be declared as a supported locale in i18n"
      )
    end
  end
end

local translations = loadTranslations(defaultLocale)

if locale ~= defaultLocale and isLocaleSupported(locale) then
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
