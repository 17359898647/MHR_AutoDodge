local Core = require("_CatLib")
local CONST = require("_CatLib.const")
local mod = Core.NewMod("Auto DualBlades Dodge")
local _player = require("_CatLib.game.player")
local _singleton = require("_CatLib.game.singletons")
mod.EnableCJKFont(18) -- 启用中文字体

-- 基础变量
local MasterPlayer      -- 主玩家对象引用
local player
local gameObje
local action_index = 0
local action_cata = 0
local damage_owner = ""
local isWeaponOn = false
local motionID         -- 动作ID
local masterInitialized = false -- 主玩家是否已初始化
local CurrentWeaponType
local CurrentWeaponTypeName = ""

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

  motionID = Core.GetPlayerMotionData().MotionID
  masterInitialized = true
  return true
end



-- 模糊匹配函数
local function fuzzy_match(str, pattern)
  return string.find(str, pattern) ~= nil
end

local NewActionID = Core.NewActionID

-- 武器类型名称映射
local WEAPON_TYPE_NAMES = {
  [CONST.WeaponType.GreatSword] = "大剑",
  [CONST.WeaponType.SwordShield] = "剑盾",
  [CONST.WeaponType.DualBlades] = "双刀",
  [CONST.WeaponType.LongSword] = "太刀",
  [CONST.WeaponType.SwitchAxe] = "斩斧",
  [CONST.WeaponType.Gunlance] = "铳枪",
  [CONST.WeaponType.Lance] = "长枪",
  [CONST.WeaponType.InsectGlaive] = "操虫棍",
  [CONST.WeaponType.ChargeBlade] = "充能斧",
  [CONST.WeaponType.HuntingHorn] = "狩猎笛",
  [CONST.WeaponType.Hammer] = "大锤",
  [CONST.WeaponType.Bow] = "弓",
  [CONST.WeaponType.HeavyBowgun] = "重弩",
  [CONST.WeaponType.LightBowgun] = "轻弩",
}

---@class config
---@field forward number 向前躲避动作索引
---@field backward number 向后躲避动作索引
---@field left number 向左躲避动作索引
---@field right number 向右躲避动作索引
---@field dogeCooldown number 躲避冷却时间设置  
---@field lasterDodgeTime number 上一次躲避时间
---@field CD number 躲避冷却时间
---@field ActionIndex number 选择躲避动作索引
---@field excludedActionIndices number[] 排除动作ID
---@field checkMotionState function 检查动作状态
---@field isEquipped function 检查是否装备武器
---@field ActionFun function 执行躲避功能
---@field excludedActionMap table<number, boolean> 懒加载哈希表
local config={}
-- 统一的isEquipped函数，接受武器配置和武器类型作为参数
local function createIsEquipped(weaponConfig, weaponType)
  -- 检查武器类型，动作状态和冷却时间
  if CurrentWeaponType == weaponType and
      weaponConfig.checkMotionState() and
      math.max(0, weaponConfig.CD - (os.clock() - weaponConfig.lasterDodgeTime)) <= 0 then
    return true
  else
    damage_owner = ""
    return false
  end
end

-- 统一的躲避函数，接受武器配置和武器类型作为参数
local function createActionFun(weaponConfig, weaponType, category, index)
  if not initMaster() then
    return
  end
  
  category = category or 2 -- 默认类别为2
  index = index or weaponConfig.ActionIndex -- 默认索引为配置中的ActionIndex
  if damage_owner == "MasterPlayer" and weaponConfig.isEquipped() then
    local actionID = NewActionID(category, index)
    if player:get_Character():call(
        "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)",
        0, 
        actionID, 
        false
    ) then
      weaponConfig.lasterDodgeTime = os.clock()
      damage_owner = ""
      log.debug('success')
    end
  end
end

