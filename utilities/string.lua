--!strict
--[[
    FileName    > string
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 09/06/2022
--]]

local stringUtil = {}

local TestService = game:GetService("TestService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Packages.t)

local isInstance = t.typeof("Instance")

local serial = {
	["Vector3"] = function(vector3: Vector3)
		return string.format("Vector3(%s, %s, %s)", tostring(vector3.X), tostring(vector3.Y), tostring(vector3.Z))
	end,
	["Vector2"] = function(vector2: Vector2)
		return string.format("Vector2(%s, %s)", tostring(vector2.X), tostring(vector2.Y))
	end,
	["string"] = function(_string: string)
		return string.format("\"%s\"", _string)
	end,
	["UDim2"] = function(udim2: UDim2)
		return string.format(
			"UDim2(%s, %s, %s, %s)",
			tostring(udim2.X.Scale),
			tostring(udim2.X.Offset),
			tostring(udim2.Y.Scale),
			tostring(udim2.Y.Offset)
		)
	end,
	["UDim"] = function(udim: UDim)
		return string.format("UDim(%s, %s)", tostring(udim.Scale), tostring(udim.Offset))
	end,
	["Instance"] = function(instance: Instance)
		return string.format("Instance(%s)<%s>", instance:GetFullName(), instance.ClassName)
	end,
}

--[[
    Returns a string representation of the given type (if it is a supported type), useful for debugging.
    ```lua
    stringUtil.serialize(Vector3.new(1, 1, 1)) -- Output: "Vector3(1, 1, 1)"
    ```
]]
function stringUtil.serialize(s: any): string
	local classF = serial[typeof(s)]
	return if classF then classF(s) else tostring(s)
end

--[[
    Returns n amount of spaces.
    ```lua
    stringUtil.spaces(2) -- Output: "  "
    stringUtil.spaces(3) -- Output: "   "
    ```
]]
function stringUtil.makeSpace(n: number)
	assert(t.integer(n), "interger number expected")
	return (" "):rep(n)
end

--[[
    Calls the callback function for each word in the given string with a next function.

    Rare usecases
    ```lua
    stringUtil.iterateString("Hello World", function(_currentString, next, index, ...)
        print(_currentString)
        next(_currentString:lower() == _currentString)
    end)
    ```
]]
function stringUtil.iterateString(_s: string, callback: (_currentString: string, index: number, next: () -> ()) -> ())
	assert(t.string(_s), "string expected")
	local i = 1
	local _next
	_next = function(...): nil
		if i >= #_s then
			return
		end
		i += 1
		callback(_s:sub(i, i), i, _next, ...)
		return
	end
	callback(_s:sub(i, i), i, _next)
	return
end

--[[
    Replaces all instances of the given substring with the given replacement.
    ```lua
    stringUtil.shift("Hello World", " ") -- Output: "HelloWorld"
    ```
]]
function stringUtil.shift(_s: string, _match: string)
	stringUtil.iterateString(_s, function(currentString, index, next)
		if currentString == _match then
			_s = _s:sub(1, index - 1) .. _s:sub(index + 1, -1)
		end
		next()
	end)
	return _s
end

-- this feature is still experimental - ark
-- custom search algorithm
-- incomplete
function stringUtil.search<k, v>(input: string, _dictionary: { [string]: any }, algorithm: number?): searchMeta
	assert(t.string(input), "string expected")
	assert(t.table(_dictionary), "table expected")
	local unsortedRelevants = {}
	local irrelevants = {}

	-- returns the relevance of _keword and _input using the levenshtein distance algorithm
	local keywordSearch = function(_keyword: string, _input: string): number -- decimal
		local _kLen = #_keyword
		local _iLen = #_input

		if _kLen == 0 then
			return 0
		elseif _iLen == 0 then
			return 0
		elseif _keyword == _input then
			return 1
		end

		-- create the matrix
		local matrix = {}
		for i = 0, _kLen do
			matrix[i] = {}
			matrix[i][0] = i
		end
		for j = 0, _iLen do
			matrix[0][j] = j
		end

		-- calculate the levenshtein distance
		for i = 1, _kLen do
			for j = 1, _iLen, 1 do
				matrix[i][j] = math.min(
					matrix[i - 1][j] + 1,
					matrix[i][j - 1] + 1,
					matrix[i - 1][j - 1] + (_keyword:byte(i) == _input:byte(j) and 0 or 1)
				)
			end
		end

		return 1 - (matrix[_kLen][_iLen] / math.max(_kLen, _iLen))
	end

	algorithm = algorithm or 1

	if algorithm == 1 then
		for key, value in _dictionary do
			local relavanceP = 0 -- confidence
			local _k, _i = key:lower(), input:lower()
			--local _kW, _iW = stringUtil.shiftMatched(key:lower(), " "), stringUtil.shiftMatched(input:lower(), " ")
			local n = 0

			--[[for _, w in _k:split(" ") do
                for _, wi in _v:split(" ") do
                    relavanceP += keywordSearch(w, wi)
                end
                n += 1
            end]]
			relavanceP += keywordSearch(_k, _i)
			--relavanceP /= (n + 1)

			if relavanceP > 0.3 then -- 0.25 is the optimal minimum confidence level (from tests, to be changed)
				table.insert(unsortedRelevants, { key = key, value = value, relavance = relavanceP })
			else
				table.insert(irrelevants, { key = key, value = value, relavance = 0 })
			end
		end
	elseif algorithm == 2 then
		for key, value in _dictionary do
			local relavanceP = 0 -- confidence
			local _k, _i = key:lower(), input:lower()
			local _kLen, _iLen = #_k, #_i

			if _k:find(_i) then
				relavanceP = 1
			end

			if relavanceP > 0.3 then
				table.insert(unsortedRelevants, { key = key, value = value, relavance = relavanceP })
			else
				table.insert(irrelevants, { key = key, value = value, relavance = 0 })
			end
		end
	end

	return {
		-- return the most relevant result (this code is generated by copilot, amazing)
		selectMostRelevant = function()
			local _max = 0
			local _maxIndex = 0
			for i, v in unsortedRelevants do
				if v.relavance > _max then
					_max = v.relavance
					_maxIndex = i
				end
			end
			return unsortedRelevants[_maxIndex]
		end,
		-- return the least relevant result (this code is generated by copilot, amazing)
		selectLeastRelevant = function()
			local _min = 0
			local _minIndex = 0
			for i, v in unsortedRelevants do
				if v.relavance < _min then
					_min = v.relavance
					_minIndex = i
				end
			end
			return unsortedRelevants[_minIndex]
		end,
		fromMostRelevant = function()
			local relevants = table.clone(unsortedRelevants)
			table.sort(relevants, function(a, b)
				return a.relavance > b.relavance
			end)
			return relevants
		end,
		fromLeastRelevant = function()
			local relevants = table.clone(unsortedRelevants)
			table.sort(relevants, function(a, b)
				return a.relavance < b.relavance
			end)
			return relevants
		end,
		fromIrrelevants = function()
			return irrelevants
		end,
	}
end

type searchMeta = typeof(stringUtil.search("", { [""] = 1 }, 1))

--[[
    Returns a readable version of the given table.
    With limited serializable types, more will be added in the future.
    Useful for debugging.
    ```lua
    stringUtil.tostringTable({
        ["TestString"] = "Test",
        ["TestNumber"] = 1,
        ["TestTable"] = {
            ["TestSubTable"] = {
            },
        },
    }) 
    ```
]]
function stringUtil.tostringTable(_t)
	assert(t.table(_t), "expected table")
	local str = ""
	local convert
	local cacheTbl = {}
	convert = function(_v, index: number)
		local spaces = stringUtil.makeSpace(index * 5)
		for k, v in _v do
			if typeof(v) == "table" then
				if cacheTbl[v] then
					str = str .. "\n" .. spaces .. "<Cyclic table>"
					continue
				end
				cacheTbl[v] = true
				str = str .. "\n" .. spaces .. "[" .. stringUtil.serialize(k) .. "] = {"
				convert(v, index + 1)
				str = str .. "\n" .. spaces .. "}" .. if next(_v, k) then "," else ""
			else
				str = str
					.. "\n"
					.. spaces
					.. "["
					.. stringUtil.serialize(k)
					.. "] = "
					.. stringUtil.serialize(v)
					.. if next(_v, k) then "," else ""
			end
		end
	end
	str = "\n" .. stringUtil.makeSpace(5) .. "from: " .. tostring(_t) .. " = {"
	convert(_t, 2)
	str = str .. "\n" .. stringUtil.makeSpace(5) .. "}"
	return str
end

return stringUtil
