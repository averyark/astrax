--[[
    FileName    > sound.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 25/07/2022
	
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

local default = "default"
local soundGroups = {}
local mainContainer

local soundUtil = {
	sounds = {},
	groups = {
		["all"] = {},
		[default] = {},
	},
}

soundUtil.setDefaultGroup = function(name: string)
	assert(t.string(name), "[sound] expected string for name")
	default = name
end

soundUtil.playLocally = function(soundName: string): Sound
	assert(t.string(soundName), "[sound] expected string for soundName")
	if not soundUtil.sounds[soundName] then
		warn(("[sound] invalid soundName \"%s\""):format(soundName))
	end
	soundUtil.sounds[soundName]:Play()
	return soundUtil.sounds[soundName]
end

soundUtil.playAtPosition = function(soundName: string, position: Vector3): Sound
	assert(t.string(soundName), "[sound] expected string for soundName")
	assert(t.Vector3(position), "[sound] expected Vector3 for position")
	if not soundUtil.sounds[soundName] then
		warn(("[sound] invalid soundName \"%s\""):format(soundName))
	end
	local cachePart = instance.makeInstance("Part", {
		Parent = workspace.__utilityCache,
		Name = "__soundUtility__playAtPosition",
		Transparency = 1,
		Size = Vector3.new(1, 1, 1),
		CanCollide = false,
		Anchored = true,
	})
	local sound = soundUtil.sounds[soundName]:Clone()
	sound.Parent = cachePart
	sound:Play()
	return sound
end

soundUtil.playAtPart = function(soundName: string, part: BasePart): Sound
	assert(t.string(soundName), "[sound] expected string for soundName")
	assert(t.instanceIsA("BasePart")(part), "[sound] expected BasePart for part")
	if not soundUtil.sounds[soundName] then
		warn(("[sound] invalid soundName \"%s\""):format(soundName))
	end
	local sound = soundUtil.sounds[soundName]:Clone()
	sound.Parent = part
	sound:Play()
	return sound
end

local indexGroup = function(soundGroupName: string)
	soundUtil.groups[soundGroupName] = {}
end

soundUtil.makeGroup = function(soundGroupName: string)
	assert(t.string(soundGroupName), "[sound] expected string for soundGroupName")
	assert(
		not soundUtil.groups[soundGroupName],
		("[sound] soundGroupName \"%s\" is already used"):format(soundGroupName)
	)

	soundGroups[soundGroupName] = instance.new("SoundGroup", {
		Parent = mainContainer,
		Name = soundGroupName,
	})

	indexGroup(soundGroupName)
end

local index = function(sound: Sound, soundGroupName: string?)
	assert(t.instanceIsA("Sound")(sound), "[sound] expected Sound for sound")
	assert(t.none(soundGroupName) or t.string(soundGroupName), "[sound] expected nil or string for soundGroupName")

	if t.string(soundGroupName) and not soundUtil.groups[soundGroupName] then
		soundUtil.makeGroup(soundGroupName :: string)
	end

	if soundGroupName ~= "all" then
		soundGroupName = soundGroupName or default
		table.insert(soundUtil.groups[soundGroupName], sound.Name)
	end

	sound.SoundGroup = soundGroups[soundGroupName]
	sound.Parent = soundGroups[soundGroupName]

	soundUtil.sounds[sound.Name] = sound
end

soundUtil.new = function(soundName: string, soundId: number, soundGroupName: string?)
	assert(t.string(soundName), "[sound] expected string for soundName")
	assert(t.number(soundId), "[sound] expected number for soundId")
	assert(t.none(soundGroupName) or t.string(soundGroupName), "[sound] expected nil or string for soundGroupName")
	local sound = instance.new("Sound", {
		Name = soundName,
		SoundId = soundId,
	})

	index(sound, soundGroupName)
end

if
	instance.firstChildWithCondition(SoundService, function(insc)
		if insc.ClassName == "Folder" and insc.Name == "sounds" then
			return true
		end
	end) or RunService:IsClient()
then
	if RunService:IsClient() then
		SoundService:WaitForChild("sounds")
	end
	mainContainer = SoundService.sounds
	instance.observeForChildrenThatIsA(mainContainer, "SoundGroup", function(insc)
		indexGroup(insc.Name)
		instance.observeForChildrenThatIsA(insc, "Sound", function(sound)
			index(sound, insc.Name)
		end)
	end)
	instance.observeForChildrenThatIsA(mainContainer, "Sound", function(sound)
		index(sound)
	end)
else
	mainContainer = instance.new("Folder", {
		Parent = SoundService,
		Name = "sounds",
	})
end

return soundUtil
