--!strict
--[[
    FileName    > player.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 16/07/2022
--]]

-- died trying to silence Roblox Types
local playerUtil = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local remote = require(script.Parent.remote)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local deb = require(script.Parent.debounce)

local isClient = RunService:IsClient()

local registry = {
	clients = {},
	callbacks = {},
	allCache = {},
	allLocalCache = {},
	client = {},
} :: {
	clients: { [Player]: mt },
	client: mt,
	allLocalCache: { any },
	callbacks: { { callback: (mt) -> (), priority: number } },
	allCache: { any },
}
local mt: mt = {}

function mt:__changed(index, value, cache)
	self.changed:Fire(index, value, cache)
end

function mt:editLocal(index, value)
	local valueCache
	if isClient then
		local rawValueCache = self._properties.client[index]
		valueCache = typeof(rawValueCache) == "table" and TableUtil.DeepCopyTable(rawValueCache) or rawValueCache
		self._properties.client[index] = value
		self._clientChanged:Fire(index, value, valueCache)
	else
		local rawValueCache = self._properties.server[index]
		valueCache = typeof(rawValueCache) == "table" and TableUtil.DeepCopyTable(rawValueCache) or rawValueCache
		self._properties.server[index] = value
		self._serverChanged:Fire(index, value, valueCache)
	end
	self.localChanged:Fire(index, value, valueCache)
	self:__changed(index, value, valueCache)
end

function mt:editCross(index, value)
	if isClient then
		remote.get("__playerUtil__modifyProperty"):Fire(index, value) -- cross editing
	elseif not isClient then
		remote.get("__playerUtil__modifyProperty"):Fire(self.object, index, value)
	end
end

function mt:editServer(index, value)
	if isClient then
		self:editCross(index, value) -- client-server/server-client edit
	else
		self:editLocal(index, value) -- client-client/server-server edit
	end
end

function mt:editClient(index, value)
	if not isClient then
		self:editCross(index, value) -- client-server/server-client edit
	else
		self:editLocal(index, value) -- client-client/server-server edit
	end
end

function mt:edit(where: string, index: any, value: any)
	if where == "server" then
		self:editServer(index, value)
	elseif where == "client" then
		self:editClient(index, value)
	elseif where == "local" then
		self:editLocal(index, value)
	elseif where == "cross" then
		self:editCross(index, value)
	end
end

function mt:__onCrossEdited(index, value)
	local valueCache
	if isClient then
		local rawValueCache = self._properties.client[index]
		valueCache = typeof(rawValueCache) == "table" and TableUtil.DeepCopyTable(rawValueCache) or rawValueCache
		self.server[index] = value
		self._serverChanged:Fire(index, value, valueCache)
	else
		local rawValueCache = self._properties.client[index]
		valueCache = typeof(rawValueCache) == "table" and TableUtil.DeepCopyTable(rawValueCache) or rawValueCache
		self.client[index] = value
		self._clientChanged:Fire(index, value, valueCache)
	end
	self:__changed(index, value, valueCache)
end

function mt:getLocal(index: any): any?
	if isClient then
		return self._properties.client[index]
	else
		return self._properties.server[index]
	end
end

function mt:getCross(index): any?
	if isClient then
		return self._properties.server[index]
	else
		return self._properties.client[index]
	end
end

