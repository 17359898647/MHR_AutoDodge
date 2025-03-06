local cfg = {} -- 配置对象，存储显示相关的各种参数设置

if not cfg.rec_margin then cfg.rec_margin = 10 end -- 矩形边距，单位为像素
if not cfg.line_space then cfg.line_space = 30 end -- 行间距，单位为像素

if not cfg.general_x then cfg.general_x = 1000 end -- 显示区域X坐标起始位置
if not cfg.general_y then cfg.general_y = 100 end -- 显示区域Y坐标起始位置
if not cfg.general_cap_width then cfg.general_cap_width = 350 end -- 标题区域宽度
if not cfg.general_width then cfg.general_width = 120 end -- 内容区域宽度

local total_line = 0 -- 总行数计数器
local general_line = 0 -- 当前行计数器
-- top left of rectengle

local printGeneralLine = function(cap, value, --[[optional]]value_color)
	draw.text(cap, cfg.general_x + cfg.rec_margin, cfg.general_y + cfg.rec_margin + general_line * cfg.line_space, 0xFFFFFFFF)
	if value == true then
		value = "true"
		value_color = value_color or 0xFF00FF00 --default value
	elseif value == false then
		value = "false"
		value_color = value_color or 0xFFFFFFFF --default value
	elseif value == nil then
		value = "nil"
		value_color = value_color or 0xFF808080 --default value
	end

    value_color = value_color or 0xFFFFFFFF --default value
	if value then
		draw.text(tostring(value), cfg.general_x + cfg.general_cap_width + cfg.rec_margin, cfg.general_y + general_line * cfg.line_space + cfg.rec_margin, value_color)
	end
	general_line = general_line + 1
end

local PlayMan -- 玩家管理器实例（PlayerManager）
local function getPlayMan()
    if not PlayMan then
        PlayMan = sdk.get_managed_singleton("app.PlayerManager")
    end
    return PlayMan
end

local MasterPlayer -- 主玩家信息（app.cPlayerManageInfo）
local function getMasterPlayer()
    if not MasterPlayer then
        if not getPlayMan() then return nil end
        MasterPlayer = PlayMan:getMasterPlayer()
    end
    return MasterPlayer
end

local HunterController -- 猎人控制器（app.HunterController）
local function getHunterController()
    if not HunterController then
        if not getMasterPlayer() then return nil end
        HunterController = MasterPlayer:get_Controller()
    end
    return HunterController
end

local HunterCharacter -- 猎人角色（app.HunterCharacter）
local function getHunterCharacter()
    if not HunterCharacter then
        if not getMasterPlayer() then return nil end
        HunterCharacter = MasterPlayer:get_Character()
    end
    return HunterCharacter
end

local PlayerObject -- 主玩家对象（MasterPlayerObject）
local function getPlayerObject()
    if not PlayerObject then
        if not getMasterPlayer() then return nil end
        PlayerObject = MasterPlayer:get_Object()
    end
    return PlayerObject
end

local HunterHitController -- 猎人受击控制器
local function getHunterHitController()
    if not HunterHitController then
        if not getHunterCharacter() then return nil end
        HunterHitController = HunterCharacter:get_HitComponent()
    end
    return HunterHitController
end

local HunterMotion -- 猎人动作组件
local function getHunterMotion()
    if not HunterMotion then
        if not getHunterCharacter() then return nil end
        HunterMotion = HunterCharacter:get_MotionComponent()
    end
    return HunterMotion
end

-- HunterCharacter
-- get_MotionComponent()
-- get_HitComponent()
-- get_ColSwitcherComponent()
-- get_CharaCtrl() -- via.physics.CharacterController
-- get_CharaParamHolder()


local playerLabel1 = "melee base attack" -- 近战基础攻击数据显示文本
local playerLabel2 = "shell base attack" -- 弹壳基础攻击数据显示文本
local playerLabel3 = "buffed attack" -- 增益后攻击数据显示文本
local function drawPlayerLabel(text, color, posOffset)
    if not getPlayerObject() then return end
    local PlayerTransform = PlayerObject:get_Transform()
    if not PlayerTransform then return end
    local playerPos =  PlayerTransform:get_Position()

    if playerPos then
        playerPos.y = playerPos.y+posOffset -- hunter height 1.8m
        draw.world_text(text, playerPos, color)
    end

