local Core = require("_CatLib")
local CONST = require("_CatLib.const")
local _player = require("_CatLib.game.player")
local _singleton = require("_CatLib.game.singletons")
local mod = Core.NewMod("Debugger-Action")
mod.EnableCJKFont(18) -- 启用中文字体

-- 基础变量
local MasterPlayer      -- 主玩家对象引用
local player
local gameObje
local action_index = 0  -- 动作索引，初始化为0
local action_cata = 0   -- 动作类别，初始化为0
local motionID = 0      -- 动作ID，初始化为0
local CustomIndex = 0
local CustomCategory = 2
-- 动作历史记录变量
local actionHistory = {}
local maxHistoryEntries = 10
local NewActionID = Core.NewActionID
local masterInitialized = false

-- 获取游戏对象组件
local function getComponent(obj, type)
  return obj:call("getComponent(System.Type)", sdk.typeof(type))
end

local function initMaster()
  if not MasterPlayer then
    MasterPlayer = _singleton.GetPlayerManager()
  end
  if not MasterPlayer then return false end

  if not player then
    player = _player.GetInfo()
  end
  if not player then return false end

  if not gameObje then
    gameObje = _player.GetGameObject()
  end
  if not gameObje then return false end

  local motionData = Core.GetPlayerMotionData()
  if motionData and motionData.MotionID then
    motionID = motionData.MotionID
  end
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
      -- 更新当前值
      action_cata = newCategory or 0
      action_index = newIndex or 0
    end
  end
)