-- change request: Server-Server and Client-Client should be isolated
local initPlayer = function(player: Player, model: { [any]: any }?)
	assert(t.instanceIsA("Player")(player), "player expected")
	local self
	self = setmetatable({
		_serverChanged = Signal.new(),
		_clientChanged = Signal.new(),
		localChanged = Signal.new(),
		_properties = {
			server = {},
			client = isClient and registry.allCache or {},
		},
		maid = Janitor.new(),
		changed = Signal.new(),
		object = player,
		server = setmetatable({}, {
			__newindex = function(_self, index, value)
				self:editClient(index, value)
			end,
			__index = function(_self, index)
				if index == "changed" then
					return self._serverChanged
				end
				return self._properties.server[index]
			end,
		}),
		client = setmetatable({}, {
			__newindex = function(_, index, value)
				self:editServer(index, value)
			end,
			__index = function(_self, index)
				if index == "changed" then
					return self._clientChanged
				end
				return self._properties.client[index]
			end,
		}),
	}, {
		__newindex = function(_, index, value)
			self:editLocal(index, value)
		end,
		__index = function(_, index)
			local response = mt.getLocal(self :: mt, index)
			if response ~= nil then
				return response
			end
			return mt[index]
		end,
	})

	for _, sig in pairs(self) do
		if Signal.Is(sig) then
			self.maid:Add(sig)
		end
	end

	self.maid:Add(self.object.AncestryChanged:Connect(function()
		if not self.object:IsDescendantOf(Players) then
			if not isClient then
				registry.clients[player] = nil
			end
			self.maid:Destroy()
		end
	end))

	if not isClient then
		registry.clients[player] = self
	else
		if model then
			self._properties.client = model
		end

		registry.client = self
		--print(registry.client)
	end

	table.sort(
		registry.callbacks,
		function(a: { callback: (mt) -> (), priority: number }, b: { callback: (mt) -> (), priority: number })
			if a.priority < b.priority then
				return true
			end
			return false
		end
	)

	for _, dat in pairs(registry.callbacks) do
		Promise.try(function()
			dat.callback(self)
		end)
	end

	return self :: mt
end

mt.__index = mt

playerUtil.observe = function(callback: (playerObject: mt) -> (), priority: number?)
	--table.insert(registry.callbacks, callback)
	if not priority then
		table.insert(registry.callbacks, {
			callback = callback,
			priority = #registry.callbacks,
		})
	else
		table.insert(registry.callbacks, {
			callback = callback,
			priority = priority,
		})
	end
	for _, client in registry.clients do -- priority is ignored
		callback(client)
	end
end

playerUtil.me = function(): mt
	repeat
		task.wait()
	until registry.client
	return registry.client :: mt
end

local __mt = {
	__index = function(_self, _index): any
		if _index == "editLocal" then
			return function(_, index, value: any)
				for _, self in pairs(_self.target) do
					if not _self.promises then
						_self.promises = {}
					end
					table.insert(
						_self.promises,
						Promise.try(function()
							self:editLocal(index, value)
						end)
					)
				end
				return _self
			end
		elseif _index == "edit" then
			return function(_, index, value: any)
				if not _self.promises then
					_self.promises = {}
				end
				for _, self in pairs(_self.target) do
					table.insert(
						_self.promises,
						Promise.try(function()
							self:editClient(index, value)
						end)
					)
				end
				return _self
			end
		elseif _index == "iterate" then
			return function(_, func)
				if not _self.promises then
					_self.promises = {}
				end
				for _, self in pairs(_self.target) do
					table.insert(
						_self.promises,
						Promise.try(function()
							func(self)
						end)
					)
				end
				return _self
			end
		end
		return
	end,
}

local exceptArray = function(t1, t2)
	local t3 = {}
	for i, j in t1 do
		if not table.find(t2, j) then
			table.insert(t3, j)
		end
	end
	return t3
end

local except = function(t1, t2)
	local t3 = {}
	for i, j in t1 do
		if not t2[i] then
			t3[i] = j
		end
	end
	return t3
end

local convert = function(plrs)
	local tb = {}
	for _, player in plrs do
		if registry.clients[player] then
			table.insert(tb, registry.clients[player])
		end
	end
	return tb
end

playerUtil.all = function()
	assert(not isClient, "all is not accessible on the client")
	return setmetatable({ target = registry.clients }, __mt) :: __mt
end

