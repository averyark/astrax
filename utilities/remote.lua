--[[
    FileName    > remote.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 01/07/2022
--]]

local remoteUtil = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Packages.t)
local Remote = require(ReplicatedStorage.Packages.Remote)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local instance = require(script.Parent.instance)

local remoteFolder
local remotes = {}

local isClient = RunService:IsClient()

if isClient then
	remoteFolder = ReplicatedStorage:WaitForChild("__network")
else
	remoteFolder = instance.new("Folder", {
		Name = "__network",
		Parent = ReplicatedStorage,
	})
end

local get = {}

get.Retrieve = function(self: remoteGet, ...: any)
	local cachedGUID = HttpService:GenerateGUID(false)
	local results
	local tr = coroutine.running()
	local connection
	connection = self._rs:Connect(function(guid, ...)
		if guid == cachedGUID then
			results = { ... }
			connection:Disconnect()
			coroutine.resume(tr, unpack(results))
		end
	end)
	self._maid:Add(connection)
	self._rs:Fire(cachedGUID, ...)
	return coroutine.yield()
end

--[[
	Connect to the remote

    Client
    ```lua
        remote:retrieve(2) -- "even"
        remote:retrieve(3) -- "odd"
    ```
    Server
	```lua
    remote:connect(function(s)
        return s/2 == math.round(s/2) and "even" or "odd";
    end)
	```
]]
get.Connect = function(self: remoteGet, callback: (...any) -> (...any)?)
	self._callback = callback
end

get.connect = get.Connect
get.retrieve = get.Retrieve
get.Get = get.Retrieve
get.get = get.Retrieve

local createClientRemote = function(remoteSignal)
	t.literal(true)(isClient) --assert(, "[remote] Attempted to create client remote on server")
	t.strict(t.instanceIsA("RemoteEvent")(remoteSignal))

	local rName, rType = remoteSignal.Name:match("(.+)__(.+)")
	if rType == "set" then
		local clientRemoteSignal = Remote.ClientRemoteSignal.new(remoteSignal)
		local self
		self = setmetatable({
			_rs = clientRemoteSignal,
			_type = "set",
			_maid = Janitor.new(),
		}, {
			__index = clientRemoteSignal,
		})

		self._maid:Add(self._rs._remote.Destroying:Connect(function()
			self._maid:Destroy()
			remotes[rName] = nil
		end))
		self._maid:Add(self._rs)

		remotes[rName] = self
		--print(("[remote][client] Created set remote: %s"):format(rName));

		return self
	elseif rType == "get" then
		local clientRemoteSignal = Remote.ClientRemoteSignal.new(remoteSignal)
		local self
		self = setmetatable({
			_rs = clientRemoteSignal,
			--[[_receiver = function(...)
                self._rs:Fire(self._callback(...)) -- pass results from callback function
            end,]]
			_maid = Janitor.new(),
		}, {
			__index = get,
		})

		--clientRemoteSignal:Connect(self._receiver)

		self._maid:Add(self._rs._remote.Destroying:Connect(function()
			self._maid:Destroy()
			self._receiver = nil
			remotes[rName] = nil
		end))
		self._maid:Add(self._rs)

		remotes[rName] = self
		--print(("[remote][client] Created get remote: %s"):format(rName));

		return self
	end
end

remoteUtil.new =
	function(remoteName: string, remoteType: ("set" | "get")?) -- : typeof(Remote.ClientRemoteSignal.new(Instance.new("RemoteEvent"))) | typeof(Remote.RemoteSignal.new())
		assert(
			isClient and remoteFolder:FindFirstChild(remoteName) or not isClient,
			"[remote] You can only create remote on the server"
		)
		assert(not instance.firstChildWithCondition(remoteFolder, function(insc)
			if insc.Name:match("(.+)__") == remoteName then
				return true
			end
		end), ("[remote] Remote name \"%s\" already exist, try another name"):format(remoteName))

		if remoteType == "set" or remoteType == nil then
			local remoteSignal = Remote.RemoteSignal.new()

			remoteSignal._remote.Name = remoteName .. "__set"
			remoteSignal._remote.Parent = remoteFolder

			local self
			self = setmetatable({
				_rs = remoteSignal,
				_type = "set",
				_maid = Janitor.new(),
			}, {
				__index = remoteSignal,
			})

			self._maid:Add(self._rs._remote.Destroying:Connect(function()
				self._maid:Destroy()
				remotes[remoteName] = nil
			end))
			self._maid:Add(self._rs)

			remotes[remoteName] = self
			--print(("[remote][server] Created set remote: %s"):format(remoteName));

			return self
		elseif remoteType == "get" then
			local remoteSignal = Remote.RemoteSignal.new()

			remoteSignal._remote.Name = remoteName .. "__get"
			remoteSignal._remote.Parent = remoteFolder

			local self
			self = setmetatable({
				_rs = remoteSignal,
				_type = "get",
				_index = {},
				_receiver = function(player, guid, ...)
					if not self._callback then
						if RunService:IsStudio() then
							warn("no callback?", debug.traceback())
						end
						return
					end
					self._rs:Fire(player, guid, self._callback(player, ...))
				end,
				_maid = Janitor.new(),
			}, {
				__index = get,
			})

			remoteSignal:Connect(self._receiver)

			self._maid:Add(self._rs._remote.Destroying:Connect(function()
				self._maid:Destroy()
				self._receiver = nil
				remotes[remoteName] = nil
			end))
			self._maid:Add(self._rs)

			remotes[remoteName] = self
			--print(("[remote][server] Created get remote: %s"):format(remoteName));

			return self
		else
			error("[remote] Invalid remoteType")
		end

		--return print(("[remote][%s] Created remote: %s"):format(isClient and "client" or "server", remoteName));
	end

remoteUtil.get = function(remoteName: string, noyield: boolean?): remote
	if not noyield then
		repeat
			task.wait()
		until remotes[remoteName]
	end
	return remotes[remoteName]
end

type remoteGet = typeof(remoteUtil.new("test", "get"))
type remoteSet = typeof(remoteUtil.new("test", "set"))
type remote = remoteGet | remoteSet

if isClient then
	task.spawn(function()
		instance.observeForChildrenThatIsA(remoteFolder, "RemoteEvent", function(insc)
			createClientRemote(insc)
		end)
	end)
end

return setmetatable({}, {
	__index = function(_, index)
		if remoteUtil[index] then
			return remoteUtil[index]
		else
			return remoteUtil.get(index, true)
		end
	end,
}) :: {
	[string]: remote,
	get: typeof(remoteUtil.get),
	new: typeof(remoteUtil.new),
}
