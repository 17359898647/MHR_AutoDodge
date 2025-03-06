-- juhe.lua (太刀增强模组)
local re = re
local sdk = sdk
local log = log
local imgui = imgui
local string = string
local table = table
local pairs = pairs
local tostring = tostring
local math = math
local type = type
local ipairs = ipairs

local Core = require("_CatLib")
local Utils = require("_CatLib.utils")
local CONST = require("_CatLib.const")

-- 创建模组实例
local mod = Core.NewMod("太刀增强")
mod.EnableCJKFont(18) -- 启用中文字体

-- 初始化配置
if mod.Config.loopAuraLevel == nil then
    mod.Config.loopAuraLevel = false
end

if mod.Config.nadaoTime == nil then
    mod.Config.nadaoTime = 3.5
end

if mod.Config.kabutowariShellNum == nil then
    mod.Config.kabutowariShellNum = 7
end

if mod.Config.Debug == nil then
    mod.Config.Debug = false
end

if mod.Config.Enabled == nil then
    mod.Config.Enabled = true
end

-- 排除的动作ID列表
local excludedMotionIDs = {
    230, 232, 233, 237,
    249, 250, 252, 263, 264, 265,
    295,
    226, 290,
    466, 467
}

-- 创建快速查找表
local motionIDLookup = {}
for _, id in ipairs(excludedMotionIDs) do
    motionIDLookup[id] = true
end

-- 运行时数据
local Runtime = {
    MasterPlayer = nil,        -- 主角玩家对象，用于获取玩家实例
    player = nil,              -- 玩家数据对象，包含玩家状态和属性
    weaponType = nil,          -- 武器类型，用于识别当前装备的武器
    isWeaponOn = nil,          -- 武器是否已拔出，true表示武器已拔出，false表示武器已收起
    action_index = 0,          -- 当前动作索引，用于标识具体动作
    action_cata = 0,           -- 当前动作类别，用于分类不同类型的动作
    damage_owner = "",         -- 伤害来源，记录造成伤害的实体
    motionID = nil,            -- 动作ID，用于识别特定的动作动画
    gameObje = nil,            -- 游戏对象，用于引用当前相关的游戏实体
    auraLevel = 1,             -- 气场等级，用于太刀特殊状态(如斩气等级)
    Isjianqie = false          -- 是否处于见切状态，太刀特有的一种反击姿态
}

-- 获取组件
local function getComponent(obj, type)
    return obj:call("getComponent(System.Type)", sdk.typeof(type))
end

-- 创建动作ID
local function NewActionID(category, index)
    local instance = ValueType.new(sdk.find_type_definition("ace.ACTION_ID"))
    sdk.set_native_field(instance, sdk.find_type_definition("ace.ACTION_ID"), "_Category", category)
    sdk.set_native_field(instance, sdk.find_type_definition("ace.ACTION_ID"), "_Index", index)
    return instance
end

-- 字符串模糊匹配
local function fuzzy_match(str, pattern)
    return string.find(str, pattern) ~= nil
end

-- 统一检测函数
local function checkMotionState()
    return not motionIDLookup[Runtime.motionID]
end

-- 初始化主玩家
local function initMaster()
    if not Runtime.MasterPlayer then
        Runtime.MasterPlayer = sdk.get_managed_singleton("app.PlayerManager")
    end
    if not Runtime.MasterPlayer then return false end

    if not Runtime.player then
        Runtime.player = Runtime.MasterPlayer:getMasterPlayer()
    end
    if not Runtime.player then return false end

    if not Runtime.gameObje then
        Runtime.gameObje = Runtime.player:get_Object()
    end
    if not Runtime.gameObje then return false end

    Runtime.motionID = getComponent(Runtime.gameObje, 'via.motion.Motion'):getLayer(0):get_MotionID()
    Runtime.weaponType = Runtime.player:get_Character():get_Weapon():get_field("_WpType")
    Runtime.isWeaponOn = Runtime.player:get_Character():get_IsWeaponOn()
    
    if Runtime.isWeaponOn == true and Runtime.weaponType == 3 then
        return true
    else
        return false
    end
end

-- 无限红刃
mod.HookFunc(
    "app.cHunterWp03Handling",
    "doUpdate()",
    function(args)
        local obj = sdk.to_managed_object(args[2])
        if not initMaster() then return end
        
        if mod.Config.loopAuraLevel and obj:call('get_AuraLevel') < 4 then
            obj:call('set_AuraLevel', 4)
            Runtime.auraLevel = obj:call('get_AuraLevel')
        else
            Runtime.auraLevel = 1
        end
        
        obj:set_field('_KabutowariShellNum', mod.Config.kabutowariShellNum)
    end
)

-- 纳刀时长
mod.HookFunc(
    "app.Wp03Action.cIaiWpOff",
    "doUpdate()",
    function(args)
        local obj = sdk.to_managed_object(args[2])
        if not initMaster() then return end
        
        obj:set_field('_IaiWpOffWaitTime', mod.Config.nadaoTime)
    end
)

