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

-- 添加动作ID监控相关变量
local lastPrintTime = 0
local lastActionInfo = ""
local actionBankId = 0

local ConfigManager = {
    kabutowariShellNum = 7,
    loopAuraLevel = false,
    nadaoTime = 3.5,
    -- 动作ID监控配置
    printActionID = true,
    printActionDelay = 0.5,
    showInGameMsg = true,
    logToConsole = false
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

-- 获取动作ID详细信息的函数
local function getActionInfo()
    if not initMaster() then return "" end
    
    local info = string.format(
        "动作ID信息:\n类别(Category): %d\n索引(Index): %d\n动作ID(MotionID): %d\n武器类型: %d\n武器状态: %s", 
        action_cata, 
        action_index, 
        motionID, 
        weaponType, 
        isWeaponOn and "已拔出" or "已收起"
    )
    
    return info
end

-- 打印动作ID信息的函数
local function printActionInfo(force)
    if not ConfigManager.printActionID or not initMaster() then return end
    
    local currentTime = os.clock()
    if not force and currentTime - lastPrintTime < ConfigManager.printActionDelay then return end
    
    local actionInfo = getActionInfo()
    
    -- 只有当动作信息变化或强制打印时才输出
    if force or actionInfo ~= lastActionInfo then
        if ConfigManager.showInGameMsg then
            re.msg(actionInfo)
        end
        
        if ConfigManager.logToConsole then
            log.info(actionInfo)
        end
        
        lastActionInfo = actionInfo
        lastPrintTime = currentTime
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
            
            -- 检测动作ID变化并打印
            printActionInfo()
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

-- 添加帧更新钩子以实时监控动作ID
re.on_frame(function()
    if ConfigManager.printActionID and initMaster() then
        printActionInfo()
    end
end)


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
        
        -- 添加动作ID监控配置节点
        if imgui.tree_node("动作ID监控") then
            changed, ConfigManager.printActionID = imgui.checkbox("启用动作ID监控", 
                ConfigManager.printActionID);
                
            if ConfigManager.printActionID then
                changed, ConfigManager.printActionDelay = imgui.drag_float("更新延迟(秒)", 
                    ConfigManager.printActionDelay, 0.1, 0.1, 5.0);
                changed, ConfigManager.showInGameMsg = imgui.checkbox("在游戏中显示消息", 
                    ConfigManager.showInGameMsg);
                changed, ConfigManager.logToConsole = imgui.checkbox("输出到控制台", 
                    ConfigManager.logToConsole);
                
                if imgui.button("立即打印当前动作ID") then
                    printActionInfo(true)  -- 强制立即打印
                end
                
                -- 显示当前动作ID信息
                imgui.text_wrapped(getActionInfo())
            end
            
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