-- 优化的动作状态检查函数，使用懒加载哈希表
local function checkMotionState(weaponConfig, weaponType)
  if not initMaster() then
    return false
  end
  if not weaponConfig.excludedActionIndices or next(weaponConfig.excludedActionIndices) == nil then
    return true
  end
  -- 懒加载：如果还没有创建哈希表，则创建一个
  if not weaponConfig.excludedActionMap then
    -- 创建一个哈希表用于O(1)查找
    weaponConfig.excludedActionMap = {}
    for _, id in ipairs(weaponConfig.excludedActionIndices) do
      weaponConfig.excludedActionMap[id] = true
    end
  end
  
  -- 直接用哈希表查找，O(1)时间复杂度
  if weaponConfig.excludedActionMap[motionID] then
    return false
  end
  
  return true
end


-- 双刀躲避配置
config[CONST.WeaponType.DualBlades] = {
  forward = 41, -- 向前躲避动作索引
  backward = 42, -- 向后躲避动作索引
  left = 43, -- 向左躲避动作索引
  right = 44, -- 向右躲避动作索引
  ActionIndex = 41, -- 选择躲避动作索引
  lasterDodgeTime = 0,
  CD = 0.5,
  excludedActionIndices = {
    312, 313, 314,320, --- 320是没气的乱舞1, 312,313,314 以此乱舞1,2,3
    81,82, --- 前躲和蓝前躲id
    84,89, --- 后躲和蓝后躲id
    82,87, --- 左躲和蓝左躲id
    83,88, --- 右躲和蓝右躲id
  },  -- 排除动作id
  checkMotionState = function()
    return checkMotionState(config[CONST.WeaponType.DualBlades], CONST.WeaponType.DualBlades)
  end,
  isEquipped = function()
    return createIsEquipped(config[CONST.WeaponType.DualBlades], CONST.WeaponType.DualBlades)
  end,
  ActionFun = function ()
    return createActionFun(config[CONST.WeaponType.DualBlades], CONST.WeaponType.DualBlades)
  end,
}

config[CONST.WeaponType.Bow] = {
  forward = 9, -- 向前躲避动作索引
  backward = 10, -- 向后躲避动作索引
  left = 11, -- 向左躲避动作索引
  right = 12, -- 向右躲避动作索引
  ActionIndex = 9, -- 选择躲避动作索引
  lasterDodgeTime = 0,
  CD = 0.5,
  excludedActionIndices = {
    274,76, -- 前躲和蓝前躲id
    276,275, -- 后躲和蓝后躲id
    275,74, -- 左躲和蓝左躲id
    278,77, -- 右躲和蓝右躲id
    60,61,62,63, -- 好像是翻滚id
    260,261,263,287, -- 几个蓄力状态的id
  },  -- 排除动作id
  checkMotionState = function()
    return checkMotionState(config[CONST.WeaponType.Bow], CONST.WeaponType.Bow)
  end,
  isEquipped = function()
    return createIsEquipped(config[CONST.WeaponType.Bow], CONST.WeaponType.Bow)
  end,
  ActionFun = function ()
    return createActionFun(config[CONST.WeaponType.Bow], CONST.WeaponType.Bow)
  end,
}

local isCharging = false --- config中配置不能实时监听,不清楚原因
-- 大剑躲避配置
config[CONST.WeaponType.GreatSword] = {
  -- 格挡索引
  guard = 141,
  -- 是否格挡
  needGuard = true,
  -- 肩撞索引
  shoulder = 15,
  -- 是否肩撞
  needShoulder = true,
  isCharging = false,
  ActionIndex = 146, -- 选择动作索引，默认为格挡
  lasterDodgeTime = 0,
  CD = 0.5,
  excludedActionIndices = {
    213,237,248,476,474,18,19 -- 都是蓄力斩的斩击id
  },  -- 排除动作id
  checkMotionState = function()
    return checkMotionState(config[CONST.WeaponType.GreatSword], CONST.WeaponType.GreatSword)
  end,
  isEquipped = function ()
    -- 根据当前状态判断是否执行动作
    if isCharging then
      -- 蓄力状态下，检查是否需要肩撞
      if not config[CONST.WeaponType.GreatSword].needShoulder then
        return false
      end
    else
      -- 非蓄力状态下，检查是否需要格挡
      if not config[CONST.WeaponType.GreatSword].needGuard then
        return false
      end
    end
    return createIsEquipped(config[CONST.WeaponType.GreatSword], CONST.WeaponType.GreatSword)
  end,
  ActionFun = function ()
    local category = 1
    local index = config[CONST.WeaponType.GreatSword].guard
    if isCharging then
      category = 2
      index = config[CONST.WeaponType.GreatSword].shoulder
    end

    return createActionFun(config[CONST.WeaponType.GreatSword], CONST.WeaponType.GreatSword, category, index)
  end,
}

