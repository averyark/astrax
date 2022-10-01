--[[
    FileName    > tween
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 09/06/2022
	
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
local TweenService = game:GetService("TweenService")

local tween = {}

local t = require(script.Parent.Parent.t)
local BoatTween = require(script.Parent.Parent.BoatTween)
local TableUtil = require(script.Parent.Parent.TableUtil)

type easingStyles =
	"RidiculousWiggle"
	| "Quart"
	| "Spring"
	| "ExitExpressive"
	| "SoftSpring"
	| "Sharp"
	| "Bounce"
	| "Back"
	| "UWPAccelerate"
	| "Elastic"
	| "StandardProductive"
	| "Quad"
	| "EntranceExpressive"
	| "Expo"
	| "Circ"
	| "Smooth"
	| "EntranceProductive"
	| "Acceleration"
	| "Sine"
	| "FabricDecelerate"
	| "Standard"
	| "FabricStandard"
	| "ExitProductive"
	| "Quint"
	| "FabricAccelerate"
	| "MozillaCurve"
	| "Linear"
	| "Cubic"
	| "RevBack"
	| "Smoother"
	| "Deceleration"
	| "StandardExpressive"

type easingDirections = "In" | "Out" | "InOut" | "OutIn"

-- tweens a instance once
tween.instance = function(
	object: Instance,
	goals: { [string]: any },
	duration: number?,
	easingStyle: easingStyles?,
	easingDirection: easingDirections?
)
	local _tween = BoatTween:Create(object, {
		Time = duration or 0.3,
		EasingStyle = easingStyle or "Cubic",
		EasingDirection = easingDirection or "Out",
		Goal = goals,
	})

	_tween:Play()

	coroutine.resume(coroutine.create(function()
		_tween.Completed:Wait()
		_tween:Destroy()
		_tween = nil
	end))

	return _tween
end

-- TODO: tweenSequence.andThenRepeatUntil, states, playState

local tweenSequenceTemplate = {}
local tweenSequence = {}

--[[
	Sequence: Pause the sequence until the given time has passed. Note: The time unit is in seconds.
	Waits for the previous tween to finish.

	@chainable true
	@yield true
	```lua
	tweenSequence.template()
		:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
		:andThenWait(5)
		:play({ Position = UDim2.new(0, 0, 0, 0) }, 0.5)
	```
]]
tweenSequenceTemplate.andThenWait = function(self: TweenSequenceTemplate, n: number): TweenSequenceTemplate
	table.insert(self._process, { fType = "andThenWait", n = n })
	return self
end
tweenSequence.__exec__andThenWait = function(self: Tweenable, args: { n: number })
	assert(t.numberPositive(args.n), "[tween] Seconds must be a positive number")
	self:__exec__andThen()
	task.wait(args.n)
end

--[[
	Sequence: Proceeds only if the callback returns true, otherwise the process is stopped.
	Waits for the previous tween to finish.

	@chainable true
	@yield false
	```lua
	local conditionFunc = function(self)
		if condition then -- some condition here
			return true
		end
	end
	tweenSequence.template()
		:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
		:andThenIf(conditionFunc) -- Process stops here if conditionFunc returns false
		:play({ Position = UDim2.new(0, 0, 0, 0) }, 0.5)
	```
]]
tweenSequenceTemplate.andThenIf = function(self: TweenSequenceTemplate, f: (...any) -> (boolean)): TweenSequenceTemplate
	table.insert(self._process, { fType = "andThenIf", conditionF = f })
	return self
end
tweenSequence.__exec__andThenIf =
	function(self: Tweenable, args: { conditionF: (...any) -> (boolean) }, cancel: () -> ())
		assert(t.callback(args.conditionF), "[tween] Condition must be a callback")
		self:__exec__andThen()
		if not args.conditionF(self) then
			cancel()
		end
	end

--[[
	Sequence: Yields the thread until the callback returns true, then continues the sequence. Note: Use this function carefully as it could cause the sequence to never end. 
	Waits for the previous tween to finish.

	@chainable true
	@yield true
	```lua
	local conditionFunc = function(self)
		if condition then -- some condition here
			return true
		end
	end
	tweenSequence.template()
		:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
		:andThenWaitUntil(conditionFunc)
		:play({ Position = UDim2.new(0, 0, 0, 0) }, 0.5)
	```
]]
tweenSequenceTemplate.andThenWaitUntil =
	function(self: TweenSequenceTemplate, f: (...any) -> (boolean)): TweenSequenceTemplate
		table.insert(self._process, { fType = "andThenWaitUntil", conditionF = f })
		return self
	end
tweenSequence.__exec__andThenWaitUntil = function(self: Tweenable, args: { conditionF: (...any) -> (boolean) })
	assert(t.callback(args.conditionF), "[tween] Condition must be a callback")
	self:__exec__andThen()
	repeat
		task.wait()
	until args.conditionF(self)
end

--[[
	Sequence: Proceeds after the last tween has finished.

	@chainable true
	@yield true

	```lua
	tweenSequence.template()
		:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
		:andThen()
		:play({ Position = UDim2.new(0, 0, 0, 0) }, 0.5)
	```
]]
tweenSequenceTemplate.andThen = function(self: TweenSequenceTemplate): TweenSequenceTemplate
	table.insert(self._process, { fType = "andThen" })
	return self
end
tweenSequence.__exec__andThen = function(self: Tweenable, args: {})
	self.tween.Completed:Wait()
end

--[[
	Sequence: Animating the object. Note: This function will not yield, use :andThen() if you want to wait for the animation to finish before executing the next process

	@chainable true
	@yield false

	```lua
	tweenSequence.template()
		:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
		:andThen()
		:play({ Position = UDim2.new(0, 0, 0, 0) }, 0.5)
	```
]]
tweenSequenceTemplate.play = function(
	self: TweenSequenceTemplate,
	goals: { [string]: any } | string,
	duration: number?,
	easingStyle: easingStyles?,
	easingDirection: easingDirections?
): TweenSequenceTemplate
	table.insert(
		self._process,
		{
			fType = "play",
			goals = goals,
			duration = duration,
			easingStyle = easingStyle,
			easingDirection = easingDirection,
		}
	)
	return self
end
tweenSequence.__exec__play = function(
	self: Tweenable,
	args: {
		goals: { [string]: any } | string,
		duration: number?,
		easingStyle: easingStyles?,
		easingDirection: easingDirections?,
	}
)
	assert(t.table(args.goals) or t.string(args.goals) and self._states[args.goals], "[tween] State is not defined: " .. tostring(args.goals))
	self.tween = BoatTween:Create(self.object, {
		Time = args.duration or 0.3,
		EasingStyle = args.easingStyle or "Cubic",
		EasingDirection = args.easingDirection or "Out",
		Goal = t.string(args.goals) and self._states[args.goals] or args.goals,
	})
	self.tween:Play()
end

--[[
	Sequence: Resets the object to its original state. Default must be set with :default({}) before using this function.

	@chainable true
	@yield false

	```lua
	tweenSequence.template()
		:default({
			Position = UDim2.new(0, 0, 0, 0)
		})
		:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
		:andThenWait(2)
		:reset()
	```
]]
tweenSequenceTemplate.reset = function(self: TweenSequenceTemplate): TweenSequenceTemplate
	table.insert(self._process, { fType = "reset" })
	return self
end
tweenSequence.__exec__reset = function(self: Tweenable, args: {})
	assert(t.table(self.default), "[tween] Default values must be a table")
	for a, b in pairs(self.default) do
		self.object[a] = b
	end
end

--[[
	Sequence: Resets the object to its original state. Default must be set with :default({}) before using this function.

	@chainable true
	@yield false

	```lua
	tweenSequence.template()
		:default({
			Position = UDim2.new(0, 0, 0, 0)
		})
		:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
		:andThenWait(2)
		:reset()
	```
]]
tweenSequenceTemplate.default = function(self: TweenSequenceTemplate, default: { [string]: any } | string): TweenSequenceTemplate
	table.insert(self._process, { fType = "default", default = default })
	return self
end
tweenSequence.__exec__default = function(self: Tweenable, args: { default: { [string]: any } | string })
	assert(t.table(args.default) or t.string(args.default), "[tween] Default values must be a table or a string")
	assert(t.table(args.default) or t.string(args.default) and self._states[args.default], "[tween] State is not defined: " .. tostring(args.default))
	self.default = t.string(args.default) and self._states[args.default] or args.default
end

--[[
	Sequence: Animating the object. Note: This function will not yield, use :andThen() if you want to wait for the animation to finish before executing the next process

	@chainable true
	@yield false

	```lua
	tweenSequence.template()
		:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
		:andThen()
		:play({ Position = UDim2.new(0, 0, 0, 0) }, 0.5)
	```
]]
tweenSequenceTemplate.playDefault = function(
	self: TweenSequenceTemplate,
	duration: number?,
	easingStyle: easingStyles?,
	easingDirection: easingDirections?
): TweenSequenceTemplate
	table.insert(
		self._process,
		{ fType = "playDefault", duration = duration, easingStyle = easingStyle, easingDirection = easingDirection }
	)
	return self
end
tweenSequence.__exec__playDefault = function(
	self: Tweenable,
	args: {
		duration: number?,
		easingStyle: easingStyles?,
		easingDirection: easingDirections?,
	}
)
	assert(t.table(self.default), "[tween] Default values must be a table")
	self.tween = BoatTween:Create(self.object, {
		Time = args.duration or 0.3,
		EasingStyle = args.easingStyle or "Cubic",
		EasingDirection = args.easingDirection or "Out",
		Goal = self.default,
	})
	self.tween:Play()
end

--[[
	Sequence: Animating the object. Note: This function will not yield, use :andThen() if you want to wait for the animation to finish before executing the next process

	@chainable true
	@yield false

	```lua
	tweenSequence.template()
		:state("SomeState", { Position = UDim2.new(0, 0, 1, 0) }, 0.5)
		:play("SomeState", 0.5)
	```
]]
tweenSequenceTemplate.state = function(
	self: TweenSequenceTemplate,
	stateName: string,
	stateProperties:  { [string]: any }
): TweenSequenceTemplate
	table.insert(
		self._process,
		{ fType = "state", stateName = stateName, stateProperties = stateProperties }
	)
	return self
end
tweenSequence.__exec__state = function(
	self: Tweenable,
	args: {
		stateName: string,
		stateProperties:  { [string]: any }
	}
)
	assert(t.string(args.stateName), "[tween] stateName must be a string")
	assert(t.table(args.stateProperties), "[tween] stateProperties must be a table")
	self._states[args.stateName] = args.stateProperties
end

--[[
	Sequence: Append a function to the sequence.

	@chainable true
	@yield false

	TODO: Allow the option to specify a position in the sequence to insert the function
	```lua
		local tweenable = tweenSequence.new(tweenTemplate, object)
			:append(function(fromTemplate)
				fromTemplate:play({ Position = UDim2.new(0, 0, 2, 0) }, 0.5)
			end)
		tweenable:run()
	```
]]
tweenSequence.append = function(self: Tweenable, callback : (TweenSequenceTemplate) -> ()): Tweenable
	local capture__meta__ = setmetatable(table.clone(self), {
		__index = tweenSequenceTemplate
	})
	callback(capture__meta__)
	return self
end

--[[
	Plays the sequence

	@yield #
	```lua
	local sequence = tweenSequence.template()
			:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
			:andThen()
			:play({ Position = UDim2.new(0, 0, 0, 0) }, 0.5)

	tween.new(sequence, GuiFrame):run()
	```
]]
tweenSequence.run = function(self : Tweenable & { _process: { [number]: { fType: string, [string]: any } } }): Tweenable
	for _, fData in pairs(self._process) do
		local cancelled = false
		tweenSequence["__exec__" .. fData.fType](self, fData, function()
			cancelled = true
		end)
		if cancelled then
			break
		end
	end
	return self
end

--[[
	Creates a chainable TweenSequenceTemplate object, you can chain multiple sequence

	@chainable true
	@yield false
	```lua
	tweenSequence.template()
		:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
	```
]]
tween.template = function(): TweenSequenceTemplate
	local self = {
		_process = {},
		_states = {}
	}

	return setmetatable(self, {
		__index = tweenSequenceTemplate,
	})
end

--[[
	Plays the sequence

	@yield #
	```lua
	local sequence = tweenSequence.template()
			:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
			:andThen()
			:play({ Position = UDim2.new(0, 0, 0, 0) }, 0.5)

	tween.run(sequence, GuiFrame)
	```
]]
tween.run = function(tsTemplate: TweenSequenceTemplate, object: Instance): Tweenable
	assert(t.Instance(object), "[tween] object must be an instance")
	local self = setmetatable({
		template = tsTemplate,
		object = object,
		_process = {},
		_states = {}
	}, {
		__index = tweenSequence,
	})
	for _, process in pairs(self.template._process) do
		table.insert(self._process, process)
	end
	for stateName, stateProperties in pairs(self.template._states) do
		self._states[stateName] = stateProperties
	end
	for _, fData in pairs(self._process) do
		local cancelled = false
		tweenSequence["__exec__" .. fData.fType](self, fData, function()
			cancelled = true
		end)
		if cancelled then
			break
		end
	end
	return self
end

local deepCloneTable; deepCloneTable = function(tb)
	local newTable = table.clone(tb)
	for key, value in pairs(tb) do
		if type(value) == "table" then
			newTable[key] = table.clone(value)
		end
	end
	return newTable
end

--[[
	Creates a new tween object from the given sequence and object. The sequence is not ran automatically, you must call :run() to play the sequence.

	@yield false
	```lua
	local sequence = tweenSequence.template()
			:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)
			:andThen()
			:play({ Position = UDim2.new(0, 0, 0, 0) }, 0.5)

	tween.new(sequence, GuiFrame)
	```
]]
tween.new = function(tsTemplate: TweenSequenceTemplate | any, object: Instance): Tweenable -- | any to silence Roblox TS
	local self = setmetatable({
		template = tsTemplate,
		object = object,
		_process = {},
		_states = {}
	}, {
		__index = function(self, index)
			if tweenSequenceTemplate[index] then
				return function (_self, ...)
					local mimic = deepCloneTable(self)
					local capture__meta__ = tweenSequenceTemplate[index](mimic, ...)._process[1]
					tweenSequence["__exec__" .. index](TableUtil.Dict.Merge1D(mimic, capture__meta__), ..., function() -- empty cancel function
					end)
				end
			end
			return tweenSequence[index]
		end,
	})
	for _, process in pairs(self.template._process) do
		table.insert(self._process, process)
	end
	for stateName, stateProperties in pairs(self.template._states) do
		self._states[stateName] = stateProperties
	end
	return self
end

tween.Destroy = function(self : Tweenable)
	self = nil
end

tweenSequenceTemplate.Destroy = function(self : TweenSequenceTemplate)
	self = nil
end

--[[
	Creates a new group of tweens, you can pass multiple tweens as arguments or add them individually with :add()

	@yield false
	```lua
	local sequence = tweenSequence.template()
			:play({ Position = UDim2.new(0, 0, 1, 0) }, 0.5)

	local group = tween.group(
		tween.new(sequence, GuiFrame1),
		tween.new(sequence, GuiFrame2)
	)
	```
]]
tween.group = function(...: Tweenable) : Tweenable
	return setmetatable({_group = {...}}, {
		__index = function(self, index)
			if tweenSequenceTemplate[index] or tweenSequence[index] then
				return function (...)
					for _, tweenable in pairs(self._group) do
						tweenable[index](tweenable, ...)
					end
				end
			end
		end,
	})
end

type TweenSequenceTemplate = typeof(tween.template()) & {
	andThen: (self: TweenSequenceTemplate) -> TweenSequenceTemplate,
	andThenWait: (self: TweenSequenceTemplate, seconds: number) -> TweenSequenceTemplate,
	andThenWaitUntil: (self: TweenSequenceTemplate, condition: () -> (boolean)) -> TweenSequenceTemplate,
	andThenIf: (self: TweenSequenceTemplate, condition: () -> (boolean)) -> TweenSequenceTemplate,
	play: (
		self: TweenSequenceTemplate,
		goals: { [string]: any  | string},
		duration: number?,
		easingStyle: easingStyles?,
		easingDirection: easingDirections?
	) -> TweenSequenceTemplate,
	reset: () -> TweenSequenceTemplate,
	default: (self: TweenSequenceTemplate, properties: ({ [string]: any }) | string) -> TweenSequenceTemplate,
	playDefault: (
		self: TweenSequenceTemplate,
		duration: number?,
		easingStyle: easingStyles?,
		easingDirection: easingDirections?
	) -> TweenSequenceTemplate,
	state: (self : TweenSequenceTemplate, name : string, properties :  { [string]: any }) -> TweenSequenceTemplate,
	Destory: (TweenSequenceTemplate) -> (),
}

type TweenSequenceMethods = {
	"andThen" |
	"andThenWait" |
	"andThenWaitUntil" |
	"andThenIf" |
	"play" |
	"reset" |
	"default" |
	"playDefault" |
	"state"
}

--[[type Tweenable = TweenSequenceTemplate & {
	run: (Tweenable) -> Tweenable,
	append: (Tweenable, (fromTemplate: TweenSequenceTemplate) -> ()) -> Tweenable
}]]

type Tweenable = {
	andThen: (self: TweenSequenceTemplate) -> TweenSequenceTemplate,
	andThenWait: (self: TweenSequenceTemplate, seconds: number) -> TweenSequenceTemplate,
	andThenWaitUntil: (self: TweenSequenceTemplate, condition: () -> (boolean)) -> TweenSequenceTemplate,
	andThenIf: (self: TweenSequenceTemplate, condition: () -> (boolean)) -> TweenSequenceTemplate,
	play: (
		self: TweenSequenceTemplate,
		goals: { [string]: any  | string},
		duration: number?,
		easingStyle: easingStyles?,
		easingDirection: easingDirections?
	) -> TweenSequenceTemplate,
	reset: () -> TweenSequenceTemplate,
	default: (self: TweenSequenceTemplate, properties: ({ [string]: any }) | string) -> TweenSequenceTemplate,
	playDefault: (
		self: TweenSequenceTemplate,
		duration: number?,
		easingStyle: easingStyles?,
		easingDirection: easingDirections?
	) -> TweenSequenceTemplate,
	state: (self : TweenSequenceTemplate, name : string, properties :  { [string]: any }) -> TweenSequenceTemplate,
	run: (Tweenable) -> Tweenable,
	append: (Tweenable, (fromTemplate: TweenSequenceTemplate) -> ()) -> Tweenable,
	Destory: (Tweenable) -> (),
}

-- server syncing tween
tween.tweenClientInstance = function() end

return tween
