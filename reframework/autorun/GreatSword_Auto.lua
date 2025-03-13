local Core = require("_CatLib")
local CONST = require("_CatLib.const")
local timer = require("_CatLib.utils.timer")
local _player = require("_CatLib.game.player")
local _singleton = require("_CatLib.game.singletons")
local mod = Core.NewMod("GreatSword Auto","GreatSword_Auto")
mod.EnableCJKFont(24) -- 启用中文字体

local NewActionID = Core.NewActionID
-- 在这里定义返回值
-- @field MotionID -- 动作id
-- @field IsWeaponOn -- 武器是否上
-- @field CurrentWeaponType -- 武器类型
-- @field isCharging -- 蓄力中
-- @type playerMotionData
local playerMotionData = {
    MotionID = nil,
    CurrentWeaponType = nil,
    IsWeaponOn = nil,
    isCharging = false
}

if mod.Config.CD == nil then
  mod.Config.CD = 1
end

if mod.Config.needGuard == nil then
  mod.Config.needGuard = true

end

if mod.Config.needShoulder == nil then
  mod.Config.needShoulder = true
end
-- 原始值
local originallyAngles = 70
if mod.Config.angles == nil then
  mod.Config.angles = 70
end

local config = {}

function checkMotionState(weaponConfig, weaponType)
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
if not playerMotionData.MotionID or weaponConfig.excludedActionMap[playerMotionData.MotionID] then
    return false
end

return true
end

local function createActionFun(weaponConfig, weaponType, category, index)
    category = category or 2 -- 默认类别为2
    index = index or weaponConfig.ActionIndex -- 默认索引为配置中的ActionIndex
      local actionID = NewActionID(category, index)
      local player = _player.GetInfo()
    if player:get_Character():call(
        "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)",
        0, 
        actionID, 
        false
    ) then
      weaponConfig.lasterDodgeTime = os.clock()
    end
  end
local function createIsEquipped(weaponConfig, weaponType)
    -- 检查武器类型，动作状态和冷却时间
    local CD = mod.Config.CD
    local CurrentWeaponType = playerMotionData.CurrentWeaponType
    return CurrentWeaponType == weaponType and
        weaponConfig.checkMotionState() and
        math.max(0, CD - (os.clock() - weaponConfig.lasterDodgeTime)) <= 0 

end
  
config[CONST.WeaponType.GreatSword] = {
    guard = 141,
    -- 是否格挡
    needGuard = true,
    -- 肩撞索引
    shoulder = 15,
    -- 是否肩撞
    needShoulder = true,
    isCharging = false,
    ActionIndex = 141, -- 选择动作索引，默认为格挡
    lasterDodgeTime = 0,
    CD = 0.5,
    excludedActionIndices = {
      213,217,237,248,476,474,18,19 -- 都是蓄力斩的斩击id
    },  -- 排除动作id
    checkMotionState = function()
      return checkMotionState(config[CONST.WeaponType.GreatSword], CONST.WeaponType.GreatSword)
    end,
    isEquipped = function ()
      -- 根据当前状态判断是否执行动作
      local needGuard = mod.Config.needGuard
      local needShoulder = mod.Config.needShoulder
      if playerMotionData.isCharging then
        -- 蓄力状态下，检查是否需要肩撞
        if not needShoulder then
          return false
        end
      else
        -- 非蓄力状态下，检查是否需要格挡
        if not needGuard then
          return false
        end
      end
      return createIsEquipped(config[CONST.WeaponType.GreatSword], CONST.WeaponType.GreatSword)
    end,
    ActionFun = function ()
      local category = 1
      local index = config[CONST.WeaponType.GreatSword].guard
      if playerMotionData.isCharging then
        category = 2
        index = config[CONST.WeaponType.GreatSword].shoulder
      end
      return createActionFun(config[CONST.WeaponType.GreatSword], CONST.WeaponType.GreatSword, category, index)
    end,
  }

  

local function onChangeAngles()
  local cataLog = Core.GetPlayerCatalogHolder()
  if not cataLog then return end
  local param = cataLog:get_Wp00ActionParam()
  if param then
    param._GuardDegree = mod.Config.angles
  end
end

mod.OnPreUpdateBehavior(function ()
    local motionData = Core.GetPlayerMotionData()
    if not motionData then return end
    onChangeAngles()
    motionData.Category = playerMotionData.Category
    motionData.Index = playerMotionData.Index
    motionData.CurrentWeaponType = _player.GetWeaponType()
    motionData.isCharging = playerMotionData.isCharging
    local playerCharacter = _player.GetCharacter()
    if playerCharacter then
        motionData.IsWeaponOn = playerCharacter:call("get_IsWeaponOn")
    end
    playerMotionData = motionData
end)