-- 监听伤害事件
mod.HookFunc(
    "app.Hit",
    "callHitReturnEvent(System.Delegate[], app.HitInfo)",
    function(args)
        if not mod.Config.Enabled then return end
        if not initMaster() then return end
        
        local hitinfo = sdk.to_managed_object(args[3])
        local attackOwner = hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name()
        local damageOwner = hitinfo:get_field("<DamageOwner>k__BackingField"):get_Name()
        
        local em = fuzzy_match(attackOwner, "Em")
        local minEm = fuzzy_match(attackOwner, "em")
        local gm = fuzzy_match(attackOwner, "Gm")
        local heal = fuzzy_match(attackOwner, "Heal")
        
        if (em or gm or minEm) and not heal then
            if Runtime.action_index == 23 and Runtime.motionID == 250 and damageOwner == "MasterPlayer" then
                Runtime.damage_owner = "MasterPlayer"
                Runtime.Isjianqie = false
                return sdk.PreHookResult.SKIP_ORIGINAL
            elseif damageOwner == "MasterPlayer" and Runtime.action_index ~= 23 and checkMotionState() then
                Runtime.damage_owner = "MasterPlayer"
                Runtime.Isjianqie = true
                return sdk.PreHookResult.SKIP_ORIGINAL
            end
        end
    end
)

-- 监听动作变更
mod.HookFunc(
    "app.HunterCharacter",
    "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)",
    function(args)
        if not mod.Config.Enabled then return end
        if not initMaster() then return end
        
        local type = sdk.find_type_definition("ace.ACTION_ID")
        Runtime.action_cata = sdk.get_native_field(args[4], type, "_Category")
        
        if Runtime.action_cata == 2 then
            Runtime.action_index = sdk.get_native_field(args[4], type, "_Index")
            if Runtime.action_index ~= 23 and Runtime.motionID ~= 250 and 
               Runtime.action_index ~= 16 and Runtime.motionID ~= 226 and 
               Runtime.motionID ~= 290 then
                Runtime.damage_owner = ""
                Runtime.Isjianqie = false
            end
        end
    end
)

-- 自动执行居合斩
mod.HookFunc(
    "app.Wp03_Export",
    "table_6820f751_3c7a_2bdf_415f_6f6842fb3e52(ace.btable.cCommandWork, ace.btable.cOperatorWork)",
    function(args)
        if not mod.Config.Enabled then return end
        
        local actionID = NewActionID(2, 25 + Runtime.auraLevel)
        if Runtime.damage_owner == "MasterPlayer" and not Runtime.Isjianqie then
            if Runtime.player:get_Character():call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, actionID, false) then
                Runtime.damage_owner = ""
            end
        end
    end
)

-- 自动执行剑气斩
mod.HookFunc(
    "app.Wp03_Export",
    "table_b91e20f6_300d_4d56_8a9b_9aa6ed81076b(ace.btable.cCommandWork, ace.btable.cOperatorWork)",
    function(args)
        if not mod.Config.Enabled then return end
        
        local actionID = NewActionID(2, 16)
        if Runtime.damage_owner == "MasterPlayer" and Runtime.Isjianqie then
            if Runtime.player:get_Character():call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, actionID, false) then
                Runtime.damage_owner = ""
                Runtime.Isjianqie = false
            end
        end
    end
)

-- 日志输出函数
local function logDebugInfo()
    if not mod.Config.Enabled or not mod.Config.Debug then return end
    
    initMaster()
    if Runtime.player and Runtime.weaponType == 3 and Runtime.isWeaponOn then
        -- 仅在有需要时输出日志，避免过多日志
        if Runtime.damage_owner ~= "" then
            log.info(string.format("太刀状态: 动作=%d, 刀气=%d, 伤害源=%s, 疾闪=%s", 
                Runtime.motionID or 0, 
                Runtime.auraLevel or 0, 
                Runtime.damage_owner, 
                tostring(Runtime.Isjianqie)))
        end
    end
end

-- 创建UI菜单
mod.Menu(function()
    local configChanged = false
    local changed = false
    
    changed, mod.Config.Enabled = imgui.checkbox("启用太刀增强", mod.Config.Enabled)
    configChanged = configChanged or changed
    
    imgui.separator()
    
    if imgui.tree_node("基础设置") then
        changed, mod.Config.loopAuraLevel = imgui.checkbox("无限红刃", mod.Config.loopAuraLevel)
        configChanged = configChanged or changed
        
        changed, mod.Config.nadaoTime = imgui.drag_float("纳刀时间", mod.Config.nadaoTime, 0.1, 0.5, 10.0)
        configChanged = configChanged or changed
        
        changed, mod.Config.kabutowariShellNum = imgui.slider_int("灯笼命中次数", mod.Config.kabutowariShellNum, 7, 30)
        configChanged = configChanged or changed
        
        imgui.tree_pop()
    end
    
    if imgui.tree_node("调试选项") then
        changed, mod.Config.Debug = imgui.checkbox("启用调试信息", mod.Config.Debug)
        configChanged = configChanged or changed
        
        if mod.Config.Debug then
            imgui.text("当前刀气等级: " .. tostring(Runtime.auraLevel))
            imgui.text("当前动作ID: " .. tostring(Runtime.motionID))
            imgui.text("伤害来源: " .. Runtime.damage_owner)
            imgui.text("是否疾闪/见切: " .. tostring(Runtime.Isjianqie))
        end
        
        imgui.tree_pop()
    end
    
    if imgui.tree_node("排除的动作ID") then
        for i, id in ipairs(excludedMotionIDs) do
            imgui.text(string.format("%d: %d", i, id))
        end
        imgui.tree_pop()
    end
    
    return configChanged
end)

-- 注册帧更新事件
mod.OnFrame(logDebugInfo)

-- 运行模组
mod.Run()