-- 跟踪角色动作请求
mod.HookFunc("app.HunterCharacter", "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 
  function(args)
    if initMaster() then
      local type = sdk.find_type_definition("ace.ACTION_ID")
      local newCategory = sdk.get_native_field(args[4], type, "_Category")
      local newIndex = sdk.get_native_field(args[4], type, "_Index")
      action_cata = newCategory
      action_index = newIndex
    end
  end
)

-- 获取当前武器类型
function getCurrentWeaponType()
  if not masterInitialized then
    initMaster()
    return
  end
  -- 确保玩家对象已初始化
  if not player then return end
  
  -- 使用参考代码中的方法获取武器类型
  -- app.HunterCharacter
  local character = player:call("get_Character")
  if not character then return end
  -- app.Weapon
  local weapon = character:call("get_Weapon")
  if not weapon then return end
  
  -- app.WeaponDef.TYPE
  local wpType = weapon:get_field("_WpType")
  if wpType ~= nil then
      CurrentWeaponType = wpType
      CurrentWeaponTypeName = WEAPON_TYPE_NAMES[wpType] or "未知武器"
      isWeaponOn = character:call("get_IsWeaponOn")
  end
end


local function checkIsMaster(hitinfo)
  local k__BackingField = hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name()
  local player = hitinfo:get_field("<DamageOwner>k__BackingField"):get_Name()
  local em = fuzzy_match(k__BackingField, "Em")
  local minEm = fuzzy_match(k__BackingField, "em")
  local gm = fuzzy_match(k__BackingField, "Gm")
  local heal = fuzzy_match(k__BackingField, "Heal")
  local isMasterPlayer = player == "MasterPlayer"
  local isEquipped = false
  if CurrentWeaponType and config[CurrentWeaponType] and type(config[CurrentWeaponType].isEquipped) == "function" then
    isEquipped = config[CurrentWeaponType].isEquipped()
  end
  damage_owner = hitinfo:get_field("<DamageOwner>k__BackingField"):get_Name()
  return (em == true or gm == true or minEm == true) and heal == false and isEquipped and isMasterPlayer
end

 

-- 攻击检测钩子
mod.HookFunc("app.HunterCharacter", "evHit_Damage(app.HitInfo)",
    function(args)
      if not masterInitialized then
        initMaster()
        return
      end
      
      if not isWeaponOn then
        return
      end

      local hitinfo = sdk.to_managed_object(args[3])
      local result = checkIsMaster(hitinfo)

      damage_owner = hitinfo:get_field("<DamageOwner>k__BackingField"):get_Name()
      if result then
        damage_owner = "MasterPlayer"
        -- 如果不是大剑，return SKIP_ORIGINAL
        if CurrentWeaponType ~= CONST.WeaponType.GreatSword then
          return sdk.PreHookResult.SKIP_ORIGINAL
        end
      else
        damage_owner = ""
      end
    end,
    function (retval)
      if config[CurrentWeaponType] and type(config[CurrentWeaponType].ActionFun) == "function" then
        config[CurrentWeaponType].ActionFun()
      end
      return retval
    end
)

mod.OnFrame(
  function ()
    getCurrentWeaponType()
  end
)

