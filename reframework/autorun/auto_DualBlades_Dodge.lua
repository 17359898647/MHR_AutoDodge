---------------------------------------------------------
-- 引用和依赖
--------------------------------------------------------------------------------
local Core = require("_CatLib")
local CONST = require("_CatLib.const")
local _player = require("_CatLib.game.player")
local _singleton = require("_CatLib.game.singletons")

-- 创建模组实例
local mod = Core.NewMod("Auto DualBlades Dodge")
mod.EnableCJKFont(24) -- 启用中文字体

--------------------------------------------------------------------------------
-- 全局变量
--------------------------------------------------------------------------------
-- 玩家相关
local MasterPlayer      -- 主玩家对象引用
local player            -- 玩家信息
local gameObje          -- 玩家游戏对象
local masterInitialized = false -- 主玩家是否已初始化

-- 武器相关
local CurrentWeaponType     -- 当前武器类型
local CurrentWeaponTypeName = "" -- 当前武器类型名称
local isWeaponOn = false    -- 武器是否拔出

-- 动作相关
local motionID         -- 当前动作ID
local action_index = 0  -- 动作索引
local action_cata = 0   -- 动作类别
local damage_owner = "" -- 伤害来源

-- 语言相关
local currentLanguage = "cn" -- 默认语言为中文
local languageStrings = {
  -- 语言选项
  cn = {
    -- 武器名称
    weapons = {
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
      unknown = "未知武器"
    },
    -- UI文本
    ui = {
      language = "语言",
      cn = "中文",
      en = "英文",
      dualblades_config = "双刀配置",
      bow_config = "弓配置",
      dodge_direction = "躲避方向",
      cooldown_time = "躲避冷却时间（秒）",
      remaining_cooldown = "冷却剩余时间: ",
      current_selection = "当前选择: ",
      weapon_info = "武器信息",
      current_weapon = "当前武器类型: ",
      weapon_status = "武器状态: ",
      weapon_drawn = "已拔出",
      weapon_sheathed = "已收起",
      current_action_index = "当前动作索引: ",
      current_action_category = "当前动作类别: ",
      current_action_id = "当前动作ID: ",
      will_auto_dodge = "是否会自动: ",
      directions = {
        forward = "向前",
        backward = "向后",
        left = "向左",
        right = "向右"
      },
      debug_info = "调试信息",
      damage_source = "伤害来源",
      action_category = "动作类别",
      action_index = "动作索引",
      motion_id = "动作ID",
      weapon_equipped = "武器装备",
      current_language = "当前语言",
      save_config = "保存配置",
      weapon_type = "武器类型"
    }
  },
  -- English
  en = {
    -- Weapon names
    weapons = {
      [CONST.WeaponType.GreatSword] = "Great Sword",
      [CONST.WeaponType.SwordShield] = "Sword & Shield",
      [CONST.WeaponType.DualBlades] = "Dual Blades",
      [CONST.WeaponType.LongSword] = "Long Sword",
      [CONST.WeaponType.SwitchAxe] = "Switch Axe",
      [CONST.WeaponType.Gunlance] = "Gunlance",
      [CONST.WeaponType.Lance] = "Lance",
      [CONST.WeaponType.InsectGlaive] = "Insect Glaive",
      [CONST.WeaponType.ChargeBlade] = "Charge Blade",
      [CONST.WeaponType.HuntingHorn] = "Hunting Horn",
      [CONST.WeaponType.Hammer] = "Hammer",
      [CONST.WeaponType.Bow] = "Bow",
      [CONST.WeaponType.HeavyBowgun] = "Heavy Bowgun",
      [CONST.WeaponType.LightBowgun] = "Light Bowgun",
      unknown = "Unknown Weapon"
    },
    -- UI text
    ui = {
      language = "Language",
      cn = "Chinese",
      en = "English",
      dualblades_config = "Dual Blades Configuration",
      bow_config = "Bow Configuration",
      dodge_direction = "Dodge Direction",
      cooldown_time = "Dodge Cooldown (seconds)",
      remaining_cooldown = "Remaining Cooldown: ",
      current_selection = "Current Selection: ",
      weapon_info = "Weapon Information",
      current_weapon = "Current Weapon Type: ",
      weapon_status = "Weapon Status: ",
      weapon_drawn = "Drawn",
      weapon_sheathed = "Sheathed",
      current_action_index = "Current Action Index: ",
      current_action_category = "Current Action Category: ",
      current_action_id = "Current Action ID: ",
      will_auto_dodge = "Will Auto Dodge: ",
      directions = {
        forward = "Forward",
        backward = "Backward",
        left = "Left",
        right = "Right"
      },
      debug_info = "Debug Information",
      damage_source = "Damage Source",
      action_category = "Action Category",
      action_index = "Action Index",
      motion_id = "Motion ID",
      weapon_equipped = "Weapon Equipped",
      current_language = "Current Language",
      save_config = "Save Configuration",
      weapon_type = "Weapon Type"
    }
  }
}

