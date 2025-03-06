-- auto_dodge.lua
-- 怪物猎人崛起自动躲避模组
local re = re
local sdk = sdk
local log = log
local imgui = imgui
local string = string
local table = table
local os = os
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local math = math

local Core = require("_CatLib")
local Utils = require("_CatLib.utils")

-- 创建模组实例
local MOD_NAME = "自动躲避"
local mod = Core.NewMod(MOD_NAME)
mod.EnableCJKFont(18) -- 启用中文字体

-- 初始化配置
if mod.Config.Enabled == nil then
    mod.Config.Enabled = true
    mod.Config.UseAutoRoll = true
    mod.Config.UseAutoGuard = true
    mod.Config.UseAutoJump = false
    mod.Config.DodgeRange = 5.0      -- 触发躲避的距离范围（米）
    mod.Config.ReactionTime = 0.2    -- 反应时间（秒）
    mod.Config.CooldownTime = 1.0    -- 冷却时间（秒）
    mod.Config.ActivationPercent = 80 -- 触发几率(%)
    mod.SaveConfig()
end

-- 运行时数据
mod.Runtime = {
    LastDodgeTime = 0,         -- 上次躲避时间
    IsInDanger = false,        -- 是否处于危险状态
    NearbyEnemies = {},        -- 附近的敌人
    AttackPatterns = {},       -- 已知的攻击模式
    PlayerState = {            -- 玩家状态
        IsGuarding = false,
        IsRolling = false,
        IsJumping = false,
        CurrentActionId = 0,
        PreviousActionId = 0,
        Health = 100,
        Stamina = 100
    }
}

-- 常量定义
local DODGE_ACTIONS = {
    ROLL = 233,       -- 翻滚动作ID（示例值，需要通过action_logger确定真实值）
    GUARD = 355,      -- 防御动作ID（示例值，需要通过action_logger确定真实值）
    JUMP = 166,       -- 跳跃动作ID（示例值，需要通过action_logger确定真实值）
    BACKSTEP = 241    -- 后跳动作ID（示例值，需要通过action_logger确定真实值）
}

-- 攻击模式列表（这里需要根据实际情况添加更多攻击模式）
local ATTACK_PATTERNS = {
    {
        enemyType = "em001_00", -- 怪物类型ID
        attackName = "Charge",   -- 攻击名称
        actionId = 51,          -- 攻击动作ID
        dangerTime = 0.8,       -- 提前预警时间（秒）
        dodgeMethod = "ROLL"    -- 推荐躲避方式
    },
    {
        enemyType = "em001_00",
        attackName = "Fireball",
        actionId = 67,
        dangerTime = 1.0,
        dodgeMethod = "ROLL"
    },
    -- 可以添加更多攻击模式
}

-- 加载攻击模式
for _, pattern in ipairs(ATTACK_PATTERNS) do
    mod.Runtime.AttackPatterns[pattern.enemyType .. "_" .. pattern.actionId] = pattern
end

-- 获取主玩家
local function get_player()
    return Core.GetPlayerInfo()
end

-- 获取怪物管理器
local function get_enemy_manager()
    return Core.GetEnemyManager()
end

-- 检查是否可以执行躲避动作
local function can_dodge()
    local current_time = os.clock()
    
    -- 检查冷却时间
    if current_time - mod.Runtime.LastDodgeTime < mod.Config.CooldownTime then
        return false
    end
    
    -- 检查玩家状态（不能在某些状态下执行躲避，例如已经在翻滚、跳跃或防御中）
    if mod.Runtime.PlayerState.IsRolling or 
       mod.Runtime.PlayerState.IsJumping or 
       mod.Runtime.PlayerState.IsGuarding then
        return false
    end
    
    -- 检查触发几率
    if math.random(1, 100) > mod.Config.ActivationPercent then
        return false
    end
    
    return true
end

-- 执行躲避动作
local function perform_dodge(dodge_type)
    local player = get_player()
    if not player then return false end
    
    local motion_control = player:get_field("_motionControl") or player:get_field("_playerMotionControl")
    if not motion_control then return false end
    
    log.info("执行躲避动作: " .. dodge_type)
    
    if dodge_type == "ROLL" and mod.Config.UseAutoRoll then
        -- 执行翻滚动作
        motion_control:call("requestActionByFixedID", DODGE_ACTIONS.ROLL, 0)
        mod.Runtime.PlayerState.IsRolling = true
    elseif dodge_type == "GUARD" and mod.Config.UseAutoGuard then
        -- 执行防御动作
        motion_control:call("requestActionByFixedID", DODGE_ACTIONS.GUARD, 0)
        mod.Runtime.PlayerState.IsGuarding = true
    elseif dodge_type == "JUMP" and mod.Config.UseAutoJump then
        -- 执行跳跃动作
        motion_control:call("requestActionByFixedID", DODGE_ACTIONS.JUMP, 0)
        mod.Runtime.PlayerState.IsJumping = true
    elseif dodge_type == "BACKSTEP" then
        -- 执行后跳动作
        motion_control:call("requestActionByFixedID", DODGE_ACTIONS.BACKSTEP, 0)
    else
        return false
    end
    
    -- 更新上次躲避时间
    mod.Runtime.LastDodgeTime = os.clock()
    return true
