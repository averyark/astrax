--[[
    FileName    > debounce.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 31/07/2022

	Copyright (c) 2022 Avery

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local instance = require(script.Parent.instance)
local t = require(script.Parent.Parent.t)
local Janitor = require(script.Parent.Parent.Janitor)
local Promise = require(script.Parent.Parent.Promise)

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

debounce.new = function(_type: types, ...)
	local self
	self = setmetatable({
		--Name = identifier,
		_type = _type,
		_loaded = false,
		_group = "none",
	}, {
		__index = function(_, index)
			if index == "State" then
				if _type == debounceUtil.type.Timer then
					return if os.clock() - self._tL < self._int
						then debounceUtil.state.Inactive
						else debounceUtil.state.Active
				elseif _type == debounceUtil.type.Boolean then
					return if self._bool then debounceUtil.state.Inactive else debounceUtil.state.Active
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
    Sets the identifier for the debounceObject, it is required if you want to index the debounceObject.
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
function debounce:setName(name: string)
	self.Name = name
	return self
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
	assert(t.string(self.Name), "Debounce must have a name to be indexed")
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
	if not self.Name then return end
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
	setName: (debounce, string) -> (debounce),
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
