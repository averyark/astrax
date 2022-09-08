--[[
    FileName    > loader.server.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 08/09/2022
--]]

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local StarterPlayer = game:GetService('StarterPlayer')
local ReplicatedFirst = game:GetService('ReplicatedFirst')
local Lighting = game:GetService('Lighting')
local CollectionService = game:GetService('CollectionService')
local MarketplaceService = game:GetService('MarketplaceService')
local ServerScriptService = game:GetService('ServerScriptService')
local ServerStorage = game:GetService('ServerStorage')
local MessagingService = game:GetService('MessagingService')
local MemoryStoreService = game:GetService('MemoryStoreService')
local BadgeService = game:GetService('BadgeService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local LocalizationService = game:GetService('LocalizationService')

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Promise = require(ReplicatedStorage.Packages.Promise)
local t = require(ReplicatedStorage.Packages.t)
local Signal = require(ReplicatedStorage.Packages.Signal)


local client = script.Parent.client
local server = script.Parent.server

client.Name = "__test__client"

local run = function(module : ModuleScript)
    return Promise.try(function()
        return require(module);
    end):catch(function(err)
       warn(err)
    end);
end

local toMicroSeconds = function(s)
    return math.round(s/10e-6)
end

local transformPackage = function(folder)
    for _, object in pairs(folder:GetChildren()) do
        object.Parent = folder.Parent
    end
end

local init = function()
    client:Clone().Parent = StarterPlayer.StarterPlayerScripts
    client:Clone().Parent = ReplicatedStorage

    transformPackage(ReplicatedStorage:WaitForChild("Packages"))

    local promises = {}

    local startClock = os.clock()
    local preInitClock

    local astrax = require(ReplicatedStorage.astrax)

    astrax.promise
        :andThen(function()
            preInitClock = os.clock()
            print(("-"):rep(25))
            print(("[astra-server] Pre-initialization(parsing) performed successfully (%sµs)"):format(toMicroSeconds(preInitClock - startClock)))
            print(("-"):rep(25))
            for i, module in pairs(astrax.instance.childrenThatIsA(server, "ModuleScript")) do
                table.insert(promises, run(module))
            end
        end)
        :catch(function()
            warn(("-"):rep(25))
            warn("[astra-server] Failed to parse libs")
            warn(("-"):rep(25))
        end)

    astrax.started
        :andThen(function()
            print(("-"):rep(25))
            print(("[astra-server] Initialization completed (%sµs)"):format(toMicroSeconds(os.clock() - preInitClock)))
            print(("-"):rep(25))
            for moduleName, length in pairs(astrax.__TEST_DUMP.TEST_LOAD_TIME) do
                print(("[astra-server](%s) Initialization time taken: %sµs"):format(moduleName, toMicroSeconds(length)))
            end
            print(("-"):rep(25))
        end)

end

task.spawn(init)


