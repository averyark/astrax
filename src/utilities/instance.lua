--!strict
--[[
    FileName    > instance
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 09/06/2022
--]]

local instanceUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Packages.t)

local isInstance = t.typeof("Instance")

--[[
	Returns the first children that is an instance of the given class type.
]]
function instanceUtil.firstChildrenThatIsA(parent: Instance, className: string): Instance?
	t.strict(isInstance(parent))
	for _, child in parent:GetChildren() do
		if child:IsA(className) then
			return child
		end
	end
	return
end

--[[
	Returns the first descendant that is an instance of the given class type.
]]
function instanceUtil.firstDescendantThatIsA(ancestor: Instance, className: string): Instance?
	t.strict(isInstance(ancestor))
	for _, descendant in ancestor:GetDescendants() do
		if descendant:IsA(className) then
			return descendant
		end
	end
	return
end

--[[
	Childrens are passed to the callback function, the first instance which returns true by the callback function is returned
]]
function instanceUtil.firstChildWithCondition(parent: Instance, callback: (Instance) -> (boolean?)): Instance?
	t.strict(isInstance(parent))
	t.strict(t.callback(callback))
	for _, child in parent:GetChildren() do
		if callback(child) then
			return child
		end
	end
	return
end

--[[
	Descendants are passed to the callback function, the first instance which returns true by the callback function is returned
]]
function instanceUtil.firstDescendantWithCondition(ancestor: Instance, callback: (Instance) -> (boolean?)): Instance?
	t.strict(isInstance(ancestor))
	t.strict(t.callback(callback))
	for _, descendant in ancestor:GetDescendants() do
		if callback(descendant) then
			return descendant
		end
	end
	return
end

--[[
	Returns all children that matches the given class type.
]]
function instanceUtil.childrenThatIsA(parent: Instance, className: string): { Instance }
	t.strict(isInstance(parent))
	local instances = {}
	for _, child in parent:GetChildren() do
		if child:IsA(className) then
			table.insert(instances, child)
		end
	end
	return instances
end

--[[
	Returns all descendant that matches the given class type.
]]
function instanceUtil.descendantThatIsA(ancestor: Instance, className: string): { Instance }
	t.strict(isInstance(ancestor))
	local instances = {}
	for _, descendant in ancestor:GetDescendants() do
		if descendant:IsA(className) then
			table.insert(instances, descendant)
		end
	end
	return instances
end

--[[
	Childrens are passed to the callback function, the first instance which returns true by the callback function is returned
]]
function instanceUtil.childWithCondition(parent: Instance, callback: (Instance) -> (boolean?))
	t.strict(isInstance(parent))
	t.strict(t.callback(callback))
	local instances = {}
	for _, child in parent:GetChildren() do
		if callback(child) then
			table.insert(instances, child)
		end
	end
end

--[[
	Descendants are passed to the callback function, the first instance which returns true by the callback function is returned
]]
function instanceUtil.descendantWithCondition(ancestor: Instance, callback: (Instance) -> (boolean?))
	t.strict(isInstance(ancestor))
	t.strict(t.callback(callback))
	local instances = {}
	for _, descendant in ancestor:GetDescendants() do
		if callback(descendant) then
			table.insert(instances, descendant)
		end
	end
end

--[[
	Returns the first children that doesn't match the given class type.
]]
function instanceUtil.firstChildrenThatIsNotA(parent: Instance, className: string): Instance?
	t.strict(isInstance(parent))
	for _, child in parent:GetChildren() do
		if not child:IsA(className) then
			return child
		end
	end
	return
end

--[[
	Returns the first descendant that doesn't match the given class type.
]]
function instanceUtil.firstDescendantThatIsNotA(ancestor: Instance, className: string): Instance?
	t.strict(isInstance(ancestor))
	for _, descendant in ancestor:GetDescendants() do
		if not descendant:IsA(className) then
			return descendant
		end
	end
	return
end

--[[
	Returns all children that doesn't match the given class type.
]]
function instanceUtil.childrenThatIsNotA(parent: Instance, className: string): { Instance }
	t.strict(isInstance(parent))
	local instances = {}
	for _, child in parent:GetChildren() do
		if child:IsA(className) then
			table.insert(instances, child)
		end
	end
	return instances
end

--[[
	Returns all descendant that doesn't match the given class type.
]]
function instanceUtil.descendantThatIsNotA(ancestor: Instance, className: string): { Instance }
	t.strict(isInstance(ancestor))
	local instances = {}
	for _, descendant in ancestor:GetDescendants() do
		if not descendant:IsA(className) then
			table.insert(instances, descendant)
		end
	end
	return instances
end

