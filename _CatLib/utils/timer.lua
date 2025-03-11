-- Timer模块实现
local _M = {}

_M.timers = {}

-- 检查计时器是否存在
-- @param tag string 计时器标签
-- @return boolean 计时器是否存在
function _M:exists(tag)
    return self.timers[tag] ~= nil
end

-- 获取计时器剩余帧数
-- @param tag string 计时器标签
-- @return number|nil 剩余帧数，如果计时器不存在则返回nil
function _M:getRemainingFrames(tag)
    if not self.timers[tag] then
        return nil
    end
    return self.timers[tag].frame - self.timers[tag].current
end

function _M:getDebugRemainingFrames()
    local debug_string = ""
    for tag, t in pairs(self.timers) do
        debug_string = debug_string .. tag .. ": " .. (t.frame - t.current) .. "\n"
    end
    return debug_string
end

-- 运行计时器函数
-- @param tag string 计时器标签
-- @param frame number 计时器帧数
-- @param func function 计时器函数，每帧执行
-- @param stop_func function 计时器停止函数，可选
function _M:run(tag, frame, func, stop_func)
    if self.timers[tag] then
        -- 如果已存在同名计时器，刷新它
        self.timers[tag].frame = frame
        self.timers[tag].func = func
        self.timers[tag].stop_func = stop_func
    else
        -- 创建新计时器
        self.timers[tag] = {
            frame = frame,
            func = func,
            stop_func = stop_func,
            current = 0
        }
    end
end

-- 计时器主循环，需要放在一个update函数中
-- 执行所有活动计时器的函数，更新计时，并在完成时移除计时器
function _M:runner()
    for tag, t in pairs(self.timers) do
        -- 执行函数
        if t.func then
            t.func()
        end
        
        -- 更新计时
        t.current = t.current + 1
        
        -- 检查是否完成
        if t.current >= t.frame then
            -- 如果有停止回调函数，执行它
            if t.stop_func then
                t.stop_func()
            end
            -- 移除计时器
            self.timers[tag] = nil
        end
    end
end

-- 停止计时器
-- @param tag string 计时器标签
-- @param runStopFunc boolean 是否执行停止函数，默认为true
function _M:stop(tag, runStopFunc)
    if not self.timers[tag] then
        return
    end
    
    if runStopFunc ~= false and self.timers[tag].stop_func then
        self.timers[tag].stop_func()
    end
    
    self.timers[tag] = nil
end

-- 停止所有计时器
-- @param runStopFunc boolean 是否执行停止函数，默认为true
function _M:stopAll(runStopFunc)
    for tag, _ in pairs(self.timers) do
        self:stop(tag, runStopFunc)
    end
end


-- 返回模块
return _M
