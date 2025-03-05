-- 玩家相关变量
local MasterPlayer      -- 主玩家管理器单例
local player            -- 主玩家对象
local weaponType        -- 武器类型
local isWeaponOn        -- 是否装备武器
local action_index = 0  -- 动作索引
local action_cata = 0   -- 动作类别
local damage_owner = "" -- 伤害所有者
local motionID          -- 动作ID
local gameObje          -- 游戏对象
local auraLevel         -- 气刃等级
local Isjianqie = false -- 是否为见切状态
local isAutoDodge = false -- 是否启用自动躲避
local autoDodgeActionID = nil -- 自动躲避动作ID

-- 配置管理器
local ConfigManager = {
    kabutowariShellNum = 7,  -- 兜割贝壳数量
    loopAuraLevel = true,   -- 是否保持红刃
    nadaoTime = 3.5,         -- 纳刀时间
    autoDodgeEnabled = false, -- 是否启用自动躲避
    autoDodgeActionIndex = nil  -- 自动躲避动作索引，请填写动作ID
}

-- 获取组件函数
-- @param obj 游戏对象
-- @param type 组件类型
-- @return 返回指定类型的组件
local function getComponent(obj, type)
    return obj:call("getComponent(System.Type)", sdk.typeof(type))
end

-- 初始化主玩家函数
-- 获取玩家信息并检查是否装备了太刀
-- @return 如果装备了太刀返回true，否则返回false
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
        return true  -- 装备了太刀
    else
        return false -- 未装备太刀
    end
end

-- 模糊匹配函数
-- @param str 要搜索的字符串
-- @param pattern 要匹配的模式
-- @return 如果找到匹配返回true，否则返回false
local function fuzzy_match(str, pattern)
    return string.find(str, pattern) ~= nil
end

-- 排除的动作ID列表
local excludedMotionIDs = {
    230, 232, 233, 237,  -- 可能是特定太刀动作
    249, 250, 252, 263, 264, 265,
    295,
    226, 290,
    466, 467
}

-- 创建动作ID查找表，用于快速检查
local motionIDLookup = {}
for _, id in ipairs(excludedMotionIDs) do
    motionIDLookup[id] = true
end

-- 检查动作状态函数
-- @return 如果当前动作ID不在排除列表中返回true，否则返回false
local function checkMotionState()
    return not motionIDLookup[motionID]
end

-- 无限红刃钩子函数
-- 修改太刀的气刃等级和兜割贝壳数量
sdk.hook(
    sdk.find_type_definition("app.cHunterWp03Handling"):get_method("doUpdate()"),
    function(args)
        local obj = sdk.to_managed_object(args[2])
        if initMaster() == true then
            if ConfigManager.loopAuraLevel == true and obj:call('get_AuraLevel') < 4 then
                obj:call('set_AuraLevel', 4)  -- 设置气刃等级为最高
                auraLevel = obj:call('get_AuraLevel')
            else
                auraLevel = 1  -- 默认气刃等级
            end
            obj:set_field('_KabutowariShellNum', ConfigManager.kabutowariShellNum)  -- 设置兜割贝壳数量
        end
    end,
    function(retval)
        return retval
    end
)

-- 纳刀时长钩子函数
-- 修改太刀的纳刀等待时间
sdk.hook(
    sdk.find_type_definition("app.Wp03Action.cIaiWpOff"):get_method("doUpdate()"),
    function(args)
        local obj = sdk.to_managed_object(args[2])
        if initMaster() == true then
            obj:set_field('_IaiWpOffWaitTime', ConfigManager.nadaoTime)  -- 设置纳刀等待时间
        end
    end,
    function(retval)
        return retval
    end
)

-- 创建新的动作ID函数
-- @param category 动作类别
-- @param index 动作索引
-- @return 返回新创建的ACTION_ID对象
local function NewActionID(category, index)
    local instance = ValueType.new(sdk.find_type_definition("ace.ACTION_ID"))
    sdk.set_native_field(instance, sdk.find_type_definition("ace.ACTION_ID"), "_Category", category)
    sdk.set_native_field(instance, sdk.find_type_definition("ace.ACTION_ID"), "_Index", index)

    return instance
end

-- 命中返回事件钩子函数
-- 处理太刀的见切和反击逻辑
sdk.hook(
    sdk.find_type_definition("app.Hit"):get_method("callHitReturnEvent(System.Delegate[], app.HitInfo)"),
    function(args)
        if initMaster() == true then
            local hitinfo = sdk.to_managed_object(args[3])
            -- 检查攻击者是否为怪物
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
                
                -- 自动躲避逻辑
                if ConfigManager.autoDodgeEnabled and hitinfo:get_field("<DamageOwner>k__BackingField"):get_Name() == "MasterPlayer" and ConfigManager.autoDodgeActionIndex ~= nil then
                    -- 创建躲避动作ID
                    local actionID = NewActionID(2, ConfigManager.autoDodgeActionIndex)
                    
                    -- 执行躲避动作
                    if player:get_Character():call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, actionID, false) then
                        isAutoDodge = true
                        return sdk.PreHookResult.SKIP_ORIGINAL
                    end
                end
            end
        end
    end,
    function(retval)
        return retval
    end
)

-- 动作请求变更钩子函数
-- 跟踪玩家的动作变化
sdk.hook(
    sdk.find_type_definition("app.HunterCharacter"):get_method(
        "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)"), function(args)
        if initMaster() == true then
            local type = sdk.find_type_definition("ace.ACTION_ID")
            action_cata = sdk.get_native_field(args[4], type, "_Category")
            if action_cata == 2 then
                action_index = sdk.get_native_field(args[4], type, "_Index")
                -- 重置见切状态
                if action_index ~= 23 and motionID ~= 250 and action_index ~= 16 and motionID ~= 226 and motionID ~= 290 then
                    damage_owner = ""
                    Isjianqie = false
                end
                
                -- 重置自动躲避状态
                if isAutoDodge == true then
                    isAutoDodge = false
                end
            end
        end
    end
)

-- 太刀特殊动作钩子函数（可能是居合斩相关）
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

-- 太刀见切动作钩子函数
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

-- UI绘制函数
-- 创建配置界面
re.on_draw_ui(
    function()
        local changed = false
        if imgui.tree_node("LongSword") then
            changed, ConfigManager.loopAuraLevel = imgui.checkbox("hongren",  -- 红刃选项
                ConfigManager.loopAuraLevel);
            changed, ConfigManager.nadaoTime = imgui.drag_float("nadaoTime", ConfigManager.nadaoTime);  -- 纳刀时间选项
            changed, ConfigManager.kabutowariShellNum = imgui.slider_int("denglong_hit", ConfigManager  -- 灯笼命中选项
                .kabutowariShellNum, 7, 30);
                
            -- 添加自动躲避选项
            changed, ConfigManager.autoDodgeEnabled = imgui.checkbox("启用自动躲避", 
                ConfigManager.autoDodgeEnabled);
                
            -- 添加动作ID输入框
            if ConfigManager.autoDodgeEnabled then
                changed, ConfigManager.autoDodgeActionIndex = imgui.input_int("躲避动作ID", 
                    ConfigManager.autoDodgeActionIndex or 0);
                
                -- 添加说明文字
                imgui.text("注意：请使用action_logger.lua记录躲避动作ID，")
                imgui.text("然后在上方填写对应的动作ID值。")
            end
            
            imgui.tree_pop()
        end
    end
)
