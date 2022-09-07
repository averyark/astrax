--[[
    FileName    > data.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 17/07/2022
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local t = require(ReplicatedStorage.Packages.t)
local Promise = require(ReplicatedStorage.Packages.Promise)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local playerUtil = require(script.Parent.player)
local remote = require(script.Parent.remote)

local isClient = RunService:IsClient()

local dataUtil
dataUtil = {
	profileStore = nil,
	name = "testing",
	list = {},
	callbacks = {},
	onChangeCallbacks = {},
}

local data = {}

local valueFromPath = function(_tb, _path)
	local ref = _tb
	for _, v in _path do
		ref = ref[v]
	end
	return ref
end

local decipher = function(_tb, _path)
	local last = #_path
	local lastTb, lastKey = _tb, _path[last]
	for i, v in _path do
		if i ~= last then
			lastTb = lastTb[v]
		end
	end
	return lastTb, lastKey
end

local compare
compare = function(tb, otherTb, path, changes) -- failed
	path = path or {}
	changes = changes or {}

	for k, value in tb do
		local otherValue = otherTb[k] -- after

		if typeof(value) == "table" and typeof(otherValue) == "table" then
			local newPath = TableUtil.DeepCopyTable(path)
			table.insert(newPath, k)
			compare(value, otherValue, newPath, changes)
			continue
		end

		if value ~= otherValue then
			local newPath = TableUtil.DeepCopyTable(path)
			table.insert(newPath, k)
			table.insert(changes, {
				path = newPath,
				value = { old = otherValue, new = value },
			})
			continue
		end
	end

	return changes
end

local matchPath = function(tb, otherTb)
	local match = 0
	for i, j in tb do
		if otherTb[i] == j then
			match = i
		else
			break
		end
	end
	return match
end

local fireListeners = function(new, old, changes, player)
	for _, change in changes do
		local max = #change.path
		for _, onChangeMeta in pairs(dataUtil.onChangeCallbacks) do
			local nm = matchPath(change.path, onChangeMeta.path)
			if nm == 0 then
				continue
			end
			if nm == max then
				if player then
					if onChangeMeta.player and not player == onChangeMeta.player then
						continue
					end
					Promise.try(onChangeMeta.callback, player, {
						new = change.value.new,
						old = change.value.old,
					})
				else
					Promise.try(onChangeMeta.callback, {
						new = change.value.new,
						old = change.value.old,
					})
				end
			else
				if onChangeMeta.shouldListenToDescendantChange then
					if player then
						if onChangeMeta.player and not player == onChangeMeta.player then
							continue
						end
						Promise.try(onChangeMeta.callback, player, {
							new = valueFromPath(new, onChangeMeta.path),
							old = valueFromPath(old, onChangeMeta.path),
						})
					else
						Promise.try(onChangeMeta.callback, {
							new = valueFromPath(new, onChangeMeta.path),
							old = valueFromPath(old, onChangeMeta.path),
						})
					end
				end
			end
		end
	end
end

function data:capture(callback: (storage: {}) -> ())
	assert(not isClient, "You cannot use this method on the client")
	if not callback then
		return
	end
	local snapchot = TableUtil.DeepCopyTable(self.storage)
	callback(self.storage) -- wait for callback
	local changes = compare(self.storage, snapchot)
	fireListeners(self.storage, snapchot, changes, self.player)
	remote.get("__dataUtil_applyDataChange"):Fire(self.player, changes)
end

function data:listen(path: { string }, callback: () -> (), shouldListenToDescendantChange)
	table.insert(dataUtil.onChangeCallbacks, {
		player = self.player,
		callback = callback,
		path = path,
		shouldListenToDescendantChange = shouldListenToDescendantChange or true,
	})
end

data.__index = data

function data.new(player)
	assert(not isClient, "You cannot use this method on the client")
	local self = setmetatable({
		profile = dataUtil.profileStore:LoadProfileAsync("player_" .. player.UserId),
		changed = Signal.new(),
		maid = Janitor.new(),
		player = player,
		storage = {},
	}, data)

	self.storage = self.profile.Data
	self.profile:Reconcile()

	self.maid:Add(self.player.AncestryChanged:Connect(function()
		if not player:IsDescendantOf(Players) then
			self.maid:Destroy()
			self.profile:Release()
			dataUtil.list[player] = nil
		end
	end))

	dataUtil.list[player] = self
	playerUtil.single(player).data = self

	for _, f in pairs(dataUtil.callbacks) do
		Promise.try(f, playerUtil.single(player), self)
	end

	for _, sig in pairs(self) do
		if Signal.Is(sig) then
			self.maid:Add(sig)
		end
	end

	return self
end

--[[
	Captures the changes made inside the callback and passed to listeners
    ```lua
    dataUtil.capture(player, function(storage : {})
        storage.Addition += 20
        storage.Boolean = true
        storage.Boolean = not storage.Bolean
    end)
    ```
]]
function dataUtil.capture(player: Player, callback: (storage: {}) -> ())
	assert(not isClient, "You cannot use this method on the client")
	if not callback then
		return
	end
	local storage = dataUtil.get(player).storage
	local snapchot = TableUtil.DeepCopyTable(storage)
	callback(storage) -- wait for callback
	local changes = compare(storage, snapchot)
	fireListeners(storage, snapchot, changes)
	remote.get("__dataUtil_applyDataChange"):Fire(player, changes)
end

--[[
    Sends the entire player data over to the client instead of just the changes. This method is much more costly on the network while also disallow change tracking.
    ```lua
    data.get(player).storage.Money = 100
    data.update(player)
    ```
]]
function dataUtil.update(player: Player)
	remote.get("__dataUtil_updateClientData"):Fire(player, dataUtil.get(player).storage)
end

--[[
	Retrieve the data object of the given player. Use `dataUtil.promise(player)` to guarantee the data object when it loads successfully
    ```lua
    dataUtil.get(player)
    ```
]]
function dataUtil.get(player: Player): data
	assert(not isClient, "You cannot use this method on the client")
	return dataUtil.list[player]
end

--[[
    Returns a promise that resolves when the player data loads and the data object is created.
    ```lua
    dataUtil.promise(player):andThen(function(playerData)
        print(playerData.storage)
    end)
    ```
]]
function dataUtil.promise(player: Player): typeof(Promise.new())
	assert(not isClient, "You cannot use this method on the client")
	return Promise.new(function(resolve, reject, onCancel)
		local cancelled = false
		onCancel(function()
			cancelled = true
		end)

		repeat
			task.wait()
		until dataUtil.list[player] or cancelled

		if not dataUtil.list[player] then
			return reject()
		end

		return resolve(dataUtil.list[player])
	end):timeout(20):catch(function(err)
		warn(tostring(err))
	end)
end

--[[
    Observe for player's data entry. Callback includes the playerUtility object of the player and the data object
    ```lua
    dataUtil.observe(function(playerObject, playerData)
        print(playerObject.data == playerData) -- output: true
    end)
    ```
]]
function dataUtil.observe(callback: (playerObject: playerUtil.mt, playerData: data) -> ())
	assert(not isClient, "You cannot use this method on the client")
	table.insert(dataUtil.callbacks, callback)
	for player, self in dataUtil.list do
		callback(playerUtil.single(player), self)
	end
end

--[[
    Yields the thread until the data is loaded on the client
    ```lua
    print(dataUtil.yield().Money)
    ```
]]
function dataUtil.yield()
	assert(isClient, "You cannot use this method on the server")
	repeat
		task.wait()
	until dataUtil.storage
	return dataUtil.storage
end

--[[
    Listens for a particular data change.
    The callback won't receive calls when a subtable's value was changed if false is passed as the 3rd arguement.
    Note: The first parameter passed to the callback is always the player on the server since callback is fired for all player's data change with that particular change on the server.

    Client
    ```lua
    dataUtil.listen({"Settings", "SoundEffect"}, function(change)
        if change.new == false then
            SoundEffect.Volume = 0
        end
    end)
    ```

    Server
    ```lua
    dataUtil.listen({"Money"}, function(player, change)
        local difference = change.new - change.old
        print(difference)
    end)
    ```
]]
function dataUtil.listen(
	path: { string },
	callback: (changes: { new: any, old: any }) -> (),
	initial: (true | (data: any) -> ())?,
	shouldListenToDescendantChange: boolean?
)
	table.insert(dataUtil.onChangeCallbacks, {
		callback = callback,
		path = path,
		shouldListenToDescendantChange = shouldListenToDescendantChange == nil and true
			or shouldListenToDescendantChange,
	})
	if typeof(initial) == "boolean" then
		callback({ new = valueFromPath(dataUtil.yield(), path) })
	elseif typeof(initial) == "function" then
		initial(valueFromPath(dataUtil.yield(), path))
	end
end

function dataUtil.start(template: { [any]: any }?, name: string?)
	if not isClient then
		local ProfileService = require(ReplicatedStorage.Packages.ProfileService)
		dataUtil.profileStore = ProfileService.GetProfileStore(name or dataUtil.name, template)

		playerUtil.observe(function(self)
			self.data = data.new(self.object)
		end, -1)
		remote.new("__dataUtil__retrieveData", "get"):Connect(function(player)
			return select(2, dataUtil.promise(player):await()).storage
		end)
		remote.new("__dataUtil_updateClientData")
		remote.new("__dataUtil_applyDataChange")
	else
		remote.get("__dataUtil_updateClientData"):Connect(function(_data)
			dataUtil.storage = _data
		end)
		remote.get("__dataUtil_applyDataChange"):Connect(function(changes)
			debug.profilebegin("__dataUtil__dataApplicance")
			local snapchot = TableUtil.DeepCopyTable(dataUtil.storage)
			for _, change in changes do -- apply changes
				local last, key = decipher(dataUtil.storage, change.path)
				last[key] = change.value.new
			end
			fireListeners(dataUtil.storage, snapchot, changes)
			debug.profileend()
		end)
		dataUtil.storage = remote.get("__dataUtil__retrieveData"):Retrieve()
		playerUtil.me().data = dataUtil.storage
	end
end

export type data = typeof(data.new())
--type profileStore = typeof(require(ReplicatedStorage.Packages.ProfileService).GetProfileStore("", {}))

return dataUtil
