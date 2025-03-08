local sdk = sdk
local log = log
local thread = thread
local tostring = tostring

sdk.hook(sdk.find_type_definition("app.GUI010001"):get_method("onOpen()"), function(args)
	local obj = sdk.to_managed_object(args[2]);
    local storage = thread.get_hook_storage()
    storage["this"] = obj
    log.info("GUI Flow was " .. tostring(obj._Flow))
end, function (retval)
    
    local storage = thread.get_hook_storage()
    local obj = storage["this"]
    if obj then
        obj._Flow = 5
        obj:toClose()
    end

    return retval
end)

sdk.hook(sdk.find_type_definition("app.GUI010001"):get_method("guiVisibleUpdate()"), function(args)
	local obj = sdk.to_managed_object(args[2])
    if not obj then return end

    obj._Skip = true
    obj._EnableSkip = true
end)