--[[
	Creates a new instance of the given class type with an option to include the instance tree and properties.
	```lua
	local instance = instanceUtil.new("BasePart", {
		Position = Vector3.new(0, 0, 0),
		Name = "A cool basepart"
		instanceUtil.new("Decal", {
			Texture = "http://www.roblox.com/asset/?id=1234",
			Name = "A cool decal"
		})
	})
	```
]]
function instanceUtil.makeInstance(instanceClass: string, instanceTree: { [string | number]: any | Instance }?)
	local _instance = Instance.new(instanceClass)

	local f
	f = function(_t)
		for k, val in _t do
			if typeof(k) == "string" then
				_instance[k] = val
			elseif typeof(val) == "Instance" then
				val.Parent = _instance
			elseif typeof(val) == "table" then
				if val ~= _t then
					f(val)
				end
			end
		end
	end

	if instanceTree then
		f(instanceTree)
	end

	return _instance
end

-- aliases
instanceUtil.new = instanceUtil.makeInstance

--[[
	Destroys all children that matches the given class type.
]]
function instanceUtil.destroyChildrenThatIsA(parent: Instance, className: string)
	t.strict(isInstance(parent))
	for _, insc in instanceUtil.childrenThatIsA(parent, className) do
		insc:Destroy()
	end
end

--[[
	Destroys all descendant that matches the given class type.
]]
function instanceUtil.destroyDescendantThatIsA(ancestor: Instance, className: string)
	t.strict(isInstance(ancestor))
	for _, insc in instanceUtil.descendantThatIsA(ancestor, className) do
		insc:Destroy()
	end
end

--[[
	Destroys all children that doesn't match the given class type.
]]
function instanceUtil.destroyChildrenThatIsNotA(parent: Instance, className: string)
	t.strict(isInstance(parent))
	for _, insc in instanceUtil.childrenThatIsNotA(parent, className) do
		insc:Destroy()
	end
end

--[[
	Destroys all descendant that doesn't match the given class type.
]]
function instanceUtil.destroyDescendantThatIsNotA(ancestor: Instance, className: string)
	t.strict(isInstance(ancestor))
	for _, insc in instanceUtil.descendantThatIsNotA(ancestor, className) do
		insc:Destroy()
	end
end

--[[
	Passes all children that matches the className to the callback. This function also listens for instances newly parented to the object.
]]
function instanceUtil.observeForChildrenThatIsA(
	parent: Instance,
	className: string,
	callback: (Instance) -> ()
): RBXScriptConnection
	t.strict(isInstance(parent))
	t.strict(t.string(className))
	t.strict(t.callback(callback))
	local checkAndCall = function(child)
		if child:IsA(className) then
			callback(child)
		end
	end
	for _, child in parent:GetChildren() do
		checkAndCall(child)
	end
	local connection = parent.ChildAdded:Connect(function(child)
		checkAndCall(child)
	end)
	return connection
end

--[[
	Passes all descendant that matches the className to the callback. This function also listens for instances newly placed under the ancestor.
]]
function instanceUtil.observeForDescendantThatIsA(
	ancestor: Instance,
	className: string,
	callback: (Instance) -> ()
): RBXScriptConnection
	t.strict(isInstance(ancestor))
	t.strict(t.string(className))
	t.strict(t.callback(callback))
	local checkAndCall = function(descendant)
		if descendant:IsA(className) then
			callback(descendant)
		end
	end
	for _, descendant in ancestor:GetChildren() do
		checkAndCall(descendant)
	end
	local connection = ancestor.DescendantAdded:Connect(function(descendant)
		checkAndCall(descendant)
	end)
	return connection
end

--[[
	Passes all children that the second callback agrees to the first callback. This function also listens for instances newly parented to the object.
]]
function instanceUtil.observeForChildrenWithCondition(
	parent: Instance,
	callback: (Instance) -> (),
	callback2: (Instance) -> (boolean?)
): RBXScriptConnection
	t.strict(isInstance(parent))
	t.strict(t.callback(callback))
	t.strict(t.callback(callback2))
	local checkAndCall = function(child)
		if callback2(child) then
			callback(child)
		end
	end
	local connection = parent.ChildAdded:Connect(function(child)
		checkAndCall(child)
	end)
	for _, child in parent:GetChildren() do
		checkAndCall(child)
	end
	return connection
end

--[[
	Passes all descendant that the second callback agrees to the first callback. This function also listens for instances newly placed under the ancestor.
]]
function instanceUtil.observeForDescendantWithCondition(
	ancestor: Instance,
	callback: (Instance) -> (),
	callback2: (Instance) -> (boolean?)
): RBXScriptConnection
	t.strict(isInstance(ancestor))
	t.strict(t.callback(callback))
	t.strict(t.callback(callback2))
	local checkAndCall = function(descendant)
		if callback(descendant) then
			callback(descendant)
		end
	end
	local connection = ancestor.DescendantAdded:Connect(function(descendant)
		checkAndCall(descendant)
	end)
	for _, descendant in ancestor:GetChildren() do
		checkAndCall(descendant)
	end
	return connection
end

return instanceUtil
