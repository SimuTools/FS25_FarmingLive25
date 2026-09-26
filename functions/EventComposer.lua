FarmingLiveRecipe = FarmingLiveRecipe or {}

local function flRecipeGetConfigValue(path)
    local current = FarmingLive.config
    if type(path) == "string" then
        return current ~= nil and current[path] or nil
    end
    if type(path) ~= "table" then
        return nil
    end
    for _, key in ipairs(path) do
        if current == nil then
            return nil
        end
        current = current[key]
    end
    return current
end

local function flRecipeResolveValue(self, ctx, spec)
    if type(spec) ~= "table" then
        return spec
    end

    if spec.kind == "ctx" then
        return ctx[spec.key]
    end

    if spec.kind == "config" then
        return flRecipeGetConfigValue(spec.path)
    end

    if spec.kind == "call" and type(spec.fn) == "function" then
        return spec.fn(self, ctx)
    end

    if spec.kind == "literal" then
        return spec.value
    end

    return spec
end

function FarmingLiveRecipe.ctx(key)
    return { kind = "ctx", key = key }
end

function FarmingLiveRecipe.config(path)
    return { kind = "config", path = path }
end

function FarmingLiveRecipe.literal(value)
    return { kind = "literal", value = value }
end

function FarmingLiveRecipe.callValue(fn)
    return { kind = "call", fn = fn }
end

function FarmingLiveRecipe.set(key, valueSpec)
    return function(self, ctx)
        ctx[key] = flRecipeResolveValue(self, ctx, valueSpec)
    end
end

function FarmingLiveRecipe.randomRange(key, minPath, maxPath)
    return function(self, ctx)
        local minValue = tonumber(flRecipeGetConfigValue(minPath)) or 0
        local maxValue = tonumber(flRecipeGetConfigValue(maxPath)) or minValue
        if maxValue < minValue then
            minValue, maxValue = maxValue, minValue
        end
        ctx[key] = math.random(minValue, maxValue)
    end
end

function FarmingLiveRecipe.numberOrRandom(key, inputKey, minPath, maxPath)
    return function(self, ctx)
        local value = tonumber(ctx[inputKey or "userInput"])
        if value == nil then
            local minValue = tonumber(flRecipeGetConfigValue(minPath)) or 0
            local maxValue = tonumber(flRecipeGetConfigValue(maxPath)) or minValue
            if maxValue < minValue then
                minValue, maxValue = maxValue, minValue
            end
            value = math.random(minValue, maxValue)
        end
        ctx[key] = value
    end
end

function FarmingLiveRecipe.queue(effectName, ...)
    local argSpecs = { ... }
    return function(self, ctx)
        local effectFunc = self[effectName]
        if type(effectFunc) ~= "function" then
            print(string.format("[FarmingLive] Recipe queue: Effekt '%s' fehlt.", tostring(effectName)))
            return
        end

        local resolvedArgs = {}
        for i, spec in ipairs(argSpecs) do
            resolvedArgs[i] = flRecipeResolveValue(self, ctx, spec)
        end

        self:queueEvent(effectFunc, table.unpack(resolvedArgs))
    end
end

function FarmingLiveRecipe.call(effectName, ...)
    local argSpecs = { ... }
    return function(self, ctx)
        local effectFunc = self[effectName]
        if type(effectFunc) ~= "function" then
            print(string.format("[FarmingLive] Recipe call: Effekt '%s' fehlt.", tostring(effectName)))
            return
        end

        local resolvedArgs = {}
        for i, spec in ipairs(argSpecs) do
            resolvedArgs[i] = flRecipeResolveValue(self, ctx, spec)
        end

        effectFunc(self, table.unpack(resolvedArgs))
    end
end

function FarmingLiveRecipe.run(fn)
    return function(self, ctx)
        fn(self, ctx)
    end
end

function FarmingLiveRecipe.register(commandName, steps, meta)
    FarmingLive:registerCommand(commandName, function(self, playerName, userInput)
        local ctx = {
            commandName = commandName,
            playerName = playerName,
            userInput = userInput
        }

        for _, step in ipairs(steps) do
            step(self, ctx)
        end
    end, meta)
end
