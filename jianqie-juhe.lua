local MasterPlayer
local player
local weaponType
local isWeaponOn
local action_index = 0
local action_cata = 0
local damage_owner = ""
local motionID
local gameObje
local auraLevel
local Isjianqie = false

local ConfigManager = {
    kabutowariShellNum = 30,
    loopAuraLevel = true,
    nadaoTime = 10
}

local function getComponent(obj, type)
    return obj:call("getComponent(System.Type)", sdk.typeof(type))
end

local function initMaster()
    if not MasterPlayer then
        MasterPlayer = sdk.get_managed_singleton("app.PlayerManager")
    end
    if not MasterPlayer then return end
    if not player then
        player = MasterPlayer:getMasterPlayer()
    end
    if not player then return end
    if not gameObje then
        gameObje = player:get_Object()
    end
    if not gameObje then return end
    motionID = getComponent(gameObje, 'via.motion.Motion'):getLayer(0):get_MotionID()
    weaponType = player:get_Character():get_Weapon():get_field("_WpType")
    isWeaponOn = player:get_Character():get_IsWeaponOn()
    if isWeaponOn == true and weaponType == 3 then
        return true
    else
        return false
    end
end

local function fuzzy_match(str, pattern)
    return string.find(str, pattern) ~= nil
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

-- 统一检测函数
local function checkMotionState()
    return not motionIDLookup[motionID]
end

-- -- 无限红刃
sdk.hook(
    sdk.find_type_definition("app.cHunterWp03Handling"):get_method("doUpdate()"),
    function(args)
        local obj = sdk.to_managed_object(args[2])
        if initMaster() == true then
            if ConfigManager.loopAuraLevel == true and obj:call('get_AuraLevel') < 4 then
                obj:call('set_AuraLevel', 4)
                auraLevel = obj:call('get_AuraLevel')
            else
                auraLevel = 1
            end
            obj:set_field('_KabutowariShellNum', ConfigManager.kabutowariShellNum)
        end
    end,
    function(retval)
        return retval
    end
)

-- -- 纳刀时长
sdk.hook(
    sdk.find_type_definition("app.Wp03Action.cIaiWpOff"):get_method("doUpdate()"),
    function(args)
        local obj = sdk.to_managed_object(args[2])
        if initMaster() == true then
            obj:set_field('_IaiWpOffWaitTime', ConfigManager.nadaoTime)
        end
    end,
    function(retval)
        return retval
    end
)


-- --创建动作ID
local function NewActionID(category, index)
    local instance = ValueType.new(sdk.find_type_definition("ace.ACTION_ID"))
    sdk.set_native_field(instance, sdk.find_type_definition("ace.ACTION_ID"), "_Category", category)
    sdk.set_native_field(instance, sdk.find_type_definition("ace.ACTION_ID"), "_Index", index)

    return instance
end


sdk.hook(
    sdk.find_type_definition("app.Hit"):get_method("callHitReturnEvent(System.Delegate[], app.HitInfo)"),
    function(args)
        if initMaster() == true then
            local hitinfo = sdk.to_managed_object(args[3])
            local em = fuzzy_match(hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name(), "Em")
            local minEm = fuzzy_match(hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name(), "em")
            local gm = fuzzy_match(hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name(), "Gm")
            local heal = fuzzy_match(hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name(), "Heal")
            if (em == true or gm == true or minEm == true) and heal == false then
                if action_index == 23 and motionID == 250 and hitinfo:get_field("<DamageOwner>k__BackingField"):get_Name() == "MasterPlayer" then
                    damage_owner = "MasterPlayer"
                    Isjianqie = false
                    return sdk.PreHookResult.SKIP_ORIGINAL
                elseif hitinfo:get_field("<DamageOwner>k__BackingField"):get_Name() == "MasterPlayer" and action_index ~= 23 and checkMotionState() then
                    damage_owner = "MasterPlayer"
                    Isjianqie = true
                    return sdk.PreHookResult.SKIP_ORIGINAL
                end
            end
        end
    end,
    function(retval)
        return retval
    end
)

sdk.hook(
    sdk.find_type_definition("app.HunterCharacter"):get_method(
        "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)"), function(args)
        if initMaster() == true then
            local type = sdk.find_type_definition("ace.ACTION_ID")
            action_cata = sdk.get_native_field(args[4], type, "_Category")
            if action_cata == 2 then
                action_index = sdk.get_native_field(args[4], type, "_Index")
                if action_index ~= 23 and motionID ~= 250 and action_index ~= 16 and motionID ~= 226 and motionID ~= 290 then
                    damage_owner = ""
                    Isjianqie = false
                end
            end
        end
    end
)

sdk.hook(
    sdk.find_type_definition("app.Wp03_Export"):get_method(
        "table_6820f751_3c7a_2bdf_415f_6f6842fb3e52(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
    function(args)
        local actionID = NewActionID(2, 25 + auraLevel)
        if damage_owner == "MasterPlayer" and Isjianqie == false then
            if player:get_Character():call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, actionID, false) then
                damage_owner = ""
            end
        end
    end
)




re.on_draw_ui(
    function()
        local changed = false
        if imgui.tree_node("LongSword") then
            changed, ConfigManager.loopAuraLevel = imgui.checkbox("hongren",
                ConfigManager.loopAuraLevel);
            changed, ConfigManager.nadaoTime = imgui.drag_float("nadaoTime", ConfigManager.nadaoTime);
            changed, ConfigManager.kabutowariShellNum = imgui.slider_int("denglong_hit", ConfigManager
                .kabutowariShellNum, 7, 30);
            imgui.tree_pop()
        end
    end
)

sdk.hook(
    sdk.find_type_definition("app.Wp03_Export"):get_method(
        "table_b91e20f6_300d_4d56_8a9b_9aa6ed81076b(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
    function(args)
        local actionID = NewActionID(2, 16)
        if damage_owner == "MasterPlayer" then
            if Isjianqie == true then
                if player:get_Character():call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, actionID, false) then
                    damage_owner = ""
                    Isjianqie = false
                end
            end
        end
    end
)