end

-- 检测附近的怪物
local function detect_nearby_enemies()
    local player = get_player()
    if not player then return {} end
    
    local player_position = player:call("get_Position")
    if not player_position then return {} end
    
    local enemy_manager = get_enemy_manager()
    if not enemy_manager then return {} end
    
    local enemies = {}
    local enemy_count = enemy_manager:call("get_ActiveEnemyCount")
    
    for i = 0, enemy_count - 1 do
        local enemy = enemy_manager:call("getActiveEnemyAt", i)
        if enemy then
            local enemy_position = enemy:call("get_Position")
            if enemy_position then
                local distance = math.sqrt(
                    (player_position.x - enemy_position.x)^2 + 
                    (player_position.y - enemy_position.y)^2 + 
                    (player_position.z - enemy_position.z)^2
                )
                
                if distance <= mod.Config.DodgeRange then
                    local enemy_type = enemy:get_field("_enemyTypeIndex")
                    local action_id = enemy:get_field("_actionId") or enemy:get_field("_currentActionId") or 0
                    
                    table.insert(enemies, {
                        enemy = enemy,
                        type = enemy_type,
                        actionId = action_id,
                        distance = distance
                    })
                end
            end
        end
    end
    
    return enemies
end

-- 分析危险情况
local function analyze_danger()
    local nearby_enemies = detect_nearby_enemies()
    mod.Runtime.NearbyEnemies = nearby_enemies
    
    local is_in_danger = false
    local recommended_dodge = "ROLL" -- 默认躲避方式
    
    for _, enemy_data in ipairs(nearby_enemies) do
        local pattern_key = tostring(enemy_data.type) .. "_" .. tostring(enemy_data.actionId)
        local pattern = mod.Runtime.AttackPatterns[pattern_key]
        
        if pattern then
            log.info("检测到危险攻击模式: " .. pattern.attackName)
            is_in_danger = true
            recommended_dodge = pattern.dodgeMethod
            break
        end
    end
    
    return is_in_danger, recommended_dodge
end

-- 更新玩家状态
local function update_player_state()
    local player = get_player()
    if not player then return end
    
    local motion_control = player:get_field("_motionControl") or player:get_field("_playerMotionControl")
    if not motion_control then return end
    
    local current_action_id = motion_control:get_field("_actionId") or motion_control:get_field("_currentActionId") or 0
    
    -- 记录上一次动作ID
    mod.Runtime.PlayerState.PreviousActionId = mod.Runtime.PlayerState.CurrentActionId
    mod.Runtime.PlayerState.CurrentActionId = current_action_id
    
    -- 重置状态标志
    if mod.Runtime.PlayerState.IsRolling and current_action_id ~= DODGE_ACTIONS.ROLL then
        mod.Runtime.PlayerState.IsRolling = false
    end
    
    if mod.Runtime.PlayerState.IsJumping and current_action_id ~= DODGE_ACTIONS.JUMP then
        mod.Runtime.PlayerState.IsJumping = false
    end
    
    if mod.Runtime.PlayerState.IsGuarding and current_action_id ~= DODGE_ACTIONS.GUARD then
        mod.Runtime.PlayerState.IsGuarding = false
    end
    
    -- 获取生命值和耐力
    local player_data = player:get_field("_playerData")
    if player_data then
        local health_manager = player_data:get_field("_healthManager")
        if health_manager then
            mod.Runtime.PlayerState.Health = health_manager:get_field("_vitalMax")
        end
        
        local stamina_manager = player_data:get_field("_staminaManager")
        if stamina_manager then
            mod.Runtime.PlayerState.Stamina = stamina_manager:get_field("_staminaMax")
        end
    end
end

-- 自动躲避主逻辑
local function auto_dodge_main()
    if not mod.Config.Enabled then return end
    
    -- 更新玩家状态
    update_player_state()
    
    -- 分析危险情况
    local is_in_danger, recommended_dodge = analyze_danger()
    mod.Runtime.IsInDanger = is_in_danger
    
    -- 如果处于危险中且可以躲避，则执行躲避动作
    if is_in_danger and can_dodge() then
        perform_dodge(recommended_dodge)
    end
end

