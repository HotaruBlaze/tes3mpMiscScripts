local typeMapping = {
    ["function"] = "function",
    ["number"] = "number",
    ["string"] = "string",
    ["boolean"] = "boolean",
    ["table"] = "table",
    ["nil"] = "nil"
}


-- If true, it will block any C++ function call that has an invalid argument type, This will usually prevent C++ crashes.
-- If false, It will not prevent it, however will print what function triggered it.
local blockFunctionOnError = false

local specialHandling = {
    -- If SendMessage is triggered without a valid string, such as a NULL or a invalid variable, it will trigger a C++ crash.
    -- Our normal handling is unable to catch this normally so we implement a special handling function. 
    SendMessage = function(args)
        if #args == 0 then
            print("Error calling tes3mp.SendMessage: expected at least 1 argument, got 0")
            return false, "Error calling tes3mp.SendMessage: expected at least 1 argument, got 0"
        end
        
        if type(args[0]) ~= "number" then
            print("Error calling tes3mp.SendMessage: expected a number as the first argument, got " .. type(args[0]))
            return false, "Error calling tes3mp.SendMessage: expected a number as the first argument, got " .. type(args[0])
        end
        
        print("Triggered Special Handling but we did not catch a special handling function: SendMessage")
        return true
    end,
}

local function checkType(value, expectedType)
    local actualType = type(value)
    local mappedType = typeMapping[expectedType]

    if expectedType == "nil" then
        return value == nil
    end

    if expectedType == "function" then
        return actualType == "function"
    end

    return actualType == mappedType
end


local function validateArguments(args, expectedTypes)
    local argCount = #args
    local expectedCount = #expectedTypes

    if argCount > expectedCount then
        return false, "Too many arguments: expected at most " .. expectedCount .. ", got " .. argCount
    end

    for i = 1, argCount do
        local isValid = checkType(args[i], expectedTypes[i])
        if not isValid then
            return false, "Argument type mismatch at position " .. i .. ": expected " .. expectedTypes[i] .. ", got " .. type(args[i])
        end
    end

    return true
end

local function createHook(funcName, originalFunc, expectedTypes)
    return function(...)
        local args = {...}

        -- Check for special handling
        if specialHandling[funcName] then
            local isValid, errorMessage = specialHandling[funcName](args)
            if not isValid then
                tes3mp.LogMessage(enumerations.log.ERROR, errorMessage)
                if blockFunctionOnError then
                    return  -- Block the function execution
                end
            end
        end

        -- Validate arguments against expected types
        local isValid, errorMessage = validateArguments(args, expectedTypes)
        if not isValid then
            local message = "Error calling tes3mp." .. funcName .. ": " .. errorMessage
            tes3mp.LogMessage(enumerations.log.WARN, message)
            return
        end

        return originalFunc(...)
    end
end

customEventHooks.registerValidator(
    "OnServerInit",
    function(eventStatus, pid)
        functions_data = jsonInterface.load("custom/functions.json")
        tes3mp.LogMessage(enumerations.log.INFO, "[TypeSafeFuncs] Highjacking all tes3mp functions...")

        for funcName, funcData in pairs(functions_data) do
            if tes3mp[funcName] then
                local originalFunc = tes3mp[funcName]
                local newFunc = createHook(funcName, originalFunc, funcData.args)
                tes3mp[funcName] = newFunc
            else
                tes3mp.LogMessage(enumerations.log.ERROR, "Function " .. funcName .. " does not exist in tes3mp.")
            end
        end
    end
)