playerUtil.single = function(player: Player)
	assert(not isClient, "all is not accessible on the client")
	assert(t.instanceIsA("Player")(player), "Player expected")
	return registry.clients[player :: Player] :: mt
end

playerUtil.some = function(players: { Player? })
	assert(not isClient, "all is not accessible on the client")
	return setmetatable({ target = convert(players) :: mt }, __mt) :: __mt
end

playerUtil.except = function(players: { Player? })
	assert(not isClient, "all is not accessible on the client")
	return setmetatable({ target = except(registry.clients, convert(players)) }, __mt) :: __mt
end

local init = function()
	Promise.new(function(resolve)
		playerUtil.observe(function(playerObject)
			playerObject.debounce = deb.newGroup(playerObject.object)
			playerObject.maid:Add(playerObject.debounce)
		end, -1)
		resolve()
	end)
	if not isClient then
		Players.PlayerAdded:Connect(initPlayer)
		for _, player in Players:GetPlayers() do
			Promise.try(function()
				if not registry.clients[player] then
					initPlayer(player, registry.allLocalCache)
				end
			end)
		end
		remote.new("__playerUtil__propertyModified"):Connect(function(player, index, value)
			playerUtil.single(player):__onCrossEdited(index, value)
		end)
		remote.new("__playerUtil__retrieveClientModel", "get"):Connect(function(player)
			return registry.clients[player]._properties.client
		end)
		remote.new("__playerUtil__modifyProperty"):Connect(function(player, index, value)
			local self = registry.clients[player] :: mt
			self:editLocal(index, value)
		end)
	else
		remote.get("__playerUtil__propertyModified"):Connect(function(index, value)
			registry.client:__onCrossEdited(index, value)
		end)
		remote.get("__playerUtil__modifyProperty"):Connect(function(index, value)
			local self = registry.client :: mt
			self:editLocal(index, value)
		end)
		initPlayer(Players.LocalPlayer, remote.get("__playerUtil__retrieveClientModel"):Retrieve()) -- yield
	end
end

type __mt = { target: { mt } } & (typeof(setmetatable({}, __mt))) & ({
	editLocal: ({}, any, any) -> __mt,
	edit: ({}, any, any) -> __mt,
	iterate: ({}, (playerObject: mt) -> ()) -> __mt,
})
type signal = typeof(Signal.new())
type janitor = typeof(Janitor.new())
export type mt = typeof(initPlayer(Instance.new("Player"))) & {
	debounce: deb.debounceGroup,
	data: ({
		storage: {},
		profile: typeof(require(ReplicatedStorage.Packages.ProfileService).GetProfileStore():LoadProfileAsync()),
		capture: () -> (),
		listen: () -> (),
		changed: signal,
		maid: janitor,
		player: Player,
	}),
	localChanged: signal,
	changed: signal,
	maid: janitor,
	object: Player,
	server: { changed: signal },
	client: { changed: signal },
	_properties: { client: { [any]: any }, server: { [any]: any } },
}
--[[({
	editLocal: ({}, any, any) -> __mt,
	edit: ({}, any, any) -> __mt,
	iterate: ({}, (playerObject: mt) -> ()) -> __mt,
})]]
task.spawn(init)

return playerUtil --[[:: {
    me: () -> (mt),
    observe: ((mt) -> ()) -> (),
    all: () -> (typeof(playerUtil.all())),
    single: (Player) -> (typeof(playerUtil.single(Instance.new("Player")))),
    some: ({Player}) -> (typeof(playerUtil.some({}))),
    except: ({Player}) -> (typeof(playerUtil.some({})))
}; --[[:: mt & {
    client: mt,
    observe: ((mt) -> ()) -> (),
    all: () -> (typeof(playerUtil.all())),
    single: (Player) -> (typeof(playerUtil.single(Instance.new("Player")))),
    some: ({Player}) -> (typeof(playerUtil.some({}))),
    except: ({Player}) -> (typeof(playerUtil.some({})))
};]]
