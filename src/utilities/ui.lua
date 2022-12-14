--[[
    FileName    > ui
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 16/06/2022
	
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

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Janitor = require(script.Parent.Parent.Janitor)
local Promise = require(script.Parent.Parent.Promise)
local t = require(script.Parent.Parent.t)
local Signal = require(script.Parent.Parent.Signal)

local isInstance = t.typeof("Instance")
local isAGuiObject = t.instanceIsA("GuiObject")
local isScreenGui = t.instanceIsA("ScreenGui")
local isAFrame = t.instanceIsA("Frame")
local isATextLabel = t.instanceIsA("TextLabel")
local isAImageLabel = t.instanceIsA("ImageLabel")
local isAButton = t.instanceIsA("GuiButton")
local isATextButton = t.instanceIsA("TextButton")
local isAImageButton = t.instanceIsA("ImageButton")
local isATextBox = t.instanceIsA("TextBox")

local uiUtil = {}
local ui = {}
local userInterfaces = {}
local listeners = {}

ui.__index = ui

ui.__resetInterface = function(self: ui)
	if self.uiObject then
		self.uiObject:Destroy()
	end
	self.uiObject = self._realUiObject:Clone()
	self.uiObject.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self.onInit:Fire(self.uiObject)
	self._maid:Add(self.uiObject)
end

--[[
	Passes the UI object upon the ScreenGui's initialization into PlayerGui, also calls if the UI is already initialized prior to the function usage.
    The second callback is called when the ui is rendering out
	```lua
	utilities.ui.get("test", function(ui)
    print(ui.uiObject.Name .. "is rendered into PlayerGui") -- test is rendered into PlayerGui
 end, function(ui)
    print(ui.uiObject.Name .. "is rendering out of PlayerGui") -- test is rendering out of PlayerGui
 end)
	```
]]
ui.observe = function(self: ui, callbackInit: (ui: ui) -> (), callbackDeinit: (ui: ui) -> ()?)
	local observed = false
	if self.uiObject and self.uiObject:IsDescendantOf(Players.LocalPlayer.PlayerGui) then
		self.uiObject.Parent:WaitForChild(self.uiObject.Name)
		Promise.try(callbackInit, self)
		observed = true
	end
	if observed then
		task.wait(.5)
	end
	self._maid:Add(self.onInit:Connect(function()
		Promise.try(callbackInit, self)
	end))
	if callbackDeinit then
		self._maid:Add(self.onDeinit:Connect(function()
			Promise.try(callbackDeinit, self)
		end))
	end
end

--[[
    @alias Destory

    Destorys the UI object, clears up all connections and ScreenGuis rendered by the UI object
    ```lua
    utilities.ui.get("test"):destory()
    ```
]]
ui.destroy = function(self: ui)
	self.onDeinit:Fire(self.uiObject)
	self._maid:Destroy()
	userInterfaces[self._realUiObject.Name] = nil
end

ui.Destroy = ui.destroy

--[[
    Creates a new UI object, accepts a ScreenGui or a string name of a ScreenGui placed under `ReplicatedStorage.Interface`.
    ```lua
    utilities.uiUtil.new(Instance.new("ScreenGui"))
    utilities.uiUtil.new("test")
    ```
]]
uiUtil.new = function(uiObject: ScreenGui | string)
	t.strict(isInstance(uiObject))
	t.strict(isScreenGui(uiObject) or t.string(uiObject))

	if t.string(uiObject) and userInterfaces[uiObject] or userInterfaces[uiObject.Name] then
		return
	end

	local _realUiObject

	if not isScreenGui(uiObject) then
		_realUiObject = ReplicatedStorage.Interface:FindFirstChild(uiObject)
	else
		_realUiObject = uiObject
	end

	if not isScreenGui(_realUiObject) then
		error(("ui: Could not find UI object with name %s."):format(tostring(uiObject)))
	end

	local self = setmetatable({
		_realUiObject = _realUiObject,
		_maid = Janitor.new(),
		uiObject = nil,
		onInit = Signal.new(),
		onDeinit = Signal.new(),
	}, ui)

	--self._maid:Add(self._realUiObject.Destroying:Connect(function()
		--self:destroy()
	--end))
	self._maid:Add(Players.LocalPlayer.CharacterRemoving:Connect(function(character)
		self.uiObject:Destroy()
		self.uiObject = nil
		self.onDeinit:Fire(self.uiObject)
	end))
	self._maid:Add(Players.LocalPlayer.CharacterAdded:Connect(function(character)
		if self._realUiObject.ResetOnSpawn then
			self:__resetInterface()
		end
	end))
	if Players.LocalPlayer.Character then
		self:__resetInterface()
	end

	userInterfaces[_realUiObject.Name] = self

	local _uiListeners = listeners[self._realUiObject.Name]

	if _uiListeners then
		for _, thread in _uiListeners do
			coroutine.resume(thread, self)
			table.remove(listeners[self._realUiObject.Name], table.find(listeners[self._realUiObject.Name], thread))
		end
		listeners[self._realUiObject.Name] = nil
	end
	return self
end

--[[
    Yields a valid UI Object with the passed name, warns when the wait period exceeds 5 seconds.

    THIS FUNCTION PAUSES THE THREAD UNTIL A UI OBJECT IS FOUND
    ```lua
    utilities.ui.get("test") -- returns the UI Object
    ```
]]
uiUtil.get = function(uiName: string, _trace: string?): ui
	if userInterfaces[uiName] then
		return userInterfaces[uiName]
	end
	if not listeners[uiName] then
		listeners[uiName] = {}
	end
	coroutine.resume(coroutine.create(function()
		task.wait(5)
		if not userInterfaces[uiName] then
			warn(
				("[ui] %s might not be a valid Interface %s"):format(
					uiName,
					type(_trace) == "string" and "\n" .. _trace or ""
				)
			)
		end
	end))
	table.insert(listeners[uiName], coroutine.running())
	return coroutine.yield()
end

function uiUtil.__init()
	if not RunService:IsClient() then
		return
	end

	if not ReplicatedStorage:FindFirstChild("Interface") then
		error("[ui] Interface folder is not present in ReplicatedStorage " .. debug.traceback())
	end

	local pgui = Players.LocalPlayer:WaitForChild("PlayerGui")

	pgui.ChildAdded:Connect(function(child)
		if child.Name == "test-run" or child.Name == "test-hide" then
			task.wait()
			child:Destroy()
		end
	end)
	task.spawn(function()
		pgui:WaitForChild("test-run"):Destroy()
		pgui:WaitForChild("test-hide"):Destroy()
	end)

	local test_hide = StarterGui:FindFirstChild("test-hide")
	local test_run = StarterGui:FindFirstChild("test-run")

	if test_hide then
		for _, child in test_hide:GetChildren() do
			child.Enabled = false
			child.Parent = nil
		end
	end
	if test_run then
		for _, child in test_run:GetChildren() do
			if isScreenGui(child) then
				child.Parent = ReplicatedStorage.Interface
			end
		end
	end

	for _, interface in ReplicatedStorage.Interface:GetChildren() do
		if isScreenGui(interface) and not userInterfaces[interface.Name] then
			uiUtil.new(interface)
		end
	end
	ReplicatedStorage.Interface.ChildAdded:Connect(function(child)
		if isScreenGui(child) and not userInterfaces[child.Name] then
			uiUtil.new(child)
		end
	end)

	test_run.ChildAdded:Connect(function(child)
		if isScreenGui(child) then
			child.Parent = ReplicatedStorage.Interface
		end
	end)
	test_hide.ChildAdded:Connect(function(child)
		if isScreenGui(child) then
			child.Parent = nil
			child.Enabled = false
		end
	end)
end

--[[
    Passes the UI object of an interface with the particular name upon its initialization into PlayerGui, also calls if the UI is already initialized prior to the function usage.
    Sugar for `ui.get(uiName):observe(callback)`.
    ```lua
    utilities.ui.observeFor("test", function(ui)
        print(ui.uiObject.Name .. "is rendered into PlayerGui") -- test is rendering into PlayerGui
    end)
    ```
]]
uiUtil.observeFor = function(uiName: string, callback: (ui: ui) -> ())
	local trace = debug.traceback("", 2)
	task.spawn(function()
		uiUtil.get(uiName, trace):observe(callback)
	end)
end

uiUtil.promise = function(uiName: string): typeof(Promise.new())
	return Promise.new(function(resolve)
		uiUtil.observeFor(uiName, function(_ui)
			resolve(_ui)
		end)
	end)
end

export type ui = typeof(uiUtil.new(Instance.new("ScreenGui")))

return uiUtil --[[:: {
    new: typeof(uiUtil.new),
    get: typeof(ui.get),
    observeFor: (uiName: string, callback: (ui: ui) -> ()) -> ()
}]]