local DualBladesMenu =  function ()
  imgui.separator()
  if imgui.tree_node("双刀配置") then
    
    -- 使用一致的方向索引映射
    local directions = {
      [0] = "向后 (" .. config[CONST.WeaponType.DualBlades].backward .. ")",
      [1] = "向左 (" .. config[CONST.WeaponType.DualBlades].left .. ")",
      [2] = "向右 (" .. config[CONST.WeaponType.DualBlades].right .. ")",
      [3] = "向前 (" .. config[CONST.WeaponType.DualBlades].forward .. ")"
    }
    
    -- 创建动作索引映射
    local indexMapping = {
      [0] = config[CONST.WeaponType.DualBlades].backward,
      [1] = config[CONST.WeaponType.DualBlades].left,
      [2] = config[CONST.WeaponType.DualBlades].right,
      [3] = config[CONST.WeaponType.DualBlades].forward
    }

    local directionsArray = {}
    for i=0, 3 do
      directionsArray[i+1] = directions[i]
    end
    
    -- 找到当前选择的索引
    local currentDodgeIndex = config[CONST.WeaponType.DualBlades].ActionIndex
    local currentDirectionIndex = 0
    for i=0, 3 do
      if indexMapping[i] == currentDodgeIndex then
        currentDirectionIndex = i
        break
      end
    end
    -- 创建下拉选择器
    changed, currentDirectionIndex = imgui.combo("躲避方向", currentDirectionIndex + 1, directionsArray)
    if changed then
      -- 转换回实际的动作索引
      config[CONST.WeaponType.DualBlades].ActionIndex = indexMapping[currentDirectionIndex - 1]
      configChanged = true
    end
    imgui.separator()
    imgui.text("当前选择: " .. directions[currentDirectionIndex - 1])

    -- 创建一个改变冷却时间的控件
    local cooldownValue = config[CONST.WeaponType.DualBlades].CD
    changed, cooldownValue = imgui.drag_float("躲避冷却时间（秒）", 
        cooldownValue, 0.1, 0.0, 10.0, "%.1f")
    if changed then
        config[CONST.WeaponType.DualBlades].CD = cooldownValue
        configChanged = true
    end

    imgui.text("冷却剩余时间: " .. string.format("%.2f", math.max(0, config[CONST.WeaponType.DualBlades].CD - (os.clock() - config[CONST.WeaponType.DualBlades].lasterDodgeTime))))
    imgui.tree_pop()
  end
end

local BowMenu = function ()
  imgui.separator()
  if imgui.tree_node("弓配置") then
    
    -- 使用一致的方向索引映射
    local directions = {
      [0] = "向后 (" .. config[CONST.WeaponType.Bow].backward .. ")",
      [1] = "向左 (" .. config[CONST.WeaponType.Bow].left .. ")",
      [2] = "向右 (" .. config[CONST.WeaponType.Bow].right .. ")",
      [3] = "向前 (" .. config[CONST.WeaponType.Bow].forward .. ")"
    }
    
    -- 创建动作索引映射
    local indexMapping = {
      [0] = config[CONST.WeaponType.Bow].backward,
      [1] = config[CONST.WeaponType.Bow].left,
      [2] = config[CONST.WeaponType.Bow].right,
      [3] = config[CONST.WeaponType.Bow].forward
    }

    local directionsArray = {}
    for i=0, 3 do
      directionsArray[i+1] = directions[i]
    end
    
    -- 找到当前选择的索引
    local currentDodgeIndex = config[CONST.WeaponType.Bow].ActionIndex
    local currentDirectionIndex = 0
    for i=0, 3 do
      if indexMapping[i] == currentDodgeIndex then
        currentDirectionIndex = i
        break
      end
    end
    -- 创建下拉选择器
    changed, currentDirectionIndex = imgui.combo("躲避方向", currentDirectionIndex + 1, directionsArray)
    if changed then
      -- 转换回实际的动作索引
      config[CONST.WeaponType.Bow].ActionIndex = indexMapping[currentDirectionIndex - 1]
      configChanged = true
    end
    imgui.separator()
    imgui.text("当前选择: " .. directions[currentDirectionIndex - 1])

    -- 创建一个改变冷却时间的控件
    local cooldownValue = config[CONST.WeaponType.Bow].CD
    changed, cooldownValue = imgui.drag_float("躲避冷却时间（秒）", 
        cooldownValue, 0.1, 0.0, 10.0, "%.1f")
    if changed then
        config[CONST.WeaponType.Bow].CD = cooldownValue
        configChanged = true
    end

    imgui.text("冷却剩余时间: " .. string.format("%.2f", math.max(0, config[CONST.WeaponType.Bow].CD - (os.clock() - config[CONST.WeaponType.Bow].lasterDodgeTime))))
    imgui.tree_pop()
  end
  imgui.separator()
