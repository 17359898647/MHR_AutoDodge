log.info("[Infinite Consumables] started loading")

local showDebug = false

local isOnline = false
local skip_changeItemNum = false
local skip_useSlingerAmmo = false

local configPath = "Infinite_Consumables_Config.json"
local drawOptionsWindow = false

local config = {
	version = "1.0.0",
	runInMultiplayer = false,
	infiniteAmmo = true,
	infiniteItems = true, --includes carried slinger ammo e.g. Flash Pods
	infiniteSlingerAmmo = false --dynamically acquired e.g. Burst Pods
	}

if json ~= nil then
    file = json.load_file(configPath)
    if file ~= nil then
		config = file
    else
        json.dump_file(configPath, config)
    end
end

local function logDebug(argStr)
	if showDebug then
		log.info("[Infinite Consumables] "..tostring(argStr));
	end
end

function checkMulti()
	local NetworkManager = sdk.get_managed_singleton("app.NetworkManager")
	local SessionService = NetworkManager:get_field("_SessionService")
	local isMultiplay = SessionService:call("isMultiplay",2)
	logDebug("isMultiplay:"..tostring(isMultiplay))
	return (isMultiplay)
end


sdk.hook(sdk.find_type_definition("app.HunterCharacter.cHunterExtendBase"):get_method("useItem"),
function(args)
	logDebug("cHunterExtendBase.useItem:"..tostring(args[3]))
	if (config.runInMultiplayer or (not checkMulti())) and config.infiniteItems then 
		skip_changeItemNum = true
	end
end,
function(retval)
	skip_changeItemNum = false
	return retval;
end
)

sdk.hook(sdk.find_type_definition("app.ItemUtil"):get_method("changeItemNum"),
function(args)
	logDebug("ItemUtil.changeItemNum:"..tostring(args[3]))
	if skip_changeItemNum then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end,
function(retval)
	return retval;
end
)

sdk.hook(sdk.find_type_definition("app.savedata.cItemParam"):get_method("changeItemPouchNum(app.ItemDef.ID, System.Int16, app.savedata.cItemParam.POUCH_CHANGE_TYPE)"),
function(args)
	logDebug("cItemParam.changeItemPouchNum:"..tostring(args[3]))
	if skip_changeItemNum then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end,
function(retval)
	return retval;
end
)

sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("useSlinger"),
function(args)
	logDebug("HunterCharacter.useSlinger:"..tostring(args[3]))
	if (config.runInMultiplayer or (not checkMulti())) and config.infiniteItems then 
		skip_changeItemNum = true
	end
	if (config.runInMultiplayer or (not checkMulti())) and config.infiniteSlingerAmmo then
		skip_useSlingerAmmo = true
	end
end,
function(retval)
	skip_changeItemNum = false
	skip_useSlingerAmmo = false
	return retval;
end
)

sdk.hook(sdk.find_type_definition("app.cHunterWpGunHandling"):get_method("shootShell"),
function(args)
	logDebug("cShootBase.shootShell:"..tostring(args[3]))
	if (config.runInMultiplayer or (not checkMulti())) and config.infiniteAmmo then 
		skip_changeItemNum = true
	end
end,
function(retval)
	skip_changeItemNum = false
	return retval;
end
)

sdk.hook(sdk.find_type_definition("app.cSlingerAmmo"):get_method("useAmmo"),
function(args)
	logDebug("cSlingerAmmo.useAmmo:"..tostring(args[3]))
	if skip_useSlingerAmmo then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end,
function(retval)
	return retval;
end
)

re.on_draw_ui(function()
	if imgui.button("[Infinite Consumables] Options##Infinite_Consumables") then
		drawOptionsWindow = true
	end
	
    if drawOptionsWindow then
        if imgui.begin_window("Infinite Consumables Options##Infinite_Consumables", true, 64) then
			local doWrite = false
			imgui.text("Multiplayer being False will override the other individual settings.")
			changed, value = imgui.checkbox('Enabled in Multiplayer##Infinite_Consumables', config.runInMultiplayer)
			if changed then
				doWrite = true
				config.runInMultiplayer = value
			end
			changed, value = imgui.checkbox('Infinite Ammo (for Bowguns)##Infinite_Consumables', config.infiniteAmmo)
			if changed then
				doWrite = true
				config.infiniteAmmo = value
			end
			changed, value = imgui.checkbox('Infinite Items (Potions, Traps, carried Slinger ammos, etc.)##Infinite_Consumables', config.infiniteItems)
			if changed then
				doWrite = true
				config.infiniteItems = value
			end
			changed, value = imgui.checkbox('Infinite Slinger Ammo (Burst Pod, Thorn Pod, etc.)##Infinite_Consumables', config.infiniteSlingerAmmo)
			if changed then
				doWrite = true
				config.infiniteSlingerAmmo = value
			end
			if doWrite then
				json.dump_file(configPath, config)
			end
			imgui.end_window()
        else
            drawOptionsWindow = false
        end
    end
end)

log.info("[Infinite Consumables] finished loading")
