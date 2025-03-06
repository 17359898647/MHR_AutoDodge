-- action_logger.lua
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
local json = json

local Core = require("_CatLib")
local Utils = require("_CatLib.utils")

-- 创建模组实例
local MOD_NAME = "动作ID记录器"
local mod = Core.NewMod(MOD_NAME)
mod.EnableCJKFont(18) -- 启用中文字体

-- 初始化配置
if mod.Config.IsRecording == nil then
    mod.Config.IsRecording = false
    mod.Config.SaveRecordsToFile = false
    mod.Config.AutoExportImportantActions = false
    mod.SaveConfig()
end

-- 运行时数据
mod.Runtime = {
    LastActionId = 0,
    RecordedActions = {},
    ImportantActions = {
        -- 玩家动作
        ROLL = { id = 0, description = "翻滚" },
        GUARD = { id = 0, description = "防御" },
        JUMP = { id = 0, description = "跳跃" },
        BACKSTEP = { id = 0, description = "后跳" },
        -- 怪物动作
        -- 可以根据需要添加更多
    }
}

-- 获取主玩家函数
local function get_master_player()
    return Core.GetPlayerInfo()
end

-- 清除记录的动作
local function clear_recorded_actions()
    mod.Runtime.RecordedActions = {}
end

-- 将动作ID标记为重要动作
local function mark_as_important_action(action_id, action_type)
    if action_type and mod.Runtime.ImportantActions[action_type] then
        mod.Runtime.ImportantActions[action_type].id = action_id
        log.info(string.format("已将动作ID %d 标记为 %s", action_id, action_type))
    end
end

-- 保存记录到文件
local function save_records_to_file()
    local filename = "action_records_" .. os.date("%Y%m%d_%H%M%S") .. ".json"
    json.dump_file(filename, mod.Runtime.RecordedActions)
    log.info("已保存记录到文件: " .. filename)
end

-- 导出重要动作ID
local function export_important_actions()
    local filename = "important_actions.json"
    json.dump_file(filename, mod.Runtime.ImportantActions)
    log.info("已导出重要动作ID到文件: " .. filename)
end

-- 导入重要动作ID
local function import_important_actions()
    local filename = "important_actions.json"
    local data = json.load_file(filename)
    if data then
        mod.Runtime.ImportantActions = data
        log.info("已从文件导入重要动作ID: " .. filename)
        return true
    end
    return false
end

-- 记录动作ID
local function record_action_id(action_id)
    if mod.Config.IsRecording then
        table.insert(mod.Runtime.RecordedActions, {
            id = action_id,
            time = os.time(),
            timestamp = os.date("%H:%M:%S")
        })
        
        -- 如果启用了自动保存到文件，且记录数量达到了指定值，则保存
        if mod.Config.SaveRecordsToFile and #mod.Runtime.RecordedActions % 50 == 0 then
            save_records_to_file()
        end
    end
    
    -- 输出到日志
    log.info(string.format("动作ID变化: %d -> %d", mod.Runtime.LastActionId, action_id))
    
    -- 更新上一个动作ID
    mod.Runtime.LastActionId = action_id
end

-- 创建UI菜单
mod.Menu(function()
    local configChanged = false
    local changed = false
    
    changed, mod.Config.IsRecording = imgui.checkbox("记录动作ID", mod.Config.IsRecording)
    configChanged = configChanged or changed
    
    changed, mod.Config.SaveRecordsToFile = imgui.checkbox("自动保存记录到文件", mod.Config.SaveRecordsToFile)
    configChanged = configChanged or changed
    
    changed, mod.Config.AutoExportImportantActions = imgui.checkbox("自动导出重要动作ID", mod.Config.AutoExportImportantActions)
    configChanged = configChanged or changed
    
    if imgui.button("清除记录") then
        clear_recorded_actions()
    end
    
    imgui.same_line()
    if imgui.button("手动保存记录") then
        save_records_to_file()
    end
    
    imgui.same_line()
    if imgui.button("导出重要动作") then
        export_important_actions()
    end
    
    imgui.same_line()
    if imgui.button("导入重要动作") then
        import_important_actions()
    end
    
    imgui.separator()
    imgui.text("当前动作ID: " .. tostring(mod.Runtime.LastActionId))
    
    -- 显示重要动作区
    imgui.separator()
    imgui.text("重要动作ID:")
    
    for action_type, action_data in pairs(mod.Runtime.ImportantActions) do
        if imgui.button("标记为" .. action_data.description) then
            mark_as_important_action(mod.Runtime.LastActionId, action_type)
            configChanged = true
        end
        imgui.same_line()
        imgui.text(string.format("%s: %d", action_data.description, action_data.id))
    end
    
    -- 显示记录列表
    if #mod.Runtime.RecordedActions > 0 then
        imgui.separator()
        imgui.text("记录的动作ID:")
        
        for i, action in ipairs(mod.Runtime.RecordedActions) do
            if i > 50 then -- 只显示最新的50条记录
                imgui.text("...")
                break
            end
            
            local is_important = false
            local importance = ""
            
            -- 检查这个动作ID是否是重要动作
            for action_type, action_data in pairs(mod.Runtime.ImportantActions) do
                if action_data.id == action.id then
                    is_important = true
                    importance = " [" .. action_data.description .. "]"
                    break
                end
            end
            
            -- 如果是重要动作，使用不同颜色显示
            if is_important then
                imgui.text_colored(0.0, 1.0, 0.0, 1.0, 
                    string.format("%d: 动作ID=%d%s, 时间=%s", 
                    i, action.id, importance, action.timestamp or os.date("%H:%M:%S", action.time)))
            else
                imgui.text(string.format("%d: 动作ID=%d, 时间=%s", 
                    i, action.id, action.timestamp or os.date("%H:%M:%S", action.time)))
            end
        end
    end
    
    return configChanged
end)

-- 每帧检查动作ID变化
mod.OnFrame(function()
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
    if current_action_id ~= mod.Runtime.LastActionId then
        record_action_id(current_action_id)
        
        -- 如果启用了自动导出重要动作ID
        if mod.Config.AutoExportImportantActions then
            export_important_actions()
        end
    end
end)

-- 添加钩子函数，监听动作变化
mod.HookFunc(
    "snow.player.PlayerBase",
    "changeAction",
    function(args)
        local player = sdk.to_managed_object(args[2])
        local action_id = sdk.to_int64(args[3])
        
        log.info(string.format("changeAction被调用: 动作ID=%d", action_id))
    end
)

-- 尝试导入重要动作ID
import_important_actions()

-- 运行模组
mod.Run()
