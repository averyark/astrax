local localizationUtil = {}

local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if not RunService:IsClient() then
	return "[localization] Only usable on the client"
end

local Promise = require(script.Parent.Parent.Promise)

local player = Players.LocalPlayer
local sourceLanguageCode = "en"

local playerTranslator, fallbackTranslator
local playerTranslatorPromise = Promise.new(function(resolve)
	playerTranslator = LocalizationService:GetTranslatorForPlayerAsync(player)
	resolve()
end)
local fallbackTranslatorPromise = Promise.new(function(resolve)
	fallbackTranslator = LocalizationService:GetTranslatorForLocaleAsync(sourceLanguageCode)
	resolve()
end)

function localizationUtil.__init()
	--playerTranslatorPromise:await()
	--fallbackTranslatorPromise:await()
end

function localizationUtil.await()
	playerTranslatorPromise:await()
	fallbackTranslatorPromise:await()
end

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
	if playerTranslatorPromise:awaitStaus() == Promise.Status.Resolved then
		return playerTranslator:Translate(object, text)
	end
	if fallbackTranslatorPromise:awaitStaus() == Promise.Status.Resolved then
		return fallbackTranslator:Translate(object, text)
	end
	return false
end

-- Create a FormatByKey() function that uses a fallback translator if the first fails to load or return successfully
function localizationUtil.translateByKey(key, arguments)
	local translation = ""
	local foundTranslation = false

	-- First tries to translate for the player's language (if a translator was found)
	if playerTranslatorPromise:awaitStaus() == Promise.Status.Resolved then
		foundTranslation = pcall(function()
			translation = playerTranslator:FormatByKey(key, arguments)
		end)
	end
	if fallbackTranslatorPromise:awaitStaus() == Promise.Status.Resolved and not foundTranslation then
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