-- 创建UI菜单
mod.Menu(function()
    local configChanged = false
    local changed = false
    
    changed, mod.Config.Enabled = imgui.checkbox("启用自动躲避", mod.Config.Enabled)
    configChanged = configChanged or changed
    
    imgui.separator()
    imgui.text("躲避设置:")
    
    changed, mod.Config.UseAutoRoll = imgui.checkbox("启用自动翻滚", mod.Config.UseAutoRoll)
    configChanged = configChanged or changed
    
    changed, mod.Config.UseAutoGuard = imgui.checkbox("启用自动防御", mod.Config.UseAutoGuard)
    configChanged = configChanged or changed
    
    changed, mod.Config.UseAutoJump = imgui.checkbox("启用自动跳跃", mod.Config.UseAutoJump)
    configChanged = configChanged or changed
    
    imgui.separator()
    imgui.text("参数设置:")
    
    changed, mod.Config.DodgeRange = imgui.slider_float("躲避范围(米)", mod.Config.DodgeRange, 1.0, 20.0)
    configChanged = configChanged or changed
    
    changed, mod.Config.ReactionTime = imgui.slider_float("反应时间(秒)", mod.Config.ReactionTime, 0.0, 1.0)
    configChanged = configChanged or changed
    
    changed, mod.Config.CooldownTime = imgui.slider_float("冷却时间(秒)", mod.Config.CooldownTime, 0.5, 5.0)
    configChanged = configChanged or changed
    
    changed, mod.Config.ActivationPercent = imgui.slider_int("触发几率(%)", mod.Config.ActivationPercent, 1, 100)
    configChanged = configChanged or changed
    
    imgui.separator()
    if mod.Config.Debug then
        imgui.text("调试信息:")
        imgui.text("处于危险: " .. (mod.Runtime.IsInDanger and "是" or "否"))
        imgui.text("上次躲避时间: " .. string.format("%.2f秒前", os.clock() - mod.Runtime.LastDodgeTime))
        imgui.text("当前动作ID: " .. tostring(mod.Runtime.PlayerState.CurrentActionId))
        
        imgui.text("附近敌人数量: " .. #mod.Runtime.NearbyEnemies)
        for i, enemy_data in ipairs(mod.Runtime.NearbyEnemies) do
            imgui.text(string.format("敌人 %d: 类型=%s, 动作ID=%d, 距离=%.2f米", 
                i, tostring(enemy_data.type), enemy_data.actionId, enemy_data.distance))
        end
    end
    
    return configChanged
end)

-- 添加调试菜单
mod.SubDebugMenu("动作ID设置", function()
    local configChanged = false
    local changed = false
    
    imgui.text("设置躲避动作的ID:")
    
    changed, DODGE_ACTIONS.ROLL = imgui.drag_int("翻滚动作ID", DODGE_ACTIONS.ROLL, 1, 0, 1000)
    if changed then
        log.info("更新翻滚动作ID: " .. DODGE_ACTIONS.ROLL)
        configChanged = true
    end
    
    changed, DODGE_ACTIONS.GUARD = imgui.drag_int("防御动作ID", DODGE_ACTIONS.GUARD, 1, 0, 1000)
    if changed then
        log.info("更新防御动作ID: " .. DODGE_ACTIONS.GUARD)
        configChanged = true
    end
    
    changed, DODGE_ACTIONS.JUMP = imgui.drag_int("跳跃动作ID", DODGE_ACTIONS.JUMP, 1, 0, 1000)
    if changed then
        log.info("更新跳跃动作ID: " .. DODGE_ACTIONS.JUMP)
        configChanged = true
    end
    
    changed, DODGE_ACTIONS.BACKSTEP = imgui.drag_int("后跳动作ID", DODGE_ACTIONS.BACKSTEP, 1, 0, 1000)
    if changed then
        log.info("更新后跳动作ID: " .. DODGE_ACTIONS.BACKSTEP)
        configChanged = true
    end
    
    imgui.separator()
    imgui.text("攻击模式设置:")
    
    -- 这里可以添加攻击模式的编辑功能
    
    return configChanged
end)

-- 在每帧中执行自动躲避逻辑
-- Runs the automatic dodge logic on every frame.
-- This function is called after the game's internal update logic, so it can
-- access the latest game state.
-- @param func function to be called on every frame
mod.OnFrame(function()
    auto_dodge_main()
end)

-- 添加钩子函数，拦截怪物攻击动作变化
mod.HookFunc(
    "snow.enemy.EnemyCharacterBase",
    "setActionId",
    function(args)
        if not mod.Config.Enabled then return end
        
        local enemy = sdk.to_managed_object(args[2])
        local action_id = sdk.to_int64(args[3])
        
        local enemy_type = enemy:get_field("_enemyTypeIndex")
        local pattern_key = tostring(enemy_type) .. "_" .. tostring(action_id)
        
        if mod.Runtime.AttackPatterns[pattern_key] then
            log.info(string.format("拦截到危险攻击: 敌人类型=%s, 动作ID=%d", tostring(enemy_type), action_id))
            
            -- 如果攻击被识别为危险攻击，可以立即尝试躲避
            if can_dodge() then
                perform_dodge(mod.Runtime.AttackPatterns[pattern_key].dodgeMethod)
            end
        end
    end
)

-- 运行模组
mod.Run()
