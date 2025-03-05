-- 游戏管理器相关变量
local MasterPlayer      -- 玩家管理器单例
local player            -- 主角玩家对象
local weaponType        -- 武器类型
local isWeaponOn        -- 武器是否拔出状态
local action_index = 0  -- 当前动作索引
local action_cata = 0   -- 当前动作类别
local damage_owner = "" -- 伤害来源
local motionID          -- 当前动作ID
local gameObje          -- 游戏对象
local auraLevel         -- 太刀气刃等级
local Isjianqie = false -- 是否处于见切状态

-- 添加动作ID监控相关变量
local lastPrintTime = 0   -- 上次打印动作信息的时间
local lastActionInfo = "" -- 上次打印的动作信息
local actionBankId = 0    -- 动作库ID

-- 添加自动闪避相关变量
local lastDodgeTime = 0   -- 上次执行闪避的时间
local isDodging = false   -- 是否正在执行闪避
local dodgeCooldown = 1.0 -- 闪避冷却时间（秒）

local ConfigManager = {
    -- 太刀相关配置
    kabutowariShellNum = 7,  -- 兜割伤害次数
    loopAuraLevel = false,   -- 是否无限红刃
    nadaoTime = 3.5,         -- 纳刀时长
    
    -- 动作ID监控配置
    printActionID = true,     -- 是否启用动作ID监控
    printActionDelay = 0.5,   -- 动作ID打印延迟（秒）
    showInGameMsg = true,     -- 是否在游戏中显示消息
    logToConsole = false,     -- 是否输出到控制台
    
    -- 自动闪避配置
    autoDodge = false,       -- 是否启用自动闪避
    dodgeCategory = 0,       -- 闪避动作类别，需要用户填写
    dodgeIndex = 0,          -- 闪避动作索引，需要用户填写
    dodgeDelay = 0.1,        -- 闪避延迟（秒）
    dodgeNotify = true       -- 是否在闪避时显示通知
}

-- 获取组件函数
local function getComponent(obj, type)
    return obj:call("getComponent(System.Type)", sdk.typeof(type))
end

-- 初始化主角函数
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
        "DongZuo ID XinXi:\nLeiBie(Category): %d\nSuoYin(Index): %d\nDongZuoID(MotionID): %d\nWuQiLeiXing: %d\nWuQiZhuangTai: %s", 
        action_cata, 
        action_index, 
        motionID, 
        weaponType, 
        isWeaponOn and "YiBaChu" or "YiShouQi"
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
            log.debug(actionInfo)
        end
        
        if ConfigManager.logToConsole then
            log.info(actionInfo)
        end
        
        lastActionInfo = actionInfo
        lastPrintTime = currentTime
    end
end

-- 执行闪避动作的函数
local function performDodge()
    if not initMaster() then return false end
    
    local currentTime = os.clock()
    if currentTime - lastDodgeTime < dodgeCooldown then return false end
    
    -- 创建闪避动作ID
    local dodgeActionID = NewActionID(ConfigManager.dodgeCategory, ConfigManager.dodgeIndex)
    
    -- 执行闪避动作
    local success = player:get_Character():call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 
        0, dodgeActionID, false)
    
    if success then
        lastDodgeTime = currentTime
        isDodging = true
        
        if ConfigManager.dodgeNotify then
            log.debug("ZhiXing ZiDong ShanBi!")
        end
        
        return true
    end
    
    return false
end

-- 模糊匹配函数
local function fuzzy_match(str, pattern)
    return string.find(str, pattern) ~= nil
end

-- 排除的动作ID列表
local excludedMotionIDs = {
    230, 232, 233, 237,
    249, 250, 252, 263, 264, 265,
    295,
    226, 290,
    466, 467
}

-- 动作ID查找表
local motionIDLookup = {}
for _, id in ipairs(excludedMotionIDs) do
    motionIDLookup[id] = true
end

-- 检测动作状态函数
local function checkMotionState()
    return not motionIDLookup[motionID]
end

-- 无限红刃钩子
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

-- 纳刀时长钩子
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

-- 创建动作ID函数
local function NewActionID(category, index)
    local instance = ValueType.new(sdk.find_type_definition("ace.ACTION_ID"))
    sdk.set_native_field(instance, sdk.find_type_definition("ace.ACTION_ID"), "_Category", category)
    sdk.set_native_field(instance, sdk.find_type_definition("ace.ACTION_ID"), "_Index", index)

    return instance
end

