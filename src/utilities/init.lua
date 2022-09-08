--!strict
--[[
    FileName    > utilities.init
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 19/05/2022
--]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cacheUtilitiesModules = {}
local cacheUtilitiesMethods = {}
local cacheUtilitiesLib = {}

-- Packages
local Janitor = require(script.Parent.Janitor)
local Promise = require(script.Parent.Promise)
local t = require(script.Parent.t)
local TestEZ = require(script.Parent.TestEZ)

-- types
local isFolder = t.instanceIsA("Folder")
local isModule = t.instanceIsA("ModuleScript")
local isFunction = t.typeof("function")

local utilWarn = function(...: string | number)
	warn("utilWarn:", ..., debug.traceback("\n\n", 2))
end

local isSpecFile = function(module: ModuleScript)
	assert(isModule(module), "utilError: expected module\n")
	return module.Name:match("(.+)%.spec$")
end

local isTypeFile = function(module: ModuleScript)
	assert(isModule(module), "utilError: expected module\n")
	return module.Name:match("(.+)%.type$")
end

local isSpecialFile = function(module: ModuleScript)
	assert(isModule(module), "utilError: expected module\n")
	return isTypeFile(module) or isSpecFile(module)
end

local utilityCache = Instance.new("Folder")
utilityCache.Parent = workspace
utilityCache.Name = "__utilityCache"

local run = function()
	for _, module in script:GetChildren() do
		if isModule(module) and not isSpecialFile(module) then
			cacheUtilitiesMethods[module.Name] = module
			local expand = require(module)
			cacheUtilitiesLib[module.Name] = expand
			for key, value in expand do
				if cacheUtilitiesMethods[key] then
					--utilWarn("Method shadowing;", key, module.Name)
					continue
				end
				if not isFunction(value) then
					continue
				end
				cacheUtilitiesMethods[key] = value
			end
		end
	end
end

run()

type typesList = {
	instance: typeof(require(script.instance)),
	tween: typeof(require(script.tween)),
	string: typeof(require(script.string)),
	number: typeof(require(script.number)),
	ui: typeof(require(script.ui)),
	remote: typeof(require(script.remote)),
	player: typeof(require(script.player)),
	data: typeof(require(script.data)),
	localization: typeof(require(script.localization)),
	sound: typeof(require(script.sound)),
	debounce: typeof(require(script.debounce)),
}

local __self = setmetatable({
	__utilitiesMethods = cacheUtilitiesMethods,
	__utilitiesFolder = cacheUtilitiesModules,
	__utilitiesLib = cacheUtilitiesLib,
	__testModeEnabled = RunService:IsStudio() and true or false,
}, {
	__index = {
		instance = require(script.instance),
		tween = require(script.tween),
		string = require(script.string),
		number = require(script.number),
		remote = require(script.remote),
		ui = require(script.ui),
		player = require(script.player), -- CLIENT UTIL YIELDS
		data = require(script.data),
		localization = require(script.localization),
		sound = require(script.sound),
		debounce = require(script.debounce),
		_getRaw = function(mt)
			return mt
		end,
		_getProperty = function(mt, key)
			return mt[key]
		end,
	},
	__newindex = function(mt, key, value)
		if key == "test" then
			if value then
				utilWarn("TestMode is enabled")
				TestEZ.TestBootstrap:run({
					ReplicatedStorage.utilities,
				})
			elseif not value then
				utilWarn("TestMode is disabled")
			end
			rawset(mt, "__testModeEnabled", value)
		else
			rawset(mt, key, value)
		end
	end,
	__tostring = function(mt)
		return ("<utilities>(#%s)"):format(tostring(mt.__testModeEnabled))
	end,
})

return __self :: typesList --[[& {_getProperty: typeof(__self._getProperty), _getRaw: typeof(__self._getRaw)}]]
