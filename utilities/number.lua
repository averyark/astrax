--[[
    FileName    > number
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 15/06/2022
--]]
local mathUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local t = require(ReplicatedStorage.Packages.t)

local suffixes = {
	"",
	"K",
	"M",
	"B",
	"T",
	"Qd",
	"Qn",
	"Sx",
	"Sp",
	"Oc",
	"Nn",
	"De",
	"Ud",
	"Dd",
	"TdD",
	"QdD",
	"QnD",
	"SxD",
	"SpD",
	"OcD",
	"NvD",
}

local romans = {
	[1000] = "M",
	[900] = "CM",
	[500] = "D",
	[400] = "CD",
	[100] = "C",
	[90] = "XC",
	[50] = "L",
	[40] = "XL",
	[10] = "X",
	[9] = "IX",
	[5] = "V",
	[4] = "IV",
	[1] = "I",
}

local onesList = { [0] = "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" }
local teenList = {
	[0] = "Ten",
	"Eleven",
	"Twelve",
	"Thirteen",
	"Fourteen",
	"Fifteen",
	"Sixteen",
	"Seventeen",
	"Eighteen",
	"Nineteen",
}
local tensList = { [0] = "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety" }
local lionList = {
	[0] = "",
	"Thousand",
	"Million",
	"Billion",
	"Trillion",
	"Quadrillion",
	"Quintillion",
	"Sextillion",
	"Septillion",
	"Octillion",
	"Nonillion",
}
local decimalList = {
	[0] = "",
	"Tenth",
	"Hundredths",
	"Thousandths",
	"Ten-Thousandths",
	"Hundred-Thousandths",
	"millionths",
	"Ten-Millionths",
	"Hundred-Millionths",
	"Billionths",
	"Ten-Billionths",
	"Hundred-Billionths",
	"Trillionths",
	"Ten-Trillionths",
	"Hundred-Trillionths",
}

--[[
	Returns a string abbreviation of the number.
	```lua
	mathUtil.abbreviate(1000000, 2) -- Output: "1.00M"
	mathUtil.abbreviate(1500000, 1) -- Output: "1.5M"
	```
]]
mathUtil.abbreviate = function(n: number, precision: number?): string
	assert(t.number(n), "number expected")
	assert(precision == nil or t.number(precision), "number or nil expected")
	-- number abbreviation
	if n == math.huge then
		return tostring(n)
	end
	precision = precision :: number or 2
	local exp = math.floor(math.log(math.max(1, math.abs(n)), 1000))
	local suffix = suffixes[1 + exp] or ("e+" .. exp)
	local norm = math.floor(n * ((10 ^ precision :: number) / (1000 ^ exp))) / (10 ^ precision :: number)
	return ("%." .. precision :: number .. "f%s"):format(norm, suffix)
end

--[[
	Returns a roman numeral representation of the number.
	```lua
	mathUtil.toRomanNumeral(1000) -- Output: "M"
	mathUtil.toRomanNumeral(1004) -- Output: "MIV"
	```
]]
mathUtil.toRomanNumeral = function(n)
	assert(t.number(n), "number expected")
	if n == 0 then
		return 0
	end

	local s = ""

	for i, rm in romans do
		while n >= i do
			n -= i
			s = s .. rm
		end
	end

	return s
end
--[[
	Returns a word representation of the number.
	```lua
	mathUtil.toWord(1000) -- Output: "One Thousand"
	mathUtil.toWord(1000000) -- Output: "One Million"
	```
]]
mathUtil.toWord = function(n)
	assert(t.number(n), "number expected")

	local numbers = math.abs(n) % 1 ~= 0 and string.split(tostring(math.abs(n)), ".") or { math.abs(n) }
	local decimalPlaces = math.abs(n) % 1 ~= 0 and string.len(numbers[2]) or 0
	local results = { "", "" }

	if n == 0 then
		return "Zero"
	end

	local function AddSpaceOrHyphen(String, Add)
		return String == "" and String or Add .. String
	end

	local function AddToResult(NextNumber, ResultNumber)
		local Lion = 0

		while NextNumber > 0 do
			local word = ""
			local ones = NextNumber % 10
			local tens = math.floor(NextNumber / 10) % 10

			local Hundreds = math.floor(NextNumber / 100) % 10
			word = tens == 0 and onesList[ones]
				or tens == 0 and teenList[ones]
				or tensList[tens] .. AddSpaceOrHyphen(onesList[ones], "-")
			word = Hundreds > 0 and onesList[Hundreds] .. " Hundred" .. AddSpaceOrHyphen(word, " ") or word
			results[ResultNumber] = word ~= ""
					and word .. AddSpaceOrHyphen(lionList[Lion], " ") .. AddSpaceOrHyphen(results[ResultNumber], " ")
				or results[ResultNumber]
			NextNumber = math.floor(NextNumber / 1000)
			Lion += 1
		end
	end

	for i, v in numbers do
		if i == 1 and v == 0 then
			continue
		end

		results[1] ..= i == 2 and numbers[1] ~= "0" and " and " or ""
		AddToResult(tonumber(v), i)
		results[2] ..= i == 2 and AddSpaceOrHyphen(decimalList[decimalPlaces], " ") or ""
	end

	return (math.sign(n) == -1 and "Negative " or "") .. table.concat(results)
