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
	easingStyle: easingStyles,
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

-- TODO: tweenSequence.andThenRepeatUntil

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
	self.tween:Wait()
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
	goals: { [string]: any },
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
		goals: { [string]: any },
		duration: number?,
		easingStyle: easingStyles?,
		easingDirection: easingDirections?,
	}
)
	self.tween = BoatTween:Create(self.object, {
		Time = args.duration or 0.3,
		EasingStyle = args.easingStyle or "Cubic",
		EasingDirection = args.easingDirection or "Out",
		Goal = args.goals,
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
tweenSequenceTemplate.default = function(self: TweenSequenceTemplate, default: { [string]: any }): TweenSequenceTemplate
	table.insert(self._process, { fType = "default", default = default })
	return self
end
tweenSequence.__exec__default = function(self: Tweenable, args: { default: { [string]: any } })
	assert(t.table(args.default), "[tween] Default values must be a table")
	self.default = args.default
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
	local self = setmetatable({
		template = tsTemplate,
		object = object,
		processes = {},
	}, {
		__index = tweenSequence,
	})
	for _, process in pairs(self.template._process) do
		table.insert(self.processes, process)
	end
	for _, fData in pairs(self.processes) do
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

type Tweenable = typeof(tween.run(tween.template(), Instance.new("Frame")))
type TweenSequenceTemplate = typeof(tween.template()) & {
	andThen: (self: TweenSequenceTemplate) -> TweenSequenceTemplate,
	andThenWait: (self: TweenSequenceTemplate, seconds: number) -> TweenSequenceTemplate,
	andThenWaitUntil: (self: TweenSequenceTemplate, condition: () -> (boolean)) -> TweenSequenceTemplate,
	andThenIf: (self: TweenSequenceTemplate, condition: () -> (boolean)) -> TweenSequenceTemplate,
	play: (
		self: TweenSequenceTemplate,
		goals: { [string]: any },
		duration: number?,
		easingStyle: easingStyles?,
		easingDirection: easingDirections?
	) -> TweenSequenceTemplate,
	reset: () -> TweenSequenceTemplate,
	default: (self: TweenSequenceTemplate, { [string]: any }) -> TweenSequenceTemplate,
	playDefault: (
		self: TweenSequenceTemplate,
		duration: number?,
		easingStyle: easingStyles?,
		easingDirection: easingDirections?
	) -> TweenSequenceTemplate,
}

-- server syncing tween
tween.tweenClientInstance = function() end

return tween