-- 获取当前语言中的字符串
---@param key string 字符串键值路径，例如 "ui.dodge_direction"
---@return string 对应的本地化字符串
local function getLocalizedString(key)
  local parts = {}
  for part in key:gmatch("[^%.]+") do
    table.insert(parts, part)
  end
  
  local current = languageStrings[currentLanguage]
  for _, part in ipairs(parts) do
    if current[part] then
      current = current[part]
    else
      return "[Missing: " .. key .. "]"
    end
  end
  
  return current
end

-- 语言函数简写
local function L(key)
  return getLocalizedString(key)
end

--------------------------------------------------------------------------------
-- 工具函数
--------------------------------------------------------------------------------

-- 初始化主玩家及相关对象
---@return boolean 初始化是否成功
local function initMaster()
  -- 初始化玩家管理器
  if not MasterPlayer then
    MasterPlayer = _singleton.GetPlayerManager()
  end
  if not MasterPlayer then return false end

  -- 初始化玩家信息
  if not player then
    player = _player.GetInfo()
  end
  if not player then return false end

  -- 初始化玩家游戏对象
  if not gameObje then
    gameObje = _player.GetGameObject()
  end
  if not gameObje then return false end

  -- 获取当前动作ID
  motionID = Core.GetPlayerMotionData().MotionID
  masterInitialized = true
  return true
end

-- 模糊匹配函数
---@param str string 要匹配的字符串
---@param pattern string 匹配模式
---@return boolean 是否匹配成功
local function fuzzy_match(str, pattern)
  return string.find(str, pattern) ~= nil
end

-- 创建动作ID的快捷方式
local NewActionID = Core.NewActionID

--------------------------------------------------------------------------------
-- 武器配置系统
--------------------------------------------------------------------------------

---@class WeaponConfig 武器配置类
---@field forward number 向前躲避动作索引
---@field backward number 向后躲避动作索引
---@field left number 向左躲避动作索引
---@field right number 向右躲避动作索引 
---@field lasterDodgeTime number 上一次躲避时间
---@field CD number 躲避冷却时间
---@field ActionIndex number 选择躲避动作索引
---@field excludedActionIndices number[] 排除动作ID
---@field checkMotionState function 检查动作状态
---@field isEquipped function 检查是否装备武器
---@field ActionFun function 执行躲避功能
---@field excludedActionMap table<number, boolean> 懒加载哈希表

-- 武器配置表
local config = {}
--------------------------------------------------------------------------------
-- 武器操作核心函数
--------------------------------------------------------------------------------

-- 检查武器是否满足闪避条件
---@param weaponConfig WeaponConfig 武器配置
---@param weaponType number 武器类型ID
---@return boolean 是否可以闪避
local function createIsEquipped(weaponConfig, weaponType)
  -- 检查武器类型，动作状态和冷却时间
  local cooldownRemaining = math.max(0, weaponConfig.CD - (os.clock() - weaponConfig.lasterDodgeTime))
  
  if CurrentWeaponType == weaponType and
     weaponConfig.checkMotionState() and
     cooldownRemaining <= 0 then
    return true
  else
    damage_owner = ""
    return false
  end
end

-- 执行闪避动作
---@param weaponConfig WeaponConfig 武器配置
---@param weaponType number 武器类型ID
---@param category number? 动作类别（可选）
---@param index number? 动作索引（可选）
local function createActionFun(weaponConfig, weaponType, category, index)
  if not initMaster() then
    return
  end
  
  -- 设置默认值
  category = category or 2 -- 默认类别为2
  index = index or weaponConfig.ActionIndex -- 默认索引为配置中的ActionIndex
  
  -- 检查是否满足执行条件
  if damage_owner == "MasterPlayer" and weaponConfig.isEquipped() then
    local actionID = NewActionID(category, index)
    
    -- 尝试执行动作
    if player:get_Character():call(
        "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)",
        0, 
        actionID, 
        false
    ) then
      -- 更新上次闪避时间并清除伤害来源
      weaponConfig.lasterDodgeTime = os.clock()
      damage_owner = ""
      log.debug('闪避动作执行成功')
    end
  end
