local MasterPlayer = nil
local player = nil
local weaponType = nil
local isWeaponOn = nil
local action_index = 0
local action_cata = 0
local damage_owner = ""
local motionID = nil
local gameObje = nil
local Isjustdodge = false


local function resetState()
    Isjustdodge = false
    damage_owner = ""
    motionID = nil
    weaponType = nil
    isWeaponOn = nil
    action_index = 0
    action_cata = 0
    MasterPlayer = nil  
    player = nil
    gameObje = nil
end


local function getComponent(obj, type)
    if not obj then 
        return nil 
    end
    
    local success, result = pcall(function()
        return obj:call("getComponent(System.Type)", sdk.typeof(type))
    end)
    return success and result or nil
end


local function initMaster()
    
    MasterPlayer = sdk.get_managed_singleton("app.PlayerManager")
    if not MasterPlayer then 
        resetState()
        return false 
    end

    player = MasterPlayer:getMasterPlayer()
    if not player then 
        resetState()
        return false 
    end

    gameObje = player:get_Object()
    if not gameObje then 
        resetState()
        return false 
    end

    
    local motionComponent = getComponent(gameObje, 'via.motion.Motion')
    if not motionComponent then 
        resetState()
        return false 
    end

    
    local success, motionLayer = pcall(function()
        return motionComponent:getLayer(0)
    end)
    if not success or not motionLayer then
        resetState()
        return false
    end

    
    success, motionID = pcall(function()
        return motionLayer:get_MotionID()
    end)
    if not success or not motionID then
        resetState()
        return false
    end

    
    success, weaponType = pcall(function()
        return player:get_Character():get_Weapon():get_field("_WpType")
    end)
    if not success or not weaponType then
        resetState()
        return false
    end

    success, isWeaponOn = pcall(function()
        return player:get_Character():get_IsWeaponOn()
    end)
    if not success or not isWeaponOn then
        resetState()
        return false
    end

    return isWeaponOn and weaponType == 2
end


local excludedMotionIDs = {
    230, 232, 233, 237,
    249, 250, 252, 263, 264, 265,
    295,
    226, 290,
    466, 467
}

local motionIDLookup = {}
for _, id in ipairs(excludedMotionIDs) do
    motionIDLookup[id] = true
end


local function checkMotionState()
    return not motionIDLookup[motionID]
end


local function NewActionID(category, index)
    local instance = ValueType.new(sdk.find_type_definition("ace.ACTION_ID"))
    sdk.set_native_field(instance, sdk.find_type_definition("ace.ACTION_ID"), "_Category", category)
    sdk.set_native_field(instance, sdk.find_type_definition("ace.ACTION_ID"), "_Index", index)
    return instance
end


sdk.hook(
    sdk.find_type_definition("app.Hit"):get_method("callHitReturnEvent(System.Delegate[], app.HitInfo)"),
    function(args)
        if not initMaster() then
            return
        end

        local hitinfo = sdk.to_managed_object(args[3])
        local attackData = hitinfo:get_field("<AttackData>k__BackingField")
        if attackData:get_field('_UserData'):get_field('<Type>k__BackingField') == 3 
            and attackData:get_field('_DamageType') > 0 
        then
            local damageOwner = hitinfo:get_field("<DamageOwner>k__BackingField")
            if damageOwner:get_Name() == "MasterPlayer" and checkMotionState() then
                damage_owner = "MasterPlayer"
                Isjustdodge = true
                return sdk.PreHookResult.SKIP_ORIGINAL
            end
        end
    end,
    function(retval)
        return retval
    end
)


sdk.hook(
    sdk.find_type_definition("app.HunterCharacter"):get_method(
        "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)"
    ),
    function(args)
        if not initMaster() then
            return
        end

        local actionID = args[3]  -- 
        local typeDef = sdk.find_type_definition("ace.ACTION_ID")

        
        local success, result = pcall(function()
            return sdk.get_native_field(actionID, typeDef, "_Category")
        end)
        if not success or result == nil then
            return
        end
        action_cata = result

        if action_cata == 2 then
            success, result = pcall(function()
                return sdk.get_native_field(actionID, typeDef, "_Index")
            end)
            if not success or result == nil then
                return
            end
            action_index = result
            print("Action Index:", action_index)
        end
    end
)


sdk.hook(
    sdk.find_type_definition("app.Wp02_Export"):get_method(
        "table_60dfb982_a642_4d77_9469_bb85f9cb2cf8(ace.btable.cCommandWork, ace.btable.cOperatorWork)"
    ),
    function(args)
        if not initMaster() then
            return
        end

        local actionID = NewActionID(2, 40)
        if damage_owner == "MasterPlayer" and Isjustdodge then
            if player:get_Character():call(
                "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 
                0, 
                actionID, 
                false
            ) then
                damage_owner = ""
                Isjustdodge = false
            end
        end
    end
)