end

local GreatSwordMenu = function ()
  if imgui.tree_node("大剑配置") then
    -- 创建一个改变冷却时间的控件
    local cooldownValue = config[CONST.WeaponType.GreatSword].CD

    changed, cooldownValue = imgui.drag_float("操作冷却时间（秒）", 
      cooldownValue, 0.05, 0.0, 10.0)
    if changed then
      config[CONST.WeaponType.GreatSword].CD = cooldownValue
      configChanged = true
    end
    imgui.text("冷却剩余时间: " .. string.format("%.2f", math.max(0, config[CONST.WeaponType.GreatSword].CD - (os.clock() - config[CONST.WeaponType.GreatSword].lasterDodgeTime))))
    
    -- 显示当前蓄力状态
    imgui.text("当前蓄力状态: " .. (isCharging and "正在蓄力" or "未蓄力"))
    
    -- 添加控制是否启用格挡的复选框
    local needGuard = config[CONST.WeaponType.GreatSword].needGuard
    changed, needGuard = imgui.checkbox("启用格挡 (普通状态)", needGuard)
    if changed then
      config[CONST.WeaponType.GreatSword].needGuard = needGuard
      configChanged = true
    end
    
    -- 添加控制是否启用肩撞的复选框
    local needShoulder = config[CONST.WeaponType.GreatSword].needShoulder
    changed, needShoulder = imgui.checkbox("启用肩撞 (蓄力状态)", needShoulder)
    if changed then
      config[CONST.WeaponType.GreatSword].needShoulder = needShoulder
      configChanged = true
    end
    
    imgui.tree_pop()
  end
end

-- 菜单
mod.Menu(function ()
  local configChanged = false
  local changed
  --   -- 武器信息部分
  if mod.Config.Debug and imgui.tree_node("武器信息") then
    imgui.text("当前武器类型: " .. CurrentWeaponTypeName .. " (" .. tostring(CurrentWeaponType) .. ")")
    imgui.text("武器状态: " .. (isWeaponOn and "已拔出" or "已收起"))
    -- 动作信息
    imgui.separator()
    imgui.text("当前动作索引: " .. tostring(action_index))
    imgui.text("当前动作类别: " .. tostring(action_cata))
    imgui.text("当前动作ID: " .. tostring(motionID))

    local isEquipped
    if CurrentWeaponType and config[CurrentWeaponType] and type(config[CurrentWeaponType].isEquipped) == "function" then

      isEquipped = config[CurrentWeaponType].isEquipped()
      -- 是否会自动
      imgui.text("是否会自动: " .. tostring(isEquipped))
    end
    -- 伤害来源
    imgui.separator()
    imgui.tree_pop()
  end
  
  DualBladesMenu()
  BowMenu()
  GreatSwordMenu()
  
end)  

mod.Run()

-- Hook大剑蓄力开始函数
mod.HookFunc(
  "app.Wp00Action.cChargeBase",
  "doEnter()",
  function(args)
    config[CONST.WeaponType.DualBlades].isCharging = true
    isCharging = true
    return sdk.PreHookResult.CALL_ORIGINAL
  end
)

-- Hook大剑蓄力结束函数
mod.HookFunc(
  "app.Wp00Action.cChargeBase",
  "doExit()",
  function(args)
    config[CONST.WeaponType.DualBlades].isCharging = false
    isCharging = false
    return sdk.PreHookResult.CALL_ORIGINAL
  end
)