end

-- 检查当前动作状态是否允许闪避
---@param weaponConfig WeaponConfig 武器配置
---@param weaponType number 武器类型ID
---@return boolean 是否允许闪避
local function checkMotionState(weaponConfig, weaponType)
  -- 确保主玩家已初始化
  if not initMaster() then
    return false
  end
  
  -- 如果没有排除动作，则始终允许闪避
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
  -- 如果当前动作ID在排除列表中，则不允许闪避
  if weaponConfig.excludedActionMap[motionID] then
    return false
  end
  
  return true
end


--------------------------------------------------------------------------------
-- 武器配置定义
--------------------------------------------------------------------------------

-- 双刀配置
---@type WeaponConfig
config[CONST.WeaponType.DualBlades] = {
  -- 闪避动作索引
  forward = 41,  -- 向前闪避
  backward = 42, -- 向后闪避
  left = 43,     -- 向左闪避
  right = 44,    -- 向右闪避
  
  -- 默认使用向前闪避
  ActionIndex = 41,
  
  -- 冷却相关
  lasterDodgeTime = 0, -- 上次闪避时间
  CD = 0.5,            -- 冷却时间（秒）
  
  -- 排除不能闪避的动作ID
  excludedActionIndices = {
    312, 313, 314, 320, -- 乱舞相关动作(320是没气的乱舞1, 312-314是乱舞1-3)
    81, 82,             -- 前躲和蓝前躲id
    84, 89,             -- 后躲和蓝后躲id
    82, 87,             -- 左躲和蓝左躲id
    83, 88,             -- 右躲和蓝右躲id
  },
  
  -- 功能函数
  checkMotionState = function()
    return checkMotionState(config[CONST.WeaponType.DualBlades], CONST.WeaponType.DualBlades)
  end,
  
  isEquipped = function()
    return createIsEquipped(config[CONST.WeaponType.DualBlades], CONST.WeaponType.DualBlades)
  end,
  
  ActionFun = function()
    return createActionFun(config[CONST.WeaponType.DualBlades], CONST.WeaponType.DualBlades)
  end,
}

-- 弓配置
---@type WeaponConfig
config[CONST.WeaponType.Bow] = {
  -- 闪避动作索引
  forward = 9,   -- 向前闪避
  backward = 10, -- 向后闪避
  left = 11,     -- 向左闪避
  right = 12,    -- 向右闪避
  
  -- 默认使用向前闪避
  ActionIndex = 9,
  
  -- 冷却相关
  lasterDodgeTime = 0, -- 上次闪避时间
  CD = 0.5,            -- 冷却时间（秒）
  
  -- 排除不能闪避的动作ID
  excludedActionIndices = {
    274, 76,  -- 前躲和蓝前躲id
    276, 275, -- 后躲和蓝后躲id
    275, 74,  -- 左躲和蓝左躲id
    278, 77,  -- 右躲和蓝右躲id
    60, 61, 62, 63,       -- 翻滚相关id
    260, 261, 263, 287,   -- 蓄力状态id
  },
  
  -- 功能函数
  checkMotionState = function()
    return checkMotionState(config[CONST.WeaponType.Bow], CONST.WeaponType.Bow)
  end,
  
  isEquipped = function()
    return createIsEquipped(config[CONST.WeaponType.Bow], CONST.WeaponType.Bow)
  end,
  
  ActionFun = function()
    return createActionFun(config[CONST.WeaponType.Bow], CONST.WeaponType.Bow)
  end,
}



--------------------------------------------------------------------------------
-- 钩子函数定义
--------------------------------------------------------------------------------

-- 跟踪角色动作请求
---@param args table 函数参数表
mod.HookFunc("app.HunterCharacter", "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 
  function(args)
    if initMaster() then
      -- 获取动作类型定义
      local type = sdk.find_type_definition("ace.ACTION_ID")
      
      -- 获取动作类别和索引
      local newCategory = sdk.get_native_field(args[4], type, "_Category")
      local newIndex = sdk.get_native_field(args[4], type, "_Index")
      
      -- 更新全局状态
      action_cata = newCategory
      action_index = newIndex
    end
  end
)

