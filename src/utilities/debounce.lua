--[[
    FileName    > debounce.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 31/07/2022
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local instance = require(script.Parent.instance)
local t = require(ReplicatedStorage.Packages.t)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Promise = require(ReplicatedStorage.Packages.Promise)

local debounceUtil = {}

local debounce = {}
local debounceGroup = {}

type debounceTypes = "time" | "boolean" | "function"

debounceUtil.state = {
	["Active"] = 1,
	["Inactive"] = 2,
	["Suspended"] = 3,
}
debounceUtil.type = {
	["Timer"] = 1,
	["Boolean"] = 2,
}
debounceUtil.groups = {}
debounceUtil.indexed = {}

debounce.new = function(identifier: string, _type: types, ...)
	local self
	self = setmetatable({
		Name = identifier,
		_type = _type,
		_loaded = false,
		_group = "none",
	}, {
		__index = function(_, index)
			if index == "State" then
				if _type == debounceUtil.type.Timer then
					if t.number(self._tL) and t.number(self._int) then
						return if os.clock() - self._tL < self._int
							then debounceUtil.state.Inactive
							else debounceUtil.state.Active
					end
				elseif _type == debounceUtil.type.Boolean then
					if t.boolean(self._bool) then
						return if self._bool then debounceUtil.state.Inactive else debounceUtil.state.Active
					end
				end
				return debounceUtil.state.Suspended
			end
			return debounce[index]
		end,
	})

	if _type == debounceUtil.type.Timer then
		self._int = select(1, ...)
		self._tL = os.clock()
	elseif _type == debounceUtil.type.Boolean then
		self._bool = false
	end

	return self :: debounce
end

--[[
    Sets the debounceObject state to the passed params.
    ```lua
    local debounceObject = debounce.new("something", debounceUtil.type.Timer, 2)
    debounceObject:set(os.clock() + 5) -- 5 second in the future
    task.wait(2)
    if debounceObject:isLocked() then
        -- Still locked
    end
    task.wait(3)
    if debounceObject:isLocked() then
    end
    -- Not locked
    ```
--]]
function debounce:set(...)
	if self._type == debounceUtil.type.Timer then
		self._tL = ...
	elseif self._type == debounceUtil.type.Boolean then
		self._bool = ...
	end
	return self :: debounce
end

--[[
    Locks the debounce forcefully. Depending on the type of the debounce, locking will only reset the timer
    ```lua
    local debounceObject = debounce.new("something", debounceUtil.type.Timer, 2)
    debounceObject:lock()
    if debounceObject:isLocked() then -- always false
        return
    end
    ```
--]]
function debounce:lock()
	if self._type == debounceUtil.type.Timer then
		self._tL = os.clock()
	elseif self._type == debounceUtil.type.Boolean then
		self._bool = not self._bool
	end
	return self :: debounce
end

--[[
    This method is used to determine whether the debounce is active or inactive.
    ```lua
    local debounceObject = debounce.new("something", debounceUtil.type.Timer, 2)
    if debounceObject:isLocked() then
        return
    end
    ```
--]]
function debounce:isLocked()
	if self.State == debounceUtil.state.Active then
		return false
	end
	return true
end

--[[
    Sets the debounce to a group. Grouping a debounce allows bulk tasks.
    ```lua
    local debounceObject = debounce.new("something", debounceUtil.type.Timer, 2)
    local group = debounceGroup.new("something")
    debounceObject:group("something")
    group:Destroy()
    ```
--]]
function debounce:group(group: string)
	self._group = group
	return self :: debounce
end

--[[
    Store a hard reference of the debounce object to prevent it from getting gced.
    ```lua
    local debounceObject = debounce.new("something", debounceUtil.type.Timer, 2)
    debounceObject:index()
    ```
--]]
function debounce:index()
	debounceUtil.indexed[self.Name] = self
	return self :: debounce
end

--[[
    Removes inner reference of the debounce object, putting it on schedule for gc.
    ```lua
    local debounceObject = debounce.new("something", debounceUtil.type.Timer, 2)
    debounceObject:Destroy()
    ```
--]]
function debounce:Destroy()
	debounceUtil.indexed[self.Name] = nil
end

debounceGroup.new = function(group: any, contents: { debounce? })
	local self = setmetatable({
		Identifier = group,
		Contents = t.table(contents) and contents or {},
	}, debounceGroup)

	return self :: debounceGroup
end

--[[
    Creates a new debounceGroupObject. debounceGroupObject is used to group multiple debounces, allowing bulk tasks.
    ```lua
    local debounceGroup = debounceGroup.new()
    debounce.new("somethingElse", debounceUtil.type.Timer, 2):index() -- Creates an internal reference using :index()
    debounceGroup:add(debounce.new("something", debounceUtil.type.Timer, 2))
    debounceGroup:add("somethingElse")
    ```
--]]
function debounceGroup:add(_d: string | debounce)
	if t.string(_d) then
		assert(
			debounceUtil.indexed[_d],
			("[debounce] none of the indexed debounce matches \"%s\""):format(_d :: string)
		)
		self.Contents[_d] = debounceUtil.indexed[_d]
		debounceUtil.indexed[_d]._group = self.Identifier
		return _d
	end
	local db = self.Contents[(_d :: debounce).Name]
	db._group = self.Identifier
	self.Contents[db.Name] = db
	return self :: debounceGroup
end

--[[
    Creates a new debounceGroupObject. debounceGroupObject is used to group multiple debounces, allowing bulk tasks.
    ```lua
    local debounceGroup = debounceGroup.new()
    debounceGroup:add(debounce.new("something", debounceUtil.type.Timer, 2):index())
    debounceGroup:remove("something")
    ```
--]]
function debounceGroup:remove(_d: string | number)
	self.Contents[_d] = nil
	return self :: debounceGroup
end

--[[
    Creates a debounceObject. The debounceObject is catergorized to the group automatically.

    Sugar for `debounce.new(identifier, type, ...):group(groupIdentifier)`
    ```lua
    local debounceGroup = debounceGroup.new()
    debounceGroup:make("something", debounceUtil.types.Timer)
    debounceGroup:remove("something")
    ```
--]]
function debounceGroup:make(identifier: string, _type: types, ...)
	return debounce.new(identifier, _type, ...):group(self.Identifier)
end

--[[
    Remove all debounces connected to the group
    ```lua
    local debounceGroup = debounceGroup.new("something")
    debounceGroup:make("thing1")
    debounceGroup:make("thing2")
    debounceGroup:Destroy()
    ```
--]]
function debounceGroup:Destroy()
	for _, debounceObject in self.Contents do
		debounceObject:Destroy()
	end
	debounceUtil.groups[self.Identifier] = nil
end

debounceGroup.__index = debounceGroup

export type types = { "Timer" | "Boolean" }
export type states = { "Active" | "Inactive" | "Suspended" }
export type debounce = { Name: string, State: states } & ({
	set: (debounce, ...any) -> (debounce),
	lock: (debounce) -> (debounce),
	isLocked: (debounce) -> (boolean),
	group: (debounce, string) -> (debounce),
	index: (debounce) -> (debounce),
	Destroy: (debounce) -> (),
})
export type debounceGroupFunction = (
	group: any,
	contents: { debounce? }
) -> ({ Identifier: any, Contents: { debounce } } & typeof(debounceGroup))
export type debounceGroup = { Identifier: any, Contents: { debounce } } & ({
	add: (debounceGroup, _d: string | debounce) -> (debounceGroup),
	remove: (debounceGroup, _d: string | number) -> (debounceGroup),
	make: (debounceGroup, identifier: string, _type: types) -> (debounce),
	Destroy: (debounceGroup) -> (),
})

debounceUtil.newGroup = debounceGroup.new
debounceUtil.new = debounce.new

return debounceUtil
