--[[
    FileName    > ui
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 16/06/2022
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
local TableUtil = require(script.Parent.Parent.TableUtil)
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
	self.uiObject = self._realUiObject:Clone()
	self.uiObject.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self.onInit:Fire(self.uiObject)
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
	if self.uiObject and self.uiObject:IsDescendantOf(Players.LocalPlayer.PlayerGui) then
		callbackInit(self)
	end
	self._maid:Add(self.onInit:Connect(function()
		callbackInit(self)
	end))
	if callbackDeinit then
		self._maid:Add(self.onDeinit:Connect(function()
			callbackDeinit(self)
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
		uiObject = _realUiObject:Clone(),
		onInit = Signal.new(),
		onDeinit = Signal.new(),
	}, ui)

	self._maid:Add(self._realUiObject.Destroying:Connect(function()
		self:destroy()
	end))
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
	self._maid:Add(self.uiObject)

	userInterfaces[_realUiObject.Name] = self
	self.uiObject.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

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
		print(userInterfaces)
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

task.spawn(function()
	if not RunService:IsClient() then
		return
	end

	if not ReplicatedStorage:FindFirstChild("Interface") then
		error("[ui] Interface folder is not present in ReplicatedStorage " .. debug.traceback())
	end

	local pgui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local test_hide = pgui:FindFirstChild("test-hide")
	local test_run = pgui:FindFirstChild("test-run")

	if test_hide then
		for _, child in test_hide:GetChildren() do
			child.Enabled = false
		end
	end
	if test_run then
		for _, child in test_run:GetChildren() do
			if isScreenGui(child) and not userInterfaces[child.Name] then
				uiUtil.new(child)
			end
		end
	end

	for _, interface in ReplicatedStorage.Interface:GetChildren() do
		uiUtil.new(interface)
	end

	ReplicatedStorage.Interface.ChildAdded:Connect(function(child)
		if isScreenGui(child) then
			uiUtil.new(child)
		end
	end)
end)

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

export type ui = typeof(uiUtil.new(Instance.new("ScreenGui")))

return uiUtil --[[:: {
    new: typeof(uiUtil.new),
    get: typeof(ui.get),
    observeFor: (uiName: string, callback: (ui: ui) -> ()) -> ()
}]]
