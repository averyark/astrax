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
local testDump = {["TEST_LOAD_TIME"] = {}}

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
	promise: typeof(Promise.new()),
	started: typeof(Promise.new()),
}

local initPromises = {}

local index
index = {
	__TEST_DUMP = testDump,
	_getRaw = function(mt)
		return mt
	end,
	_getProperty = function(mt, key)
		return mt[key]
	end,
}
index.promise = Promise.new(function(resolve)
	--[[local list = {
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
		debounce = require(script.debounce)
	}]]

	local promises = {}
	local resolveStartPromise

	index.started = Promise.new(function(r)
		resolveStartPromise = r
	end)

	for _, module in pairs(script:GetChildren()) do
		if isModule(module) then
			table.insert(
				promises,
				Promise.new(function(_resolve)
					local clock = os.clock()
					local expanded = require(module)
					_resolve()
					index[module.Name] = expanded
					cacheUtilitiesLib[module.Name] = expanded
					if t["function"](expanded.__init) then
						table.insert(
							initPromises,
							Promise.new(function(__resolve)
								expanded.__init()
								__resolve()
							end)
						)
					end
					testDump["TEST_LOAD_TIME"][module.Name] = os.clock() - clock
				end):catch(warn)
			)
		end
	end

	Promise.all(promises)
		:andThen(function()
			resolve()
		end)
		:catch(function(err)
			warn(("[fatal-init-error] Astra failed to run\n%s"):format(err))
		end)

	Promise.all(initPromises)
		:andThen(function()
			resolveStartPromise()
		end)
	print(promises, initPromises)
end)

local __self = setmetatable({
	__utilitiesMethods = cacheUtilitiesMethods,
	__utilitiesFolder = cacheUtilitiesModules,
	__utilitiesLib = cacheUtilitiesLib,
	__testModeEnabled = false,
}, {
	__index = index,
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
