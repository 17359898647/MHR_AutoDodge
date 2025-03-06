-- auto_dodge_system.lua
-- 自动加载动作ID记录器和自动躲避模组

local log = log

log.info("=== 正在加载怪物猎人崛起自动躲避系统 ===")

-- 加载动作ID记录器
local success, action_logger = pcall(function() return require("action_logger") end)
if not success then
    log.error("加载动作ID记录器失败: " .. tostring(action_logger))
else
    log.info("动作ID记录器加载成功")
end

-- 加载自动躲避模组
local success, auto_dodge = pcall(function() return require("auto_dodge") end)
if not success then
    log.error("加载自动躲避模组失败: " .. tostring(auto_dodge))
else
    log.info("自动躲避模组加载成功")
end

log.info("=== 怪物猎人崛起自动躲避系统加载完成 ===")
