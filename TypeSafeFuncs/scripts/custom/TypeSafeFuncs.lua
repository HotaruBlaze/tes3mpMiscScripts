local typeMapping = {
    ["function"] = "function",
    ["number"] = "number",
    ["string"] = "string",
    ["boolean"] = "boolean",
    ["table"] = "table",
    ["nil"] = "nil"
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