-- 获取当前武器类型
---@return nil
function getCurrentWeaponType()
  -- 确保主玩家已初始化
  if not masterInitialized then
    initMaster()
    return
  end
  
  -- 确保玩家对象已初始化
  if not player then return end
  
  -- 获取角色对象
  local character = player:call("get_Character")
  if not character then return end
  
  -- 获取武器对象
  local weapon = character:call("get_Weapon")
  if not weapon then return end
  
  -- 获取武器类型
  local wpType = weapon:get_field("_WpType")
  if wpType ~= nil then
      -- 更新全局状态
      CurrentWeaponType = wpType
      -- 从语言字符串表中获取武器名称
      CurrentWeaponTypeName = languageStrings[currentLanguage].weapons[wpType] or languageStrings[currentLanguage].weapons.unknown
      isWeaponOn = character:call("get_IsWeaponOn")
  end
end

-- 检查是否是主玩家受到的怪物攻击
---@param hitinfo userdata 伤害信息对象
---@return boolean 是否满足自动闪避条件
local function checkIsMaster(hitinfo)
  -- 获取攻击者和受击者
  local attackOwner = hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name()
  local damageOwner = hitinfo:get_field("<DamageOwner>k__BackingField"):get_Name()
  
  -- 检查攻击来源是否为怪物
  local isMonsterAttack = fuzzy_match(attackOwner, "Em") or
                          fuzzy_match(attackOwner, "em") or
                          fuzzy_match(attackOwner, "Gm")
                          
  -- 检查是否为治疗效果
  local isHealEffect = fuzzy_match(attackOwner, "Heal")
  
  -- 检查是否为主玩家
  local isMasterPlayer = damageOwner == "MasterPlayer"
  
  -- 检查是否装备了配置的武器
  local isEquipped = false
  if CurrentWeaponType and 
     config[CurrentWeaponType] and 
     type(config[CurrentWeaponType].isEquipped) == "function" then
    isEquipped = config[CurrentWeaponType].isEquipped()
  end
  
  -- 保存伤害来源
  damage_owner = damageOwner
  
  -- 返回是否满足所有条件
  return isMonsterAttack and not isHealEffect and isEquipped and isMasterPlayer
end

-- 攻击检测钩子
mod.HookFunc("app.HunterCharacter", "evHit_Damage(app.HitInfo)",
    -- 攻击前检查
    function(args)
      -- 确保主玩家已初始化
      if not masterInitialized then
        initMaster()
        return
      end
      
      -- 确保武器已拔出
      if not isWeaponOn then
        return
      end
      
      -- 获取伤害信息并检查是否满足条件
      local hitinfo = sdk.to_managed_object(args[3])
      local result = checkIsMaster(hitinfo)
      
      -- 如果满足条件，跳过原始伤害处理
      if result then
        return sdk.PreHookResult.SKIP_ORIGINAL
      else
        damage_owner = ""
      end
    end,
    
    -- 攻击后执行闪避
    function (retval)
      -- 检查是否有对应武器的闪避函数并执行
      if config[CurrentWeaponType] and
         type(config[CurrentWeaponType].ActionFun) == "function" then
        config[CurrentWeaponType].ActionFun()
      end
      return retval
    end
)

-- 每帧更新武器类型
mod.OnFrame(function()
  getCurrentWeaponType()
end)

--------------------------------------------------------------------------------
-- 用户界面 - 菜单定义
--------------------------------------------------------------------------------