end

local AttackUniqueID = nil -- 攻击唯一ID
local CollisionDataID = nil -- 碰撞数据ID

local CleanUp = function() -- 清理函数，重置所有全局变量
    PlayMan = nil
    MasterPlayer = nil
    HunterController = nil
    HunterCharacter = nil
    PlayerObject = nil
    HunterHitController = nil
    HunterMotion = nil
end

re.on_frame(function()

    if not getHunterCharacter() then CleanUp() return end
    
    local IsWeaponOn = HunterCharacter:get_IsWeaponOn() -- 是否持有武器
    local IsWeaponOnAction = HunterCharacter:get_IsWeaponOnAction() -- 是否正在执行武器动作
    local IsCombat = HunterCharacter:get_IsCombat() -- 是否在战斗状态
    local IsCombatBoss = HunterCharacter:get_IsCombatBoss() -- 是否在与大型怪物战斗
    local IsCombatAngryBoss = HunterCharacter:get_IsCombatAngryBoss() -- 是否在与愤怒状态的大型怪物战斗
    local IsHalfCombat = HunterCharacter:get_IsHalfCombat() -- 是否在半战斗状态
    local IsCombatCageLight = HunterCharacter:get_IsCombatCageLight() -- 是否在笼子光照战斗状态
    local IsInLifeArea = HunterCharacter:get_IsInLifeArea() -- 是否在生活区域
    local IsInBaseCamp = HunterCharacter:get_IsInBaseCamp() -- 是否在基地营地
    local IsInTent = HunterCharacter:get_IsInTent() -- 是否在帐篷中

	if IsWeaponOn or (not IsInLifeArea) then

    general_line = 0

    draw.filled_rect(cfg.general_x, cfg.general_y, 
        cfg.general_width + cfg.general_cap_width + cfg.rec_margin * 2, 
        total_line * cfg.line_space + cfg.rec_margin * 2,
        0x44000000)

    total_line = general_line


    printGeneralLine("IsWeaponOn", IsWeaponOn) -- 显示是否持有武器
    printGeneralLine("IsWeaponOnAction", IsWeaponOnAction) -- 显示是否正在执行武器动作
    printGeneralLine("IsCombat", IsCombat) -- 显示是否在战斗状态
    printGeneralLine("IsCombatBoss", IsCombatBoss) -- 显示是否在与大型怪物战斗
    printGeneralLine("IsCombatAngryBoss", IsCombatAngryBoss) -- 显示是否在与愤怒状态的大型怪物战斗
    printGeneralLine("IsHalfCombat", IsHalfCombat) -- 显示是否在半战斗状态
    printGeneralLine("IsCombatCageLight", IsCombatCageLight) -- 显示是否在笼子光照战斗状态
    printGeneralLine("IsInLifeArea", IsInLifeArea) -- 显示是否在生活区域
    printGeneralLine("IsInBaseCamp", IsInBaseCamp) -- 显示是否在基地营地
    printGeneralLine("IsInTent", IsInTent) -- 显示是否在帐篷中
    
    local BaseActionController = HunterCharacter:get_BaseActionController() -- 获取基础动作控制器
    if BaseActionController then
        local CurrentActionID = BaseActionController._CurrentActionID -- 当前动作ID
        if CurrentActionID then
            printGeneralLine("[Base]CurrentActionID", "["..CurrentActionID:get_Category().."]"..CurrentActionID:get_Index())
        end
        local PrevActionID = BaseActionController._PrevActionID -- 前一个动作ID
        if PrevActionID then
            printGeneralLine("[Base]PrevActionID", "["..PrevActionID:get_Category().."]"..PrevActionID:get_Index())
        end
    end

    local SubActionController = HunterCharacter:get_SubActionController() -- 获取子动作控制器
    if SubActionController then
        local CurrentActionID = SubActionController._CurrentActionID -- 当前子动作ID
        if CurrentActionID then
            printGeneralLine("[Sub]CurrentActionID", "["..CurrentActionID:get_Category().."]"..CurrentActionID:get_Index())
        end
        local PrevActionID = SubActionController._PrevActionID -- 前一个子动作ID
        if PrevActionID then
            printGeneralLine("[Sub]PrevActionID", "["..PrevActionID:get_Category().."]"..PrevActionID:get_Index())
        end
    end

    
    if getPlayerObject() then
        drawPlayerLabel(playerLabel1, 0xFFFFFFFF, 1.8)
        drawPlayerLabel(playerLabel2, 0xFFFFFFFF, 1.9)
        drawPlayerLabel(playerLabel3, 0xFFFFFFFF, 2.0)
    end

    if IsWeaponOn then
        printGeneralLine("AttackUniqueID", AttackUniqueID) -- 显示攻击唯一ID
        printGeneralLine("CollisionDataID", CollisionDataID) -- 显示碰撞数据ID
    end

    total_line = general_line
	end

end)