-- 伤害检测钩子
sdk.hook(
    sdk.find_type_definition("app.Hit"):get_method("callHitReturnEvent(System.Delegate[], app.HitInfo)"),
    function(args)
        if initMaster() == true then
            local hitinfo = sdk.to_managed_object(args[3])
            local em = fuzzy_match(hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name(), "Em")
            local minEm = fuzzy_match(hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name(), "em")
            local gm = fuzzy_match(hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name(), "Gm")
            local heal = fuzzy_match(hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name(), "Heal")
            
            -- 检测敌人攻击并尝试自动闪避
            if ConfigManager.autoDodge and (em == true or gm == true or minEm == true) and heal == false then
                -- 如果目标是玩家，且闪避动作ID已设置，则执行闪避
                if hitinfo:get_field("<DamageOwner>k__BackingField"):get_Name() == "MasterPlayer" and
                   ConfigManager.dodgeCategory > 0 and ConfigManager.dodgeIndex > 0 then
                    -- 添加一个小延迟后执行闪避
                    re.on_next_frame(function()
                        performDodge()
                    end)
                end
            end
            
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

-- 动作切换钩子
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

-- 自动闪避钩子
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

-- 帧更新钩子
re.on_frame(function()
    if ConfigManager.printActionID and initMaster() then
        printActionInfo()
    end
    
    -- 重置闪避状态
    if isDodging and os.clock() - lastDodgeTime > 1.0 then
        isDodging = false
    end
end)

-- UI绘制函数
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
        if imgui.tree_node("DongZuo ID JianKong") then
            changed, ConfigManager.printActionID = imgui.checkbox("QiYong DongZuo ID JianKong", 
                ConfigManager.printActionID);
                
            if ConfigManager.printActionID then
                changed, ConfigManager.printActionDelay = imgui.drag_float("GengXin YanChi(miao)", 
                    ConfigManager.printActionDelay, 0.1, 0.1, 5.0);
                changed, ConfigManager.showInGameMsg = imgui.checkbox("ShuChu Dao Debug RiZhi", 
                    ConfigManager.showInGameMsg);
                changed, ConfigManager.logToConsole = imgui.checkbox("ShuChu Dao Info RiZhi", 
                    ConfigManager.logToConsole);
                
                if imgui.button("LiJi DaYin DangQian DongZuo ID") then
                    printActionInfo(true)  -- 强制立即打印
                end
                
                -- 显示当前动作ID信息
                imgui.text_wrapped(getActionInfo())
            end
            
            imgui.tree_pop()
        end
        
        -- 添加自动闪避配置节点
        if imgui.tree_node("ZiDong ShanBi") then
            changed, ConfigManager.autoDodge = imgui.checkbox("QiYong ZiDong ShanBi", 
                ConfigManager.autoDodge);
                
            if ConfigManager.autoDodge then
                changed, ConfigManager.dodgeCategory = imgui.drag_int("ShanBi DongZuo LeiBie", 
                    ConfigManager.dodgeCategory, 1, 0, 100);
                changed, ConfigManager.dodgeIndex = imgui.drag_int("ShanBi DongZuo SuoYin", 
                    ConfigManager.dodgeIndex, 1, 0, 100);
                changed, ConfigManager.dodgeDelay = imgui.drag_float("ShanBi YanChi(miao)", 
                    ConfigManager.dodgeDelay, 0.05, 0.0, 1.0);
                changed, ConfigManager.dodgeNotify = imgui.checkbox("ShanBi Shi ShuChu Debug XiaoXi", 
                    ConfigManager.dodgeNotify);
                
                if imgui.button("CeShi ShanBi") and ConfigManager.dodgeCategory > 0 and ConfigManager.dodgeIndex > 0 then
                    performDodge()
                end
                
                -- 显示闪避状态
                if isDodging then
                    imgui.text_colored("ZhengZai ShanBi Zhong...", 0.0, 1.0, 0.0, 1.0)
                elseif os.clock() - lastDodgeTime < dodgeCooldown then
                    imgui.text_colored(string.format("ShanBi LengQue Zhong (%.1f miao)", dodgeCooldown - (os.clock() - lastDodgeTime)), 1.0, 0.5, 0.0, 1.0)
                else
                    imgui.text_colored("ShanBi JiuXu", 0.0, 1.0, 0.0, 1.0)
                end
                
                imgui.text_wrapped("ShiYong FangFa:\n1. QiYong ZiDong ShanBi\n2. SheDing ShanBi DongZuo LeiBie He SuoYin\n3. KeYi TongGuo DongZuo ID JianKong GongNeng ZhaoDao HeShi De ShanBi DongZuo ID\n4. ShiYong 'CeShi ShanBi' AnNiu CeShi SheDing ShiFou YouXiao")
            end
            
            imgui.tree_pop()
        end
    end
)

-- 自动闪避钩子
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