-- 创建通用的武器菜单构建函数
---@param weaponType number 武器类型ID
---@param menuTitle string 菜单标题
---@return function 菜单渲染函数
local function createWeaponMenu(weaponType, menuTitle)
  return function()
    -- 分隔符和菜单树节点
    imgui.separator()
    if not imgui.tree_node(menuTitle) then return end
    
    local weaponConfig = config[weaponType]
    
    -- 获取方向本地化名称
    local dirText = {
      forward = L("ui.directions.forward"),
      backward = L("ui.directions.backward"),
      left = L("ui.directions.left"),
      right = L("ui.directions.right")
    }
    
    -- 使用一致的方向索引映射
    local directions = {
      [0] = dirText.backward .. " (" .. weaponConfig.backward .. ")",
      [1] = dirText.left .. " (" .. weaponConfig.left .. ")",
      [2] = dirText.right .. " (" .. weaponConfig.right .. ")",
      [3] = dirText.forward .. " (" .. weaponConfig.forward .. ")"
    }
    
    -- 创建动作索引映射
    local indexMapping = {
      [0] = weaponConfig.backward,
      [1] = weaponConfig.left,
      [2] = weaponConfig.right,
      [3] = weaponConfig.forward
    }

    -- 创建方向数组用于UI显示
    local directionsArray = {}
    for i=0, 3 do
      directionsArray[i+1] = directions[i]
    end
    
    -- 找到当前选择的索引
    local currentDodgeIndex = weaponConfig.ActionIndex
    local currentDirectionIndex = 0
    for i=0, 3 do
      if indexMapping[i] == currentDodgeIndex then
        currentDirectionIndex = i
        break
      end
    end
    
    -- 创建下拉选择器
    local changed
    changed, currentDirectionIndex = imgui.combo(L("ui.dodge_direction"), currentDirectionIndex + 1, directionsArray)
    if changed then
      -- 转换回实际的动作索引
      weaponConfig.ActionIndex = indexMapping[currentDirectionIndex - 1]
      configChanged = true
    end
    
    imgui.separator()
    imgui.text(L("ui.current_selection") .. directions[currentDirectionIndex - 1])

    -- 创建冷却时间控件
    local cooldownValue = weaponConfig.CD
    changed, cooldownValue = imgui.drag_float(L("ui.cooldown_time"), 
        cooldownValue, 0.1, 0.0, 10.0, "%.1f")
    if changed then
        weaponConfig.CD = cooldownValue
        configChanged = true
    end

    -- 显示冷却剩余时间
    local remainingCD = math.max(0, weaponConfig.CD - (os.clock() - weaponConfig.lasterDodgeTime))
    imgui.text(L("ui.remaining_cooldown") .. string.format("%.2f", remainingCD))
    
    imgui.tree_pop()
    
    -- 如果是弓，添加额外的分隔符
    if weaponType == CONST.WeaponType.Bow then
      imgui.separator()
    end
  end
end

-- 创建双刀菜单和弓菜单函数
local function DualBladesMenu()
  createWeaponMenu(CONST.WeaponType.DualBlades, L("ui.dualblades_config"))()
end

local function BowMenu()
  createWeaponMenu(CONST.WeaponType.Bow, L("ui.bow_config"))()
end

-- 调试信息菜单
---@param configChanged boolean 配置是否变更
local function DebugMenu(configChanged)
  imgui.separator()
  if imgui.tree_node(L("ui.debug_info")) then
    -- 显示武器类型
    imgui.text(L("ui.weapon_type") .. ": " .. CurrentWeaponTypeName)
    
    -- 显示伤害来源
    imgui.text(L("ui.damage_source") .. ": " .. damage_owner)
    
    -- 显示动作信息
    imgui.text(L("ui.action_category") .. ": " .. tostring(action_cata))
    imgui.text(L("ui.action_index") .. ": " .. tostring(action_index))
    imgui.text(L("ui.motion_id") .. ": " .. tostring(motionID))
    
    -- 显示武器状态
    imgui.text(L("ui.weapon_equipped") .. ": " .. tostring(isWeaponOn))
    
    -- 显示当前语言
    imgui.text(L("ui.current_language") .. ": " .. currentLanguage)
    
    -- 如果有待保存的配置，则显示保存按钮
    if configChanged and imgui.button(L("ui.save_config")) then
      json.dump_file("auto_DualBlades_Dodge.json", config)
    end
    
    imgui.tree_pop()
  end
end

-- 语言选择菜单
local function LanguageMenu()
  imgui.separator()
  if imgui.tree_node(L("ui.language")) then
    local languages = {
      { id = "cn", name = L("ui.cn") },
      { id = "en", name = L("ui.en") }
    }
    
    local selectedIndex = currentLanguage == "cn" and 1 or 2
    local changed, newIndex = imgui.combo("##language", selectedIndex, { languages[1].name, languages[2].name })
    
    if changed then
      currentLanguage = languages[newIndex].id
      -- 强制刷新当前武器名称
      if CurrentWeaponType then
        CurrentWeaponTypeName = languageStrings[currentLanguage].weapons[CurrentWeaponType] or languageStrings[currentLanguage].weapons.unknown
      end
    end
    
    imgui.tree_pop()
  end
end

-- 主菜单函数
mod.Menu(function()
  local configChanged = false
  
  -- 语言选择菜单
  LanguageMenu()
  
  -- 调试信息菜单
  DebugMenu(configChanged)
  
  -- 武器配置菜单
  DualBladesMenu()
  BowMenu()
end)

-- 启动模组
mod.Run()