mod.OnDebugFrame(
    function ()
      imgui.text("CD: " .. string.format("%.2f", math.max(0, mod.Config.CD - (os.clock() - config[CONST.WeaponType.GreatSword].lasterDodgeTime))))
      imgui.text("angles: " .. tostring(mod.Config.angles))
    end
)

local function fuzzy_match(str, pattern)
  return string.find(str, pattern) ~= nil
end

local function checkHarm(hitinfo)
    local k__BackingField = hitinfo:get_field('<AttackOwner>k__BackingField'):get_Name()
    local player = hitinfo:get_field("<DamageOwner>k__BackingField"):get_Name()
    local em = fuzzy_match(k__BackingField, "Em")
    local minEm = fuzzy_match(k__BackingField, "em")
    local gm = fuzzy_match(k__BackingField, "Gm")
    local heal = fuzzy_match(k__BackingField, "Heal")
    local isMasterPlayer = player == "MasterPlayer"
    local isEquipped = false
    local CurrentWeaponType = playerMotionData.CurrentWeaponType
    if CurrentWeaponType and config[CurrentWeaponType] and type(config[CurrentWeaponType].isEquipped) == "function" then
      isEquipped = config[CurrentWeaponType].isEquipped()
    end
    return (em == true or gm == true or minEm == true) and heal == false and isEquipped and isMasterPlayer
end
local isAction = false
local function onStatusFlag()
    local hunterCharacter = Core.GetPlayerCharacter()
    if not hunterCharacter then return end
    if playerMotionData.isCharging then
        hunterCharacter:onHunterStatusFlag(0)
        hunterCharacter:onHunterStatusFlag(8)
    else
        hunterCharacter:onHunterStatusFlag(4)
    end
end

local function offStatusFlag()
    local hunterCharacter = Core.GetPlayerCharacter()
    if not hunterCharacter then return end
    hunterCharacter:get_HunterStatus():get_field("_HunterStatusFlag"):off(0)
    hunterCharacter:get_HunterStatus():get_field("_HunterStatusFlag"):off(8)
    hunterCharacter:get_HunterStatus():get_field("_HunterStatusFlag"):off(4)
end

-- app.HunterCharacter.evHit_ShellDamagePreProcess
mod.HookFunc("app.HunterCharacter", "evHit_ShellDamagePreProcess(app.HitInfo)", 
  function(args)
  local hitInfo = sdk.to_managed_object(args[3])
    local CurrentWeaponType = playerMotionData.CurrentWeaponType
    if config[CurrentWeaponType] and
    type(config[CurrentWeaponType].ActionFun) == "function" and
    playerMotionData.CurrentWeaponType == CONST.WeaponType.GreatSword and
    playerMotionData.IsWeaponOn
    then
      isAction = checkHarm(hitInfo)
      if isAction then
        onStatusFlag()
        config[CurrentWeaponType].ActionFun()
      end
    end
end
)

mod.OnFrame(function ()
    if isAction then
      offStatusFlag()
    end
end)

mod.Menu(function ()
  local changed
  local configChanged
  changed, mod.Config.CD = imgui.slider_float("CD", 
  mod.Config.CD, 0.0, 10.0)
  configChanged = configChanged or changed

  changed, mod.Config.angles = imgui.slider_float("angles", 
  mod.Config.angles,  0.0, 360.0)
  configChanged = configChanged or changed

  changed, mod.Config.needShoulder = imgui.checkbox("needShoulder", 
  mod.Config.needShoulder)
  configChanged = configChanged or changed

  changed, mod.Config.needGuard = imgui.checkbox("needGuard", 
  mod.Config.needGuard)
  configChanged = configChanged or changed

  return configChanged
end)

mod.Run()

-- Hook大剑蓄力开始函数
mod.HookFunc(
  "app.Wp00Action.cChargeBase",
  "doEnter()",
  function(args)
    playerMotionData.isCharging = true
    return sdk.PreHookResult.CALL_ORIGINAL
  end
)

-- Hook大剑蓄力结束函数
mod.HookFunc(
  "app.Wp00Action.cChargeBase",
  "doExit()",
  function(args)
    playerMotionData.isCharging = false
    return sdk.PreHookResult.CALL_ORIGINAL
  end
)
