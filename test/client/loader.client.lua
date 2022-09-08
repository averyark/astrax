--[[
    FileName	> init.client.lua
    Author  	> AveryArk
    Contact 	> Twitter: https://twitter.com/averyark_
    Created 	> 08/09/2022
--]]

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Promise = require(ReplicatedStorage.Promise)

local client = script.Parent

local toMicroSeconds = function(s)
    return math.round(s/10e-6)
end

local run = function(module : ModuleScript)
    return Promise.try(function()
        return require(module);
    end):catch(function(err)
       warn(err)
    end);
end

local init = function()
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
            for i, module in pairs(astrax.instance.childrenThatIsA(client, "ModuleScript")) do
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