end

-- Forked from https://devforum.roblox.com/t/introducing-mathaddons/1338754
function mathUtil.commaFormat(number: number)
	local i, j, n, int, dec = tostring(number):find("([-]?)(%d+)([.]?%d*)")
	int = string.gsub(string.reverse(int), "(%d%d%d)", "%1,")
	return n .. string.gsub(string.reverse(int), "^,", "") .. dec
end

-- Forked from https://devforum.roblox.com/t/make-your-workflow-easier-with-math/1025960
-- Documented and typed by AveryArk (zenn#4004)

mathUtil.phi = 1.6180339887
mathUtil.e = 2.718281828459
mathUtil.G = 6.673 * 10 ^ -11

--[[
	Equivalent to doing math.log(e, log). This is the fundamental of exponential growth.
	```lua
	print(mathUtil.naturalLog(2)) -- Output: 0.69314718055996
	```
]]
mathUtil.naturalLog = function(exp: number): number
	assert(t.number(exp), "number expected")
	return math.log(exp, 2.718281828459)
end

--[[
	In a sense this maps an integer to a number from 0 to 1 between a range. So say we had our min as 0 and our max as 10 and our value was 5 we would return 0.5.

	```lua
	print(mathUtil.bound(0, 10, 5)) -- Output: 0.5
	```
]]
mathUtil.bound = function(min: number, max: number, value: number): number
	return (-max + value) / (-max + min)
end

--[[
	Finds the derivative of the passed function (fx) at point x. The closer dx is to 0 the more close it is to the true answer.

	```lua
	print(mathUtil.derivative(2, 0.000001, function(x)
		return x^2;
	end)) --Output: 4.000001000648
	```
]]
mathUtil.derivative = function(x: number, dx: number, func: (number) -> number): number
	return (func(x + dx) - func(x)) / dx
end

--[[
	Returns an array where the first element is X and the second is Y (can be replaced with Z) of a given ellipse. Contrary to the name you can still draw circles with this, the minorAxisLength just has to be equal to the majorAxisLength

	```lua
	for i = 0, 1, 0.01 do
		local part = Instance.new("Part")
		part.Position = Vector3.new(select(1, mathUtil.ellipse(5, 5, i)), 5, select(2, mathUtil.ellipse(5, 5, i)))
		part.Anchored = true
		part.Size = Vector3.new(1, 1, 1)
		part.Parent = workspace
	end
	```
]]
mathUtil.ellipse = function(minorAxisLength: number, majorAxisLength: number, alpha: number): (number, number)
	return math.cos(2 * alpha * math.pi - math.pi) * majorAxisLength,
		math.sin(2 * alpha * math.pi - math.pi) * minorAxisLength
end

--[[
	Maps a value to a value from 0 to 1. Similar to bound(min, max, value), the Sigmoid function maps to ± ∞. Note though, that just like the hyperbolic tangent of x this function becomes obsolete for numbers not near 0.

	```lua
	print(mathUtil.sigmoid(6.9)) -- Output: 0.00100677082009
	```
]]
mathUtil.sigmoid = function(z: number): number
	return 1 / (1 + 2.718281828459 ^ -z)
end

--[[
	Returns a quadratic graph where t is the timestep and a is basically how spacey it is in a sense. The smaller a is the wider the trajectory. “b” correlates to how high the graph will go and c refers to the position of where the trajectory starts (relative to axis)

	```lua
	for i=0, 6, 0.01 do
		local part = Instance.new("Part")
		part.Position = Vector3.new(i, mathUtil.quadratic(-0.5, 3, 0, i), 0)
		part.Anchored = true
		part.Size = Vector3.new(0.1, 0.1, 0.1)
		part.Parent = workspace
	end
	```
]]
mathUtil.quadratic = function(a: number, b: number, c: number, _t: number): number
	return a * (_t ^ 2) + (b * _t) + c
end

--[[
	Returns the definite integral from a to b. The smaller dx is to 0 the more accurate the answer is. func refers to our graph function. For further information on what a definite integral is 
		
	https://www.mathsisfun.com/calculus/integration-definite.html
		
	```lua
	print(mathUtil.integral(0, 1, 0.0001, function(x)
		return x^3;
	end)) -- Output: 0.25005000249993
	```
]]
mathUtil.integral = function(a: number, b: number, dx: number, func: (number) -> number): number
	local sum = 0
	for n = a, b, dx do
		sum += func(n)
	end
	return sum * dx
end

--[[
	Given starting point a and end point b it gets the sum of all values from a function. Returning x on the function will be the equivalent of just doing 1+2+3 if a is 1 and b is 3.
	
	```lua
	print(mathUtil.sum(1, 10, function(x)
		return x+x;
	end)) -- Output: 110
	```
]]
mathUtil.sum = function(a: number, b: number, func: (number) -> number): number
	local sum = 0
	for i = a, b, 1 do
		sum += func(i)
	end
	return sum
end

--[[
	Exact same as sum(a, b, func) except instead of returning the sum of them it is the product. Returning x will be the equivalent of doing b! if a is 1. However this won’t work if it is a non-integer. You would need to use a gamma function. Do note that just cause of how exponential prod is if you get 0 or -NaN it’s probably because the range is too large.

	```lua
	print(mathUtil.prod(1, 3, function(x)
		return x^2;
	end)) -- Output: 36
	```
]]
mathUtil.prod = function(a: number, b: number, func: (number) -> number): number
	local sum = a
	for i = a + 1, b, 1 do
		sum *= func(i)
	end
	return sum
end

--[[
	Linear interpolates a real number where z is the alpha. NOT a class. A refers to the minimum value and b refers to the maximum.

	```lua
	print(mathUtil.lerp(1, 3, 0.5)) -- Output: 2
	```
]]
mathUtil.lerp = function(a: number, b: number, _t: number)
	return a + (b - a) * _t
end

--[[
	Generates a bezier path from 0 to 1 (timeStep). The controls do not have to be a vector2 or a vector3.
	
	```lua
	print(mathUtil.quadBezier(0.5, Vector3.new(0, 1, 0), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1))) -- Output: (0.5, 0.25, 0.25)(Vector3)
	```
]]
mathUtil.quadBezier = function<a1>(
	timeStep: number,
	control1: (Vector2 | Vector3) & a1,
	control2: (Vector2 | Vector3) & a1,
	control3: (Vector2 | Vector3) & a1
): (Vector2 | Vector3) & a1
	assert(
		typeof(control1) == typeof(control2) and typeof(control1) == typeof(control3),
		"Control points must be the same type."
	)
	assert(
		typeof(control1) == "Vector2" or typeof(control1) == "Vector3",
		"Control points must be of type Vector2 or Vector3."
	)
	assert(
		typeof(control2) == "Vector2" or typeof(control2) == "Vector3",
		"Control points must be of type Vector2 or Vector3."
	)
	assert(
		typeof(control3) == "Vector2" or typeof(control3) == "Vector3",
		"Control points must be of type Vector2 or Vector3."
	)
	return (1 - timeStep) ^ 2 * control1 + 2 * (1 - timeStep) * timeStep * control2 + timeStep ^ 2 * control3
end

--[[
	Same thing as quadBezier(timeStep, control1, control2, control3) but there is another control point.

	```lua
	print(mathUtil.cubicBezier(0.69, Vector3.new(0, 1, 0), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 1, 1))) -- Output: (0.731073022, 0.3583, 0.328509003)(Vector3)
	```
]]
mathUtil.cubicBezier = function<a1>(
	timeStep: number,
	control1: (Vector2 | Vector3) & a1,
	control2: (Vector2 | Vector3) & a1,
	control3: (Vector2 | Vector3) & a1
): (Vector2 | Vector3) & a1
	assert(
		typeof(control1) == typeof(control2) and typeof(control1) == typeof(control3),
		"Control points must be the same type."
	)
	assert(
		typeof(control1) == "Vector2" or typeof(control1) == "Vector3",
		"Control points must be of type Vector2 or Vector3."
	)
	assert(
		typeof(control2) == "Vector2" or typeof(control2) == "Vector3",
		"Control points must be of type Vector2 or Vector3."
	)
	assert(
		typeof(control3) == "Vector2" or typeof(control3) == "Vector3",
		"Control points must be of type Vector2 or Vector3."
	)
	return (1 - timeStep) ^ 3 * control1
		+ 3 * (1 - timeStep) ^ 2 * control2
		+ 3 * (1 - timeStep) * timeStep ^ 2 * control2
		+ timeStep ^ 3 * control3
end

--[[
	Equivalent to (a.Position - b.Position).Magnitude. This is useful for getting the distance between two objects.
	
	```lua
	print(mathUtil.eucDist(workspace.A.Position, workspace.B.Position)) -- Output: 22.137750904447
	```
]]
mathUtil.eucDist = function<a1>(a: (Vector2 | Vector3) & a1, b: a1 & (Vector2 | Vector3)): number
	if typeof(a) == "Vector2" and typeof(b) == "Vector2" then
		return math.sqrt(((a.X - b.X) ^ 2 + (a.Y - b.Y) ^ 2))
	elseif typeof(a) == "Vector3" and typeof(b) == "Vector3" then
		return math.sqrt(((a.X - b.X) ^ 2 + (a.Y - b.Y) ^ 2 + (a.Z - b.Z) ^ 2))
	else
		error("out of bound dimensions")
	end
end

--[[
	Useful in Artificial Intelligence development. This returns the distance between two points in manhattan distance.

	```lua
	print(mathUtil.manHatDist(workspace.A.Position, workspace.B.Position)) -- Output: 26.760003268719
	```
]]
mathUtil.manHatDist = function<a1>(a: (Vector2 | Vector3) & a1, b: a1 & (Vector2 | Vector3)): number
	if typeof(a) == "Vector2" and typeof(b) == "Vector2" then
		return math.abs(a.X - b.X) + math.abs(a.Y - b.Y)
	elseif typeof(a) == "Vector3" and typeof(b) == "Vector3" then
		return math.abs(a.X - b.X) + math.abs(a.Y - b.Y) + math.abs(a.Z - b.Z)
	else
		error("out of bound dimensions")
	end
end
--[[
	Chebyshev distance essentially solves the chess problem. Of course it will be useful for that but it is also used in some sudoku algorithms. Note, even though it is used in the example it is encouraged you use this for 2d cartesian coordinates in euclidean space only.

	```lua
	print(mathUtil.chebDist(workspace.A.Position, workspace.B.Position)) -- Output: 21.504999160767
	```
]]
mathUtil.chebDist = function<a1>(a: (Vector2 | Vector3) & a1, b: a1 & (Vector2 | Vector3)): number
	if typeof(a) == "Vector2" and typeof(b) == "Vector2" then
		return math.max(math.abs(a.X - b.X), math.abs(a.Y - b.Y))
	elseif typeof(a) == "Vector3" and typeof(b) == "Vector3" then
		return math.max(math.abs(a.X - b.X), math.abs(a.Y - b.Y), math.abs(a.Z - b.Z))
	else
		error("out of bound dimensions")
	end
end
--[[
	“Flips” a vector across another in a sense. Combining this with parametric ray equations you can get some cool stuff.

	```lua
	game:GetService("RunService").Heartbeat:Connect(function()
		local dir = workspace.Head.Position - workspace.Tail.Position
		local newDir = mathUtil.reflect(Vector3.new(0,1,0), dir)
		local p = workspace.Head.Position + newDir
		workspace.Aligner.CFrame = CFrame.new((p + workspace.Head.Position) / 2, p)
		workspace.Aligner.Size = Vector3.new(0.5, 0.5, (p-workspace.Head.Position).Magnitude)
		workspace.AlignerO.CFrame = CFrame.new((workspace.Tail.Position + >workspace.Head.Position) / 2, workspace.Tail.Position)
		workspace.AlignerO.Size = Vector3.new(0.5, 0.5, (workspace.Tail.Position->workspace.Head.Position).Magnitude)
	end)
	```
]]
mathUtil.reflect = function(normal: Vector3, dir: Vector3): Vector3
	return dir - 2 * (dir:Dot(normal)) * normal
end

return mathUtil
