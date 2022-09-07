local ReplicatedStorage = game:GetService("ReplicatedStorage")

local utilties = require(ReplicatedStorage.utilities)

local Cmdr = require(ReplicatedStorage.ServerPackages.Cmdr)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Loader = require(ReplicatedStorage.Packages.Loader)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Promise = require(ReplicatedStorage.Packages.Promise)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local t = require(ReplicatedStorage.Packages.t)
local TestEZ = require(ReplicatedStorage.Packages.TestEZ)

utilties.data.start({}, "Testing")

Loader.LoadDescendants(script.Parent:FindFirstChild("server"))

Cmdr:RegisterDefaultCommands()
Cmdr:RegisterHooksIn(ReplicatedStorage:WaitForChild("Hooks"))
Cmdr:RegisterCommandsIn(ReplicatedStorage:WaitForChild("Commands"))

Knit.Start()
	:andThen(function()
		print(("[%s-%s] Knit Initialized; developed by @arkizen."):format(game.PrivateServerId, game.JobId))
	end)
	:catch(warn)
