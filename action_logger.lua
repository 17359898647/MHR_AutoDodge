-- action_logger.lua
local sdk = sdk
local log = log
local re = re
local imgui = imgui

-- 获取主玩家函数
local function get_master_player()
    local player_manager = sdk.get_managed_singleton("snow.player.PlayerManager")
    if not player_manager then return nil end
    return player_manager:call("findMasterPlayer")
end

-- 上一个动作ID
local last_action_id = 0
-- 记录的动作ID列表
local recorded_actions = {}
-- 是否记录动作
local is_recording = false

-- 创建UI
re.on_draw_ui(function()
    if imgui.begin_window("动作ID记录器", true) then
        is_recording = imgui.checkbox("记录动作ID", is_recording)
        
        if imgui.button("清除记录") then
            recorded_actions = {}
        end
        
        imgui.text("当前动作ID: " .. tostring(last_action_id))
        
        if #recorded_actions > 0 then
            imgui.separator()
            imgui.text("记录的动作ID:")
            
            for i, action in ipairs(recorded_actions) do
                imgui.text(string.format("%d: 动作ID=%d, 时间=%s", 
                    i, action.id, os.date("%H:%M:%S", action.time)))
            end
        end
        
        imgui.end_window()
    end
end)

-- 每帧检查
re.on_frame(function()
    local player = get_master_player()
    if not player then return end
    
    -- 获取玩家动作控制器
    local motion_control = player:get_field("_motionControl")
    if not motion_control then 
        -- 尝试其他可能的字段名
        motion_control = player:get_field("_playerMotionControl")
        if not motion_control then return end
    end
    
    -- 获取当前动作ID
    local current_action_id = motion_control:get_field("_actionId")
    if not current_action_id then 
        -- 尝试其他可能的字段名
        current_action_id = motion_control:get_field("_currentActionId")
        if not current_action_id then return end
    end
    
    -- 如果动作ID变化了
    if current_action_id ~= last_action_id then
        -- 输出到日志
        log.info(string.format("动作ID变化: %d -> %d", last_action_id, current_action_id))
        
        -- 如果正在记录，则添加到列表
        if is_recording then
            table.insert(recorded_actions, {
                id = current_action_id,
                time = os.time()
            })
        end
        
        -- 更新上一个动作ID
        last_action_id = current_action_id
    end
end)

-- 添加钩子函数，监听动作变化
sdk.hook(
    sdk.find_type_definition("snow.player.PlayerBase"):get_method("changeAction"),
    function(args)
        local player = sdk.to_managed_object(args[2])
        local action_id = sdk.to_int64(args[3])
        
        log.info(string.format("changeAction被调用: 动作ID=%d", action_id))
    end,
    function(retval)
        return retval
    end
)