-- thanks to @orcas
sdk.hook(
    sdk.find_type_definition("app.Weapon"):get_method("evAttackCollisionActive(app.col_user_data.AttackParam)"),
    function(args)
        local AttackParam = sdk.to_managed_object(args[3]) -- 攻击参数对象
        if not AttackParam then return end
        local cRuntimeData = sdk.to_managed_object(AttackParam._RuntimeData) -- 获取运行时数据
        if not cRuntimeData then return end
        AttackUniqueID = cRuntimeData._AttackUniqueID -- 设置攻击唯一ID
        CollisionDataID = cRuntimeData._CollisionDataID._Index -- 设置碰撞数据ID
        
        local Attack = AttackParam:get_Attack() -- 攻击力值
        local TotalAttack = AttackParam:get_TotalAttack() -- 总攻击力值
        local StatusAttrRate = AttackParam:get_StatusAttrRate() -- 状态属性率
        local StatusConditionRate = AttackParam:get_StatusConditionRate() -- 状态条件率

        playerLabel1 = "melee  [ "..Attack.." | "..TotalAttack.." ] "..StatusAttrRate.." / "..StatusConditionRate
    end,
    function (retval)
        return retval
    end
)

-- thanks to @orcas
sdk.hook(
    sdk.find_type_definition("app.mcShellColHit"):get_method(
        "evAttackPreProcess(app.HitInfo)"),
    function(args)
        local HitInfo = sdk.to_managed_object(args[3]) -- 命中信息对象
        if not HitInfo then return end
        if not (HitInfo:getActualAttackOwner():ToString() == getPlayerObject():ToString()) then return end

        local AttackParam = HitInfo:get_field("<AttackData>k__BackingField") -- 攻击数据
        if not AttackParam then return end

        local Attack = AttackParam:get_field("_Attack") -- 攻击力值
        local StatusAttrRate = AttackParam:get_field("_StatusAttrRate") -- 状态属性率
        local StatusConditionRate = AttackParam:get_field("_StatusConditionRate") -- 状态条件率

        playerLabel2 = "shell  [ "..Attack.." | ".." ] "..StatusAttrRate.." / "..StatusConditionRate
    end,
    function (retval)
        return retval
    end
)

-- thanks to @WAI
sdk.hook(
    sdk.find_type_definition("app.HunterCharacter"):get_method("evHit_AttackPostProcess(app.HitInfo)"),
    function(args)
        local HitInfo = sdk.to_managed_object(args[3]) -- 命中信息对象
        if not HitInfo then return end
        if not (HitInfo:getActualAttackOwner():ToString() == getPlayerObject():ToString()) then return end

        local AttackParam = HitInfo:get_field("<AttackData>k__BackingField") -- 攻击数据
        if not AttackParam then return end

        local Attack = AttackParam:get_field("_Attack") -- 攻击力值
        local StatusAttrRate = AttackParam:get_field("_StatusAttrRate") -- 状态属性率
        local StatusConditionRate = AttackParam:get_field("_StatusConditionRate") -- 状态条件率

        playerLabel3 = "buffed [ "..Attack.." | ".." ] "..StatusAttrRate.." / "..StatusConditionRate
    end,
    function (retval)
        return retval
    end
)
