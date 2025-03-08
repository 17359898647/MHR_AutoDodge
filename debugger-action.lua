local Core = require("_CatLib")
local CONST = require("_CatLib.const")
local mod = Core.NewMod("Debugger-Action")
mod.EnableCJKFont(18) -- 启用中文字体

-- 基础变量
local MasterPlayer      -- 主玩家对象引用
local player
local gameObje
local action_index  -- 动作索引
local action_cata   -- 动作类别
local motionID      -- 动作ID
local CustomIndex = 0
local CustomCategory = 2
-- 动作历史记录变量
local actionHistory = {}
local maxHistoryEntries = 10
local NewActionID = Core.NewActionID

-- 获取游戏对象组件
local function getComponent(obj, type)
  return obj:call("getComponent(System.Type)", sdk.typeof(type))
end

local function initMaster()
  if not MasterPlayer then
    MasterPlayer = sdk.get_managed_singleton("app.PlayerManager")
  end
  if not MasterPlayer then return false end

  if not player then
    player = MasterPlayer:getMasterPlayer()
  end
  if not player then return false end

  if not gameObje then
    gameObje = player:get_Object()
  end
  if not gameObje then return false end

  motionID = getComponent(gameObje, 'via.motion.Motion'):getLayer(0):get_MotionID()
  masterInitialized = true
  return true
end

-- 跟踪角色动作请求
mod.HookFunc("app.HunterCharacter", "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 
  function(args)
    if initMaster() then
      local type = sdk.find_type_definition("ace.ACTION_ID")
      local newCategory = sdk.get_native_field(args[4], type, "_Category")
      local newIndex = sdk.get_native_field(args[4], type, "_Index")
      
      -- 保存旧值用于比较
      local oldCategory = action_cata
      local oldIndex = action_index
      
      -- 更新当前值
      action_cata = newCategory
      action_index = newIndex

      -- 当类别或索引变化时记录到历史
      if newCategory ~= oldCategory or newIndex ~= oldIndex then
        -- 直接将动作记录到历史，但暂时不设置motionID字段
        local entry = {
            timestamp = os.clock(),
            category = newCategory,
            index = newIndex,
            motionID = nil -- 先设为nil，稍后更新
        }
        
        -- 插入到历史记录的开头
        table.insert(actionHistory, 1, entry)
        
        -- 如果超过最大记录数，删除最老的记录
        if #actionHistory > maxHistoryEntries then
            table.remove(actionHistory, #actionHistory)
        end
        
        -- 创建延迟任务，在几帧后获取更新后的motionID
        local waitFrames = 3 -- 等待3帧再获取motionID
        local frameCount = 0
        
        local updateMotionIDTask = function()
          frameCount = frameCount + 1
          if frameCount >= waitFrames then
            if gameObje then
              local motion = getComponent(gameObje, 'via.motion.Motion')
              if motion then
                local layer = motion:getLayer(0)
                if layer then
                  -- 更新刚添加的历史记录的motionID
                  entry.motionID = layer:get_MotionID()
                end
              end
            end
            return true -- 任务完成，不再继续执行
          end
          return false -- 任务未完成，继续执行
        end
        
        -- 添加到帧更新任务列表
        if not mod.frameTasks then mod.frameTasks = {} end
        table.insert(mod.frameTasks, updateMotionIDTask)
      end
    end
  end
)

-- 添加帧任务处理器
mod.OnFrame(
  function ()
    initMaster()
    
    -- 处理延迟任务
    if mod.frameTasks then
      local i = 1
      while i <= #mod.frameTasks do
        local task = mod.frameTasks[i]
        local completed = task()
        if completed then
          table.remove(mod.frameTasks, i)
        else
          i = i + 1
        end
      end
    end
  end
)

mod.Menu(function ()
  local configChanged = false
  local changed
  --   -- 武器信息部分
    if imgui.tree_node("调试") then

      changed, CustomIndex = imgui.drag_int("自定义动作索引", CustomIndex, 1, 0, 500)
      if changed then
          configChanged = true
      end
      
      changed, CustomCategory = imgui.drag_int("自定义动作类别", CustomCategory, 1, 0, 500)
      if changed then
          configChanged = true
      end

      if imgui.button("执行自定义动作 [索引: " .. CustomIndex .. "]") then
        local actionID = NewActionID(CustomCategory, CustomIndex)
      player:get_Character():call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, actionID, false)
      end
      
      imgui.tree_pop()
    end
    imgui.separator()
    imgui.text("当前动作索引: " .. tostring(action_index))
    imgui.text("当前动作类别: " .. tostring(action_cata))
    imgui.text("当前动作ID: " .. tostring(motionID))
    imgui.separator()
    -- 显示动作历史记录
    if imgui.tree_node("最近动作历史记录") then
      imgui.text("最近的" .. #actionHistory .. "次动作变化:")
      
      for i, entry in ipairs(actionHistory) do
        local timeAgo = os.clock() - entry.timestamp
        local motionIDText = entry.motionID and tostring(entry.motionID) or "等待中..."
        imgui.text(string.format("[%.2f秒前] 类别: %d, 索引: %d, 动作ID: %s", 
            timeAgo, entry.category, entry.index, motionIDText))
    end
      
      imgui.tree_pop()
    end
end)

mod.Run()