-- 添加帧任务处理器
mod.OnFrame(
  function ()
    if not initMaster() then return end
    
    -- 更新当前motionID
    local motionData = Core.GetPlayerMotionData()
    if motionData and motionData.MotionID then
      local currentMotionID = motionData.MotionID
      
      -- 检查motionID是否与历史记录中最新一条不同
      local shouldRecord = false
      if #actionHistory == 0 or actionHistory[1].motionID ~= currentMotionID then
        shouldRecord = true
        motionID = currentMotionID -- 更新全局motionID
      end
      
      if shouldRecord then
        local entry = {
            timestamp = os.clock(),
            category = action_cata or 0,
            index = action_index or 0,
            motionID = currentMotionID
        }
        
        -- 插入到历史记录的开头
        table.insert(actionHistory, 1, entry)
        
        -- 如果超过最大记录数，删除最老的记录
        if #actionHistory > maxHistoryEntries then
            table.remove(actionHistory, #actionHistory)
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
        if player and player:get_Character() then
          player:get_Character():call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, actionID, false)
        end
      end
      
      imgui.tree_pop()
    end
    imgui.separator()
    imgui.text("当前动作类别: " .. tostring(action_cata or 0))
    imgui.text("当前动作索引: " .. tostring(action_index or 0))
    imgui.text("当前动作ID: " .. tostring(motionID or 0))
    imgui.separator()
    -- 显示动作历史记录
    if imgui.tree_node("最近动作历史记录") then
      imgui.text("最近的" .. #actionHistory .. "次动作变化:")
      
      for i, entry in ipairs(actionHistory) do
        local timeAgo = os.clock() - entry.timestamp
        local motionIDText = entry.motionID and tostring(entry.motionID) or "未知"
        imgui.text(string.format("[%.2f秒前] 类别: %d, 索引: %d, 动作ID: %s", 
            timeAgo, entry.category or 0, entry.index or 0, motionIDText))
      end
      
      imgui.tree_pop()
    end
end)

mod.Run()

-- -- app.HunterCharacter.evHit_ShellDamagePreProcess(app.HitInfo)
-- mod.HookFunc(
-- "app.HunterCharacter", 
-- "evHit_ShellDamagePreProcess(app.HitInfo)", 
-- function(args)
--   log.debug("app.HunterCharacter.evHit_ShellDamagePreProcess")
--   -- return sdk.PreHookResult.SKIP_ORIGINAL
-- end, 
-- function(retval)
--   log.debug("-- app.HunterCharacter.evHit_ShellDamagePreProcess" .. os.clock())
--   return retval
-- end)

-- app.HunterCharacter.evHit_Damage(app.HitInfo)

local function noHitTimer(float)
	player:get_Character():startNoHitTimer(float)
end
mod.HookFunc(
"app.HunterCharacter", 
"evHit_Damage(app.HitInfo)", 
function(args)
  log.debug("app.HunterCharacter.evHit_Damage")
  local hitInfo = sdk.to_managed_object(args[3])
  local name = hitInfo:get_DamageOwner():get_Name()
  -- return sdk.PreHookResult.SKIP_ORIGINAL
end, 
function(retval)
  log.debug("-- app.HunterCharacter.evHit_Damage" .. os.clock())
  -- 在这里打印一下retval的
  -- noHitTimer(1.0)
  
  return retval
end)

-- -- app.HitController.checkAngleLimit(app.HitInfo)
-- mod.HookFunc(
-- "app.HitController", 
-- "checkAngleLimit(app.HitInfo)", 
-- function(args)
--   log.debug("app.HitController.checkAngleLimit")
--   -- return sdk.PreHookResult.SKIP_ORIGINAL
-- end, 
-- function(retval)
--   log.debug("-- app.HitController.checkAngleLimit" .. os.clock())
--   return sdk.to_ptr(false)
-- end)

-- app.HunterCharacter.doBaseActionEnter(ace.ACTION_ID)
-- mod.HookFunc(
-- "app.HunterCharacter", 
-- "doBaseActionEnter(ace.ACTION_ID)", 
-- function(args)
--   log.debug("app.HunterCharacter.doBaseActionEnter")
--   -- return sdk.PreHookResult.SKIP_ORIGINAL

--   local type = sdk.find_type_definition("ace.ACTION_ID")
--   local actionID = sdk.get_native_field(args[3], type, "_Index")
--   log.debug(actionID)
-- end, 
-- function(retval)
--   log.debug("-- app.HunterCharacter.doBaseActionEnter" .. os.clock())
--   return retval
-- end)
local action = false
-- 模糊匹配函数
local function fuzzy_match(str, pattern)
  return string.find(str, pattern) ~= nil
end

local function checkIsMaster(hitinfo)
  local k__BackingField = hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name()
  local player = hitinfo:get_field("<DamageOwner>k__BackingField"):get_Name()
  local em = fuzzy_match(k__BackingField, "Em")
  local minEm = fuzzy_match(k__BackingField, "em")
  local gm = fuzzy_match(k__BackingField, "Gm")
  local heal = fuzzy_match(k__BackingField, "Heal")
  local isMasterPlayer = player == "MasterPlayer"
  return (em == true or gm == true or minEm == true) and heal == false and isMasterPlayer
end

local techGuardFlag 
local guardFlag 
local timer = require("_CatLib.utils.timer")

-- local function autoGuardFlag()
--   timer:runner()
--   local hunterCharacter = Core.GetPlayerCharacter()
--   if not hunterCharacter then return end
--   -- app.cHunterStatus
--   -- ace.cSafeContinueFlagGroup
--   local status = hunterCharacter:get_HunterStatus():get_field("_HunterStatusFlag")
--   log.debug("status:" .. sdk.to_float(status))

--   -- log.debug("autoGuardFlag")
--   -- timer:run("autoGuardFlag",600,function ()
--   --   hunterCharacter:onHunterStatusFlag(4)
--   -- end,function ()
--   --   hunterCharacter:get_HunterStatus():get_field("_HunterStatusFlag"):off(4)
--   -- end)
-- end

-- mod.HookFunc("app.HitController", "checkAngleLimit(app.HitInfo)",
--   function(args)

--     local hitInfo = Core.Cast(args[3])

--     local result = checkIsMaster(hitInfo)
--     if result then
--       autoGuardFlag()
--     end
--   end
-- )

mod.OnPreUpdateBehavior(function ()
  timer:runner()
  local Catalog = Core.GetPlayerCatalogHolder()
  if not Catalog then return end
  local param = Catalog:get_Wp00ActionParam()
  local old = param._GuardDegree
  timer:run("autoGuardFlag",600,function ()

  param:set_field("_GuardDegree",11)
  log.debug("GuardDegree:" .. param._GuardDegree .. " old:" .. old)
  end,
  function ()
    param:set_field("_GuardDegree",old)
  end)
end)
