local localizationUtil = {}

local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local sourceLanguageCode = "en"

local playerTranslator, fallbackTranslator
local foundPlayerTranslator = pcall(function()
	playerTranslator = LocalizationService:GetTranslatorForPlayerAsync(player)
end)
local foundFallbackTranslator = pcall(function()
	fallbackTranslator = LocalizationService:GetTranslatorForLocaleAsync(sourceLanguageCode)
end)

-- Create a method TranslationHelper.setLanguage to load a new translation for the TranslationHelper
function localizationUtil.setLanguage(newLanguageCode)
	if sourceLanguageCode ~= newLanguageCode then
		local success, newPlayerTranslator = pcall(function()
			return LocalizationService:GetTranslatorForLocaleAsync(newLanguageCode)
		end)

		--Only override current playerTranslator if the new one is valid (fallbackTranslator remains as experience's source language)
		if success and newPlayerTranslator then
			playerTranslator = newPlayerTranslator
			return true
		end
	end
	return false
end

-- Create a Translate function that uses a fallback translator if the first fails to load or return successfully. You can also set the referenced object to default to the generic game object
function localizationUtil.translate(text, object)
	if not object then
		object = game
	end
	local translation = ""
	local foundTranslation = false
	if foundPlayerTranslator then
		return playerTranslator:Translate(object, text)
	end
	if foundFallbackTranslator then
		return fallbackTranslator:Translate(object, text)
	end
	return false
end

-- Create a FormatByKey() function that uses a fallback translator if the first fails to load or return successfully
function localizationUtil.translateByKey(key, arguments)
	local translation = ""
	local foundTranslation = false

	-- First tries to translate for the player's language (if a translator was found)
	if foundPlayerTranslator then
		foundTranslation = pcall(function()
			translation = playerTranslator:FormatByKey(key, arguments)
		end)
	end
	if foundFallbackTranslator and not foundTranslation then
		foundTranslation = pcall(function()
			translation = fallbackTranslator:FormatByKey(key, arguments)
		end)
	end
	if foundTranslation then
		return translation
	else
		return false
	end
end

return localizationUtil
